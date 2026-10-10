"""Kiểm thử: đổi mật khẩu admin, tài khoản khách tạm, ưu tiên phân khu chưa ghé, thống kê.

Các test có đánh dấu `needs_db` chạy trên một database PostGIS THỬ NGHIỆM có dữ liệu mẫu,
chỉ bật khi đặt biến môi trường TCV_TEST_DB=1 (tránh ghi dữ liệu rác vào database thật).
"""
import os
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import auth
import tracking

needs_db = pytest.mark.skipif(os.getenv('TCV_TEST_DB') != '1', reason='Đặt TCV_TEST_DB=1 để chạy với database thử nghiệm')


@pytest.fixture
def session(monkeypatch):
    state = {}
    monkeypatch.setattr(auth.st, 'session_state', state)
    return state


# ---------- Không cần database ----------

def test_change_password_requires_admin(session):
    with pytest.raises(PermissionError):
        auth.change_password('123456', 'mat-khau-moi', 'mat-khau-moi')


@pytest.mark.parametrize('new, confirm, code', [
    ('123', '123', 'too_short'),
    ('mat-khau-moi', 'khac-nhau', 'mismatch'),
    ('123456', '123456', 'same'),
])
def test_change_password_validation(session, monkeypatch, new, confirm, code):
    monkeypatch.setattr(auth, 'is_admin', lambda: True)
    session.update(admin_user='admin', admin_source='db')
    monkeypatch.setattr(auth, '_stored_hash', lambda u: (auth.password_hash('123456'), 'db'))
    with pytest.raises(ValueError, match=code):
        auth.change_password('123456', new, confirm)


def test_change_password_wrong_current(session, monkeypatch):
    monkeypatch.setattr(auth, 'is_admin', lambda: True)
    session.update(admin_user='admin', admin_source='db')
    monkeypatch.setattr(auth, '_stored_hash', lambda u: (auth.password_hash('123456'), 'db'))
    with pytest.raises(ValueError, match='wrong_current'):
        auth.change_password('sai-mat-khau', 'mat-khau-moi', 'mat-khau-moi')


def test_invalid_visitor_ids_are_rejected():
    for bad in [None, '', 'abc', "'; DROP TABLE visitors; --", 123]:
        assert tracking._valid_uuid(bad) is None
    assert tracking._valid_uuid('3f2b1c9e-4c1d-4a8e-9a57-0b0e8f7e3c11')


# ---------- Cần database thử nghiệm ----------
# Dữ liệu mẫu: 'Khu Thú Ăn Thịt' (106.7047, 10.7880) và 'Khu Chuồng Voi' (106.7053, 10.7880)
# cách đều điểm EQUAL = (10.7880, 106.7050) khoảng 33 m.
EQUAL = (10.7880, 106.7050)


@needs_db
def test_default_admin_login_and_change_password(session):
    assert auth.login('admin', '123456')
    assert session['admin_default_pw'] is True
    auth.change_password('123456', 'matkhau-moi', 'matkhau-moi')
    assert session['admin_default_pw'] is False
    auth.logout()
    assert not auth.login('admin', '123456')
    assert auth.login('admin', 'matkhau-moi')
    auth.change_password('matkhau-moi', '123456x', '123456x')
    # trả lại mặc định cho các lần test sau
    from db_services import database_cursor
    with database_cursor() as cur:
        cur.execute("UPDATE admin_users SET password_hash=%s WHERE username='admin'", (auth.password_hash('123456'),))


@needs_db
def test_unvisited_zone_is_preferred_when_equidistant():
    vid = tracking.get_or_create_visitor()
    first = tracking.nearby_for_visitor(vid, *EQUAL)
    assert len(first) == 2 and all(r['in_tie_group'] for r in first)
    tracking.mark_visited(vid, first[0]['id'])
    second = tracking.nearby_for_visitor(vid, *EQUAL)
    assert second[0]['id'] == first[1]['id']          # chuyển sang khu chưa ghé
    assert second[1]['visited'] is True


@needs_db
def test_closer_zone_wins_outside_tie_threshold():
    vid = tracking.get_or_create_visitor()
    near_lion = (10.7880, 106.70480)                    # ~11 m tới khu thú, ~55 m tới khu voi
    rows = tracking.nearby_for_visitor(vid, *near_lion, radius=60)
    tracking.mark_visited(vid, rows[0]['id'])
    again = tracking.nearby_for_visitor(vid, *near_lion, radius=60)
    assert again[0]['id'] == rows[0]['id']             # đã ghé nhưng vẫn gần hơn hẳn -> vẫn ưu tiên


@needs_db
def test_visitor_reuse_and_reset_after_period():
    vid = tracking.get_or_create_visitor()
    assert tracking.get_or_create_visitor(vid) == vid  # cùng chu kỳ -> giữ tài khoản
    from db_services import database_cursor
    with database_cursor() as cur:
        cur.execute("UPDATE visitors SET period_start = period_start - 7 WHERE id = %s", (vid,))
    renewed = tracking.get_or_create_visitor(vid)
    assert renewed != vid                              # hết chu kỳ -> tài khoản mới


@needs_db
def test_track_and_daily_stats():
    vid = tracking.get_or_create_visitor()
    for lat, lng in [(10.78775, 106.7056), EQUAL, (10.7880, 106.7048)]:
        tracking.record_position(vid, lat, lng)
    assert len(tracking.visitor_track(vid)) == 3
    assert tracking.track_length_metres(vid) > 50
    day = tracking.today()
    before = {r['id']: r['visitors'] for r in tracking.daily_stats(day)}
    rows = tracking.nearby_for_visitor(vid, *EQUAL)
    tracking.mark_visited(vid, rows[0]['id'])
    tracking.mark_visited(vid, rows[0]['id'])           # ghé lại cùng ngày -> không đếm 2 lần
    after = {r['id']: r['visitors'] for r in tracking.daily_stats(day)}
    assert after[rows[0]['id']] == before[rows[0]['id']] + 1
    assert tracking.summary(day)['active_visitors'] >= 1


@needs_db
def test_app_end_to_end_priority_and_tracking():
    from streamlit.testing.v1 import AppTest
    app = AppTest.from_file(str(Path(__file__).resolve().parents[1] / 'app.py'), default_timeout=60)
    app.session_state['user_lat'], app.session_state['user_lng'] = EQUAL
    app.run()
    assert not app.exception, app.exception
    first = app.success[0].value
    vid = app.session_state['visitor_id']
    assert app.query_params['v'] == [vid] or app.query_params['v'] == vid
    app.run()                                           # rerun tại chỗ -> không nhảy sang khu khác
    assert app.success[0].value == first
    # Đi ra rồi quay lại đúng điểm cách đều -> lần này phải phát khu CHƯA ghé
    app.session_state['user_lat'], app.session_state['user_lng'] = (10.7850, 106.7000)   # chỗ không có phân khu
    app.run()
    app.session_state['user_lat'], app.session_state['user_lng'] = EQUAL
    app.run()
    assert not app.exception
    assert app.success[0].value != first
    assert len(tracking.visitor_track(vid)) == 3
