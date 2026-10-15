"""Tự nạp dữ liệu 52 phân khu + mạng lối đi (neon_52_phan_khu.sql) lên database khi app khởi động.

Không cần dán SQL vào Neon nữa: mỗi khi file neon_52_phan_khu.sql trong repo thay đổi (khác dấu vân tay
đã lưu trong bảng app_meta), app chạy file đó MỘT lần rồi ghi lại dấu vân tay. Các lần khởi động sau bỏ qua,
nên những gì admin sửa trên web không bị ghi đè (trừ khi file SQL được cập nhật lại).
"""
import hashlib
import logging
from pathlib import Path
import psycopg2
import streamlit as st
from config import DB_CONFIG, setting

SQL_FILE = Path(__file__).resolve().parent / 'neon_52_phan_khu.sql'
# Thay đổi cấu trúc nhỏ, chạy mỗi lần khởi động (IF NOT EXISTS nên chạy lại vẫn an toàn)
SCHEMA_SQL = Path(__file__).resolve().parent / 'migrations' / '009_visit_count.sql'


def _fingerprint():
    return hashlib.sha256(SQL_FILE.read_bytes()).hexdigest()[:16]


@st.cache_resource(show_spinner='Đang cập nhật dữ liệu bản đồ...')
def ensure_map_data():
    """Trả về 'updated', 'current' hoặc 'skipped'. Lỗi không làm hỏng app (chỉ ghi log)."""
    if not SQL_FILE.exists() or str(setting('app', 'auto_data_sync', '1')).lower() in ('0', 'false', 'no'):
        return 'skipped'
    version = _fingerprint()
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            cur.execute('CREATE TABLE IF NOT EXISTS app_meta (key text PRIMARY KEY, value text NOT NULL)')
            if SCHEMA_SQL.exists():
                try:
                    cur.execute(SCHEMA_SQL.read_text(encoding='utf-8'))
                except Exception:
                    logging.exception('Không chạy được %s', SCHEMA_SQL.name)
            # (không dùng advisory lock: Neon pooler đổi kết nối giữa các lệnh nên khoá có thể bị treo)
            cur.execute("SELECT value FROM app_meta WHERE key = 'map_data'")
            row = cur.fetchone()
            if row and row[0] == version:
                return 'current'
            cur.execute(SQL_FILE.read_text(encoding='utf-8'))          # file tự có BEGIN ... COMMIT
            cur.execute("""INSERT INTO app_meta (key, value) VALUES ('map_data', %s)
                           ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value""", (version,))
            logging.info('Đã nạp neon_52_phan_khu.sql (phiên bản %s)', version)
            return 'updated'
    except Exception:
        logging.exception('Không nạp được neon_52_phan_khu.sql')
        return 'skipped'
    finally:
        conn.close()
