from contextlib import contextmanager
from threading import BoundedSemaphore
import psycopg2
from psycopg2.pool import ThreadedConnectionPool
from psycopg2.extras import RealDictCursor
import streamlit as st
from config import DB_CONFIG, POOL_SIZE

@st.cache_resource
def resources():
    return (ThreadedConnectionPool(1, POOL_SIZE, **DB_CONFIG),
            BoundedSemaphore(POOL_SIZE))

def _healthy_connection(pool, attempts=3):
    """Lấy kết nối từ pool và kiểm tra còn sống không.

    Neon tự tạm dừng (auto-suspend) khi không ai truy cập vài phút và cắt mọi kết nối;
    kết nối cũ nằm trong pool sẽ báo "connection already closed". Kết nối hỏng thì bỏ đi
    và mở kết nối mới (lần đầu Neon thức dậy có thể mất vài giây)."""
    last_error = None
    for _ in range(attempts):
        conn = pool.getconn()
        try:
            if not conn.closed:
                with conn.cursor() as cur:
                    cur.execute('SELECT 1')
                conn.rollback()
                return conn
        except (psycopg2.InterfaceError, psycopg2.OperationalError) as exc:
            last_error = exc
        pool.putconn(conn, close=True)
    raise last_error or psycopg2.InterfaceError('connection already closed')


@contextmanager
def database_cursor():
    pool, slots = resources()
    if not slots.acquire(timeout=10):
        raise TimeoutError("Database is busy")
    conn = None
    try:
        conn = _healthy_connection(pool)
        with conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                # Chỉ áp dụng trong transaction hiện tại -> tương thích Neon pooler
                cur.execute("SET LOCAL statement_timeout = '15s'")
                yield cur
    finally:
        try:
            if conn is not None:
                pool.putconn(conn, close=bool(conn.closed))
        finally:
            slots.release()

@st.cache_data(ttl=60, show_spinner=False)
def zones_v2():
    """True nếu database đã chạy migration 007 (cột is_active, color + bảng exhibit_images)."""
    with database_cursor() as cur:
        cur.execute("""SELECT COUNT(*) AS n FROM information_schema.columns
                       WHERE table_name = 'exhibits' AND column_name IN ('is_active', 'color')""")
        return cur.fetchone()['n'] == 2


def active_sql(alias=''):
    """Điều kiện chỉ lấy khu còn hiển thị (khu đã xoá bị ẩn). Database cũ -> lấy tất cả."""
    return f'{alias}is_active' if zones_v2() else 'TRUE'


@st.cache_data(ttl=600, show_spinner=False)
def get_all_exhibits():
    """Truy vấn danh sách tất cả các điểm trưng bày kèm tọa độ và polygon ranh giới."""
    with database_cursor() as cur:
        color = 'color' if zones_v2() else 'NULL::text AS color'
        cur.execute(f"""
            SELECT id, name, description, audio_file, {color},
                   ST_X(geom) AS lng, ST_Y(geom) AS lat,
                   ST_AsGeoJSON(geom_poly) AS poly_geojson
            FROM exhibits
            WHERE {active_sql()}
            ORDER BY id ASC;
        """)
        rows = cur.fetchall()
        return rows

@st.cache_data(ttl=600, show_spinner=False)
def get_all_walkways():
    """Truy vấn toàn bộ mạng lưới đường đi bộ nội khu từ PostGIS (có lưu cache)."""
    with database_cursor() as cur:
        cur.execute("SELECT id, name, ST_AsGeoJSON(geom) AS geom_json FROM walkways;")
        rows = cur.fetchall()
        return rows

@st.cache_data(ttl=5, max_entries=2048, show_spinner=False)
def query_nearby(lat: float, lng: float, radius: float = 50.0):
    """
    Truy vấn không gian ST_DWithin phát hiện các phân khu nằm trong bán kính người dùng.
    Cache ngắn 5 giây theo tọa độ, giới hạn số mục để tránh tăng RAM vô hạn.
    """
    active = active_sql()
    with database_cursor() as cur:
        query = f"""
            SELECT 
                id, 
                name, 
                description, 
                audio_file, 
                ROUND(
                    COALESCE(
                        ST_Distance(geom_poly::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography),
                        ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography)
                    )::numeric, 1
                ) AS distance_meters
            FROM exhibits
            WHERE {active} AND ST_DWithin(
                COALESCE(geom_poly::geography, geom::geography), 
                ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, 
                %s
            )
            ORDER BY distance_meters ASC;
        """
        cur.execute(query, (lng, lat, lng, lat, lng, lat, radius))
        rows = cur.fetchall()
        return rows

@st.cache_data(ttl=60, max_entries=1024, show_spinner=False)
def get_shortest_path(user_lat: float, user_lng: float, target_lat: float, target_lng: float):
    """Thuật toán tìm đường ngắn nhất pgr_dijkstra qua mạng lưới walkways."""
    with database_cursor() as cur:
        query = """
            WITH 
            start_vertex AS (
                SELECT id FROM walkways_vertices_pgr 
                ORDER BY the_geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326) 
                LIMIT 1
            ),
            end_vertex AS (
                SELECT id FROM walkways_vertices_pgr 
                ORDER BY the_geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326) 
                LIMIT 1
            ),
            dijkstra_route AS (
                SELECT 
                    r.seq,
                    r.node,
                    r.edge,
                    r.cost,
                    CASE 
                        WHEN r.node = w.target THEN ST_Reverse(w.geom) 
                        ELSE w.geom 
                    END AS ordered_geom
                FROM pgr_dijkstra(
                    'SELECT id, source, target, cost, reverse_cost FROM walkways',
                    (SELECT id FROM start_vertex),
                    (SELECT id FROM end_vertex),
                    directed := false
                ) AS r
                JOIN walkways AS w ON r.edge = w.id
                ORDER BY r.seq
            )
            SELECT ST_AsGeoJSON(ordered_geom) AS geom_json, cost FROM dijkstra_route;
        """
        cur.execute(query, (user_lng, user_lat, target_lng, target_lat))
        rows = cur.fetchall()
        return rows


# Các phần database mà từng migration tạo ra -> dùng để báo admin đang thiếu migration nào
SCHEMA_CHECKS = [
    ('001', 'bảng exhibit_translations', "SELECT to_regclass('public.exhibit_translations') IS NOT NULL"),
    ('003', 'bảng admin_users / visitors', "SELECT to_regclass('public.admin_users') IS NOT NULL AND to_regclass('public.visitors') IS NOT NULL"),
    ('004', 'cột audio_data (giọng đọc)', "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='exhibit_translations' AND column_name='audio_data')"),
    ('004', 'cho phép ngôn ngữ zh (tiếng Trung)', "SELECT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='exhibit_translations_language_check' AND pg_get_constraintdef(oid) LIKE '%zh%')"),
    ('006', 'cột kiểm tra bản dịch + bảng glossary', "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='exhibit_translations' AND column_name='quality') AND to_regclass('public.glossary') IS NOT NULL"),
]


def missing_schema():
    """Trả về danh sách (migration, mô tả) còn thiếu trên database đang kết nối."""
    missing = []
    with database_cursor() as cur:
        for migration, label, sql in SCHEMA_CHECKS:
            cur.execute(sql)
            if not list(cur.fetchone().values())[0]:
                missing.append((migration, label))
    return missing
