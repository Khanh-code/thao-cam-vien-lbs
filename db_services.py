import psycopg2
from psycopg2.extras import RealDictCursor
import streamlit as st
from config import DB_CONFIG

def get_connection():
    """Tạo kết nối mới tới cơ sở dữ liệu PostgreSQL."""
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

@st.cache_data(ttl=600, show_spinner=False)
def get_all_exhibits():
    """Truy vấn danh sách tất cả các điểm trưng bày kèm tọa độ và polygon ranh giới."""
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT id, name, description, audio_file, 
                   ST_X(geom) AS lng, ST_Y(geom) AS lat,
                   ST_AsGeoJSON(geom_poly) AS poly_geojson
            FROM exhibits 
            ORDER BY id ASC;
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        st.error(f"Lỗi cơ sở dữ liệu khi tải danh sách phân khu: {e}")
        return []

@st.cache_data(ttl=600, show_spinner=False)
def get_all_walkways():
    """Truy vấn toàn bộ mạng lưới đường đi bộ nội khu từ PostGIS (có lưu cache)."""
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, name, ST_AsGeoJSON(geom) AS geom_json FROM walkways;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        st.error(f"Lỗi khi tải mạng lưới đường đi: {e}")
        return []

def query_nearby(lat: float, lng: float, radius: float = 50.0):
    """
    Truy vấn không gian ST_DWithin phát hiện các phân khu nằm trong bán kính người dùng.
    Hàm này không dùng cache tĩnh vì tọa độ người dùng thay đổi theo thời gian thực.
    """
    try:
        conn = get_connection()
        cur = conn.cursor()
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
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        st.error(f"Lỗi truy vấn không gian PostGIS: {e}")
        return []

def get_shortest_path(user_lat: float, user_lng: float, target_lat: float, target_lng: float):
    """Thuật toán tìm đường ngắn nhất pgr_dijkstra qua mạng lưới walkways."""
    try:
        conn = get_connection()
        cur = conn.cursor()
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
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        st.error(f"Lỗi tìm đường pgRouting: {e}")
        return []