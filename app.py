from pathlib import Path
import logging
import html
from admin_ui import render_admin
from auth import is_admin
from content import LANGUAGES, translations, localize, generated_audio, auto_voice, with_vietnamese_name
BASE = Path(__file__).resolve().parent
import json
import os
import streamlit as st
import folium
from streamlit_folium import st_folium
from config import COLOR_PALETTE, EXHIBIT_IMAGES
from db_services import get_all_exhibits, get_all_walkways, query_nearby, get_shortest_path
import tracking
import ui

def database_read(operation, *args, **kwargs):
    try:
        return operation(*args, **kwargs)
    except Exception:
        logging.exception('Spatial query failed')
        st.error(tr('Truy vấn đang bận hoặc gặp lỗi. Vui lòng thử lại.', 'Query is busy or failed. Please retry.', '查询繁忙或出错，请重试。'))
        st.stop()
st.set_page_config(page_title='Thảo Cầm Viên – Hướng dẫn tham quan', page_icon='🌿', layout='wide')
st.markdown(ui.CSS, unsafe_allow_html=True)
language = st.sidebar.selectbox('Ngôn ngữ / Language', list(LANGUAGES), format_func=LANGUAGES.get)
def tr(vi, en, zh=None):
    # Chuỗi giao diện theo ngôn ngữ đang chọn (thiếu tiếng Trung -> dùng tiếng Anh)
    return {'vi': vi, 'zh': zh or en}.get(language, en)

HERO_TITLE = tr('Thảo Cầm Viên Sài Gòn', 'Saigon Zoo and Botanical Gardens (Thảo Cầm Viên)', '西贡动植物园（Thảo Cầm Viên）')
try:
    raw_exhibits = get_all_exhibits()
    content_translations = translations(language)
    # Tên riêng giữ nguyên tiếng Việt có dấu: tên phân khu dịch kèm tên gốc
    all_exhibits = [with_vietnamese_name(localize(item, language, content_translations), item['name'], language) for item in raw_exhibits]
    all_walkways = get_all_walkways()
except Exception as load_error:
    logging.exception('Database load failed')
    st.error(tr('Không thể tải dữ liệu. Kiểm tra database và chạy migration.', 'Cannot load data. Check database configuration and run the migration.', '无法加载数据。请检查数据库并运行迁移。'))
    with st.expander(tr('Chi tiết lỗi', 'Error details', '错误详情')):
        st.code(f'{type(load_error).__name__}: {str(load_error).strip()[:500]}')
    st.stop()
if not all_exhibits:
    st.info(tr('Database chưa có phân khu.', 'No zones in the database.', '数据库中没有展区。'))
    st.stop()
render_admin(raw_exhibits, language)
# Admin chỉ cần công cụ quản trị; giao diện khách (bản đồ, dẫn đường...) chỉ hiện khi bật xem thử
admin_mode = is_admin()
if admin_mode and not st.sidebar.toggle(tr('👁 Xem giao diện khách', '👁 Preview visitor view', '👁 预览游客界面'), key='admin_preview'):
    st.stop()
st.markdown(ui.hero(
    HERO_TITLE,
    tr('Hướng dẫn viên bỏ túi cho chuyến tham quan tự túc: đến gần một khu là nghe thuyết minh, cần đi đâu thì app chỉ đường đi bộ theo lối thật trong vườn.',
       'Your pocket guide for a self-guided visit: walk up to a zone to hear its story, and get walking directions along the real paths of the garden.',
       '自助游览的随身导游：走近展区即可收听讲解，需要去哪里，系统会沿园内真实步道为您指路。'),
    tr('Vườn thú và vườn thực vật mở cửa từ năm 1864', 'A zoo and botanical garden open since 1864', '自1864年开放的动物园与植物园'),
    [tr('Chạm vào bản đồ hoặc chọn một khu trong menu', 'Tap the map or pick a zone from the menu', '点击地图或在菜单中选择展区'),
     tr('Trong vòng 50 m, thuyết minh tự phát', 'Within 50 m, the narration plays by itself', '进入50米范围，讲解自动播放'),
     tr('Bấm "Tìm đường" để đi bộ tới khu tiếp theo', 'Press "Find route" to walk to the next zone', '点击"查找路线"步行前往下一个展区')]),
    unsafe_allow_html=True)
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

# Admin xem thử không tạo tài khoản khách / không lưu vết -> không làm sai thống kê
visitor_id = None if admin_mode else tracking_call(tracking.get_or_create_visitor, st.query_params.get('v') or st.session_state.get('visitor_id'))
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
def zone_color(item):
    return COLOR_PALETTE.get(next(x['name'] for x in raw_exhibits if x['id'] == item['id']), ui.LEAF)


def zone_dot(item):
    return ui.ZONE_DOT.get(zone_color(item), '🟢')


