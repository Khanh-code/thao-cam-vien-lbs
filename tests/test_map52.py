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
        assert '52 |         156 |         14' in out
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
    finally:
        run('-c', 'DROP DATABASE IF EXISTS tcv_map52_copy')
