"""Kiểm thử 52 phân khu theo bản đồ chính thức (neon_52_phan_khu.sql) + cọc đỏ đánh số."""
import os
import subprocess
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import ui

needs_db = pytest.mark.skipif(os.getenv('TCV_TEST_DB') != '1', reason='Đặt TCV_TEST_DB=1 để chạy với database thử nghiệm')
SQL = Path(__file__).resolve().parents[1] / 'neon_52_phan_khu.sql'


def test_pin_icon_and_label():
    icon = ui.pin_icon(36)
    assert '>36<' in icon.options['html'] and ui.PIN_RED in icon.options['html']
    assert '></div>' in ui.pin_icon(None).options['html']          # khu chưa có số: chấm tròn, không có chữ
    assert ui.zone_label({'map_no': 12, 'name': 'Voọc bạc, Nhím'}) == '12 · Voọc bạc, Nhím'
    assert ui.zone_label({'map_no': None, 'name': 'Khu mới'}) == 'Khu mới'


def test_sql_file_has_52_zones_in_three_languages():
    text = SQL.read_text(encoding='utf-8')
    assert text.count('INSERT INTO exhibits ') == 52
    assert text.count('INSERT INTO exhibit_translations ') == 52 * 3
    assert 'BEGIN;' in text and 'COMMIT;' in text


@needs_db
def test_load_52_zones_on_database_copy():
    env = dict(os.environ, PGPASSWORD=os.getenv('POSTGRES_PASSWORD', ''))
    run = lambda *a: subprocess.run(['psql', '-q', '-v', 'ON_ERROR_STOP=1', '-h', 'localhost', '-U', 'postgres', *a],
                                    env=env, check=True, capture_output=True, text=True)
    run('-c', 'DROP DATABASE IF EXISTS tcv_map52_copy')
    run('-c', 'CREATE DATABASE tcv_map52_copy')
    dump = subprocess.run(['pg_dump', '-h', 'localhost', '-U', 'postgres', os.getenv('POSTGRES_DBNAME', 'tcv')],
                          env=env, check=True, capture_output=True, text=True).stdout
    subprocess.run(['psql', '-q', '-h', 'localhost', '-U', 'postgres', '-d', 'tcv_map52_copy'], input=dump,
                   env=env, check=True, capture_output=True, text=True)
    try:
        run('-d', 'tcv_map52_copy', '-f', str(SQL))
        out = run('-d', 'tcv_map52_copy', '-f', str(SQL)).stdout       # chạy lại lần 2 vẫn an toàn
        row = [c.strip() for c in out.strip().splitlines()[-2].split('|')]
        assert row[:4] == ['52', '156', '14', '0']        # 52 khu, 156 bản dịch, 14 cọc phụ, 0 khu cũ
        assert int(row[4]) > 100                          # mạng lối đi theo đường vẽ trên sơ đồ
        ids = run('-d', 'tcv_map52_copy', '-At', '-c', 'SELECT COUNT(*) FROM exhibits WHERE id <> map_no').stdout.strip()
        assert ids == '0'                                  # id phân khu = đúng số trên sơ đồ
        check = run('-d', 'tcv_map52_copy', '-At', '-c', '''
            SELECT COUNT(*), COUNT(DISTINCT map_no), MIN(map_no), MAX(map_no),
                   (SELECT COUNT(*) FROM exhibits a JOIN exhibits b ON a.id < b.id AND a.is_active AND b.is_active
                     AND ST_Area(ST_Intersection(a.geom_poly, b.geom_poly)::geography) > 1),
                   (SELECT COUNT(*) FROM exhibits WHERE is_active AND map_no IS NULL),
                   MAX((SELECT MIN(ST_Distance(e.geom::geography, w.geom::geography)) FROM walkways w)),
                   BOOL_AND(ST_Contains(geom_poly, geom))
            FROM exhibits e WHERE is_active''').stdout.strip().split('|')
        total, distinct, lo, hi, overlaps, unnumbered, far, centred = check
        assert (int(total), int(distinct), int(lo), int(hi)) == (52, 52, 1, 52)
        assert int(overlaps) == 0 and int(unnumbered) == 0 and centred == 't'
        assert float(far) < 60          # khu nào cũng gần lối đi bộ -> tìm đường được
        # mạng lối đi liền một mảnh, từ cổng chính đi tới được mọi khu
        parts = run('-d', 'tcv_map52_copy', '-At', '-c', """SELECT COUNT(DISTINCT component) FROM pgr_connectedComponents(
            'SELECT id, source, target, cost, reverse_cost FROM walkways')""").stdout.strip()
        assert parts == '1'
    finally:
        run('-c', 'DROP DATABASE IF EXISTS tcv_map52_copy')


def test_art_map_round_trip():
    """Pixel sơ đồ -> toạ độ thật -> pixel sơ đồ phải trùng (cọc hiện đúng chỗ số in)."""
    import artmap
    if not artmap.available():
        pytest.skip('thiếu ảnh sơ đồ')
    pts = [(300.0, 400.0), (900.0, 700.0), (1400.0, 1100.0)]
    real = [artmap.to_latlng(x, y) for x, y in pts]
    back = artmap.to_art_many(real)
    assert all(abs(a[0] - b[0]) < 0.5 and abs(a[1] - b[1]) < 0.5 for a, b in zip(pts, back))
    # 50 m thật trên sơ đồ khoảng 80-200 px (sơ đồ co giãn theo vùng)
    assert 60 < artmap.metres_to_px(*real[1], 50) < 250
    assert artmap.leaflet(10, 20) == [-20, 10] and artmap.from_leaflet(-20, 10) == (10, 20)
