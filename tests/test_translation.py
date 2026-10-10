"""Kiểm thử tự dịch: bảng thuật ngữ được giữ đúng, dịch ngược + điểm khớp phát hiện dịch lệch nghĩa.
Máy dịch được giả lập (không gọi Internet)."""
import os
import re
import sys
from pathlib import Path
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import content
import translator

needs_db = pytest.mark.skipif(os.getenv('TCV_TEST_DB') != '1', reason='Đặt TCV_TEST_DB=1 để chạy với database thử nghiệm')
FAKE_MP3 = b'ID3fake'

# Máy dịch giả: dịch từng cụm theo từ điển nhỏ, giữ nguyên mã giữ chỗ (giống Google thật)
PHRASES = {
    ('vi', 'en'): {'Nơi nuôi dưỡng và bảo tồn các loài động vật săn mồi dũng mãnh như': 'A place that raises and conserves fierce predators such as',
                   'và': 'and'},
    ('en', 'vi'): {'A place that raises and conserves fierce predators such as': 'Nơi nuôi dưỡng và bảo tồn các loài động vật săn mồi dũng mãnh như',
                   'and': 'và'},
    ('vi', 'zh'): {'Nơi nuôi dưỡng và bảo tồn các loài động vật săn mồi dũng mãnh như': '这里饲养和保护凶猛的猛兽，例如', 'và': '和'},
    ('zh', 'vi'): {'这里饲养和保护凶猛的猛兽，例如': 'Nơi nuôi dưỡng và bảo tồn các loài động vật săn mồi dũng mãnh như', '和': 'và'},
}


def fake_engine(text, source, target):
    for a, b in sorted(PHRASES[(source, target)].items(), key=lambda kv: -len(kv[0])):
        text = re.sub(r'(?<!\w)' + re.escape(a) + r'(?!\w)', b, text)
    return text


@pytest.fixture
def engine(monkeypatch):
    monkeypatch.setattr(translator, '_engine', fake_engine)
    monkeypatch.setattr(translator, 'glossary', lambda: translator.DEFAULT_GLOSSARY)


SOURCE = 'Nơi nuôi dưỡng và bảo tồn các loài động vật săn mồi dũng mãnh như sư tử, hổ trắng Bengal, hổ Đông Dương và báo hoa mai.'


def test_glossary_terms_are_fixed(engine):
    en, missing = translator.translate(SOURCE, 'vi', 'en')
    assert not missing
    for term in ('lions', 'white Bengal tigers', 'Indochinese tigers', 'leopards'):
        assert term in en
    assert 'ZQX' not in en
    zh, _ = translator.translate(SOURCE, 'vi', 'zh')
    for term in ('狮子', '孟加拉白虎', '印度支那虎', '花豹'):
        assert term in zh
    assert '豹.' not in zh.replace('花豹', '')          # không ra "báo" chung chung


def test_proper_names(engine):
    en, _ = translator.translate('Thảo Cầm Viên Sài Gòn', 'vi', 'en')
    zh, _ = translator.translate('Thảo Cầm Viên', 'vi', 'zh')
    assert en == 'Saigon Zoo and Botanical Gardens (Thảo Cầm Viên)'
    assert zh == '西贡动植物园（Thảo Cầm Viên）'
    name, _ = translator.translate('Khu Bò Sát', 'vi', 'zh')
    assert name == '爬行动物区'


def test_token_mangled_by_engine_still_restored(engine, monkeypatch):
    monkeypatch.setattr(translator, '_engine', lambda t, s, d: t.replace('ZQX0QZ', 'zqx 0 qz'))
    out, missing = translator.translate('sư tử', 'vi', 'en')
    assert out == 'lions' and not missing


def test_back_translation_scores_good_when_meaning_kept(engine):
    res = translator.translate_with_review(SOURCE, 'en')
    assert res['verdict'] == 'good', res
    assert 'sư tử' in res['back'] and 'hổ Đông Dương' in res['back']


def test_drifting_translation_is_flagged(engine, monkeypatch):
    # Máy dịch "lan man": thêm ý không có trong câu gốc và bỏ mất thuật ngữ
    def rambling(text, source, target):
        if source == 'vi':
            return 'Welcome to our beautiful park where you can buy tickets and enjoy food.'
        return 'Chào mừng đến công viên xinh đẹp nơi bạn có thể mua vé và thưởng thức đồ ăn.'
    monkeypatch.setattr(translator, '_engine', rambling)
    res = translator.translate_with_review(SOURCE, 'en')
    assert res['verdict'] == 'bad'
    assert set(res['missing_terms']) >= {'sư tử', 'báo hoa mai'}


def test_similarity_bounds():
    assert translator.similarity('con voi ở bờ sông', 'con voi ở bờ sông') == 1.0
    assert translator.similarity('con voi ở bờ sông', 'mua vé xem phim') < translator.REVIEW


@needs_db
def test_save_with_auto_translation_stores_review(engine, monkeypatch):
    monkeypatch.setattr(content, 'require_admin', lambda: None)
    monkeypatch.setattr(content, 'synthesize', lambda t, l: FAKE_MP3)
    results = content.save_with_auto_translation(1, 'Khu Thú Ăn Thịt', SOURCE)
    assert set(results) == {'en', 'zh'} and all('error' not in r for r in results.values())
    content.translations.clear()
    en = content.translations('en')[1]
    zh = content.translations('zh')[1]
    assert en['name'] == 'Carnivore Zone' and 'Indochinese tigers' in en['description']
    assert zh['name'] == '食肉动物区' and '印度支那虎' in zh['description']
    assert en['machine_translated'] and en['quality'] >= translator.GOOD and en['back_translation']
    assert en['has_audio'] and zh['has_audio']


@needs_db
def test_translation_failure_keeps_vietnamese_and_old_translation(engine, monkeypatch):
    monkeypatch.setattr(content, 'require_admin', lambda: None)
    monkeypatch.setattr(content, 'synthesize', lambda t, l: FAKE_MP3)
    content.save_with_auto_translation(2, 'Khu Chuồng Voi', 'voi và hươu cao cổ')
    def offline(*a): raise translator.TranslationError('offline')
    monkeypatch.setattr(translator, '_engine', offline)
    results = content.save_with_auto_translation(2, 'Khu Chuồng Voi', 'voi ở gần bờ sông')
    assert all('error' in r for r in results.values())
    content.translations.clear()
    assert content.translations('vi')[2]['description'] == 'voi ở gần bờ sông'
    assert 'giraffes' in content.translations('en')[2]['description']   # bản dịch cũ còn nguyên


@needs_db
def test_glossary_saved_in_database(monkeypatch):
    import auth
    monkeypatch.setattr(translator, 'require_admin', lambda: None)
    before = translator.glossary()
    assert any(t['vi'] == 'báo hoa mai' for t in before)
    rows = before + [{'vi': 'chim công', 'en': 'peacocks', 'zh': '孔雀'}, {'vi': '', 'en': '', 'zh': ''}]
    assert translator.save_glossary(rows) == len(before) + 1
    assert any(t['vi'] == 'chim công' for t in translator.glossary())
    translator.save_glossary(before)
