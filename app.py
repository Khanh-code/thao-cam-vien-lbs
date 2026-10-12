from pathlib import Path
import json
import logging
import os
import html
import streamlit as st
import folium
from streamlit_folium import st_folium
from admin_ui import render_admin
from auth import is_admin
from content import LANGUAGES, translations, localize, generated_audio, auto_voice, with_vietnamese_name
from config import COLOR_PALETTE, EXHIBIT_IMAGES
from db_services import get_all_exhibits, get_all_walkways, query_nearby, get_shortest_path
import tracking
import ui
import location
import artmap
import streamlit.components.v1 as components
from zones import zone_images

BASE = Path(__file__).resolve().parent
# Thành phần theo dõi GPS liên tục (navigator.geolocation.watchPosition)
gps_watch = components.declare_component('gps_watch', path=str(BASE / 'gps_component'))


def database_read(operation, *args, **kwargs):
    try:
        return operation(*args, **kwargs)
    except Exception:
        logging.exception('Spatial query failed')
        st.error(tr('Truy vấn đang bận hoặc gặp lỗi. Vui lòng thử lại.', 'Query is busy or failed. Please retry.', '查询繁忙或出错，请重试。'))
        st.stop()


st.set_page_config(page_title='Thảo Cầm Viên Sài Gòn – Hướng dẫn tham quan', page_icon='🌿', layout='wide')
st.markdown(ui.CSS, unsafe_allow_html=True)

# ===== Thanh trên cùng: chọn ngôn ngữ =====
_, bar_right = st.columns([3, 2], vertical_alignment='center')
with bar_right:
    language = st.radio('Ngôn ngữ / Language / 语言', list(LANGUAGES), format_func=LANGUAGES.get,
                        horizontal=True, key='lang', label_visibility='collapsed')


def tr(vi, en, zh=None):
    # Chuỗi giao diện theo ngôn ngữ đang chọn (thiếu tiếng Trung -> dùng tiếng Anh)
    return {'vi': vi, 'zh': zh or en}.get(language, en)


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
# Admin chỉ cần công cụ quản trị; giao diện khách chỉ hiện khi bật xem thử
admin_mode = is_admin()
if admin_mode and not st.sidebar.toggle(tr('Xem giao diện khách', 'Preview visitor view', '预览游客界面'), key='admin_preview'):
    st.stop()

if 'user_lat' not in st.session_state:
    st.session_state.user_lat = 10.78775
if 'user_lng' not in st.session_state:
    st.session_state.user_lng = 106.7056
if 'img_index' not in st.session_state:
    st.session_state.img_index = 0
if 'target_route_id' not in st.session_state:
    st.session_state.target_route_id = None

# ===== Ảnh bìa =====
st.markdown(ui.hero(
    tr('Thảo Cầm Viên Sài Gòn', 'Saigon Zoo and Botanical Gardens (Thảo Cầm Viên)', '西贡动植物园（Thảo Cầm Viên）'),
    tr('Đi tới đâu, nghe kể tới đó. Muốn sang khu khác, app chỉ đường cho bạn.',
       'Hear each zone’s story as you reach it. When you want to move on, the app shows you the way.',
       '走到哪里，就听到哪里的故事。想去下一个展区，系统为您指路。'),
    BASE / 'images' / 'cong_chinh.jpg',
    tr('Cổng chính, đường Nguyễn Bỉnh Khiêm', 'Main gate (Thảo Cầm Viên), Nguyễn Bỉnh Khiêm street', '正门（Thảo Cầm Viên），Nguyễn Bỉnh Khiêm 街')),
    unsafe_allow_html=True)

