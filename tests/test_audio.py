"""Kiểm thử giọng đọc tự động: admin lưu thuyết minh -> tạo MP3 -> lưu DB -> khách nghe đúng bản mới.
gTTS được giả lập (không gọi Internet). Test có `needs_db` chỉ chạy khi TCV_TEST_DB=1 (database thử nghiệm)."""
import os
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import auth
import content

needs_db = pytest.mark.skipif(os.getenv('TCV_TEST_DB') != '1', reason='Đặt TCV_TEST_DB=1 để chạy với database thử nghiệm')
FAKE_MP3 = b'ID3fake-mp3-bytes'


def test_localize_prefers_generated_voice():
    raw = {'id': 1, 'name': 'Khu Thú Ăn Thịt', 'description': 'Gốc', 'audio_file': 'thu_an_thit.mp3'}
    row = {'exhibit_id': 1, 'name': 'Khu Thú', 'description': 'Mới', 'audio_file': None,
           'has_audio': True, 'updated_at': '2026-10-10 21:00'}
    vi = content.localize(raw, 'vi', {1: row})
    assert vi['audio_key'] == (1, 'vi', '2026-10-10 21:00') and vi['audio_file'] is None
    assert vi['description'] == 'Mới'
    # Không có giọng đọc tự tạo -> vẫn dùng file gốc
    old = content.localize(raw, 'vi', {1: dict(row, has_audio=False)})
    assert old['audio_key'] is None and old['audio_file'] == 'thu_an_thit.mp3'


def test_synthesize_wraps_errors(monkeypatch):
    import gtts
    class Broken:
        def __init__(self, **kw): pass
        def write_to_fp(self, fp): raise ConnectionError('offline')
    monkeypatch.setattr(gtts, 'gTTS', Broken)
    with pytest.raises(content.AudioError):
        content.synthesize('xin chào', 'vi')


@pytest.fixture
def admin(monkeypatch):
    # Chỉ bỏ kiểm tra quyền ở hàm lưu, không giả lập admin cho giao diện
    monkeypatch.setattr(content, 'require_admin', lambda: None)


@needs_db
def test_save_generates_and_stores_voice(admin, monkeypatch):
    spoken = []
    monkeypatch.setattr(content, 'synthesize', lambda text, lang: spoken.append((text, lang)) or FAKE_MP3)
    content.save_translation(2, 'vi', 'Khu Chuồng Voi', '  Đây là đàn voi châu Á.  ')
    assert spoken == [('Đây là đàn voi châu Á.', 'vi')]          # đọc đúng nội dung vừa lưu
    item = content.localize({'id': 2, 'name': 'Khu Chuồng Voi', 'description': 'x', 'audio_file': 'chuong_voi.mp3'},
                            'vi', content.translations('vi'))
    assert item['audio_key'] and content.generated_audio(*item['audio_key']) == FAKE_MP3


@needs_db
def test_failed_voice_saves_nothing(admin, monkeypatch):
    monkeypatch.setattr(content, 'synthesize', lambda t, l: FAKE_MP3)
    content.save_translation(3, 'en', 'Reptiles', 'Old text')
    def fail(t, l): raise content.AudioError('offline')
    monkeypatch.setattr(content, 'synthesize', fail)
    with pytest.raises(content.AudioError):
        content.save_translation(3, 'en', 'Reptiles', 'New text')
    content.translations.clear()
    assert content.translations('en')[3]['description'] == 'Old text'  # nội dung cũ + audio cũ vẫn khớp nhau


@needs_db
def test_visitor_hears_generated_voice(admin, monkeypatch):
    from streamlit.testing.v1 import AppTest
    monkeypatch.setattr(content, 'synthesize', lambda t, l: FAKE_MP3)
    content.save_translation(1, 'vi', 'Khu Thú Ăn Thịt', 'Hổ và sư tử đang nghỉ trưa.')
    app = AppTest.from_file(str(Path(__file__).resolve().parents[1] / 'app.py'), default_timeout=60)
    app.session_state['user_lat'], app.session_state['user_lng'] = (10.7880, 106.70475)
    app.run()
    assert not app.exception, app.exception
    assert any('Hổ và sư tử đang nghỉ trưa.' in m.value for m in app.markdown)
    assert len(app.get('audio')) == 1


