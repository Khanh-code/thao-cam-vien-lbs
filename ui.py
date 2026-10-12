"""Tầng trình bày: phông chữ, màu sắc, bố cục và các khối HTML dùng chung.

Hướng thiết kế: trang hướng dẫn tham quan kiểu bảo tàng — ảnh thật làm chủ đạo, nền trắng,
chữ đậm rõ ràng, một màu nhấn xanh đậm. Màu hồng sen chỉ dành cho những gì thuộc về KHÁCH
(vị trí của bạn, vòng 50 m, đường bạn sẽ đi) để mắt nhận ra ngay. Không dùng emoji trang trí.
"""
import base64
import html
import math
from functools import lru_cache
from pathlib import Path

GREEN = '#1F5C43'    # màu nhấn chính: nút, tiêu đề phụ
INK = '#17221C'      # chữ
MUTED = '#5E6B63'    # chữ phụ
LINE = '#E3E8E4'     # đường viền
GROUND = '#F5F7F5'   # nền phụ (thanh bên, khối phụ)
LOTUS = '#C8406E'    # hồng sen — "bạn"
LEAF = GREEN

# Màu vùng trên bản đồ -> biểu tượng folium tương ứng
ZONE_ICON = {'#e74c3c': ('red', 'paw'), '#8e44ad': ('purple', 'paw'), '#e67e22': ('orange', 'paw'),
             '#27ae60': ('green', 'paw'), '#2ecc71': ('lightgreen', 'leaf'), '#3498db': ('blue', 'child')}