# ===== Vị trí: mô phỏng (chạm bản đồ, mặc định) hoặc GPS thật, theo dõi liên tục như Google Maps =====
zoo_lat = sum(x['lat'] for x in all_exhibits) / len(all_exhibits)
zoo_lng = sum(x['lng'] for x in all_exhibits) / len(all_exhibits)
gps_live = False   # True khi đang đi trong vườn với GPS bật -> bản đồ bám theo, dẫn đường trực tiếp
# Đặt ngay trên bản đồ (không để ở thanh bên vì trên điện thoại thanh bên bị ẩn)
gps_box = st.container(key='gps_box')
if gps_box.toggle(tr('Dùng GPS của tôi', 'Use my GPS', '使用我的GPS'), key='use_gps'):
    with gps_box:
        try:
            gps_raw = gps_watch(min_move_m=3, resend_s=30, key='gps_watch', default=None)
        except Exception:
            logging.exception('GPS component failed')
            gps_raw = {'error': {'message': 'unavailable'}}
    gps = location.interpret(gps_raw, zoo_lat, zoo_lng)
    if gps['status'] == 'inside':
        gps_live = True
        reading = (round(gps['lat'], 6), round(gps['lng'], 6))
        if st.session_state.get('last_gps') != reading:   # chỉ dùng khi có số đo GPS mới
            if st.session_state.get('last_gps') is None:
                st.session_state.img_index = 0
            st.session_state.last_gps = reading
            st.session_state.user_lat, st.session_state.user_lng = gps['lat'], gps['lng']
        acc = f' (±{gps["accuracy_m"]} m)' if gps['accuracy_m'] is not None else ''
        gps_box.caption(tr(f'Đang theo dõi vị trí GPS{acc}. Bản đồ sẽ di chuyển theo bạn.',
                              f'Following your GPS position{acc}. The map moves with you.',
                              f'正在跟踪GPS位置{acc}，地图将随您移动。'))
    elif gps['status'] == 'outside':
        km = gps['distance_m'] / 1000
        # Khoảng cách THẬT: từ toạ độ GPS của bạn tới khuôn viên vườn (haversine, đường chim bay)
        gps_box.info(tr(f'Bạn đang ở ngoài Thảo Cầm Viên (cách khoảng {km:.1f}'.replace('.', ',') + ' km đường chim bay).',
                           f'You are outside the garden (about {km:.1f} km in a straight line).',
                           f'您不在园区内（直线距离约 {km:.1f} 公里）。'))
    elif gps['status'] == 'error':
        gps_box.warning(tr('Không lấy được vị trí. Hãy cho phép trình duyệt truy cập vị trí.',
                              'Could not get your position. Please allow location access in the browser.',
                              '无法获取位置，请允许浏览器访问位置。'))
    else:
        gps_box.caption(tr('Đang lấy vị trí GPS...', 'Getting your GPS position...', '正在获取GPS位置…'))
else:
    st.session_state.pop('last_gps', None)


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

# ===== Geofencing 50 m: ưu tiên khu chưa ghé, rồi khu bên phải hướng đi =====
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
    # Màu admin chọn (lưu trong database); database cũ -> bảng màu cố định theo tên khu
    raw = next(x for x in raw_exhibits if x['id'] == item['id'])
    return raw.get('color') or COLOR_PALETTE.get(raw['name'], ui.GREEN)


def go_to(item):
    st.session_state.user_lat = item['lat']
    st.session_state.user_lng = item['lng']
    st.session_state.img_index = 0
    st.session_state.target_route_id = None
    st.rerun()


st.markdown(ui.zone_css([(x['id'], zone_color(x)) for x in all_exhibits]), unsafe_allow_html=True)

