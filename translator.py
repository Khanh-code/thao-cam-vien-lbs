"""Tự dịch thuyết minh Việt -> Anh / Trung, có KIỂM TRA để người không biết ngoại ngữ vẫn duyệt được.

Cách làm (để dịch sát nghĩa, tránh "lan man"):
1. Bảng thuật ngữ cố định (glossary): tên riêng và tên loài/khu được thay bằng mã giữ chỗ trước khi
   đưa cho máy dịch, dịch xong mới thay lại bằng bản dịch chuẩn -> máy dịch không thể tự chế tên.
2. Dịch câu bằng Google Dịch (thư viện deep-translator, miễn phí).
3. Dịch NGƯỢC bản Anh/Trung về lại tiếng Việt và so với câu gốc -> điểm độ khớp 0..1.
   Admin chỉ cần đọc câu tiếng Việt dịch ngược là biết máy có hiểu sai/thêm/bớt ý hay không.
"""
import json
import re
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path
from psycopg2.errors import UndefinedTable
from auth import require_admin
import moderation
from db_services import database_cursor

TARGETS = ('en', 'zh')
ENGINE_CODE = {'vi': 'vi', 'en': 'en', 'zh': 'zh-CN'}
MYMEMORY_CODE = {'vi': 'vi-VN', 'en': 'en-GB', 'zh': 'zh-CN'}
GOOD, REVIEW = 0.75, 0.5          # >= GOOD: ✅ khớp | >= REVIEW: ⚠️ nên xem lại | thấp hơn: ❌ có thể sai nghĩa
DEFAULT_GLOSSARY = json.loads((Path(__file__).resolve().parent / 'glossary.json').read_text(encoding='utf-8'))


class TranslationError(RuntimeError):
    """Không gọi được dịch vụ dịch (mất mạng, bị chặn...)."""


def _chunks(text, limit=450):
    """Cắt theo câu để không vượt giới hạn độ dài của dịch vụ dự phòng."""
    parts, current = [], ''
    for sentence in re.split(r'(?<=[.!?。！？])\s+', text):
        if current and len(current) + len(sentence) + 1 > limit:
            parts.append(current)
            current = sentence
        else:
            current = f'{current} {sentence}'.strip()
    return parts + ([current] if current else [])


def _google(text, source, target):
    from deep_translator import GoogleTranslator
    return GoogleTranslator(source=ENGINE_CODE[source], target=ENGINE_CODE[target]).translate(text)


def _mymemory(text, source, target):
    from deep_translator import MyMemoryTranslator
    tr = MyMemoryTranslator(source=MYMEMORY_CODE[source], target=MYMEMORY_CODE[target])
    sep = '' if target == 'zh' else ' '
    return sep.join(tr.translate(part) for part in _chunks(text))


def _engine(text, source, target):
    """Gọi máy dịch: Google Dịch trước, lỗi thì tự chuyển sang MyMemory (dự phòng).
    Tách riêng để dễ thay dịch vụ khác / giả lập khi kiểm thử."""
    errors = []
    for name, service in (('Google', _google), ('MyMemory', _mymemory)):
        try:
            out = service(text, source, target)
            if out and out.strip() and 'MYMEMORY WARNING' not in out:
                return out.strip()
            errors.append(f'{name}: kết quả rỗng')
        except Exception as e:
            errors.append(f'{name}: {type(e).__name__}: {str(e)[:150]}')
    raise TranslationError(' | '.join(errors))


def glossary():
    """Bảng thuật ngữ trong database (admin sửa được). Chưa chạy migration 006 -> dùng glossary.json."""
    try:
        with database_cursor() as cur:
            cur.execute('SELECT vi, en, zh FROM glossary ORDER BY vi')
            terms = [dict(row) for row in cur.fetchall()]
    except UndefinedTable:
        terms = [dict(row) for row in DEFAULT_GLOSSARY]
    return [t for t in terms if t.get('vi') and t.get('en') and t.get('zh')]


