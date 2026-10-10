"""Nội dung thuyết minh đa ngôn ngữ + giọng đọc tự động.

Khi admin bấm Lưu, hệ thống dùng gTTS (Google Text-to-Speech) đọc đúng đoạn thuyết minh vừa nhập,
lưu file MP3 vào cột exhibit_translations.audio_data (bytea, migration 004) trên database.
Không lưu thành file trên ổ đĩa vì Streamlit Cloud xoá các file tạo lúc chạy mỗi khi khởi động lại.
"""
from pathlib import PurePosixPath, Path
from io import BytesIO
import json
import psycopg2
from psycopg2.errors import UndefinedTable, UndefinedColumn
import streamlit as st
from auth import require_admin
from db_services import database_cursor, get_all_exhibits, query_nearby

LANGUAGES = {'vi': 'Tiếng Việt', 'en': 'English', 'zh': '中文'}
# Mã ngôn ngữ của gTTS (tiếng Trung giản thể: zh-CN)
TTS_LANG = {'vi': 'vi', 'en': 'en', 'zh': 'zh-CN'}
_BASE = Path(__file__).resolve().parent
ENGLISH = json.loads((_BASE / 'english_content.json').read_text(encoding='utf-8'))
CHINESE = json.loads((_BASE / 'chinese_content.json').read_text(encoding='utf-8'))
# Bản dịch có sẵn đi kèm mã nguồn (admin có thể sửa lại, bản sửa lưu trong database được ưu tiên)
BUILTIN = {'en': ENGLISH, 'zh': CHINESE}


class AudioError(RuntimeError):
    """Không tạo được giọng đọc (thường do không kết nối được dịch vụ Google TTS)."""


def valid_audio(value, language):
    if not value:
        return True
    parts = PurePosixPath(value).parts
    return (len(parts) == 2 and parts[0] == language and
            parts[1] not in ('.', '..') and '\\' not in value and
            parts[1].lower().endswith('.mp3'))


def synthesize(text, language):
    """Đọc văn bản thành MP3 (bytes) bằng gTTS."""
    try:
        from gtts import gTTS
        buf = BytesIO()
        gTTS(text=text, lang=TTS_LANG.get(language, language), slow=False).write_to_fp(buf)
        data = buf.getvalue()
    except Exception as e:
        raise AudioError(str(e)) from e
    if not data:
        raise AudioError('Empty audio')
    return data


@st.cache_data(ttl=60, show_spinner=False)
def translations(language):
    try:
        with database_cursor() as cur:
            try:
                cur.execute('''SELECT exhibit_id, name, description, audio_file,
                                      (audio_data IS NOT NULL) AS has_audio, updated_at
                               FROM exhibit_translations WHERE language=%s''', (language,))
            except UndefinedColumn:
                # Chưa chạy migration 004 -> chưa có giọng đọc tự động
                cur.connection.rollback()
                cur.execute('SELECT exhibit_id, name, description, audio_file FROM exhibit_translations WHERE language=%s', (language,))
            return {row['exhibit_id']: dict(row) for row in cur.fetchall()}
    except UndefinedTable:
        # Existing deployments can continue serving guests before migration 001.
        return {}


@st.cache_data(ttl=3600, max_entries=64, show_spinner=False)
def generated_audio(exhibit_id, language, version):
    """MP3 do hệ thống tạo. `version` (updated_at) đổi mỗi lần admin lưu -> tự làm mới cache."""
    with database_cursor() as cur:
        cur.execute('SELECT audio_data FROM exhibit_translations WHERE exhibit_id=%s AND language=%s',
                    (exhibit_id, language))
        row = cur.fetchone()
        return bytes(row['audio_data']) if row and row['audio_data'] is not None else None


@st.cache_data(ttl=None, max_entries=128, show_spinner=False)
def auto_voice(text, language):
    """Giọng đọc tạo tự động cho nội dung chưa có audio (vd. bản dịch tiếng Trung có sẵn).
    Lưu trong bộ nhớ đệm của server, mỗi đoạn văn bản chỉ tạo 1 lần."""
    return synthesize(text, language)


def localize(item, language, translated):
    result = dict(item)
    result['translated'] = language == 'vi'
    result['audio_key'] = None
    if item['id'] in translated:
        row = translated[item['id']]
        result.update({k: v for k, v in row.items() if k not in ('exhibit_id', 'has_audio', 'updated_at')})
        if row.get('has_audio'):
            # Giọng đọc tự động khớp đúng nội dung admin đã lưu
            result['audio_key'] = (item['id'], language, str(row.get('updated_at')))
            result['audio_file'] = None
        elif language == 'vi' and not result.get('audio_file'):
            result['audio_file'] = item.get('audio_file')
        elif language == 'en' and not result.get('audio_file'):
            default = ENGLISH.get(item['name'], {})
            if result.get('description') == default.get('description'):
                result['audio_file'] = default.get('audio_file')
        result['translated'] = True
    elif item['name'] in BUILTIN.get(language, {}):
        result.update(BUILTIN[language][item['name']])
        result.setdefault('audio_file', None)
        if language != 'en':
            result['audio_file'] = None   # chưa có file MP3 -> app dùng auto_voice()
        result['translated'] = True
    elif language != 'vi':
        # Do not silently play Vietnamese narration under an English selection.
        result['audio_file'] = None
    return result


def save_translation(exhibit_id, language, name, description, synthesize_audio=True):
    """Lưu tên + thuyết minh và tạo giọng đọc mới cho đúng nội dung đó.
    Nếu tạo giọng đọc thất bại thì KHÔNG lưu gì (ném AudioError), tránh audio cũ đọc sai nội dung mới."""
    require_admin()
    if language not in LANGUAGES or not name.strip() or not description.strip():
        raise ValueError('Language, name and description are required')
    audio = synthesize(description.strip(), language) if synthesize_audio else None
    with database_cursor() as cur:
        cur.execute('''INSERT INTO exhibit_translations(exhibit_id, language, name, description, audio_file, audio_data)
            VALUES (%s,%s,%s,%s,NULL,%s) ON CONFLICT(exhibit_id, language)
            DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description,
            audio_file=NULL, audio_data=EXCLUDED.audio_data, updated_at=now()''',
            (exhibit_id, language, name.strip(), description.strip(),
             psycopg2.Binary(audio) if audio else None))
    translations.clear()
    get_all_exhibits.clear()
    query_nearby.clear()
