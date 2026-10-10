"""Kiểm duyệt nội dung admin nhập (và bản máy dịch) trước khi lưu: chặn từ ngữ tục tĩu, xúc phạm.

- Kiểm tra cả 3 ngôn ngữ trên mọi đoạn văn (người xấu có thể gõ tiếng Anh vào ô tiếng Việt...).
- Chống lách luật: viết hoa, lặp chữ (fuuuck), số thay chữ (sh1t, f4ck), chèn dấu giữa chữ (đ.m, f*ck, d-m).
- Tránh chặn nhầm: từ nào bỏ dấu sẽ trùng từ bình thường (lon, buoi, deo, du...) thì chỉ chặn khi viết ĐÚNG dấu.
Danh sách từ nằm trong banned_words.json (thêm/bớt được).
"""
import json
import re
import unicodedata
from pathlib import Path

_WORDS = json.loads((Path(__file__).resolve().parent / 'banned_words.json').read_text(encoding='utf-8'))
_LEET = str.maketrans({'0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '@': 'a', '$': 's', '!': 'i'})


class ProfanityError(ValueError):
    """Nội dung có từ ngữ không phù hợp. .words: các từ phát hiện được."""
    def __init__(self, words):
        self.words = words
        super().__init__('profanity: ' + ', '.join(words))


def _strip_accents(text):
    text = text.replace('đ', 'd').replace('Đ', 'D')
    return ''.join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')


def _squeeze(text):
    """fuuuck -> fuck, điiiit -> địt (gộp chữ lặp)."""
    return re.sub(r'(\w)\1+', r'\1', text)


def _variants(text):
    """Các dạng chuẩn hoá của văn bản để so khớp."""
    base = unicodedata.normalize('NFC', text).lower()
    # Bỏ ký tự chèn giữa các chữ đơn lẻ: "đ.m", "d - m", "f*ck" -> "đm", "dm", "fck"
    joined = re.sub(r'(?<=\w)[\s.\-_*+~|/\\]+(?=\w)', lambda m: '' if re.fullmatch(r'[.\-_*+~|/\\]+', m.group().strip() or ' ') else m.group(), base)
    single = re.sub(r'\b(\w)(?:[\s.\-_*]+(\w)\b)+', lambda m: re.sub(r'[\s.\-_*]+', '', m.group()), base)
    out = set()
    for v in (base, joined, single):
        v = v.translate(_LEET)
        out.add(v)
        out.add(_squeeze(v))
    # f*ck / sh*t: dấu * thay một chữ cái
    out |= {re.sub(r'\*', '', v) for v in list(out)}
    return out


def _has_phrase(text, phrase):
    return re.search(r'(?<!\w)' + re.escape(phrase) + r'(?!\w)', text) is not None


def find_profanity(text):
    """Trả về danh sách từ không phù hợp tìm thấy (rỗng nếu sạch)."""
    if not text or not text.strip():
        return []
    found = []
    variants = _variants(text)
    plain_variants = {_strip_accents(v) for v in variants}
    for word in _WORDS['vi_exact']:
        w = unicodedata.normalize('NFC', word)
        if any(_has_phrase(v, w) or _has_phrase(v, _squeeze(w)) for v in variants):
            found.append(word)
    for word in _WORDS['vi_plain']:
        w = _strip_accents(word)
        if any(_has_phrase(v, w) for v in plain_variants):
            found.append(word)
    raw = unicodedata.normalize('NFC', text).lower().translate(_LEET)
    for stem in _WORDS['en_stems']:
        # Chỉ chấp nhận các đuôi biến thể thường gặp -> "shiitake", "Dickens", "assessment" không bị chặn nhầm
        tail = r'(?:s|es|ed|er|ers|ing|in|y|ty|head|hole|face|bag)?(?![a-z])'
        if any(re.search(r'(?<![a-z])' + re.escape(stem) + tail, v) for v in variants):
            found.append(stem)
            continue
        # f*ck, sh*t, b*tch: dấu * thay cho một chữ cái
        starred = ''.join(rf'(?:{re.escape(c)}|\*)' for c in stem)
        m = re.search(r'(?<![a-z*])' + starred + tail, raw)
        if m and '*' in m.group() and m.group().count('*') < len(stem) - 1:
            found.append(stem)
    compact_zh = re.sub(r'[\s.\-_*，。、]+', '', unicodedata.normalize('NFC', text))
    for word in _WORDS['zh']:
        if word in compact_zh:
            found.append(word)
    return list(dict.fromkeys(found))


def mask(word):
    """Che từ khi hiển thị: 'đéo' -> 'đ**'."""
    return word[0] + '*' * (len(word) - 1) if len(word) > 1 else '*'


def check(*texts):
    """Ném ProfanityError nếu bất kỳ đoạn nào chứa từ không phù hợp."""
    found = []
    for t in texts:
        found += find_profanity(t)
    if found:
        raise ProfanityError(list(dict.fromkeys(found)))
