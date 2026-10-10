"""Kiểm thử quản lý phân khu: thêm / sửa / xoá, kiểm tra không gian PostGIS, ảnh.
Chạy trên database thử nghiệm (TCV_TEST_DB=1)."""
import io
import os
import sys
import uuid
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import zones
import db_services as db
import moderation

needs_db = pytest.mark.skipif(os.getenv('TCV_TEST_DB') != '1', reason='Đặt TCV_TEST_DB=1 để chạy với database thử nghiệm')


def square(lat, lng, half=0.00012):
    """Hình vuông ~26 m x 26 m quanh (lat, lng), dạng GeoJSON Feature như công cụ vẽ trả về."""
    ring = [[lng - half, lat - half], [lng + half, lat - half], [lng + half, lat + half], [lng - half, lat + half], [lng - half, lat - half]]
    return {'type': 'Feature', 'geometry': {'type': 'Polygon', 'coordinates': [ring]}}


@pytest.fixture
def admin(monkeypatch):
    monkeypatch.setattr(zones, 'require_admin', lambda: None)


@pytest.fixture
def free_spot():
    """Một điểm nằm trên lối đi bộ, cách xa mọi khu đang có (để vẽ khu mới)."""
    with db.database_cursor() as cur:
        cur.execute("""SELECT ST_Y(p) AS lat, ST_X(p) AS lng FROM (
                         SELECT ST_StartPoint(w.geom) AS p FROM walkways w) s
                       WHERE NOT EXISTS (SELECT 1 FROM exhibits e WHERE e.is_active
                             AND ST_DWithin(COALESCE(e.geom_poly, e.geom)::geography, s.p::geography, 60))
                       ORDER BY ST_X(p), ST_Y(p) LIMIT 1""")
        return cur.fetchone()


def test_guest_cannot_create():
    with pytest.raises(PermissionError):
        zones.create_zone('Khu mới', 'Thuyết minh', '#123456', square(10.788, 106.705))


@pytest.mark.parametrize('drawing, code', [
    (None, 'no_shape'),
    ({'type': 'Feature', 'geometry': {'type': 'Point', 'coordinates': [106.7, 10.78]}}, 'not_polygon'),
    ({'type': 'Polygon', 'coordinates': [[[106.7, 10.78], [106.7001, 10.78], [106.7, 10.78]]]}, 'too_few_points'),
])
def test_shape_must_be_a_polygon(drawing, code):
    with pytest.raises(zones.ZoneError) as e:
        zones._polygon_geojson(drawing)
    assert e.value.code == code


@needs_db
def test_spatial_checks(admin, free_spot):
    lat, lng = free_spot['lat'], free_spot['lng']
    bowtie = {'type': 'Polygon', 'coordinates': [[[lng, lat], [lng + .0003, lat + .0003], [lng + .0003, lat], [lng, lat + .0003], [lng, lat]]]}
    for drawing, code in [(bowtie, 'invalid'),                                   # ST_IsValid: cạnh tự cắt nhau
                          (square(lat, lng, half=0.00001), 'too_small'),         # ST_Area < 20 m²
                          (square(lat + 0.03, lng + 0.03), 'far_from_paths'),    # cách lối đi > 40 m
                          (square(lat, lng, half=0.003), 'too_big')]:            # ST_Area quá lớn
        with pytest.raises(zones.ZoneError) as e:
            zones.check_geometry(drawing)
        assert e.value.code == code, (code, e.value)
    poly, info = zones.check_geometry(square(lat, lng))
    assert 400 < info['area_m2'] < 1000 and info['walkway_gap_m'] <= zones.MAX_WALKWAY_GAP_M


@needs_db
def test_create_update_delete_zone(admin, free_spot):
    lat, lng = free_spot['lat'], free_spot['lng']
    name = 'Khu Chim Cảnh ' + uuid.uuid4().hex[:4]
    zid = zones.create_zone(name, 'Nơi có nhiều loài chim quý.', '#AA3355', square(lat, lng))
    found = next(x for x in db.get_all_exhibits() if x['id'] == zid)
    assert found['name'] == name and found['color'] == '#aa3355'
    with db.database_cursor() as cur:   # điểm tâm nằm trong ranh giới (ST_PointOnSurface)
        cur.execute('SELECT ST_Within(geom, geom_poly) AS inside FROM exhibits WHERE id = %s', (zid,))
        assert cur.fetchone()['inside']
    # Trùng tên / chồng ranh giới
    with pytest.raises(zones.ZoneError) as e:
        zones.create_zone(name.upper(), 'x', '#000000', square(lat + .001, lng + .001))
    assert e.value.code in ('duplicate_name', 'far_from_paths')
    with pytest.raises(zones.ZoneError) as e:
        zones.create_zone('Khu khác ' + uuid.uuid4().hex[:4], 'x', '#000000', square(lat + 0.00005, lng + 0.00005))
    assert e.value.code == 'overlap' and name in e.value.detail
    # Sửa: đổi tên, màu, vẽ lại ranh giới (được phép đè lên chính nó)
    zones.update_zone(zid, name=name + ' mới', description='Mô tả mới.', color='#112233', drawing=square(lat, lng, half=0.00014))
    found = next(x for x in db.get_all_exhibits() if x['id'] == zid)
    assert found['name'] == name + ' mới' and found['color'] == '#112233'
    # Khách đứng giữa khu -> được phát hiện; xoá xong -> khách không thấy nữa
    assert any(r['id'] == zid for r in db.query_nearby(lat, lng, 50))
    zones.delete_zone(zid)
    assert all(x['id'] != zid for x in db.get_all_exhibits())
    db.query_nearby.clear()
    assert all(r['id'] != zid for r in db.query_nearby(lat, lng, 50))
    with db.database_cursor() as cur:   # dữ liệu vẫn còn (ẩn), không mất lịch sử
        cur.execute('SELECT is_active FROM exhibits WHERE id = %s', (zid,))
        assert cur.fetchone()['is_active'] is False