CSS = f"""
<style>
@import url('https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700&family=Noto+Sans+SC:wght@400;500;700&display=swap');
:root {{ --green:{GREEN}; --ink:{INK}; --muted:{MUTED}; --line:{LINE}; --ground:{GROUND}; --lotus:{LOTUS}; }}
html, body, .stApp, .stMarkdown, button, input, textarea, [data-testid="stSidebar"], [data-baseweb] {{
  font-family: 'Be Vietnam Pro', 'Noto Sans SC', system-ui, sans-serif;
}}
.stApp {{ background: #fff; color: var(--ink); }}
#MainMenu, footer, [data-testid="stStatusWidget"], [data-testid="stToolbar"] {{ visibility: hidden; }}
header[data-testid="stHeader"] {{ background: transparent; height: 2.6rem; }}
.block-container {{ padding-top: 1.2rem; padding-bottom: 4rem; max-width: 1380px; }}
h1, h2, h3, h4 {{ color: var(--ink); letter-spacing: -0.02em; }}
p, li {{ line-height: 1.6; }}

/* Thanh bên: danh mục gọn, không đóng hộp */
[data-testid="stSidebar"] {{ background: var(--ground); border-right: 1px solid var(--line); }}
[data-testid="stSidebar"] .block-container, [data-testid="stSidebarContent"] {{ padding-top: .4rem; }}
.tcv-side-title {{ font-size: .82rem; font-weight: 600; color: var(--muted); margin: 18px 0 6px; }}
.tcv-side-title:first-child {{ margin-top: 4px; }}

/* Ô nhập: luôn có nền trắng + viền rõ (không phải bấm vào mới thấy), viền xanh khi đang nhập.
   Áp dụng cho cả Streamlit mới (stTextInputRootElement...) và bản cũ (data-baseweb). */
[data-testid="stTextInputRootElement"], [data-testid="stTextAreaRootElement"], [data-testid="stNumberInputContainer"],
[data-testid="stSelectbox"] [role="group"], [data-testid="stDateInput"] [role="group"],
[data-baseweb="input"], [data-baseweb="textarea"], [data-baseweb="select"] > div {{
  background: #fff !important; border: 1px solid #C3CEC6 !important; border-radius: 8px !important; }}
[data-testid="stTextInputRootElement"]:focus-within, [data-testid="stTextAreaRootElement"]:focus-within,
[data-testid="stSelectbox"] [role="group"]:focus-within, [data-testid="stDateInput"] [role="group"]:focus-within,
[data-baseweb="input"]:focus-within, [data-baseweb="textarea"]:focus-within, [data-baseweb="select"] > div:focus-within {{
  border-color: var(--green) !important; box-shadow: 0 0 0 3px rgba(31,92,67,.12) !important; }}
[data-testid="stTextInputRootElement"] input, [data-testid="stTextAreaRootElement"] textarea, [data-testid="stSelectbox"] input,
[data-baseweb="input"] input, [data-baseweb="textarea"] textarea {{ background: #fff !important; color: var(--ink); }}
[data-testid="stFileUploaderDropzone"] {{ background: #fff; border: 1px dashed #C3CEC6; border-radius: 8px; }}
[data-testid="InputInstructions"] {{ display: none; }}

/* Nút */
.stButton button {{ border-radius: 8px; border: 1px solid var(--line); background: #fff; color: var(--ink);
  font-weight: 500; box-shadow: none; }}
.stButton button:hover {{ border-color: var(--green); color: var(--green); background: #fff; }}
.stButton button[kind="primary"] {{ background: var(--green); border-color: var(--green); color: #fff; }}
.stButton button[kind="primary"]:hover {{ background: #174A35; color: #fff; }}
button:focus-visible, input:focus-visible {{ outline: 2px solid var(--lotus) !important; outline-offset: 2px; }}

/* Danh sách khu: hàng chữ căn trái, vạch màu khớp màu vùng trên bản đồ */
[class*="st-key-zone_"] button {{ justify-content: flex-start; text-align: left; border: none; border-left: 4px solid var(--zc, var(--green));
  border-radius: 0 6px 6px 0; background: transparent; padding: 6px 12px; min-height: 2.3rem; }}
[class*="st-key-zone_"] button:hover {{ background: #fff; color: var(--ink); }}
[class*="st-key-zone_"] button > div, [class*="st-key-zone_"] button [data-testid="stMarkdownContainer"] {{ justify-content: flex-start; width: 100%; }}
[class*="st-key-zone_"] button p {{ font-size: .95rem; text-align: left; }}
[class*="st-key-zone_"].tcv-active button, [class*="st-key-zone_"] button:focus {{ background: #fff; font-weight: 600; }}

/* Thanh trên cùng */
.tcv-brand {{ font-weight: 700; font-size: 1.05rem; letter-spacing: -0.01em; color: var(--ink); padding-top: .35rem; }}
.tcv-brand span {{ color: var(--muted); font-weight: 500; }}
[class*="st-key-lang"] [role="radiogroup"] {{ justify-content: flex-end; gap: 4px; }}
[class*="st-key-lang"] [data-testid="stRadioOption"] {{ border: 1px solid var(--line); border-radius: 999px; padding: 5px 14px; margin: 0; cursor: pointer; }}
[class*="st-key-lang"] [data-testid="stRadioOption"] > div > div:not([data-testid="stMarkdownContainer"]) {{ display: none; }}
[class*="st-key-lang"] [data-testid="stRadioOption"] p {{ font-size: .9rem; }}
[class*="st-key-lang"] [data-testid="stRadioOption"][data-selected="true"] {{ border-color: var(--green); background: var(--green); }}
[class*="st-key-lang"] [data-testid="stRadioOption"][data-selected="true"] p {{ color: #fff; }}

/* Ảnh bìa */
.tcv-hero {{ position: relative; height: 400px; border-radius: 16px; overflow: hidden; margin: 6px 0 30px;
  background-size: cover; background-position: center 35%; display: flex; align-items: flex-end; }}
.tcv-hero::after {{ content: ""; position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(8,18,13,0) 25%, rgba(8,18,13,.55) 55%, rgba(8,18,13,.88) 100%),
              linear-gradient(90deg, rgba(8,18,13,.45) 0%, rgba(8,18,13,0) 60%); }}
.tcv-hero-text {{ position: relative; z-index: 1; padding: 0 36px 30px; max-width: 760px; }}
.tcv-hero h1 {{ text-shadow: 0 1px 12px rgba(0,0,0,.25); color: #fff; font-size: clamp(2.1rem, 4.6vw, 3.6rem); font-weight: 700; line-height: 1.05;
  letter-spacing: -0.035em; margin: 0 0 10px; padding: 0; text-wrap: balance; }}
.tcv-hero p {{ color: rgba(255,255,255,.88); font-size: 1.12rem; line-height: 1.5; margin: 0; max-width: 46ch; }}
.tcv-credit {{ position: absolute; right: 14px; bottom: 10px; z-index: 1; font-size: .72rem; color: rgba(255,255,255,.6); }}

/* Ô bật GPS: ngay trên bản đồ, hiện cả trên điện thoại */
[class*="st-key-gps_box"] {{ background: var(--ground); border: 1px solid var(--line); border-radius: 12px;
  padding: 10px 14px 4px; margin: -8px 0 18px; }}
[class*="st-key-gps_box"] [data-testid="stAlert"] {{ margin-bottom: 6px; }}
/* Khung theo dõi GPS chạy ngầm: không chiếm chỗ (vẫn chạy, chỉ không hiển thị) */
[class*="st-key-gps_box"] [data-testid="stElementContainer"]:has(iframe) {{ position: absolute; width: 1px; height: 1px;
  overflow: hidden; opacity: 0; pointer-events: none; }}

/* Tiêu đề khu vực */
.tcv-section {{ font-size: 1.2rem; font-weight: 700; letter-spacing: -0.02em; margin: 0 0 10px; color: var(--ink); }}
.tcv-section small {{ font-size: .88rem; font-weight: 400; color: var(--muted); margin-left: 8px; letter-spacing: 0; }}

/* Thẻ hướng dẫn (ảnh ở trên, chữ ở dưới — như một trang sách hướng dẫn) */
[class*="st-key-guide"] {{ border: 1px solid var(--line); border-radius: 16px; padding: 14px 16px 6px; background: #fff; }}
[class*="st-key-guide"] img {{ border-radius: 10px; }}
.tcv-zone {{ border-left: 4px solid var(--zc, var(--green)); padding: 2px 0 2px 14px; margin: 14px 0 12px; }}
.tcv-zone h2 {{ font-size: 1.7rem; font-weight: 700; line-height: 1.15; letter-spacing: -0.03em; margin: 0 0 6px; padding: 0; }}
.tcv-meta {{ font-size: .92rem; color: var(--muted); display: flex; gap: 14px; flex-wrap: wrap; align-items: center; }}
.tcv-meta .tcv-here {{ color: var(--lotus); font-weight: 600; display: inline-flex; align-items: center; gap: 7px; }}
.tcv-here i {{ width: 8px; height: 8px; border-radius: 50%; background: var(--lotus); box-shadow: 0 0 0 0 rgba(200,64,110,.45);
  animation: tcv-pulse 2s ease-out infinite; }}
@keyframes tcv-pulse {{ to {{ box-shadow: 0 0 0 9px rgba(200,64,110,0); }} }}
@media (prefers-reduced-motion: reduce) {{ .tcv-here i {{ animation: none; }} }}
.tcv-story {{ font-size: 1.04rem; line-height: 1.68; max-width: 60ch; margin: 0 0 12px; color: var(--ink); }}
.tcv-note {{ font-size: .86rem; color: var(--muted); margin: -4px 0 10px; }}
.tcv-counter {{ text-align: center; font-size: .86rem; color: var(--muted); padding-top: .5rem; }}

.tcv-empty {{ padding: 26px 22px; border: 1px dashed #C9D3CC; border-radius: 16px; background: var(--ground); }}
.tcv-empty h2 {{ font-size: 1.25rem; margin: 0 0 8px; padding: 0; }}
.tcv-empty p {{ margin: 0; color: var(--ink); max-width: 52ch; }}

/* Chú thích + thông tin đường đi */
.tcv-legend {{ display: flex; flex-wrap: wrap; gap: 6px 18px; font-size: .86rem; color: var(--muted); margin: 10px 2px 0; }}
.tcv-legend span {{ display: inline-flex; align-items: center; gap: 7px; }}
.tcv-legend b {{ width: 12px; height: 12px; border-radius: 50%; display: inline-block; opacity: .85; }}
.tcv-legend-note {{ font-size: .86rem; color: var(--muted); margin: 10px 2px 0; }}
.tcv-legend .you b {{ border-radius: 50%; background: var(--lotus); }}
.tcv-legend .route b {{ width: 20px; height: 0; border-radius: 0; border-top: 3px dotted var(--lotus); }}
.tcv-route {{ display: flex; gap: 10px; align-items: baseline; font-size: .98rem; padding: 10px 14px; margin-bottom: 10px;
  border-radius: 10px; background: #FBEFF3; color: var(--ink); }}
.tcv-route b {{ color: var(--lotus); }}
.tcv-coords {{ font-size: .8rem; color: var(--muted); margin: 8px 0 0; }}
iframe[title="streamlit_folium.st_folium"] {{ border-radius: 14px; border: 1px solid var(--line); }}

@media (max-width: 760px) {{
  .block-container {{ padding-left: 1rem; padding-right: 1rem; }}
  .tcv-hero {{ height: 250px; margin-bottom: 20px; border-radius: 14px; }}
  .tcv-hero-text {{ padding: 0 20px 20px; }}
  .tcv-hero p {{ font-size: 1rem; }}
  .tcv-credit {{ display: none; }}
  [class*="st-key-lang"] [role="radiogroup"] {{ justify-content: flex-start; }}
  .tcv-zone h2 {{ font-size: 1.45rem; }}
}}
</style>
"""


