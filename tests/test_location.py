"""Kiểm thử chế độ GPS: trong vườn -> dùng GPS; ở xa -> giữ vị trí mô phỏng; lỗi/chặn quyền -> báo lỗi."""
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import location

ZOO = (10.7877, 106.7056)   # tâm Thảo Cầm Viên (gần đúng)


def reading(lat, lng, acc=8.4):
    return {'coords': {'latitude': lat, 'longitude': lng, 'accuracy': acc}, 'timestamp': 1}


def test_inside_garden_uses_gps():
    r = location.interpret(reading(10.7880, 106.7050), *ZOO)
    assert r['status'] == 'inside' and r['lat'] == 10.7880 and r['accuracy_m'] == 8


def test_far_away_keeps_simulation():
    r = location.interpret(reading(10.7626, 106.6602), *ZOO)   # ~5,6 km (Quận 5)
    assert r['status'] == 'outside' and 5000 < r['distance_m'] < 6500


@pytest.mark.parametrize('raw', [None, {}, '', {'error': {'code': 1, 'message': 'User denied Geolocation'}}, {'coords': {}}])
def test_waiting_or_error(raw):
    assert location.interpret(raw, *ZOO)['status'] in ('waiting', 'error')


def test_denied_message():
    r = location.interpret({'error': {'code': 1, 'message': 'User denied Geolocation'}}, *ZOO)
    assert r == {'status': 'error', 'message': 'User denied Geolocation'}


def test_distance_known_value():
    # 0,001 độ vĩ ~ 111 m
    assert 110 < location.distance_m(10.0, 106.0, 10.001, 106.0) < 112
