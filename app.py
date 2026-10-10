from pathlib import Path
import logging
import html
from admin_ui import render_admin
from content import LANGUAGES, translations, localize
BASE = Path(__file__).resolve().parent
import json
import os
import streamlit as st
import folium
from streamlit_folium import st_folium
from config import COLOR_PALETTE, EXHIBIT_IMAGES
from db_services import get_all_exhibits, get_all_walkways, query_nearby, get_shortest_path
import tracking

def database_read(operation, *args, **kwargs):
    try:
        return operation(*args, **kwargs)
    except Exception:
        logging.exception('Spatial query failed')
        st.error(tr('Truy vấn đang bận hoặc gặp lỗi. Vui lòng thử lại.', 'Query is busy or failed. Please retry.'))
        st.stop()
st.set_page_config(page_title='Hệ Thống Hướng Dẫn Viên Du Lịch - Thảo Cầm Viên', page_icon='🌿', layout='wide')
language = st.sidebar.selectbox('Ngôn ngữ / Language', list(LANGUAGES), format_func=LANGUAGES.get)
def tr(vi, en):
    return vi if language == 'vi' else en

st.title(tr('Hệ Thống Hướng Dẫn Viên Du Lịch Ngoài Trời - Thảo Cầm Viên', 'Saigon Zoo Visitor Guide'))
try:
    raw_exhibits = get_all_exhibits()
    content_translations = translations(language)
    all_exhibits = [localize(item, language, content_translations) for item in raw_exhibits]
    all_walkways = get_all_walkways()
except Exception as load_error:
    logging.exception('Database load failed')
    st.error(tr('Không thể tải dữ liệu. Kiểm tra database và chạy migration.', 'Cannot load data. Check database configuration and run the migration.'))
    with st.expander(tr('Chi tiết lỗi', 'Error details')):
        st.code(f'{type(load_error).__name__}: {str(load_error).strip()[:500]}')
    st.stop()
if not all_exhibits:
    st.info(tr('Database chưa có phân khu.', 'No zones in the database.'))
    st.stop()
render_admin(raw_exhibits, language)
st.sidebar.caption(tr('Vị trí mô phỏng bằng bấm bản đồ; chưa kết nối GPS thiết bị.', 'Position is simulated by map clicks; device GPS is not connected.'))
if 'user_lat' not in st.session_state:
    st.session_state.user_lat = 10.78775
if 'user_lng' not in st.session_state:
    st.session_state.user_lng = 106.7056
if 'img_index' not in st.session_state:
    st.session_state.img_index = 0
if 'target_route_id' not in st.session_state:
    st.session_state.target_route_id = None

# ===== Tài khoản khách tạm (tạo khi quét QR) + lưu vết lộ trình =====
def tracking_call(operation, *args, default=None, **kwargs):
    # Lỗi phần lưu vết không được làm hỏng chức năng hướng dẫn chính
    try:
        return operation(*args, **kwargs)
    except Exception:
        logging.exception('Visitor tracking failed')
        return default

visitor_id = tracking_call(tracking.get_or_create_visitor, st.query_params.get('v') or st.session_state.get('visitor_id'))
st.session_state.visitor_id = visitor_id
if visitor_id and st.query_params.get('v') != visitor_id:
    # Gắn mã khách vào URL để tải lại trang vẫn giữ tài khoản; mã cũ hết hạn sẽ được thay mã mới
    st.query_params['v'] = visitor_id
user_pos = (round(st.session_state.user_lat, 6), round(st.session_state.user_lng, 6))
if visitor_id and st.session_state.get('last_logged_pos') != (visitor_id, user_pos):
    tracking_call(tracking.record_position, visitor_id, st.session_state.user_lat, st.session_state.user_lng)
    st.session_state.last_logged_pos = (visitor_id, user_pos)

# ===== Geofencing 50m: ưu tiên phân khu chưa ghé khi cùng khoảng cách =====
nearby = None
if visitor_id:
    nearby = tracking_call(tracking.nearby_for_visitor, visitor_id, st.session_state.user_lat, st.session_state.user_lng, 50.0)
if nearby is None:
    nearby = database_read(query_nearby, st.session_state.user_lat, st.session_state.user_lng, radius=50.0)
target_raw = None
if not nearby:
    # Đã rời khỏi mọi phân khu -> quên phân khu đang thuyết minh, lần quay lại sẽ chọn lại theo ưu tiên
    st.session_state.narration = (visitor_id, user_pos, None)