with st.sidebar:
    st.subheader(tr('Tìm một khu', 'Find a zone', '查找展区'))
    keyword = st.text_input(tr('Tên hoặc con vật', 'Name or animal', '名称或动物'), placeholder=tr('voi, hổ, bò sát, vườn lan...', 'elephants, tigers, orchids...', '大象、老虎、兰花...'))
    if keyword:
        results = [item for item in all_exhibits if keyword.lower() in item["name"].lower() or keyword.lower() in item['description'].lower()]
        if results:
            st.write(tr(f'Kết quả tìm kiếm ({len(results)}):', f'Search results ({len(results)}):', f'搜索结果（{len(results)}）：'))
            for r in results:
                if st.button(f'{zone_dot(r)} {r["name"]}', key=f'search_{r["id"]}', use_container_width=True):
                    st.session_state.user_lat = r['lat']
                    st.session_state.user_lng = r['lng']
                    st.session_state.img_index = 0
                    st.session_state.target_route_id = None
                    st.rerun()
        else:
            st.warning(tr('Không tìm thấy kết quả.', 'No results found.', '未找到结果。'))
    st.subheader(tr('Các khu tham quan', 'Zones', '展区'))
    for item in all_exhibits:
        if st.button(f'{zone_dot(item)} {item["name"]}', key=f'select_{item["id"]}', use_container_width=True):
            st.session_state.user_lat = item['lat']
            st.session_state.user_lng = item['lng']
            st.session_state.img_index = 0
            st.session_state.target_route_id = None
            st.rerun()
    st.subheader(tr('Đi bộ tới', 'Walk to', '步行前往'))
    route_options = {item["id"]: item["name"] for item in all_exhibits}
    selected_target = st.selectbox(tr('Điểm đến', 'Destination', '目的地'), options=list(route_options.keys()), format_func=lambda x: route_options[x])
    col_btn1, col_btn2 = st.columns(2)
    with col_btn1:
        if st.button(tr('Tìm đường', 'Find route', '查找路线'), type='primary', use_container_width=True):
            st.session_state.target_route_id = selected_target
            st.rerun()
    with col_btn2:
        if st.button(tr('Xóa đường', 'Clear route', '清除路线'), use_container_width=True):
            st.session_state.target_route_id = None
            st.rerun()
    st.caption(tr('Vị trí được mô phỏng bằng cách chạm vào bản đồ. Thuyết minh tự phát khi bạn cách một khu dưới 50 m.',
                  'Your position is simulated by tapping the map. Narration plays when you are within 50 m of a zone.',
                  '通过点击地图模拟您的位置。距离展区50米以内时自动播放讲解。'))
