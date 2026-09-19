import json
import os
import streamlit as st
import folium
from streamlit_folium import st_folium

from config import COLOR_PALETTE, EXHIBIT_IMAGES
from db_services import get_all_exhibits, get_all_walkways, query_nearby, get_shortest_path

st.set_page_config(
    page_title="Hệ Thống Hướng Dẫn Viên Du Lịch - Thảo Cầm Viên",
    page_icon="🌿",
    layout="wide"
)

st.title("Hệ Thống Hướng Dẫn Viên Du Lịch Ngoài Trời - Thảo Cầm Viên")

# Tải dữ liệu thông qua module dịch vụ (đã có cơ chế cache tối ưu)
all_exhibits = get_all_exhibits()
all_walkways = get_all_walkways()

# Khởi tạo trạng thái phiên làm việc (Session State)
if "user_lat" not in st.session_state:
    st.session_state.user_lat = 10.78775
if "user_lng" not in st.session_state:
    st.session_state.user_lng = 106.70560
if "img_index" not in st.session_state:
    st.session_state.img_index = 0
if "target_route_id" not in st.session_state:
    st.session_state.target_route_id = None

# --- KHUNG ĐIỀU KHIỂN BÊN TRÁI (SIDEBAR) ---
with st.sidebar:
    st.header("🎮 Bảng Điều Khiển")

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
                    st.session_state.target_route_id = None
                    st.rerun()
        else:
            st.warning("Không tìm thấy kết quả.")

    st.markdown("---")

    st.subheader("2. Chọn Nhanh Phân Khu")
    for item in all_exhibits:
        if st.button(item['name'], key=f"select_{item['id']}", use_container_width=True):
            st.session_state.user_lat = item['lat']
            st.session_state.user_lng = item['lng']
            st.session_state.img_index = 0
            st.session_state.target_route_id = None
            st.rerun()

    st.markdown("---")

    st.subheader("🚶 Dẫn Đường Đi Bộ")
    route_options = {item['id']: item['name'] for item in all_exhibits}
    selected_target = st.selectbox(
        "Chọn địa điểm muốn đến:",
        options=list(route_options.keys()),
        format_func=lambda x: route_options[x]
    )

    col_btn1, col_btn2 = st.columns(2)
    with col_btn1:
        if st.button("🗺️ Tìm đường", use_container_width=True):
            st.session_state.target_route_id = selected_target
            st.rerun()
    with col_btn2:
        if st.button("❌ Xóa đường", use_container_width=True):
            st.session_state.target_route_id = None
            st.rerun()

    st.caption("Bán kính phát hiện GPS: **50 mét**")

# --- GIAO DIỆN CHÍNH (BẢN ĐỒ & THUYẾT MINH) ---
col_map, col_info = st.columns([7, 5])

with col_map:
    st.subheader("📍 Bản đồ Thảo Cầm Viên")
    
    fmap = folium.Map(
        location=[st.session_state.user_lat, st.session_state.user_lng],
        zoom_start=18,
        tiles="https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}",
        attr="Esri"
    )

    # 1. Vẽ mạng lưới lối đi bộ nội khu
    for w in all_walkways:
        if w.get('geom_json'):
            w_geo = json.loads(w['geom_json'])
            w_coords = [(pt[1], pt[0]) for pt in w_geo['coordinates']]
            folium.PolyLine(
                w_coords,
                color="#7f8c8d",
                weight=3,
                opacity=0.6,
                tooltip=f"Lối đi bộ: {w['name']}"
            ).add_to(fmap)

    # 2. Vẽ Polygon ranh giới và Marker cho từng phân khu
    for item in all_exhibits:
        color = COLOR_PALETTE.get(item['name'], '#3388ff')
        if item.get('poly_geojson'):
            geo_data = json.loads(item['poly_geojson'])
            folium.GeoJson(
                geo_data,
                name=f"Ranh giới: {item['name']}",
                style_function=lambda x, c=color: {
                    'fillColor': c,
                    'color': c,
                    'weight': 2,
                    'fillOpacity': 0.35
                },
                tooltip=f"<b>{item['name']}</b>"
            ).add_to(fmap)

        folium.Marker(
            location=[item['lat'], item['lng']],
            tooltip=item['name'],
            popup=item['name'],
            icon=folium.Icon(color="green", icon="leaf", prefix="fa")
        ).add_to(fmap)

    # 3. Vẽ lộ trình dẫn đường pgRouting
    if st.session_state.target_route_id:
        target_info = next((item for item in all_exhibits if item['id'] == st.session_state.target_route_id), None)
        if target_info:
            path_segments = get_shortest_path(
                st.session_state.user_lat, 
                st.session_state.user_lng,
                target_info['lat'], 
                target_info['lng']
            )
            
            if path_segments:
                full_walk_path = [(st.session_state.user_lat, st.session_state.user_lng)]
                total_distance = 0.0

                for seg in path_segments:
                    seg_geo = json.loads(seg['geom_json'])
                    coords = [(pt[1], pt[0]) for pt in seg_geo['coordinates']]
                    for c in coords:
                        if not full_walk_path or full_walk_path[-1] != c:
                            full_walk_path.append(c)
                    total_distance += float(seg.get('cost', 0.0))

                target_pt = (target_info['lat'], target_info['lng'])
                if full_walk_path[-1] != target_pt:
                    full_walk_path.append(target_pt)

                folium.PolyLine(
                    full_walk_path,
                    color="#0055FF",
                    weight=6,
                    opacity=0.9,
                    dash_array="8, 10",
                    tooltip=f"Lộ trình đi bộ đến {target_info['name']}"
                ).add_to(fmap)

                st.info(f"🚶 **Lộ trình đi bộ đến:** {target_info['name']} (Cự ly ước tính: ~{int(total_distance)} mét)")
            else:
                st.warning("Không tìm thấy đường đi bộ liên thông đến địa điểm này!")

    # 4. Vị trí người dùng & Bán kính phát hiện GPS
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

    # Hiển thị bản đồ và bắt sự kiện click
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

        audio_file = os.path.join("audio", str(target.get('audio_file')))
        if os.path.exists(audio_file):
            st.audio(audio_file, format="audio/mp3", autoplay=True)
        else:
            st.warning("Đang chuẩn bị file âm thanh...")
    else:
        st.info("🚶 Không có phân khu nào trong bán kính 50m. Hãy click vào các biểu tượng màu xanh lá trên bản đồ hoặc chọn ở danh mục bên trái!")