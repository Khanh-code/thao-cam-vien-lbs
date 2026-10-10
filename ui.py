"""Giao diện: phông chữ, màu sắc và các khối HTML dùng chung (tầng trình bày).

Hệ màu lấy từ Thảo Cầm Viên: xanh tán cây, xanh lá, sương sớm, rêu; hồng sen chỉ dùng cho những gì
thuộc về KHÁCH (vị trí của bạn, đường bạn đi, khu đang thuyết minh) để mắt nhận ra ngay.
"""
import html
import math

CANOPY = '#0F3B2E'   # xanh tán cây — dải tiêu đề, tiêu đề
LEAF = '#2E7D4F'     # xanh lá — nút chính
MIST = '#F2F6F1'     # nền trang
MOSS = '#DCE8DE'     # thanh bên
INK = '#1C2B24'      # chữ
LOTUS = '#C8406E'    # hồng sen — "bạn"

# Màu vùng trên bản đồ -> chấm màu cho nút / biểu tượng folium tương ứng
ZONE_DOT = {'#e74c3c': '🔴', '#8e44ad': '🟣', '#e67e22': '🟠', '#27ae60': '🟢', '#2ecc71': '🟢', '#3498db': '🔵'}
ZONE_ICON = {'#e74c3c': ('red', 'paw'), '#8e44ad': ('purple', 'paw'), '#e67e22': ('orange', 'paw'),
             '#27ae60': ('green', 'paw'), '#2ecc71': ('lightgreen', 'leaf'), '#3498db': ('blue', 'child')}

CSS = f"""
<style>
@import url('https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&family=Noto+Sans+SC:wght@400;500;700&display=swap');
:root {{ --canopy:{CANOPY}; --leaf:{LEAF}; --mist:{MIST}; --moss:{MOSS}; --ink:{INK}; --lotus:{LOTUS}; }}
html, body, .stApp, .stMarkdown, .stButton button, .stTextInput input, .stSelectbox, [data-testid="stSidebar"] {{
  font-family: 'Be Vietnam Pro', 'Noto Sans SC', system-ui, sans-serif;
}}
.stApp {{ background: var(--mist); color: var(--ink); }}
header[data-testid="stHeader"] {{ background: transparent; }}
.block-container {{ padding-top: 1.4rem; padding-bottom: 3rem; max-width: 1440px; }}
[data-testid="stSidebar"] {{ background: var(--moss); }}
[data-testid="stSidebar"] h2, [data-testid="stSidebar"] h3 {{ color: var(--canopy); letter-spacing: -0.01em; }}
[data-testid="stSidebar"] h3 {{ font-size: 1.02rem; font-weight: 700; margin-top: .4rem; }}
h2, h3 {{ color: var(--canopy); letter-spacing: -0.015em; }}
.stButton button {{ border-radius: 10px; border: 1px solid #c3d4c7; background: #fff; color: var(--ink);
  font-weight: 500; }}
.stButton button:hover {{ border-color: var(--leaf); color: var(--leaf); }}
.stButton button[kind="primary"] {{ background: var(--leaf); border-color: var(--leaf); color: #fff; }}
.stButton button[kind="primary"]:hover {{ background: var(--canopy); color: #fff; }}
.stButton button:focus-visible {{ outline: 3px solid var(--lotus); outline-offset: 2px; }}

/* ---------- Dải tiêu đề ---------- */
.tcv-hero {{ position: relative; overflow: hidden; background: var(--canopy); color: #EAF3EC;
  border-radius: 20px; padding: 30px 34px 26px; margin-bottom: 18px; }}
.tcv-hero h1 {{ font-size: clamp(2rem, 4.2vw, 3.3rem); font-weight: 800; letter-spacing: -0.03em; line-height: 1.04;
  color: #fff; margin: 0 0 6px; padding: 0; max-width: 26ch; text-wrap: balance; }}
.tcv-hero .tcv-sub {{ font-size: 1.06rem; line-height: 1.55; max-width: 60ch; color: #CFE3D5; margin: 0 0 20px; }}
.tcv-hero .tcv-since {{ font-size: .9rem; color: #9FC4AB; margin: 0 0 14px; }}
.tcv-hero ol {{ list-style: none; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px 24px; margin: 0; padding: 0; counter-reset: step; }}
.tcv-hero li {{ counter-increment: step; display: flex; align-items: center; gap: 10px; font-size: .95rem; color: #EAF3EC; }}
.tcv-hero li::before {{ content: counter(step); flex: 0 0 26px; height: 26px; border-radius: 50%; display: grid; place-items: center;
  background: #1F5C45; color: #fff; font-weight: 700; font-size: .85rem; }}
.tcv-hero svg {{ position: absolute; right: -20px; top: -60px; width: 320px; height: 320px; opacity: .2; pointer-events: none; }}
.tcv-hero > :not(svg) {{ position: relative; }}
.tcv-hero ol {{ max-width: calc(100% - 200px); }}
@media (max-width: 760px) {{
  .tcv-hero {{ padding: 20px 18px 18px; border-radius: 16px; }}
  .tcv-hero .tcv-sub {{ font-size: .98rem; margin-bottom: 12px; }}
  .tcv-hero ol {{ grid-template-columns: 1fr; gap: 6px; max-width: none; }}
  .tcv-hero li {{ font-size: .9rem; }}
  .tcv-hero li::before {{ flex-basis: 22px; height: 22px; font-size: .78rem; }}
  .tcv-hero svg {{ width: 200px; height: 200px; right: -70px; top: -50px; }}
}}

/* ---------- Thẻ thuyết minh (kiểu bảng tên hiện vật) ---------- */
.tcv-placard {{ background: #fff; border-radius: 14px; border-left: 7px solid var(--zone, var(--leaf));
  padding: 18px 20px 14px; margin-bottom: 12px; box-shadow: 0 1px 0 #d9e5dc; }}
.tcv-now {{ display: flex; align-items: center; gap: 8px; color: var(--lotus); font-weight: 600; font-size: .9rem; margin-bottom: 6px; }}
.tcv-now i {{ width: 9px; height: 9px; border-radius: 50%; background: var(--lotus); box-shadow: 0 0 0 0 rgba(200,64,110,.5);
  animation: tcv-pulse 1.8s ease-out infinite; }}
@keyframes tcv-pulse {{ to {{ box-shadow: 0 0 0 10px rgba(200,64,110,0); }} }}
@media (prefers-reduced-motion: reduce) {{ .tcv-now i {{ animation: none; }} }}
.tcv-placard h3 {{ font-size: 1.55rem; font-weight: 800; letter-spacing: -0.02em; line-height: 1.15; margin: 0 0 8px; padding: 0; color: var(--canopy); }}
.tcv-dist {{ display: inline-block; font-size: .88rem; font-weight: 600; color: var(--lotus); background: #FBE9EF;
  border-radius: 999px; padding: 3px 11px; margin-bottom: 12px; }}
.tcv-placard p {{ font-size: 1.02rem; line-height: 1.62; max-width: 62ch; margin: 0; color: var(--ink); }}
.tcv-note {{ font-size: .86rem; color: #5B6F63; margin-top: 10px; }}
.tcv-empty {{ background: #fff; border-radius: 14px; padding: 20px; border: 1px dashed #b7cbbd; }}
.tcv-empty h3 {{ font-size: 1.15rem; margin: 0 0 6px; color: var(--canopy); }}
.tcv-empty p {{ margin: 0; line-height: 1.55; }}

/* ---------- Chú thích bản đồ ---------- */
.tcv-legend {{ display: flex; flex-wrap: wrap; gap: 6px 16px; font-size: .88rem; color: #3E5246; margin: 8px 2px 0; }}
.tcv-legend span {{ display: inline-flex; align-items: center; gap: 6px; }}
.tcv-legend b {{ width: 11px; height: 11px; border-radius: 3px; display: inline-block; }}
.tcv-legend .you b {{ border-radius: 50%; background: var(--lotus); }}
.tcv-legend .route b {{ width: 18px; height: 0; border-radius: 0; border-top: 3px dotted var(--lotus); }}
.tcv-coords {{ font-size: .84rem; color: #5B6F63; margin: 0 0 8px; }}
.tcv-route {{ background: #fff; border-radius: 12px; padding: 10px 14px; border: 1px solid #e3c4cf; margin-bottom: 10px; }}
.tcv-route strong {{ color: var(--lotus); }}
</style>
"""