def _protect(text, terms, source):
    """Thay thuật ngữ bằng mã giữ chỗ ZQX<n>QZ (máy dịch để nguyên). Ưu tiên cụm dài trước."""
    found = []
    for term in sorted(terms, key=lambda t: len(t[source]), reverse=True):
        word = term[source]
        if source == 'zh':
            pattern = re.escape(word)
        else:
            pattern = r'(?<![\w])' + re.escape(word) + r'(?![\w])'
        def sub(m, term=term):
            found.append(term)
            return f' ZQX{len(found) - 1}QZ '
        text = re.sub(pattern, sub, text, flags=re.IGNORECASE)
    return text, found


def _restore(text, found, target):
    missing = []
    for i, term in enumerate(found):
        pattern = re.compile(rf'\s*Z\s*Q\s*X\s*{i}\s*Q\s*Z\s*', re.IGNORECASE)
        if not pattern.search(text):
            missing.append(term['vi'])
            continue
        sep = '' if target == 'zh' else ' '
        text = pattern.sub(lambda m: sep + term[target] + sep, text, count=1)
    text = re.sub(r'\s+([,.;:!?，。；：！？）)])', r'\1', text)
    text = re.sub(r'([（(])\s+', r'\1', text)
    if target == 'zh':
        # Dấu câu tiếng Trung: , . ; : ! ? sát chữ Hán -> ，。；：！？
        cjk = r'[\u3400-\u9fff）]'
        for a, b in ((',', '，'), ('.', '。'), (';', '；'), (':', '：'), ('!', '！'), ('?', '？')):
            text = re.sub(rf'(?<={cjk})\s*{re.escape(a)}\s*', b, text)
    return re.sub(r'[ \t]{2,}', ' ', text).strip(), missing


def translate(text, source, target):
    """Dịch có bảo vệ thuật ngữ. Trả về (bản dịch, danh sách thuật ngữ bị máy dịch làm mất)."""
    terms = glossary()
    protected, found = _protect(text, terms, source)
    if not protected.strip(' ZQX0123456789'):
        raw = protected                     # toàn bộ câu là thuật ngữ -> khỏi gọi máy dịch
    else:
        raw = _engine(protected, source, target)
    return _restore(raw, found, target)


def _words(text):
    text = unicodedata.normalize('NFC', text.lower())
    return re.findall(r'\w+', text)


def similarity(original_vi, back_vi):
    """Độ khớp giữa câu gốc và câu dịch ngược (0..1), so theo chuỗi từ."""
    a, b = _words(original_vi), _words(back_vi)
    if not a or not b:
        return 0.0
    seq = SequenceMatcher(None, a, b).ratio()
    overlap = len(set(a) & set(b)) / len(set(a) | set(b))
    return round(max(seq, overlap), 2)


def verdict(score):
    if score is None:
        return 'none'
    return 'good' if score >= GOOD else 'review' if score >= REVIEW else 'bad'


def translate_with_review(text_vi, target):
    """Dịch Việt -> target rồi dịch ngược để kiểm tra.
    Trả về dict: text (bản dịch), back (dịch ngược về tiếng Việt), score, verdict, missing_terms."""
    translated, missing = translate(text_vi, 'vi', target)
    back, _ = translate(translated, target, 'vi')
    score = similarity(text_vi, back)
    if missing:
        score = min(score, REVIEW - 0.01)   # mất thuật ngữ -> bắt buộc xem lại
    return {'text': translated, 'back': back, 'score': score, 'verdict': verdict(score), 'missing_terms': missing}


def save_glossary(rows):
    """Admin lưu bảng thuật ngữ (thay toàn bộ phần admin quản lý trong database)."""
    require_admin()
    moderation.check(*[str(r.get(k) or '') for r in rows for k in ('vi', 'en', 'zh')])
    clean = [(r['vi'].strip(), r['en'].strip(), r['zh'].strip()) for r in rows
             if (r.get('vi') or '').strip() and (r.get('en') or '').strip() and (r.get('zh') or '').strip()]
    with database_cursor() as cur:
        cur.execute('DELETE FROM glossary')
        for row in clean:
            cur.execute('INSERT INTO glossary(vi, en, zh) VALUES (%s, %s, %s) ON CONFLICT (vi) DO UPDATE SET en=EXCLUDED.en, zh=EXCLUDED.zh', row)
    return len(clean)
