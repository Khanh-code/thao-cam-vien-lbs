import sys
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from threading import BoundedSemaphore, Lock
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import auth
import content
import db_services as db
import tracking


@pytest.fixture(autouse=True)
def no_visitor_tracking(monkeypatch):
    # Các test giao diện cũ chạy không có tài khoản khách tạm (không chạm database)
    monkeypatch.setattr(tracking, 'get_or_create_visitor', lambda *a, **k: None)

def test_password_hash_and_invalid_credentials():
    encoded = auth.password_hash('a-long-test-password')
    assert auth.verify_password('a-long-test-password', encoded)
    assert not auth.verify_password('wrong', encoded)
    assert not auth.verify_password('anything', 'invalid')

def test_guest_cannot_save(monkeypatch):
    monkeypatch.setattr(auth, 'is_admin', lambda: False)
    with pytest.raises(PermissionError):
        content.save_translation(1, 'en', 'Elephants', 'Text', '')

def test_translation_does_not_mutate_shared_data():
    raw = {'id': 1, 'name': 'Voi', 'description': 'Nội dung', 'audio_file': 'voi.mp3'}
    english = content.localize(raw, 'en', {1: {'name': 'Elephants', 'description': 'Text', 'audio_file': 'en/elephants.mp3'}})
    assert english['name'] == 'Elephants'
    assert raw['name'] == 'Voi'
    assert content.localize(raw, 'vi', {})['audio_file'] == 'voi.mp3'
    fallback = content.localize(raw, 'en', {})
    assert not fallback['translated'] and fallback['audio_file'] is None

@pytest.mark.parametrize('path', ['../secret.mp3', '/en/test.mp3', 'en/../test.mp3', 'en\\test.mp3', 'vi/test.mp3', 'en/test.wav'])
def test_audio_paths(path):
    assert not content.valid_audio(path, 'en')

class FakeCursor:
    def __enter__(self): return self
    def __exit__(self, *args): pass

class FakeConnection:
    closed = False
    def __enter__(self): return self
    def __exit__(self, *args): pass
    def cursor(self, **kwargs): return FakeCursor()

class FakePool:
    def __init__(self):
        self.lock = Lock()
        self.active = self.maximum = self.returned = 0
    def getconn(self):
        with self.lock:
            self.active += 1
            self.maximum = max(self.maximum, self.active)
        return FakeConnection()
    def putconn(self, conn, **kwargs):
        with self.lock:
            self.active -= 1
            self.returned += 1

def test_concurrent_pool_and_error_release(monkeypatch):
    pool, slots = FakePool(), BoundedSemaphore(2)
    monkeypatch.setattr(db, 'resources', lambda: (pool, slots))
    def request(index):
        try:
            with db.database_cursor():
                time.sleep(.01)
                if index % 3 == 0:
                    raise ValueError('query failed')
        except ValueError:
            pass
    with ThreadPoolExecutor(max_workers=10) as executor:
        list(executor.map(request, range(30)))
    assert pool.maximum <= 2
    assert pool.returned == 30 and pool.active == 0
    with db.database_cursor():
        pass

def test_pool_acquisition_failure_releases_slot(monkeypatch):
    class BrokenPool(FakePool):
        def getconn(self): raise RuntimeError('offline')
    slots = BoundedSemaphore(1)
    monkeypatch.setattr(db, 'resources', lambda: (BrokenPool(), slots))
    with pytest.raises(RuntimeError):
        with db.database_cursor(): pass
    assert slots.acquire(blocking=False)

def test_guest_ui_languages_and_session_isolation(monkeypatch):
    from streamlit.testing.v1 import AppTest
    import streamlit_folium
    monkeypatch.setattr(db, 'get_all_exhibits', lambda: [
        {'id': 1, 'name': 'Voi', 'description': 'Khu voi', 'audio_file': None,
         'lat': 10.78775, 'lng': 106.7056, 'poly_geojson': None}])
    monkeypatch.setattr(db, 'get_all_walkways', lambda: [])
    monkeypatch.setattr(db, 'query_nearby', lambda *args, **kwargs: [])
    monkeypatch.setattr(content, 'translations', lambda lang: {})
    monkeypatch.setattr(streamlit_folium, 'st_folium', lambda *args, **kwargs: {})
    app_path = str(Path(__file__).resolve().parents[1] / 'app.py')
    vietnamese = AppTest.from_file(app_path).run()
    assert not vietnamese.exception
    assert 'Thảo Cầm Viên' in vietnamese.title[0].value
    english = AppTest.from_file(app_path).run()
    english.sidebar.selectbox[0].select('en').run()
    assert not english.exception
    assert english.title[0].value == 'Saigon Zoo Visitor Guide'
    assert vietnamese.sidebar.selectbox[0].value == 'vi'
    english.session_state['user_lat'] = 10.8
    assert vietnamese.session_state['user_lat'] == 10.78775
    assert len(english.text_area) == 0  # guest cannot access the content editor

def test_original_images_and_narration_remain_available(monkeypatch):
    from streamlit.testing.v1 import AppTest
    import streamlit_folium
    exhibit = {'id': 1, 'name': 'Khu Thú Ăn Thịt', 'description': 'Nội dung gốc',
               'audio_file': 'thu_an_thit.mp3', 'lat': 10.78775,
               'lng': 106.7056, 'poly_geojson': None}
    monkeypatch.setattr(db, 'get_all_exhibits', lambda: [exhibit])
    monkeypatch.setattr(db, 'get_all_walkways', lambda: [])
    monkeypatch.setattr(db, 'query_nearby', lambda *args, **kwargs: [dict(exhibit, distance_meters=0)])
    monkeypatch.setattr(content, 'translations', lambda lang: {})
    monkeypatch.setattr(streamlit_folium, 'st_folium', lambda *args, **kwargs: {})
    app = AppTest.from_file(str(Path(__file__).resolve().parents[1] / 'app.py')).run()
    assert not app.exception
    assert len(app.get('image')) == 1, repr(app)
    assert len(app.get('audio')) == 1
    assert any(button.label == '◀ Trước' for button in app.button)
    app.sidebar.selectbox[0].select('en').run()
    assert not app.exception
    assert len(app.get('image')) == 1 and len(app.get('audio')) == 1
    assert any('Carnivore Zone' in item.value for item in app.success)