LEAF_SVG = """<svg viewBox="0 0 200 200" aria-hidden="true" fill="none" stroke="#BFE3CB" stroke-width="2.2" stroke-linecap="round">
<path d="M40 178C30 120 52 62 104 34c22-12 46-18 72-20-2 26-8 50-20 72-28 52-86 74-116 92Z"/>
<path d="M40 178C74 136 112 92 160 34"/>
<path d="M66 148c-8-18-10-38-4-58M88 122c-6-20-6-42 2-62M110 96c-4-18-2-38 8-54M132 70c-2-12 2-24 8-34"/>
<path d="M66 148c20 2 40-2 58-12M88 122c20 0 40-6 56-18M110 96c18-2 34-8 48-20M132 70c12-2 22-6 32-14"/>
</svg>"""


def esc(text):
    return html.escape(str(text or ''))


def hero(title, subtitle, since, steps):
    items = ''.join(f'<li>{esc(s)}</li>' for s in steps)
    return (f'<section class="tcv-hero">{LEAF_SVG}<h1>{esc(title)}</h1><p class="tcv-since">{esc(since)}</p>'
            f'<p class="tcv-sub">{esc(subtitle)}</p><ol>{items}</ol></section>')


def placard(name, distance_text, description, zone_color, now_label, note=''):
    note_html = f'<div class="tcv-note">{esc(note)}</div>' if note else ''
    return (f'<div class="tcv-placard" style="--zone:{esc(zone_color)}">'
            f'<div class="tcv-now"><i></i>{esc(now_label)}</div><h3>{esc(name)}</h3>'
            f'<span class="tcv-dist">{esc(distance_text)}</span><p>{esc(description)}</p>{note_html}</div>')


def empty_state(title, body):
    return f'<div class="tcv-empty"><h3>{esc(title)}</h3><p>{esc(body)}</p></div>'


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
