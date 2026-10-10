from pathlib import PurePosixPath, Path
import json
from psycopg2.errors import UndefinedTable
import streamlit as st
from auth import require_admin
from db_services import database_cursor, get_all_exhibits, query_nearby

LANGUAGES = {'vi': 'Tiếng Việt', 'en': 'English'}
ENGLISH = json.loads((Path(__file__).resolve().parent / 'english_content.json').read_text(encoding='utf-8'))

def valid_audio(value, language):
    if not value:
        return True
    parts = PurePosixPath(value).parts
    return (len(parts) == 2 and parts[0] == language and
            parts[1] not in ('.', '..') and '\\' not in value and
            parts[1].lower().endswith('.mp3'))

@st.cache_data(ttl=60, show_spinner=False)
def translations(language):
    try:
        with database_cursor() as cur:
            cur.execute('SELECT exhibit_id, name, description, audio_file FROM exhibit_translations WHERE language=%s', (language,))
            return {row['exhibit_id']: dict(row) for row in cur.fetchall()}
    except UndefinedTable:
        # Existing deployments can continue serving guests before migration 001.
        return {}

def localize(item, language, translated):
    result = dict(item)
    result['translated'] = language == 'vi'
    if item['id'] in translated:
        result.update({k: v for k, v in translated[item['id']].items() if k != 'exhibit_id'})
        if language == 'vi' and not result.get('audio_file'):
            result['audio_file'] = item.get('audio_file')
        if language == 'en' and not result.get('audio_file'):
            default = ENGLISH.get(item['name'], {})
            if result.get('description') == default.get('description'):
                result['audio_file'] = default.get('audio_file')
        result['translated'] = True
    elif language == 'en' and item['name'] in ENGLISH:
        result.update(ENGLISH[item['name']])
        result['translated'] = True
    elif language != 'vi':
        # Do not silently play Vietnamese narration under an English selection.
        result['audio_file'] = None
    return result

def save_translation(exhibit_id, language, name, description, audio_file):
    require_admin()
    if language not in LANGUAGES or not name.strip() or not description.strip():
        raise ValueError('Language, name and description are required')
    if not valid_audio(audio_file, language):
        raise ValueError('Audio path must be language/filename.mp3')
    with database_cursor() as cur:
        cur.execute('''INSERT INTO exhibit_translations(exhibit_id, language, name, description, audio_file)
            VALUES (%s,%s,%s,%s,%s) ON CONFLICT(exhibit_id, language)
            DO UPDATE SET name=EXCLUDED.name, description=EXCLUDED.description,
            audio_file=EXCLUDED.audio_file, updated_at=now()''',
            (exhibit_id, language, name.strip(), description.strip(), audio_file or None))
    translations.clear()
    get_all_exhibits.clear()
    query_nearby.clear()
