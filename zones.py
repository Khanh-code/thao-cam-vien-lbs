"""Quản lý phân khu (chỉ admin): thêm, sửa, xoá, ảnh — kèm kiểm tra không gian bằng PostGIS.

Kiểm tra ranh giới trước khi lưu:
- ST_IsValid       : đa giác hợp lệ (không tự cắt nhau)
- ST_Area          : diện tích hợp lý (không quá nhỏ do bấm nhầm, không quá lớn)
- ST_Intersects    : không chồng lên khu khác đang hiển thị
- ST_DWithin       : nằm gần mạng lối đi bộ (để còn chỉ đường tới được bằng pgRouting)
Điểm tâm (chỗ đặt biểu tượng) = ST_PointOnSurface: luôn nằm TRONG ranh giới, kể cả khu hình chữ L.
Xoá = ẩn (is_active = false) để giữ dữ liệu lịch sử và thống kê lượt ghé.
"""
import io
import json
import re
import psycopg2
import streamlit as st
from auth import require_admin
from db_services import database_cursor, get_all_exhibits, query_nearby, zones_v2
import moderation

MIN_AREA_M2, MAX_AREA_M2 = 20, 200_000
MAX_WALKWAY_GAP_M = 40
MAX_IMAGE_SIDE = 1280


class ZoneError(ValueError):
    """Dữ liệu phân khu không hợp lệ. .code: mã lỗi để giao diện hiển thị theo ngôn ngữ."""
    def __init__(self, code, detail=''):
        self.code, self.detail = code, detail
        super().__init__(code if not detail else f'{code}: {detail}')


def _clear_caches():
    get_all_exhibits.clear()
    query_nearby.clear()
    zone_images.clear()
    zones_v2.clear()
    try:
        from content import translations
        translations.clear()
    except Exception:
        pass


def _require_schema():
    if not zones_v2():
        raise ZoneError('no_db')


def _valid_color(color):
    if not re.fullmatch(r'#[0-9a-fA-F]{6}', color or ''):
        raise ZoneError('bad_color')
    return color.lower()


def _polygon_geojson(drawing):
    """Nhận GeoJSON (Feature hoặc Geometry) từ công cụ vẽ, chỉ chấp nhận Polygon."""
    if not drawing:
        raise ZoneError('no_shape')
    geom = drawing.get('geometry', drawing) if isinstance(drawing, dict) else None
    if not geom or geom.get('type') != 'Polygon' or not geom.get('coordinates'):
        raise ZoneError('not_polygon')
    ring = geom['coordinates'][0]
    if len(ring) < 4:
        raise ZoneError('too_few_points')
    return json.dumps({'type': 'Polygon', 'coordinates': geom['coordinates']})


def _poly_expr(cur):
    """Cột geom_poly có thể là Polygon hoặc MultiPolygon tuỳ database -> ép đúng kiểu khi ghi."""
    cur.execute("""SELECT type FROM geometry_columns WHERE f_table_name = 'exhibits' AND f_geometry_column = 'geom_poly'""")
    row = cur.fetchone()
    shape = (row['type'] if row else 'POLYGON').upper()
    base = 'ST_SetSRID(ST_GeomFromGeoJSON(%(poly)s), 4326)'
    return f'ST_Multi({base})' if shape == 'MULTIPOLYGON' else base


def check_geometry(drawing, exclude_id=None):
    """Kiểm tra ranh giới vẽ trên bản đồ. Trả về (geojson, kết quả đo) hoặc ném ZoneError."""
    poly = _polygon_geojson(drawing)
    with database_cursor() as cur:
        cur.execute("""
            WITH g AS (SELECT ST_SetSRID(ST_GeomFromGeoJSON(%(poly)s), 4326) AS p)
            SELECT ST_IsValid(g.p) AS valid,
                   ST_IsValidReason(g.p) AS reason,
                   ST_Area(g.p::geography) AS area_m2,
                   (SELECT string_agg(e.name, ', ' ORDER BY e.id) FROM exhibits e
                     WHERE e.is_active AND e.id IS DISTINCT FROM %(ex)s AND e.geom_poly IS NOT NULL
                       AND ST_Intersects(e.geom_poly, g.p)
                       AND ST_Area(ST_Intersection(e.geom_poly, g.p)::geography) > 1) AS overlaps,
                   (SELECT MIN(ST_Distance(w.geom::geography, g.p::geography)) FROM walkways w
                     WHERE ST_DWithin(w.geom::geography, g.p::geography, 500)) AS walkway_gap_m
            FROM g""", {'poly': poly, 'ex': exclude_id})
        r = cur.fetchone()
    if not r['valid']:
        raise ZoneError('invalid', r['reason'])
    if r['area_m2'] < MIN_AREA_M2:
        raise ZoneError('too_small', f"{r['area_m2']:.0f}")
    if r['area_m2'] > MAX_AREA_M2:
        raise ZoneError('too_big', f"{r['area_m2']:.0f}")
    if r['overlaps']:
        raise ZoneError('overlap', r['overlaps'])
    if r['walkway_gap_m'] is None or r['walkway_gap_m'] > MAX_WALKWAY_GAP_M:
        raise ZoneError('far_from_paths', '' if r['walkway_gap_m'] is None else f"{r['walkway_gap_m']:.0f}")
    return poly, {'area_m2': round(r['area_m2']), 'walkway_gap_m': round(r['walkway_gap_m'])}