@needs_db
def test_profanity_in_zone_name(admin, free_spot):
    with pytest.raises(moderation.ProfanityError):
        zones.create_zone('Khu vcl', 'x', '#000000', square(free_spot['lat'], free_spot['lng']))


@needs_db
def test_images_are_resized_and_stored(admin):
    from PIL import Image
    zid = db.get_all_exhibits()[0]['id']
    big = io.BytesIO()
    Image.new('RGB', (3000, 2000), (40, 120, 70)).save(big, format='PNG')
    assert zones.add_images(zid, [big.getvalue()]) == 1
    img_id, data = zones.zone_images(zid)[-1]
    im = Image.open(io.BytesIO(data))
    assert im.format == 'JPEG' and max(im.size) == zones.MAX_IMAGE_SIDE
    zones.delete_image(img_id)
    assert all(i != img_id for i, _ in zones.zone_images(zid))
    with pytest.raises(zones.ZoneError):
        zones.add_images(zid, [b'not an image'])


# ---------- Vùng nghe thuyết minh hình tròn (tâm + bán kính) ----------

def test_radius_limits():
    for bad in (0, 5, 61, 500):
        with pytest.raises(zones.ZoneError) as e:
            zones.circle(10.78, 106.70, bad)
        assert e.value.code == 'bad_radius'


@needs_db
def test_create_zone_at_point(admin, free_spot):
    import math
    lat, lng = free_spot['lat'], free_spot['lng']
    r = zones.suggest_radius(lat, lng)
    assert zones.MIN_RADIUS_M <= r <= zones.MAX_SUGGESTED_RADIUS_M
    zid = zones.create_zone_at('Khu Hồng Hạc ' + uuid.uuid4().hex[:4], 'Đàn hồng hạc.', '#E91E63', lat, lng, r)
    with db.database_cursor() as cur:
        cur.execute('''SELECT ST_Y(geom) AS lat, ST_X(geom) AS lng, ST_Area(geom_poly::geography) AS area,
                              ST_Within(geom, geom_poly) AS inside FROM exhibits WHERE id = %s''', (zid,))
        row = cur.fetchone()
    assert abs(row['lat'] - lat) < 1e-9 and abs(row['lng'] - lng) < 1e-9     # tâm đúng điểm đã chạm
    assert abs(row['area'] - math.pi * r * r) / (math.pi * r * r) < 0.02      # đúng vòng tròn bán kính r
    assert row['inside'] and zones.current_radius(zid) == r
    # Khu kế bên: bán kính gợi ý không làm 2 vùng chồng nhau
    near_lat, near_lng = lat, lng + 0.0006                                    # cách ~65 m
    r2 = zones.suggest_radius(near_lat, near_lng)
    assert r2 + r <= 66
    # Đổi vị trí + bán kính
    zones.move_zone(zid, lat + 0.0001, lng, 15)
    assert zones.current_radius(zid) == 15
    zones.delete_zone(zid)


@needs_db
def test_convert_existing_zones_to_circles():
    """Chạy neon_vung_tron.sql trên bản sao database: mọi khu thành vòng tròn, không vùng nào chồng nhau."""
    import subprocess
    env = dict(os.environ, PGPASSWORD=os.getenv('POSTGRES_PASSWORD', ''))
    run = lambda *a: subprocess.run(['psql', '-q', '-h', 'localhost', '-U', 'postgres', *a], env=env, check=True, capture_output=True, text=True)
    run('-c', 'DROP DATABASE IF EXISTS tcv_circle_copy')
    run('-c', 'CREATE DATABASE tcv_circle_copy')
    dump = subprocess.run(['pg_dump', '-h', 'localhost', '-U', 'postgres', os.getenv('POSTGRES_DBNAME', 'tcv')],
                          env=env, check=True, capture_output=True, text=True).stdout
    subprocess.run(['psql', '-q', '-h', 'localhost', '-U', 'postgres', '-d', 'tcv_circle_copy'], input=dump,
                   env=env, check=True, capture_output=True, text=True)
    sql = Path(__file__).resolve().parents[1] / 'neon_vung_tron.sql'
    out = run('-d', 'tcv_circle_copy', '-f', str(sql)).stdout
    assert 'ban_kinh_m' in out
    check = run('-d', 'tcv_circle_copy', '-At', '-c', '''
        SELECT COUNT(*) FILTER (WHERE geom_poly IS NULL),
               (SELECT COUNT(*) FROM exhibits a JOIN exhibits b ON a.id < b.id AND a.is_active AND b.is_active
                 AND ST_Area(ST_Intersection(a.geom_poly, b.geom_poly)::geography) > 1),
               MIN(sqrt(ST_Area(geom_poly::geography) / pi())), MAX(sqrt(ST_Area(geom_poly::geography) / pi()))
        FROM exhibits WHERE is_active''').stdout.strip().split('|')
    no_poly, overlaps, rmin, rmax = int(check[0]), int(check[1]), float(check[2]), float(check[3])
    assert no_poly == 0 and overlaps == 0 and rmin >= 9.9 and rmax <= 40.1
    run('-c', 'DROP DATABASE IF EXISTS tcv_circle_copy')