# Bản đồ nền: Esri (không cần khoá API). CARTO đã yêu cầu khoá API nên không dùng nữa.
ESRI_STREET = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}'
ESRI_IMAGERY = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
ESRI_ATTR = 'Tiles &copy; Esri'
IMAGERY_ATTR = 'Tiles &copy; Esri, Maxar, Earthstar Geographics'


def add_base_layers(fmap, street_name, imagery_name, imagery_first=False, control=True):
    """Thêm 2 lớp nền: bản đồ đường phố và ảnh vệ tinh (chuyển qua lại ở góc phải bản đồ).
    control=False: trả về LayerControl để truyền cho st_folium (khi có lớp động feature_group_to_add)."""
    import folium
    # show=... quyết định lớp nào đang bật khi mở bản đồ
    folium.TileLayer(ESRI_STREET, attr=ESRI_ATTR, name=street_name, max_zoom=20, max_native_zoom=19,
                     show=not imagery_first).add_to(fmap)
    folium.TileLayer(ESRI_IMAGERY, attr=IMAGERY_ATTR, name=imagery_name, max_zoom=20, max_native_zoom=19,
                     show=imagery_first).add_to(fmap)
    lc = folium.LayerControl(position='topright', collapsed=True)   # thu gọn thành biểu tượng, không che bản đồ
    if control:
        lc.add_to(fmap)
    return lc