# ===== Thanh bên: tìm, danh sách khu, đi bộ tới =====
with st.sidebar:
    st.markdown('<div class="tcv-side-title">' + ui.esc(tr('Tìm khu tham quan', 'Find a zone', '查找展区')) + '</div>', unsafe_allow_html=True)
    keyword = st.text_input(tr('Tìm khu tham quan', 'Find a zone', '查找展区'), label_visibility='collapsed',
                            placeholder=tr('Thử gõ: voi, hổ, lan…', 'Try: elephant, tiger, orchid…', '例如：大象、老虎、兰花…'))
    shown = all_exhibits
    if keyword:
        k = keyword.lower().strip()
        shown = [x for x in all_exhibits if k in x['name'].lower() or k in (x['description'] or '').lower()]
        if not shown:
            st.caption(tr('Không có khu nào khớp. Thử một từ khác.', 'No zone matches. Try another word.', '没有匹配的展区，请换个词试试。'))
    st.markdown('<div class="tcv-side-title">' + ui.esc(tr(f'Các khu ({len(shown)})', f'Zones ({len(shown)})', f'展区（{len(shown)}）')) + '</div>', unsafe_allow_html=True)
    for item in shown:
        if st.button(ui.zone_label(item), key=f'zone_{item["id"]}', use_container_width=True):
            go_to(item)

    st.markdown('<div class="tcv-side-title">' + ui.esc(tr('Đi bộ tới', 'Walk to', '步行前往')) + '</div>', unsafe_allow_html=True)
    route_options = {item['id']: ui.zone_label(item) for item in all_exhibits}
    selected_target = st.selectbox(tr('Điểm đến', 'Destination', '目的地'), options=list(route_options.keys()),
                                   format_func=lambda x: route_options[x], label_visibility='collapsed')
    col_btn1, col_btn2 = st.columns(2)
    with col_btn1:
        if st.button(tr('Tìm đường', 'Find route', '查找路线'), type='primary', use_container_width=True):
            st.session_state.target_route_id = selected_target
            st.rerun()
    with col_btn2:
        if st.button(tr('Xóa đường', 'Clear route', '清除路线'), use_container_width=True):
            st.session_state.target_route_id = None
            st.rerun()
    st.caption(tr('Chạm vào bản đồ để chọn vị trí, hoặc bật "Dùng GPS của tôi" khi đang ở Thảo Cầm Viên. Thuyết minh tự phát khi bạn cách một khu dưới 50 m.',
                  'Tap the map to set your position, or turn on "Use my GPS" inside the garden. Narration plays within 50 m of a zone.',
                  '点击地图设定位置，或在园内打开"使用我的GPS"。距离展区50米以内时自动播放讲解。'))


# ===== Dẫn đường: tới nơi chưa? (khu đích đang được thuyết minh = đã vào vùng 50 m của khu đó) =====
arrived_name = None
if st.session_state.target_route_id and target_raw and target_raw['id'] == st.session_state.target_route_id:
    arrived_name = next((x['name'] for x in all_exhibits if x['id'] == target_raw['id']), '')
    st.session_state.target_route_id = None