def check_name(name, exclude_id=None):
    """Báo lỗi nếu tên trống hoặc trùng với một khu khác đang hiển thị (không phân biệt hoa thường)."""
    require_admin()
    _require_schema()
    name = (name or '').strip()
    if not name:
        raise ZoneError('empty')
    with database_cursor() as cur:
        cur.execute('SELECT 1 FROM exhibits WHERE is_active AND lower(name) = lower(%s) AND id IS DISTINCT FROM %s',
                    (name, exclude_id))
        if cur.fetchone():
            raise ZoneError('duplicate_name', name)


def create_zone(name, description, color, drawing):
    """Thêm khu mới. Trả về id. Nội dung đa ngôn ngữ + giọng đọc do content.save_with_auto_translation tạo sau."""
    require_admin()
    _require_schema()
    name, description = (name or '').strip(), (description or '').strip()
    if not name or not description:
        raise ZoneError('empty')
    moderation.check(name, description)
    color = _valid_color(color)
    poly, _ = check_geometry(drawing)
    with database_cursor() as cur:
        cur.execute('SELECT 1 FROM exhibits WHERE is_active AND lower(name) = lower(%s)', (name,))
        if cur.fetchone():
            raise ZoneError('duplicate_name', name)
        poly_sql = _poly_expr(cur)
        cur.execute('LOCK TABLE exhibits IN SHARE ROW EXCLUSIVE MODE')   # cấp id an toàn khi nhiều admin cùng thêm
        cur.execute(f"""
            INSERT INTO exhibits (id, name, description, color, is_active, geom_poly, geom)
            SELECT COALESCE(MAX(id), 0) + 1, %(name)s, %(desc)s, %(color)s, true,
                   {poly_sql}, ST_PointOnSurface(ST_SetSRID(ST_GeomFromGeoJSON(%(poly)s), 4326))
            FROM exhibits
            RETURNING id""", {'name': name, 'desc': description, 'color': color, 'poly': poly})
        new_id = cur.fetchone()['id']
    _clear_caches()
    return new_id


def update_zone(exhibit_id, name=None, description=None, color=None, drawing=None):
    """Sửa thông tin gốc của khu (tên, thuyết minh tiếng Việt, màu, ranh giới)."""
    require_admin()
    _require_schema()
    sets, params = [], {'id': exhibit_id}
    if name is not None or description is not None:
        name, description = (name or '').strip(), (description or '').strip()
        if not name or not description:
            raise ZoneError('empty')
        moderation.check(name, description)
        with database_cursor() as cur:
            cur.execute('SELECT 1 FROM exhibits WHERE is_active AND lower(name) = lower(%s) AND id <> %s', (name, exhibit_id))
            if cur.fetchone():
                raise ZoneError('duplicate_name', name)
        sets += ['name = %(name)s', 'description = %(desc)s']
        params.update(name=name, desc=description)
    if color is not None:
        sets.append('color = %(color)s')
        params['color'] = _valid_color(color)
    poly_sql = None
    if drawing is not None:
        params['poly'], _ = check_geometry(drawing, exclude_id=exhibit_id)
    if not sets and drawing is None:
        return
    with database_cursor() as cur:
        if drawing is not None:
            poly_sql = _poly_expr(cur)
            sets += [f'geom_poly = {poly_sql}', 'geom = ST_PointOnSurface(ST_SetSRID(ST_GeomFromGeoJSON(%(poly)s), 4326))']
        cur.execute(f"UPDATE exhibits SET {', '.join(sets)} WHERE id = %(id)s", params)
    _clear_caches()


def delete_zone(exhibit_id):
    """Xoá khu khỏi giao diện khách (ẩn). Lịch sử lượt ghé và nội dung vẫn được giữ trong database."""
    require_admin()
    _require_schema()
    with database_cursor() as cur:
        cur.execute('UPDATE exhibits SET is_active = false WHERE id = %s', (exhibit_id,))
    _clear_caches()


# ---------- Ảnh ----------

def _prepare_image(raw):
    """Thu nhỏ ảnh (cạnh dài <= 1280 px) và lưu JPEG để trang tải nhanh."""
    from PIL import Image, ImageOps
    try:
        im = ImageOps.exif_transpose(Image.open(io.BytesIO(raw)))
    except Exception as e:
        raise ZoneError('bad_image') from e
    im = im.convert('RGB')
    im.thumbnail((MAX_IMAGE_SIDE, MAX_IMAGE_SIDE))
    out = io.BytesIO()
    im.save(out, format='JPEG', quality=82, optimize=True, progressive=True)
    return out.getvalue()


def add_images(exhibit_id, raw_files):
    require_admin()
    _require_schema()
    prepared = [_prepare_image(raw) for raw in raw_files]
    with database_cursor() as cur:
        for data in prepared:
            cur.execute('INSERT INTO exhibit_images (exhibit_id, data) VALUES (%s, %s)', (exhibit_id, psycopg2.Binary(data)))
    zone_images.clear()
    return len(prepared)


def delete_image(image_id):
    require_admin()
    with database_cursor() as cur:
        cur.execute('DELETE FROM exhibit_images WHERE id = %s', (image_id,))
    zone_images.clear()


@st.cache_data(ttl=600, max_entries=64, show_spinner=False)
def zone_images(exhibit_id):
    """Ảnh admin đã tải lên cho một khu: [(id, bytes)]. Database cũ (chưa có bảng) -> []."""
    if not zones_v2():
        return []
    with database_cursor() as cur:
        cur.execute('SELECT id, data FROM exhibit_images WHERE exhibit_id = %s ORDER BY id', (exhibit_id,))
        return [(row['id'], bytes(row['data'])) for row in cur.fetchall()]