def esc(text):
    return html.escape(str(text or ''))


@lru_cache(maxsize=4)
def _data_uri(path):
    p = Path(path)
    if not p.is_file():
        return ''
    return 'data:image/jpeg;base64,' + base64.b64encode(p.read_bytes()).decode()


def zone_css(zones):
    """Màu vạch cho từng nút khu (theo key widget: zone_<id>) — khớp màu vùng trên bản đồ."""
    rules = ''.join(f'.st-key-zone_{int(zid)} button {{ --zc: {esc(color)}; }}' for zid, color in zones)
    return f'<style>{rules}</style>'


def top_bar_brand(name, place):
    return f'<div class="tcv-brand">{esc(name)} <span>{esc(place)}</span></div>'


def hero(title, subtitle, image_path, credit=''):
    uri = _data_uri(str(image_path))
    bg = f"background-image:url('{uri}')" if uri else f'background:{GREEN}'
    credit_html = f'<div class="tcv-credit">{esc(credit)}</div>' if credit else ''
    return (f'<section class="tcv-hero" style="{bg}"><div class="tcv-hero-text">'
            f'<h1>{esc(title)}</h1><p>{esc(subtitle)}</p></div>{credit_html}</section>')


def section(title, hint=''):
    small = f'<small>{esc(hint)}</small>' if hint else ''
    return f'<div class="tcv-section">{esc(title)}{small}</div>'


def zone_header(name, distance_text, now_label, zone_color):
    return (f'<div class="tcv-zone" style="--zc:{esc(zone_color)}"><h2>{esc(name)}</h2>'
            f'<div class="tcv-meta"><span class="tcv-here"><i></i>{esc(now_label)}</span>'
            f'<span>{esc(distance_text)}</span></div></div>')


def story(text, note=''):
    note_html = f'<p class="tcv-note">{esc(note)}</p>' if note else ''
    return f'{note_html}<p class="tcv-story">{esc(text)}</p>'


def empty_state(title, body):
    return f'<div class="tcv-empty"><h2>{esc(title)}</h2><p>{esc(body)}</p></div>'


def route_line(text_before, name, text_after):
    return f'<div class="tcv-route"><span>{esc(text_before)}<b>{esc(name)}</b>{esc(text_after)}</span></div>'


PIN_RED = '#E3262E'   # màu cọc trên bản đồ chính thức của Thảo Cầm Viên


def pin_icon(number, color=PIN_RED, size=26):
    """Cọc tròn đỏ có số, giống bản đồ in "Khám phá Thảo Cầm Viên". Khu chưa có số -> chấm tròn nhỏ."""
    import folium
    if number is None:
        size = 14
        inner = ''
    else:
        inner = str(int(number))
    font = 12 if len(inner) < 2 else 11
    html_pin = (f'<div style="width:{size}px;height:{size}px;border-radius:50%;background:{color};'
                f'border:2px solid #fff;box-shadow:0 1px 3px rgba(0,0,0,.45);color:#fff;'
                f'font:700 {font}px/{size - 4}px Arial,Helvetica,sans-serif;text-align:center;">{inner}</div>')
    return folium.DivIcon(html=html_pin, icon_size=(size, size), icon_anchor=(size // 2, size // 2))


def zone_label(item):
    """Tên hiển thị trong danh sách: "12 · Voọc bạc, Nhím"."""
    return f"{item['map_no']} · {item['name']}" if item.get('map_no') is not None else item['name']


def legend_note(text):
    return f'<p class="tcv-legend-note">{esc(text)}</p>'


def legend(zones, you_label, route_label):
    chips = ''.join(f'<span><b style="background:{esc(color)}"></b>{esc(name)}</span>' for name, color in zones)
    return (f'<div class="tcv-legend">{chips}<span class="you"><b></b>{esc(you_label)}</span>'
            f'<span class="route"><b></b>{esc(route_label)}</span></div>')


def haversine_m(lat1, lng1, lat2, lng2):
    """Khoảng cách đường chim bay (mét) — chỉ dùng để gợi ý khu gần nhất ngoài bán kính 50 m."""
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))