col_map, col_info = st.columns([7, 5], gap='large')
with col_map:
    st.markdown(ui.section(tr('Bản đồ', 'Map', '地图'),
                           tr('Bản đồ đang đi theo bạn', 'The map follows you', '地图正在跟随您') if gps_live else
                           tr('Chạm vào bản đồ để di chuyển', 'Tap the map to move', '点击地图移动')), unsafe_allow_html=True)
    route_box = st.container()
    if arrived_name:
        route_box.success(tr(f'Bạn đã tới {arrived_name}.', f'You have arrived at {arrived_name}.', f'您已到达 {arrived_name}。'))
    # Kiểu bản đồ: sơ đồ minh hoạ chính thức (mặc định, giống bản in) hoặc bản đồ thật / ảnh vệ tinh.
    # Dù chọn kiểu nào, định vị, vùng thuyết minh và tìm đường đều tính bằng toạ độ thật trong PostGIS.
    art_ok = artmap.available() and any(x.get('map_no') is not None for x in all_exhibits)
    art = art_ok and st.radio(tr('Kiểu bản đồ', 'Map style', '地图样式'), ['art', 'real'], horizontal=True, key='map_mode',
                              label_visibility='collapsed',
                              format_func=lambda m: tr('Sơ đồ Thảo Cầm Viên', 'Zoo map', '园区导览图') if m == 'art'
                              else tr('Bản đồ thật', 'Real map', '真实地图')) == 'art'

    def project_many(points):
        """Toạ độ thật -> toạ độ vẽ trên bản đồ đang hiển thị."""
        if not art:
            return [list(p) for p in points]
        return [artmap.leaflet(x, y) for x, y in artmap.to_art_many(points)]

    # Lớp tĩnh (vẽ một lần): nền, lối đi, các khu. Tâm cố định để bản đồ không phải tải lại khi bạn di chuyển.
    if art:
        fmap = folium.Map(location=artmap.leaflet(artmap.WIDTH / 2, artmap.HEIGHT / 2), crs='Simple', tiles=None,
                          zoom_start=-1, minZoom=-2, maxZoom=2, zoom_snap=0.25, max_bounds=True,   # min/maxZoom: folium chỉ áp cho lớp nền tile
                          min_lat=-artmap.HEIGHT, max_lat=0, min_lon=0, max_lon=artmap.WIDTH)
        folium.raster_layers.ImageOverlay(image=artmap.IMAGE_URL, bounds=artmap.bounds()).add_to(fmap)
        layer_control = None
    else:
        fmap = folium.Map(location=[zoo_lat, zoo_lng], zoom_start=18, tiles=None, control_scale=True)
        layer_control = ui.add_base_layers(fmap, tr('Bản đồ', 'Map', '地图'), tr('Ảnh vệ tinh', 'Satellite', '卫星图'), control=False)
    for w in ([] if art else all_walkways):   # sơ đồ đã vẽ sẵn lối đi
        if w.get('geom_json'):
            w_coords = [(pt[1], pt[0]) for pt in json.loads(w['geom_json'])['coordinates']]
            folium.PolyLine(w_coords, color='#9AAFA1', weight=2.5, opacity=0.75,
                            tooltip=tr(f'Lối đi bộ: {w["name"]}', f'Walkway: {w["name"]}', f'步行道：{w["name"]}')).add_to(fmap)
    for item in all_exhibits:
        color = zone_color(item)
        if item.get('poly_geojson') and not art:
            folium.GeoJson(json.loads(item['poly_geojson']), name=item['name'], control=False,
                           # Vùng nghe thuyết minh (không phải hàng rào chuồng): nét đứt, màu nhạt
                           style_function=lambda x, c=color: {'fillColor': c, 'color': c, 'weight': 1.5, 'dashArray': '6 6', 'fillOpacity': 0.14},
                           tooltip=f'<b>{html.escape(item["name"])}</b>').add_to(fmap)
        # Cọc đỏ đánh số như bản đồ in của Thảo Cầm Viên (khu có nhiều điểm: thêm cọc phụ cùng số)
        label = html.escape(ui.zone_label(item))
        spots = [(item['lat'], item['lng'])] + [tuple(p) for p in (item.get('extra_pins') or [])]
        for spot in project_many(spots):
            folium.Marker(location=spot, tooltip=label, popup=label, icon=ui.pin_icon(item.get('map_no'))).add_to(fmap)

    # Lớp động (cập nhật mỗi lần bạn di chuyển, không tải lại bản đồ): vị trí, vòng 50 m, đường đi
    live = folium.FeatureGroup(name=tr('Vị trí và đường đi', 'Position and route', '位置与路线'), control=False)
    if st.session_state.target_route_id:
        target_info = next((item for item in all_exhibits if item['id'] == st.session_state.target_route_id), None)
        if target_info:
            path_segments = database_read(get_shortest_path, st.session_state.user_lat, st.session_state.user_lng, target_info['lat'], target_info['lng'])
            if path_segments:
                full_walk_path = [(st.session_state.user_lat, st.session_state.user_lng)]
                total_distance = 0.0
                for seg in path_segments:
                    for c in [(pt[1], pt[0]) for pt in json.loads(seg['geom_json'])['coordinates']]:
                        if full_walk_path[-1] != c:
                            full_walk_path.append(c)
                    total_distance += float(seg.get('cost', 0.0))
                target_pt = (target_info['lat'], target_info['lng'])
                if full_walk_path[-1] != target_pt:
                    full_walk_path.append(target_pt)
                folium.PolyLine(project_many(full_walk_path), color=ui.LOTUS, weight=6, opacity=0.95, dash_array='1, 11', line_cap='round',
                                tooltip=tr(f'Đường đi bộ tới {target_info["name"]}', f'Walking route to {target_info["name"]}', f'前往 {target_info["name"]} 的步行路线')).add_to(live)
                minutes = max(1, round(total_distance / 70))   # ~70 m/phút đi bộ thong thả
                if gps_live:   # đang đi thật: hiện quãng đường còn lại, tự tính lại khi bạn di chuyển
                    route_box.markdown(ui.route_line(
                        tr('Đang dẫn đường tới ', 'Navigating to ', '正在导航至 '), target_info['name'],
                        tr(f': còn khoảng {int(total_distance)} m, chừng {minutes} phút.', f': about {int(total_distance)} m left, roughly {minutes} min.',
                           f'：还剩约 {int(total_distance)} 米，大约 {minutes} 分钟。')), unsafe_allow_html=True)
                else:
                    route_box.markdown(ui.route_line(
                        tr('Đường đi bộ tới ', 'Walking route to ', '步行前往 '), target_info['name'],
                        tr(f': khoảng {int(total_distance)} m, chừng {minutes} phút.', f': about {int(total_distance)} m, roughly {minutes} min.',
                           f'：约 {int(total_distance)} 米，大约 {minutes} 分钟。')), unsafe_allow_html=True)
            else:
                route_box.warning(tr('Không tìm thấy lối đi bộ nối tới khu này. Hãy chọn một điểm xuất phát khác trên bản đồ.',
                                     'No connected walking path reaches this zone. Try starting from another point on the map.',
                                     '没有可通往该展区的步道，请在地图上换一个起点。'))
    me = project_many([(st.session_state.user_lat, st.session_state.user_lng)])[0]
    ring = artmap.metres_to_px(st.session_state.user_lat, st.session_state.user_lng, 50) if art else 50   # vòng 50 m thật
    folium.Marker(location=me, tooltip=tr('Bạn đang ở đây', 'You are here', '您在这里'),
                  icon=folium.Icon(color='pink', icon='street-view', prefix='fa')).add_to(live)
    folium.Circle(location=me, radius=ring, color=ui.LOTUS, weight=2, dash_array='6, 6',
                  fill=True, fill_color=ui.LOTUS, fill_opacity=0.07).add_to(live)
    map_out = st_folium(fmap, key='visitor_map_art' if art else 'visitor_map', width='100%', height=600,
                        returned_objects=['last_clicked'], center=tuple(me), zoom=-1 if art else None,
                        feature_group_to_add=live, layer_control=layer_control)
    st.markdown(ui.legend_note(
        tr('Mỗi cọc đỏ là một khu tham quan, đánh số đúng như sơ đồ của Thảo Cầm Viên. Đi tới gần là app tự kể.',
           'Each red pin is a zone, numbered as on the official zoo map. Walk close and the story plays.',
           '每个红色标记是一个展区，编号与动植物园官方导览图一致。走近即可自动播放讲解。') if art else
        tr('Vòng nét đứt quanh mỗi khu là vùng nghe thuyết minh: bước vào là app tự kể.',
           'The dashed ring around each zone is its narration area: step inside and the story plays.',
           '每个展区周围的虚线圈是讲解区域：走进去就会自动播放讲解。')), unsafe_allow_html=True)
    numbered = any(item.get('map_no') is not None for item in all_exhibits)
    legend_zones = [] if numbered else [(item['name'], zone_color(item)) for item in all_exhibits]
    if numbered:   # 52 khu: chú thích bằng cọc số (xem danh sách bên trái) thay vì liệt kê từng màu
        legend_zones = [(tr('Cọc số: phân khu theo bản đồ Thảo Cầm Viên', 'Numbered pins: zones as on the official zoo map',
                            '数字标记：与动植物园官方地图一致的展区'), ui.PIN_RED)]
    st.markdown(ui.legend(legend_zones,
                          tr('Bạn đang ở đây, vòng 50 m', 'You are here, 50 m ring', '您的位置，50米范围'),
                          tr('Đường đi bộ gợi ý', 'Suggested walking route', '建议步行路线')), unsafe_allow_html=True)
    if map_out and map_out.get('last_clicked'):
        c_lat, c_lng = map_out['last_clicked']['lat'], map_out['last_clicked']['lng']
        if (art, round(c_lat, 5), round(c_lng, 5)) != st.session_state.get('last_click'):
            st.session_state.last_click = (art, round(c_lat, 5), round(c_lng, 5))
            if art:   # chạm trên sơ đồ -> đổi ra toạ độ thật
                c_lat, c_lng = artmap.to_latlng(*artmap.from_leaflet(c_lat, c_lng))
            st.session_state.user_lat, st.session_state.user_lng = c_lat, c_lng
            st.session_state.img_index = 0
            st.rerun()

