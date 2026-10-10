"""Kiểm duyệt từ ngữ: chặn tục tĩu (kể cả kiểu lách luật) nhưng không chặn nhầm câu bình thường."""
import os
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import content
import moderation

needs_db = pytest.mark.skipif(os.getenv('TCV_TEST_DB') != '1', reason='Đặt TCV_TEST_DB=1 để chạy với database thử nghiệm')

BAD = ['Đồ chó đẻ', 'đ.m thằng này', 'D M', 'vcl luôn', 'f*ck this', 'F**K', 'sh*t', 'b1tch', 'Fuuuuck', 'sh1t',
       'what the FUCKING hell', 'motherfucker', 'dit me may', 'con đĩ', '他妈的', '傻 逼', 'đéo biết', 'vãi lồn', 'ĐỊT', 'bullshit']
GOOD = ['Nơi nuôi dưỡng và bảo tồn các loài động vật săn mồi dũng mãnh như sư tử, hổ trắng Bengal, hổ Đông Dương và báo hoa mai.',
        'Khu vui chơi có đu quay cho trẻ em', 'Buổi sáng voi ăn mía', 'Mua lon nước ở căng tin', 'Hãy đeo khẩu trang',
        'du lịch Sài Gòn', 'Chó sói và cáo', 'deo khau trang', 'buoi sang', 'cac loai chim', 'Dickens wrote books',
        'Assessment of the habitat', 'mother bear', 'shiitake mushrooms', 'Rated 5* by visitors', 'Scunthorpe',
        '蟒蛇和鳄鱼', '大象馆', 'Khu vực điểm tâm', 'dm2 diện tích', 'Đi dạo', 'cứu hộ động vật']


@pytest.mark.parametrize('text', BAD)
def test_blocks_profanity(text):
    assert moderation.find_profanity(text), text


@pytest.mark.parametrize('text', GOOD)
def test_allows_normal_text(text):
    assert moderation.find_profanity(text) == [], text


def test_mask():
    assert moderation.mask('đéo') == 'đ**'


def test_save_rejects_before_any_work(monkeypatch):
    monkeypatch.setattr(content, 'require_admin', lambda: None)
    calls = []
    monkeypatch.setattr(content, 'synthesize', lambda t, l: calls.append(l) or b'x')
    with pytest.raises(moderation.ProfanityError):
        content.save_translation(1, 'vi', 'Khu Thú Ăn Thịt', 'Đây là khu đ.m')
    with pytest.raises(moderation.ProfanityError):
        content.save_translation(1, 'en', 'Fucking zone', 'Lions')       # tên phân khu cũng bị kiểm tra
    assert calls == []                                                    # không tạo giọng đọc, không ghi database


@needs_db
def test_admin_ui_shows_profanity_error(monkeypatch):
    from streamlit.testing.v1 import AppTest
    monkeypatch.setattr(content, 'synthesize', lambda t, l: b'x')
    app = AppTest.from_file(str(Path(__file__).resolve().parents[1] / 'app.py'), default_timeout=60).run()
    inp = lambda label: next(t for t in app.sidebar.text_input if t.label == label)
    inp('Tài khoản').input('admin'); inp('Mật khẩu').input('123456')
    next(b for b in app.sidebar.button if 'Đăng nhập' in b.label).click().run()
    app.text_area[0].input('Khu này vcl luôn')
    next(b for b in app.button if b.label == 'Lưu thay đổi').click().run()
    assert not app.exception
    assert any('không phù hợp' in e.value and 'v**' in e.value for e in app.error)