else:
    # Khách chưa di chuyển -> giữ phân khu đang thuyết minh (tránh nhảy qua lại sau khi đánh dấu "đã ghé")
    sticky = st.session_state.get('narration')
    if sticky and sticky[:2] == (visitor_id, user_pos):
        target_raw = next((n for n in nearby if n['id'] == sticky[2]), None)
    if target_raw is None:
        target_raw = nearby[0]
        st.session_state.narration = (visitor_id, user_pos, target_raw['id'])
        if visitor_id:
            tracking_call(tracking.mark_visited, visitor_id, target_raw['id'])
with st.sidebar:
    st.header(tr('🎮 Bảng Điều Khiển', '🎮 Controls'))
    st.subheader(tr('1. Tìm kiếm vị trí', '1. Search places'))
    keyword = st.text_input(tr('Gõ tên hoặc đặc điểm:', 'Name or description:'), placeholder=tr('voi, hổ, bò sát, vườn lan...', 'elephants, tigers, orchids...'))
    if keyword:
        results = [item for item in all_exhibits if keyword.lower() in item["name"].lower() or keyword.lower() in item['description'].lower()]
        if results:
            st.write(tr(f'Kết quả tìm kiếm ({len(results)}):', f'Search results ({len(results)}):'))
            for r in results:
                if st.button(r["name"], key=f'search_{r["id"]}', use_container_width=True):
                    st.session_state.user_lat = r['lat']
                    st.session_state.user_lng = r['lng']
                    st.session_state.img_index = 0
                    st.session_state.target_route_id = None
                    st.rerun()
        else:
            st.warning(tr('Không tìm thấy kết quả.', 'No results found.'))
    st.markdown('---')
    st.subheader(tr('2. Chọn Nhanh Phân Khu', '2. Choose a zone'))
    for item in all_exhibits:
        if st.button(item["name"], key=f'select_{item["id"]}', use_container_width=True):
            st.session_state.user_lat = item['lat']
            st.session_state.user_lng = item['lng']
            st.session_state.img_index = 0
            st.session_state.target_route_id = None
            st.rerun()
    st.markdown('---')
    st.subheader(tr('🚶 Dẫn Đường Đi Bộ', '🚶 Walking directions'))
    route_options = {item["id"]: item["name"] for item in all_exhibits}
    selected_target = st.selectbox(tr('Chọn địa điểm muốn đến:', 'Choose a destination:'), options=list(route_options.keys()), format_func=lambda x: route_options[x])
    col_btn1, col_btn2 = st.columns(2)
    with col_btn1:
        if st.button(tr('🗺️ Tìm đường', '🗺️ Find route'), use_container_width=True):
            st.session_state.target_route_id = selected_target
            st.rerun()
    with col_btn2:
        if st.button(tr('❌ Xóa đường', '❌ Clear route'), use_container_width=True):
            st.session_state.target_route_id = None
            st.rerun()
    st.caption(tr('Bán kính phát hiện GPS: **50 mét**', 'Detection radius: **50 metres**'))
col_map, col_info = st.columns([7, 5])
with col_map:
    st.subheader(tr('📍 Bản đồ Thảo Cầm Viên', '📍 Saigon Zoo Map'))
    fmap = folium.Map(location=[st.session_state.user_lat, st.session_state.user_lng], zoom_start=18, tiles='https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', attr='Esri')
    for w in all_walkways:
        if w.get('geom_json'):
            w_geo = json.loads(w['geom_json'])
            w_coords = [(pt[1], pt[0]) for pt in w_geo['coordinates']]
            folium.PolyLine(w_coords, color='#7f8c8d', weight=3, opacity=0.6, tooltip=tr(f'Lối đi bộ: {w["name"]}', f'Walkway: {w["name"]}')).add_to(fmap)
    for item in all_exhibits:
        color = COLOR_PALETTE.get(next(x["name"] for x in raw_exhibits if x["id"] == item["id"]), '#3388ff')
        if item.get('poly_geojson'):
            geo_data = json.loads(item['poly_geojson'])
            folium.GeoJson(geo_data, name=tr(f'Ranh giới: {item["name"]}', f'Boundary: {item["name"]}'), style_function=lambda x, c=color: {'fillColor': c, 'color': c, 'weight': 2, 'fillOpacity': 0.35}, tooltip=f'<b>{item["name"]}</b>').add_to(fmap)
        folium.Marker(location=[item['lat'], item['lng']], tooltip=html.escape(item["name"]), popup=html.escape(item["name"]), icon=folium.Icon(color='green', icon='leaf', prefix='fa')).add_to(fmap)
    if st.session_state.target_route_id:
        target_info = next((item for item in all_exhibits if item["id"] == st.session_state.target_route_id), None)
        if target_info:
            path_segments = database_read(get_shortest_path, st.session_state.user_lat, st.session_state.user_lng, target_info['lat'], target_info['lng'])
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
                folium.PolyLine(full_walk_path, color='#0055FF', weight=6, opacity=0.9, dash_array='8, 10', tooltip=tr(f'Lộ trình đi bộ đến {target_info["name"]}', f'Walking route to {target_info["name"]}')).add_to(fmap)
                st.info(tr(f'🚶 **Lộ trình đi bộ đến:** {target_info["name"]} (Cự ly ước tính: ~{int(total_distance)} mét)', f'🚶 **Walking route to:** {target_info["name"]} (Network distance: ~{int(total_distance)} m)'))
            else:
                st.warning(tr('Không tìm thấy đường đi bộ liên thông đến địa điểm này!', 'No connected walking route found.'))
    folium.Marker(location=[st.session_state.user_lat, st.session_state.user_lng], tooltip=tr('Vị trí của bạn', 'Your position'), icon=folium.Icon(color='red', icon='user', prefix='fa')).add_to(fmap)
    folium.Circle(location=[st.session_state.user_lat, st.session_state.user_lng], radius=50, color='#1a73e8', fill=True, fill_color='#4285f4', fill_opacity=0.2).add_to(fmap)
    map_out = st_folium(fmap, width='100%', height=560, returned_objects=['last_clicked'])
    if map_out and map_out.get('last_clicked'):
        c_lat = map_out['last_clicked']['lat']
        c_lng = map_out['last_clicked']['lng']
        if round(c_lat, 5) != round(st.session_state.user_lat, 5) or round(c_lng, 5) != round(st.session_state.user_lng, 5):
            st.session_state.user_lat = c_lat
            st.session_state.user_lng = c_lng
            st.session_state.img_index = 0
            st.rerun()