with col_info:
    st.markdown(ui.section(tr('Thuyết minh', 'Narration', '讲解')), unsafe_allow_html=True)
    if target_raw:
        target = with_vietnamese_name(localize(target_raw, language, content_translations), target_raw['name'], language)
        with st.container(key='guide'):
            # Ảnh admin tải lên (database) trước, sau đó ảnh có sẵn trong thư mục images/
            valid_images = [data for _, data in (tracking_call(zone_images, target['id'], default=[]) or [])]
            valid_images += [str(BASE / 'images' / img) for img in EXHIBIT_IMAGES.get(target['id'], [])
                             if os.path.exists(str(BASE / 'images' / img))]
            if valid_images:
                idx = st.session_state.img_index % len(valid_images)
                st.image(valid_images[idx], use_container_width=True)
                if len(valid_images) > 1:
                    c_prev, c_txt, c_next = st.columns([2, 1, 2])
                    with c_prev:
                        if st.button(tr('Ảnh trước', 'Previous', '上一张'), key='btn_img_prev', use_container_width=True):
                            st.session_state.img_index = (idx - 1) % len(valid_images)
                            st.rerun()
                    with c_txt:
                        st.markdown(f'<div class="tcv-counter">{idx + 1} / {len(valid_images)}</div>', unsafe_allow_html=True)
                    with c_next:
                        if st.button(tr('Ảnh sau', 'Next', '下一张'), key='btn_img_next', use_container_width=True):
                            st.session_state.img_index = (idx + 1) % len(valid_images)
                            st.rerun()
            dist = float(target['distance_meters'] or 0)
            dist_text = (tr('Bạn đang ở trong khu này', 'You are inside this zone', '您正在该展区内') if dist < 1 else
                         tr(f'Cách bạn {dist:.0f} m', f'{dist:.0f} m from you', f'距您 {dist:.0f} 米'))
            st.markdown(ui.zone_header(target['name'], dist_text, tr('Đang thuyết minh', 'Now playing', '正在讲解'), zone_color(target_raw)),
                        unsafe_allow_html=True)
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
            st.markdown(ui.story(target['description'],
                                 '' if target['translated'] else tr('', 'This zone has no English text yet, so the Vietnamese text is shown.',
                                                                     '该展区暂无中文内容，显示越南语原文。')),
                        unsafe_allow_html=True)
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
