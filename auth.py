"""Xác thực admin. Tài khoản lưu trong bảng admin_users (migration 003).

- Mặc định: admin / 123456 (tạo bởi migration 003). Admin nên đổi ngay sau lần đăng nhập đầu.
- Mật khẩu chỉ lưu dạng hash PBKDF2-SHA256 có salt, không lưu bản rõ.
- Nếu chưa chạy migration 003, dùng tạm [admin] trong secrets (nếu có).
"""
import base64
import hashlib
import hmac
import secrets
import time
import streamlit as st
from psycopg2.errors import UndefinedTable
from config import setting
from db_services import database_cursor

DEFAULT_PASSWORD = '123456'
MIN_PASSWORD_LENGTH = 6
SESSION_SECONDS = 3600


def password_hash(password):
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac('sha256', password.encode(), salt, 600_000)
    return 'pbkdf2_sha256$600000$' + base64.b64encode(salt).decode() + '$' + base64.b64encode(digest).decode()


def verify_password(password, encoded):
    try:
        scheme, rounds, salt, expected = encoded.split('$')
        if scheme != 'pbkdf2_sha256' or not 100_000 <= int(rounds) <= 2_000_000:
            return False
        actual = hashlib.pbkdf2_hmac('sha256', password.encode(), base64.b64decode(salt, validate=True), int(rounds))
        return hmac.compare_digest(actual, base64.b64decode(expected, validate=True))
    except (ValueError, TypeError, AttributeError):
        return False


# Hash giả để thời gian kiểm tra như nhau dù tài khoản có tồn tại hay không
_DUMMY_HASH = password_hash(secrets.token_urlsafe(16))


def _stored_hash(username):
    """Trả về (hash, nguồn). nguồn = 'db' | 'secrets' | None."""
    try:
        with database_cursor() as cur:
            cur.execute('SELECT password_hash FROM admin_users WHERE username = %s', (username,))
            row = cur.fetchone()
            return (row['password_hash'], 'db') if row else (None, None)
    except UndefinedTable:
        expected_user = str(setting('admin', 'username', '') or '')
        encoded = str(setting('admin', 'password_hash', '') or '')
        if expected_user and encoded and hmac.compare_digest(username.encode(), expected_user.encode()):
            return encoded, 'secrets'
        return None, None


def login(username, password):
    username = (username or '').strip()
    encoded, source = _stored_hash(username)
    valid = verify_password(password, encoded or _DUMMY_HASH) and encoded is not None
    if valid:
        st.session_state['admin_until'] = time.time() + SESSION_SECONDS
        st.session_state['admin_user'] = username
        st.session_state['admin_source'] = source
        # Nhắc đổi mật khẩu khi vẫn dùng mật khẩu mặc định
        st.session_state['admin_default_pw'] = hmac.compare_digest(password.encode(), DEFAULT_PASSWORD.encode())
    return valid


def logout():
    for key in ('admin_until', 'admin_user', 'admin_source', 'admin_default_pw'):
        st.session_state.pop(key, None)


def is_admin():
    return st.session_state.get('admin_until', 0) > time.time()


def require_admin():
    if not is_admin():
        raise PermissionError('Admin login required')


def change_password(current, new, confirm):
    """Admin tự đổi mật khẩu. Ném ValueError(mã lỗi): no_db | too_short | mismatch | same | wrong_current."""
    require_admin()
    username = st.session_state.get('admin_user')
    if st.session_state.get('admin_source') != 'db':
        raise ValueError('no_db')
    if len(new or '') < MIN_PASSWORD_LENGTH:
        raise ValueError('too_short')
    if new != confirm:
        raise ValueError('mismatch')
    if new == current:
        raise ValueError('same')
    encoded, _ = _stored_hash(username)
    if not encoded or not verify_password(current, encoded):
        raise ValueError('wrong_current')
    with database_cursor() as cur:
        cur.execute('UPDATE admin_users SET password_hash = %s, updated_at = now() WHERE username = %s',
                    (password_hash(new), username))
    st.session_state['admin_default_pw'] = False


if __name__ == '__main__':
    import getpass
    print(password_hash(getpass.getpass('Admin password: ')))
