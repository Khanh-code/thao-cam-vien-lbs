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

@contextmanager
def database_cursor():
    pool, slots = resources()
    if not slots.acquire(timeout=10):
        raise TimeoutError("Database is busy")
    conn = None
    try:
        conn = pool.getconn()
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

@st.cache_data(ttl=600, show_spinner=False)
def get_all_exhibits():
    """Truy vấn danh sách tất cả các điểm trưng bày kèm tọa độ và polygon ranh giới."""
    with database_cursor() as cur:
        cur.execute("""
            SELECT id, name, description, audio_file, 
                   ST_X(geom) AS lng, ST_Y(geom) AS lat,
                   ST_AsGeoJSON(geom_poly) AS poly_geojson
            FROM exhibits 
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
    with database_cursor() as cur:
        query = """
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
            WHERE ST_DWithin(
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