# ---------- Tiếng Trung ----------

def test_chinese_builtin_translation_and_tts_code(monkeypatch):
    raw = {'id': 1, 'name': 'Khu Thú Ăn Thịt', 'description': 'Gốc', 'audio_file': 'thu_an_thit.mp3'}
    zh = content.localize(raw, 'zh', {})
    assert zh['name'] == '食肉动物区' and zh['translated']
    assert zh['audio_file'] is None            # không phát nhầm audio tiếng Việt
    import gtts
    used = {}
    class Fake:
        def __init__(self, text, lang, slow): used['lang'] = lang
        def write_to_fp(self, fp): fp.write(FAKE_MP3)
    monkeypatch.setattr(gtts, 'gTTS', Fake)
    assert content.synthesize('你好', 'zh') == FAKE_MP3 and used['lang'] == 'zh-CN'


def test_chinese_ui_plays_auto_voice(monkeypatch):
    from streamlit.testing.v1 import AppTest
    import streamlit_folium
    import db_services as db
    import tracking
    exhibit = {'id': 1, 'name': 'Khu Thú Ăn Thịt', 'description': 'Nội dung gốc', 'audio_file': 'thu_an_thit.mp3',
               'lat': 10.78775, 'lng': 106.7056, 'poly_geojson': None}
    monkeypatch.setattr(db, 'get_all_exhibits', lambda: [exhibit])
    monkeypatch.setattr(db, 'get_all_walkways', lambda: [])
    monkeypatch.setattr(db, 'query_nearby', lambda *a, **k: [dict(exhibit, distance_meters=0)])
    monkeypatch.setattr(content, 'translations', lambda lang: {})
    monkeypatch.setattr(tracking, 'get_or_create_visitor', lambda *a, **k: None)
    monkeypatch.setattr(streamlit_folium, 'st_folium', lambda *a, **k: {})
    spoken = []
    monkeypatch.setattr(content, 'synthesize', lambda t, l: spoken.append((t, l)) or FAKE_MP3)
    app = AppTest.from_file(str(Path(__file__).resolve().parents[1] / 'app.py'), default_timeout=30).run()
    app.sidebar.selectbox[0].select('zh').run()
    assert not app.exception, app.exception
    assert app.title[0].value == '西贡动植物园（Thảo Cầm Viên）户外导览系统'
    assert any('食肉动物区' in s.value for s in app.success)
    assert len(app.get('audio')) == 1
    assert ('这里饲养和保护狮子、孟加拉白虎、印度支那虎和花豹等凶猛的猛兽。', 'zh') in spoken


@needs_db
def test_admin_can_save_chinese(admin, monkeypatch):
    monkeypatch.setattr(content, 'synthesize', lambda t, l: FAKE_MP3)
    content.save_translation(3, 'zh', '爬行动物区', '蟒蛇和鳄鱼。')
    content.translations.clear()
    row = content.translations('zh')[3]
    assert row['name'] == '爬行动物区' and row['has_audio']


def test_proper_names_keep_vietnamese_with_diacritics():
    raw = {'id': 4, 'name': 'Khu Bò Sát', 'description': 'x', 'audio_file': None}
    zh = content.with_vietnamese_name(content.localize(raw, 'zh', {}), raw['name'], 'zh')
    en = content.with_vietnamese_name(content.localize(raw, 'en', {}), raw['name'], 'en')
    vi = content.with_vietnamese_name(content.localize(raw, 'vi', {}), raw['name'], 'vi')
    assert zh['name'] == '爬行动物区（Khu Bò Sát）'
    assert en['name'] == 'Reptile Zone (Khu Bò Sát)'
    assert vi['name'] == 'Khu Bò Sát'
    # Không lặp tên gốc nếu bản dịch đã chứa sẵn
    again = content.with_vietnamese_name(zh, raw['name'], 'zh')
    assert again['name'].count('Khu Bò Sát') == 1
