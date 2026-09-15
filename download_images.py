import streamlit as st
import folium
from streamlit_folium import st_folium
import psycopg2
from psycopg2.extras import RealDictCursor
import os

st.set_page_config(
    page_title="Hệ Thống Hướng Dẫn Viên Du Lịch - Thảo Cầm Viên",
    page_icon="🌿",
    layout="wide"
)

st.title("🌿 Hệ Thống Hướng Dẫn Viên Du Lịch Ngoài Trời - Thảo Cầm Viên")

DB_CONFIG = {
    "dbname": "postgis_36_sample",
    "user": "postgres",
    "password": "123456",  # <-- Nhớ đổi đúng mật khẩu PostgreSQL của bạn
    "host": "localhost",
    "port": "5432"
}

def get_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

def get_all_exhibits():
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT id, name, description, audio_file, image_url, 
                   ST_X(geom) AS lng, ST_Y(geom) AS lat 
            FROM exhibits 
            ORDER BY id ASC;
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        st.error(f"Lỗi kết nối cơ sở dữ liệu: {e}")
        return []

def query_nearby(lat: float, lng: float, radius: float = 50.0):
    try:
        conn = get_connection()
        cur = conn.cursor()
        query = """
            SELECT 
                id, 
                name, 
                description, 
                audio_file, 
                image_url,
                ROUND(ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography)::numeric, 1) AS distance_meters
            FROM exhibits
            WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, %s)
            ORDER BY distance_meters ASC;
        """
        cur.execute(query, (lng, lat, lng, lat, radius))
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        st.error(f"Lỗi truy vấn không gian PostGIS: {e}")
        return []

IMG_MAPPING = {
    1: "thu_an_thit.jpg",
    2: "chuong_voi.jpg",
    3: "linh_truong.jpg",
    4: "bo_sat.jpg",
    5: "vuon_lan.jpg",
    6: "vui_choi.jpg"
}

all_exhibits = get_all_exhibits()

if "user_lat" not in st.session_state:
    st.session_state.user_lat = 10.78752
if "user_lng" not in st.session_state:
    st.session_state.user_lng = 106.70526

with st.sidebar:
    st.header("🎮 Điều Khiển Mô Phỏng (GPS)")
    st.caption("Bấm nút để di chuyển nhanh bước chân đến từng phân khu:")
    
    for item in all_exhibits:
        if st.button(f"🚶 Đến: {item['name']}", key=f"btn_{item['id']}", use_container_width=True):
            st.session_state.user_lat = item['lat']
            st.session_state.user_lng = item['lng']
            st.rerun()

    st.markdown("---")
    st.markdown("**Bán kính quét hiện vật:** 50 mét")

col_map, col_info = st.columns([7, 5])

with col_map:
    st.subheader("📍 Bản đồ Thảo Cầm Viên")
    
    fmap = folium.Map(
        location=[st.session_state.user_lat, st.session_state.user_lng],
        zoom_start=17,
        tiles="OpenStreetMap"
    )

    for item in all_exhibits:
        folium.Marker(
            location=[item['lat'], item['lng']],
            tooltip=item['name'],
            popup=item['name'],
            icon=folium.Icon(color="green", icon="leaf", prefix="fa")
        ).add_to(fmap)

    folium.Marker(
        location=[st.session_state.user_lat, st.session_state.user_lng],
        tooltip="Vị trí của bạn",
        icon=folium.Icon(color="red", icon="user", prefix="fa")
    ).add_to(fmap)

    folium.Circle(
        location=[st.session_state.user_lat, st.session_state.user_lng],
        radius=50,
        color="#1a73e8",
        fill=True,
        fill_color="#4285f4",
        fill_opacity=0.2
    ).add_to(fmap)

    map_out = st_folium(fmap, width="100%", height=560, returned_objects=["last_clicked"])

    if map_out and map_out.get("last_clicked"):
        c_lat = map_out["last_clicked"]["lat"]
        c_lng = map_out["last_clicked"]["lng"]
        if round(c_lat, 5) != round(st.session_state.user_lat, 5) or round(c_lng, 5) != round(st.session_state.user_lng, 5):
            st.session_state.user_lat = c_lat
            st.session_state.user_lng = c_lng
            st.rerun()

with col_info:
    st.subheader("🎧 Hướng Dẫn Viên Thuyết Minh")
    st.markdown(f"**Tọa độ hiện tại:** `{st.session_state.user_lat:.5f}, {st.session_state.user_lng:.5f}`")
    
    nearby = query_nearby(st.session_state.user_lat, st.session_state.user_lng, radius=50.0)

    if nearby:
        target = nearby[0]
        st.success(f"🎯 **Hiện vật gần nhất:** {target['name']}")
        st.markdown(f"📏 **Khoảng cách:** `{target['distance_meters']} mét`")
        st.write(target['description'])
        
        img_file = IMG_MAPPING.get(target['id'])
        local_img = os.path.join("images", img_file) if img_file else None
        
        if local_img and os.path.exists(local_img):
            st.image(local_img, caption=target['name'], use_container_width=True)
        elif target.get('image_url') and str(target.get('image_url')).startswith("http"):
            st.image(target['image_url'], caption=target['name'], use_container_width=True)

        audio_file = os.path.join("audio", target['audio_file']) if target.get('audio_file') else None
        if audio_file and os.path.exists(audio_file):
            st.audio(audio_file, format="audio/mp3", autoplay=True)
        else:
            st.warning("Đang chuẩn bị file âm thanh...")
    else:
        st.info("🚶 Không có phân khu nào trong bán kính 50m. Hãy bấm các nút bên trái hoặc click gần các biểu tượng màu xanh lá trên bản đồ!")