col_map, col_info = st.columns([7, 5])
with col_map:
    st.subheader(tr('Bản đồ Thảo Cầm Viên', 'Garden map', '园区地图'))
    route_box = st.container()
    fmap = folium.Map(location=[st.session_state.user_lat, st.session_state.user_lng], zoom_start=18, tiles=None, control_scale=True)
    # Nền sáng để màu các khu nổi bật; vẫn chuyển được sang bản đồ Esri quen thuộc
    folium.TileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                     attr='&copy; OpenStreetMap contributors &copy; CARTO', name=tr('Bản đồ sáng', 'Light map', '浅色地图'), max_zoom=20).add_to(fmap)
    folium.TileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                     attr='Esri', name='Esri', max_zoom=20).add_to(fmap)
    for w in all_walkways:
        if w.get('geom_json'):
            w_geo = json.loads(w['geom_json'])
            w_coords = [(pt[1], pt[0]) for pt in w_geo['coordinates']]
            folium.PolyLine(w_coords, color='#8FA596', weight=2.5, opacity=0.7, tooltip=tr(f'Lối đi bộ: {w["name"]}', f'Walkway: {w["name"]}', f'步行道：{w["name"]}')).add_to(fmap)
    for item in all_exhibits:
        color = zone_color(item)
        if item.get('poly_geojson'):
            geo_data = json.loads(item['poly_geojson'])
            folium.GeoJson(geo_data, name=tr(f'Ranh giới: {item["name"]}', f'Boundary: {item["name"]}', f'边界：{item["name"]}'), style_function=lambda x, c=color: {'fillColor': c, 'color': c, 'weight': 2, 'fillOpacity': 0.28}, tooltip=f'<b>{item["name"]}</b>').add_to(fmap)
        folium.Marker(location=[item['lat'], item['lng']], tooltip=html.escape(item["name"]), popup=html.escape(item["name"]), icon=folium.Icon(color=ui.ZONE_ICON.get(color, ('green', 'leaf'))[0], icon=ui.ZONE_ICON.get(color, ('green', 'leaf'))[1], prefix='fa')).add_to(fmap)
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
                folium.PolyLine(full_walk_path, color=ui.LOTUS, weight=6, opacity=0.95, dash_array='1, 11', line_cap='round', tooltip=tr(f'Lộ trình đi bộ đến {target_info["name"]}', f'Walking route to {target_info["name"]}', f'前往 {target_info["name"]} 的步行路线')).add_to(fmap)
                minutes = max(1, round(total_distance / 70))   # ~70 m/phút đi bộ thong thả
                route_box.markdown('<div class="tcv-route">' + ui.esc(tr(f'Đường đi bộ tới {target_info["name"]}: khoảng {int(total_distance)} m, chừng {minutes} phút.',
                    f'Walking route to {target_info["name"]}: about {int(total_distance)} m, roughly {minutes} min.',
                    f'步行前往 {target_info["name"]}：约 {int(total_distance)} 米，大约 {minutes} 分钟。')).replace(ui.esc(target_info["name"]), '<strong>' + ui.esc(target_info["name"]) + '</strong>', 1) + '</div>', unsafe_allow_html=True)
            else:
                route_box.warning(tr('Không tìm thấy lối đi bộ nối tới khu này. Hãy chọn một điểm xuất phát khác trên bản đồ.', 'No connected walking path reaches this zone. Try starting from another point on the map.', '没有可通往该展区的步道，请在地图上换一个起点。'))
    folium.Marker(location=[st.session_state.user_lat, st.session_state.user_lng], tooltip=tr('Vị trí của bạn', 'Your position', '您的位置'), icon=folium.Icon(color='pink', icon='street-view', prefix='fa')).add_to(fmap)
    folium.Circle(location=[st.session_state.user_lat, st.session_state.user_lng], radius=50, color=ui.LOTUS, weight=2, dash_array='6, 6', fill=True, fill_color=ui.LOTUS, fill_opacity=0.08).add_to(fmap)
    folium.LayerControl(position='topright', collapsed=True).add_to(fmap)
    map_out = st_folium(fmap, width='100%', height=580, returned_objects=['last_clicked'])
    st.markdown(ui.legend([(item['name'], zone_color(item)) for item in all_exhibits],
                          tr('Bạn đang ở đây (vòng 50 m)', 'You are here (50 m ring)', '您的位置（50米范围）'),
                          tr('Đường đi bộ gợi ý', 'Suggested walking route', '建议步行路线')), unsafe_allow_html=True)
    if map_out and map_out.get('last_clicked'):
        c_lat = map_out['last_clicked']['lat']
        c_lng = map_out['last_clicked']['lng']
        if round(c_lat, 5) != round(st.session_state.user_lat, 5) or round(c_lng, 5) != round(st.session_state.user_lng, 5):
            st.session_state.user_lat = c_lat
            st.session_state.user_lng = c_lng
            st.session_state.img_index = 0
            st.rerun()
