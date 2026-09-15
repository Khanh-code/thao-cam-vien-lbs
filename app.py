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

st.title("Hệ Thống Hướng Dẫn Viên Du Lịch Ngoài Trời - Thảo Cầm Viên")

# Cấu hình Database
# Cấu hình Database: đọc từ st.secrets khi chạy trên Streamlit Cloud
if "postgres" in st.secrets:
    DB_CONFIG = {
        "dbname": st.secrets["postgres"]["dbname"],
        "user": st.secrets["postgres"]["user"],
        "password": st.secrets["postgres"]["password"],
        "host": st.secrets["postgres"]["host"],
        "port": str(st.secrets["postgres"]["port"]),
        "sslmode": "require"
    }
else:
    # Fallback khi chạy thử nghiệm offline trên máy tính
    DB_CONFIG = {
        "dbname": "postgis_36_sample",
        "user": "postgres",
        "password": "YOUR_LOCAL_PASSWORD",
        "host": "localhost",
        "port": "5432"
    }
# Danh sách file ảnh theo từng phân khu
EXHIBIT_IMAGES = {
    1: ["1.jpg", "9.jpg", "10.jpg"],
    2: ["2.jpg", "11.jpg"],
    3: ["3.jpg", "4.jpg", "5.jpg"],
    4: ["6.jpg", "7.jpg", "8.jpg"],
    5: ["12.jpg", "13.jpg"],
    6: ["14.jpg", "15.jpg", "16.jpg", "17.jpg"]
}

def get_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

def get_all_exhibits():
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT id, name, description, audio_file, 
                   ST_X(geom) AS lng, ST_Y(geom) AS lat 
            FROM exhibits 
            ORDER BY id ASC;
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return rows
    except Exception as e:
        st.error(f"Lỗi cơ sở dữ liệu: {e}")
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

all_exhibits = get_all_exhibits()

if "user_lat" not in st.session_state:
    st.session_state.user_lat = 10.78775
if "user_lng" not in st.session_state:
    st.session_state.user_lng = 106.70560
if "img_index" not in st.session_state:
    st.session_state.img_index = 0

# --- SIDEBAR: ĐIỀU KHIỂN MÔ PHỎNG ---
with st.sidebar:
    st.header("🎮 Địa Điểm Checkin")

    # 1. Tìm kiếm
    st.subheader("1. Tìm kiếm vị trí")
    keyword = st.text_input("Gõ tên hoặc đặc điểm:", placeholder="voi, hổ, bò sát, vườn lan...")
    if keyword:
        results = [
            item for item in all_exhibits 
            if keyword.lower() in item['name'].lower() or keyword.lower() in item['description'].lower()
        ]
        if results:
            st.write(f"Kết quả tìm kiếm ({len(results)}):")
            for r in results:
                if st.button(r['name'], key=f"search_{r['id']}", use_container_width=True):
                    st.session_state.user_lat = r['lat']
                    st.session_state.user_lng = r['lng']
                    st.session_state.img_index = 0
                    st.rerun()
        else:
            st.warning("Không tìm thấy kết quả.")

    st.markdown("---")

    # 2. Danh sách chọn nhanh
    st.subheader("2. Danh Sách Chọn Theo Phân Khu")
    for item in all_exhibits:
        if st.button(item['name'], key=f"select_{item['id']}", use_container_width=True):
            st.session_state.user_lat = item['lat']
            st.session_state.user_lng = item['lng']
            st.session_state.img_index = 0
            st.rerun()

    st.markdown("---")
    st.caption("Bán kính phát hiện GPS: **50 mét**")

# --- GIAO DIỆN CHÍNH ---
col_map, col_info = st.columns([7, 5])

with col_map:
    st.subheader("📍 Bản đồ Thảo Cầm Viên")
    
    # Nền bản đồ Esri rõ đường nét Thảo Cầm Viên
    fmap = folium.Map(
        location=[st.session_state.user_lat, st.session_state.user_lng],
        zoom_start=18,
        tiles="https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}",
        attr="Esri"
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
        fill_opacity=0.25
    ).add_to(fmap)

    map_out = st_folium(fmap, width="100%", height=560, returned_objects=["last_clicked"])

    if map_out and map_out.get("last_clicked"):
        c_lat = map_out["last_clicked"]["lat"]
        c_lng = map_out["last_clicked"]["lng"]
        if round(c_lat, 5) != round(st.session_state.user_lat, 5) or round(c_lng, 5) != round(st.session_state.user_lng, 5):
            st.session_state.user_lat = c_lat
            st.session_state.user_lng = c_lng
            st.session_state.img_index = 0
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
        
        # --- BỘ TRÌNH CHIẾU ẢNH (SLIDER & ZOOM) ---
        img_list = EXHIBIT_IMAGES.get(target['id'], [])
        valid_images = [img for img in img_list if os.path.exists(os.path.join("images", img))]

        if valid_images:
            idx = st.session_state.img_index % len(valid_images)
            current_img_path = os.path.join("images", valid_images[idx])
            st.image(
                current_img_path, 
                caption=f"{target['name']} ({idx + 1}/{len(valid_images)})", 
                use_container_width=True
            )
            # Hai nút chuyển ảnh qua lại
            c_prev, c_txt, c_next = st.columns([1, 2, 1])
            with c_prev:
                if st.button("◀ Trước", key="btn_img_prev", use_container_width=True):
                    st.session_state.img_index = (idx - 1) % len(valid_images)
                    st.rerun()
            
            with c_next:
                if st.button("Sau ▶", key="btn_img_next", use_container_width=True):
                    st.session_state.img_index = (idx + 1) % len(valid_images)
                    st.rerun()
        else:
            st.info("💡 Đặt các file ảnh (.jpg) vào thư mục `images/` để hiển thị.")

        # Trình phát âm thanh
        audio_file = os.path.join("audio", str(target.get('audio_file')))
        if os.path.exists(audio_file):
            st.audio(audio_file, format="audio/mp3", autoplay=True)
        else:
            st.warning("Đang chuẩn bị file âm thanh...")
    else:
        st.info("🚶 Không có phân khu nào trong bán kính 50m. Hãy click vào các biểu tượng màu xanh lá trên bản đồ hoặc chọn ở danh mục bên trái!")