with col_info:
    st.subheader(tr('🎧 Hướng Dẫn Viên Thuyết Minh', '🎧 Visitor information'))
    st.markdown(tr(f'**Tọa độ hiện tại:** `{st.session_state.user_lat:.5f}, {st.session_state.user_lng:.5f}`', f'**Current coordinates:** `{st.session_state.user_lat:.5f}, {st.session_state.user_lng:.5f}`'))
    if target_raw:
        target = localize(target_raw, language, content_translations)
        if not target['translated']:
            st.info(tr('Chưa có bản dịch; hiển thị nội dung tiếng Việt.', 'Translation unavailable; showing Vietnamese content.'))
        st.success(tr(f'🎯 **Hiện vật gần nhất:** {target["name"]}', f'🎯 **Nearest zone:** {target["name"]}'))
        st.markdown(tr(f'📏 **Khoảng cách:** `{target["distance_meters"]} mét`', f'📏 **Distance:** `{target["distance_meters"]} m`'))
        st.write(target['description'])
        img_list = EXHIBIT_IMAGES.get(target["id"], [])
        valid_images = [img for img in img_list if os.path.exists(str(BASE / 'images' / img))]
        if valid_images:
            idx = st.session_state.img_index % len(valid_images)
            current_img_path = str(BASE / 'images' / valid_images[idx])
            st.image(current_img_path, caption=f'{target["name"]} ({idx + 1}/{len(valid_images)})', use_container_width=True)
            c_prev, c_txt, c_next = st.columns([1, 2, 1])
            with c_prev:
                if st.button(tr('◀ Trước', '◀ Previous'), key='btn_img_prev', use_container_width=True):
                    st.session_state.img_index = (idx - 1) % len(valid_images)
                    st.rerun()
            with c_next:
                if st.button(tr('Sau ▶', 'Next ▶'), key='btn_img_next', use_container_width=True):
                    st.session_state.img_index = (idx + 1) % len(valid_images)
                    st.rerun()
        else:
            st.info(tr('💡 Đặt các file ảnh (.jpg) vào thư mục `images/` để hiển thị.', 'No pictures are available.'))
        audio_file = str((BASE / 'audio' / (target.get('audio_file') or '')).resolve())
        if Path(audio_file).is_relative_to((BASE / 'audio').resolve()) and Path(audio_file).is_file() and Path(audio_file).suffix.lower() == '.mp3':
            st.audio(audio_file, format='audio/mp3', autoplay=True)
        else:
            st.warning(tr('Đang chuẩn bị file âm thanh...', 'No narration available in this language.'))
    else:
        st.info(tr('🚶 Không có phân khu nào trong bán kính 50m. Hãy click vào các biểu tượng màu xanh lá trên bản đồ hoặc chọn ở danh mục bên trái!', '🚶 No zone within 50 m. Click the map or select a zone in the sidebar.'))