with col_info:
    st.subheader(tr('Thuyết minh', 'Narration', '语音讲解'))
    if target_raw:
        target = with_vietnamese_name(localize(target_raw, language, content_translations), target_raw['name'], language)
        dist = float(target['distance_meters'] or 0)
        dist_text = (tr('Bạn đang ở trong khu này', 'You are inside this zone', '您正在该展区内') if dist < 1 else
                     tr(f'Cách bạn {dist:.0f} m', f'{dist:.0f} m from you', f'距您 {dist:.0f} 米'))
        st.markdown(ui.placard(target['name'], dist_text, target['description'], zone_color(target_raw),
                               tr('Đang thuyết minh', 'Now playing', '正在讲解'),
                               '' if target['translated'] else tr('', 'This zone has no English text yet, so the Vietnamese text is shown.', '该展区暂无中文内容，显示越南语原文。')),
                    unsafe_allow_html=True)
        img_list = EXHIBIT_IMAGES.get(target["id"], [])
        valid_images = [img for img in img_list if os.path.exists(str(BASE / 'images' / img))]
        if valid_images:
            idx = st.session_state.img_index % len(valid_images)
            current_img_path = str(BASE / 'images' / valid_images[idx])
            st.image(current_img_path, caption=f'{idx + 1}/{len(valid_images)}', use_container_width=True)
            c_prev, c_txt, c_next = st.columns([1, 2, 1])
            with c_prev:
                if st.button(tr('◀ Trước', '◀ Previous', '◀ 上一张'), key='btn_img_prev', use_container_width=True):
                    st.session_state.img_index = (idx - 1) % len(valid_images)
                    st.rerun()
            with c_next:
                if st.button(tr('Sau ▶', 'Next ▶', '下一张 ▶'), key='btn_img_next', use_container_width=True):
                    st.session_state.img_index = (idx + 1) % len(valid_images)
                    st.rerun()
        audio_file = str((BASE / 'audio' / (target.get('audio_file') or '')).resolve())
        voice = tracking_call(generated_audio, *target['audio_key']) if target.get('audio_key') else None
        if voice:
            # Giọng đọc tự tạo khi admin lưu nội dung (lưu trong database)
            st.audio(voice, format='audio/mp3', autoplay=True)
        elif Path(audio_file).is_relative_to((BASE / 'audio').resolve()) and Path(audio_file).is_file() and Path(audio_file).suffix.lower() == '.mp3':
            st.audio(audio_file, format='audio/mp3', autoplay=True)
        elif target['translated'] and target.get('description') and (voice := tracking_call(auto_voice, target['description'], language)):
            # Chưa có audio cho ngôn ngữ này (vd. tiếng Trung) -> tự đọc nội dung đang hiển thị
            st.audio(voice, format='audio/mp3', autoplay=True)
        else:
            st.caption(tr('Khu này chưa có giọng đọc, bạn đọc phần chữ phía trên nhé.', 'No audio for this zone yet; please read the text above.', '该展区暂无语音，请阅读上方文字。'))
    else:
        # Gợi ý khu gần nhất ngoài bán kính để khách biết đi tiếp đâu
        closest = min(all_exhibits, key=lambda x: ui.haversine_m(st.session_state.user_lat, st.session_state.user_lng, x['lat'], x['lng']))
        far = ui.haversine_m(st.session_state.user_lat, st.session_state.user_lng, closest['lat'], closest['lng'])
        st.markdown(ui.empty_state(
            tr('Chưa có khu nào trong vòng 50 m', 'No zone within 50 m yet', '50米内暂无展区'),
            tr(f'Khu gần bạn nhất là {closest["name"]}, cách khoảng {far:.0f} m. Chọn khu đó ở mục "Đi bộ tới" rồi bấm Tìm đường, hoặc chạm thẳng vào bản đồ.',
               f'The closest zone is {closest["name"]}, about {far:.0f} m away. Pick it under "Walk to" and press Find route, or tap the map.',
               f'离您最近的是 {closest["name"]}，约 {far:.0f} 米。可在"步行前往"中选择并点击查找路线，或直接点击地图。')),
            unsafe_allow_html=True)
    st.markdown('<p class="tcv-coords">' + ui.esc(tr('Tọa độ', 'Coordinates', '坐标')) + f': {st.session_state.user_lat:.5f}, {st.session_state.user_lng:.5f}</p>', unsafe_allow_html=True)

# ===== Thông tin kỹ thuật (cho người đánh giá đồ án) =====
with st.expander(tr('Về hệ thống', 'About this system', '关于本系统')):
    st.markdown(tr('''
- **Lưu trữ không gian:** PostgreSQL + PostGIS trên Neon; ranh giới khu là `Polygon`, lối đi bộ là `LineString`, có chỉ mục GiST.
- **Geofencing 50 m:** `ST_DWithin` trên kiểu `geography`, xếp hạng bằng window function và ưu tiên khu khách chưa ghé.
- **Dẫn đường:** `pgr_dijkstra` (pgRouting) trên 1.192 đoạn lối đi lấy từ OpenStreetMap; điểm vào mạng tìm bằng KNN `<->`.
- **Nội dung đa ngôn ngữ:** Việt / Anh / Trung, giọng đọc tạo bằng gTTS, bản dịch máy được kiểm tra bằng dịch ngược và bảng thuật ngữ.
- **Bản đồ nền:** © OpenStreetMap contributors, © CARTO, Esri.
''', '''
- **Spatial storage:** PostgreSQL + PostGIS on Neon; zone boundaries as `Polygon`, walkways as `LineString`, GiST indexes.
- **50 m geofencing:** `ST_DWithin` on `geography`, ranked with a window function that favours zones not yet visited.
- **Routing:** `pgr_dijkstra` (pgRouting) over 1,192 OpenStreetMap walkway segments; network entry via KNN `<->`.
- **Multilingual content:** Vietnamese / English / Chinese, gTTS narration, machine translations checked by back-translation and a glossary.
- **Base maps:** © OpenStreetMap contributors, © CARTO, Esri.
''', '''
- **空间存储：** Neon 上的 PostgreSQL + PostGIS；展区边界为 `Polygon`，步道为 `LineString`，建有 GiST 索引。
- **50米地理围栏：** 基于 `geography` 的 `ST_DWithin`，用窗口函数排序并优先未参观的展区。
- **路径规划：** 在 1,192 段 OpenStreetMap 步道上运行 `pgr_dijkstra`（pgRouting），用 KNN `<->` 接入路网。
- **多语言内容：** 越南语 / 英语 / 中文，gTTS 语音，机器翻译经回译和术语表校验。
- **底图：** © OpenStreetMap contributors, © CARTO, Esri。
'''))

