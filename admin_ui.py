import io
import logging
import time
from pathlib import Path
import streamlit as st
from auth import is_admin, login, logout, change_password, MIN_PASSWORD_LENGTH
from config import setting
from content import LANGUAGES, translations, localize, save_translation, valid_audio
import tracking

PUBLIC_URL = str(setting('app', 'public_url', 'https://hdvthaocamvien.streamlit.app/'))


def render_admin(exhibits, language):
    def tr(vi, en):
        return vi if language == 'vi' else en

    st.sidebar.caption(tr('Vai trò: ', 'Role: ') + ('Admin' if is_admin() else tr('Khách', 'Guest')))
    with st.sidebar.expander(tr('Quản trị', 'Administration'), expanded=is_admin()):
        if is_admin():
            st.write(tr('Đang đăng nhập: ', 'Signed in as: ') + f"**{st.session_state.get('admin_user', 'admin')}**")
            c1, c2 = st.columns(2)
            with c1:
                if st.button(tr('🔑 Đổi mật khẩu', '🔑 Change password'), use_container_width=True):
                    st.session_state['show_change_pw'] = not st.session_state.get('show_change_pw', False)
            with c2:
                if st.button(tr('Đăng xuất', 'Sign out'), use_container_width=True):
                    logout()
                    st.session_state.pop('show_change_pw', None)
                    st.rerun()
            if st.session_state.get('show_change_pw'):
                _change_password_form(tr)
        else:
            with st.form('login_admin', clear_on_submit=True):
                username = st.text_input(tr('Tài khoản', 'Username'), max_chars=100)
                password = st.text_input(tr('Mật khẩu', 'Password'), type='password', max_chars=512)
                submit = st.form_submit_button(tr('Đăng nhập admin', 'Admin sign in'))
            if submit:
                ok = False
                if time.time() >= st.session_state.get('login_retry_at', 0):
                    try:
                        ok = login(username, password)
                    except Exception:
                        logging.exception('Admin login failed')
                if ok:
                    st.rerun()
                else:
                    st.session_state['login_retry_at'] = time.time() + 3
                    st.warning(tr('Đăng nhập thất bại. Thử lại sau.', 'Sign in failed. Retry later.'))

    if not is_admin():
        return

    if st.session_state.get('admin_default_pw'):
        st.warning(tr('⚠️ Bạn đang dùng mật khẩu mặc định **123456**. Hãy bấm **🔑 Đổi mật khẩu** ở thanh bên trái.',
                      '⚠️ You are using the default password **123456**. Click **🔑 Change password** in the sidebar.'))

    _content_editor(exhibits, tr)
    _visitor_stats(tr)
    _qr_code(tr)


def _change_password_form(tr):
    messages = {
        'no_db': tr('Chưa chạy migration 003 (python run_migrations.py) nên chưa đổi được mật khẩu.',
                    'Run migration 003 (python run_migrations.py) before changing the password.'),
        'too_short': tr(f'Mật khẩu mới phải có ít nhất {MIN_PASSWORD_LENGTH} ký tự.',
                        f'New password must be at least {MIN_PASSWORD_LENGTH} characters.'),
        'mismatch': tr('Mật khẩu nhập lại không khớp.', 'Passwords do not match.'),
        'same': tr('Mật khẩu mới phải khác mật khẩu hiện tại.', 'New password must differ from the current one.'),
        'wrong_current': tr('Mật khẩu hiện tại không đúng.', 'Current password is incorrect.'),
    }
    with st.form('change_password', clear_on_submit=True):
        current = st.text_input(tr('Mật khẩu hiện tại', 'Current password'), type='password', max_chars=512)
        new = st.text_input(tr('Mật khẩu mới', 'New password'), type='password', max_chars=512)
        confirm = st.text_input(tr('Nhập lại mật khẩu mới', 'Confirm new password'), type='password', max_chars=512)
        submitted = st.form_submit_button(tr('Lưu mật khẩu mới', 'Save new password'))
    if submitted:
        try:
            change_password(current, new, confirm)
        except ValueError as e:
            st.error(messages.get(str(e), str(e)))
        except Exception:
            logging.exception('Change password failed')
            st.error(tr('Không đổi được mật khẩu. Kiểm tra database.', 'Could not change password. Check the database.'))
        else:
            st.session_state['show_change_pw'] = False
            st.success(tr('✅ Đã đổi mật khẩu.', '✅ Password changed.'))


def _content_editor(exhibits, tr):
    with st.expander(tr('✏️ Biên tập nội dung', '✏️ Edit content')):
        st.caption(tr('Chọn phân khu và ngôn ngữ để cập nhật thuyết minh. Âm thanh phải khớp nội dung.',
                      'Choose a zone and language to update its narration. Audio should match the text.'))
        options = {x['id']: x['name'] for x in exhibits}
        exhibit_id = st.selectbox(tr('Phân khu', 'Zone'), list(options), format_func=options.get, key='edit_id')
        lang = st.selectbox(tr('Ngôn ngữ nội dung', 'Content language'), list(LANGUAGES), format_func=LANGUAGES.get, key='edit_lang')
        original = next(x for x in exhibits if x['id'] == exhibit_id)
        item = localize(original, lang, translations(lang))
        with st.form(f'edit_{exhibit_id}_{lang}'):
            name = st.text_input(tr('Tên phân khu', 'Zone name'), item['name'], max_chars=300)
            description = st.text_area(tr('Thuyết minh', 'Narration text'), item['description'] or '', max_chars=20000)
            existing = item.get('audio_file') or ''
            audio = st.text_input(tr('Audio: vi/voi.mp3 hoặc en/elephants.mp3', 'Audio: vi/voi.mp3 or en/elephants.mp3'),
                                  existing if '/' in existing else '')
            save = st.form_submit_button(tr('Lưu', 'Save'))
        if save:
            if not valid_audio(audio, lang) or (audio and not (Path(__file__).resolve().parent / 'audio' / audio).is_file()):
                st.error(tr('Đường dẫn audio không hợp lệ hoặc file chưa được triển khai.', 'Invalid audio path or file has not been deployed.'))
                return
            try:
                save_translation(exhibit_id, lang, name, description, audio)
            except Exception:
                logging.exception('Admin save failed')
                st.error(tr('Không lưu được. Kiểm tra dữ liệu và database.', 'Save failed. Check inputs and database.'))
            else:
                st.rerun()


def _visitor_stats(tr):
    with st.expander(tr('📊 Thống kê khách tham quan', '📊 Visitor statistics')):
        try:
            default_day = tracking.today()
        except Exception:
            st.info(tr('Chưa có dữ liệu khách. Hãy chạy migration 003 (python run_migrations.py).',
                       'No visitor data yet. Run migration 003 (python run_migrations.py).'))
            return
        day = st.date_input(tr('Ngày thống kê', 'Date'), value=default_day, key='stats_day')
        try:
            s = tracking.summary(day)
            rows = tracking.daily_stats(day)
        except Exception:
            logging.exception('Visitor statistics failed')
            st.error(tr('Không tải được thống kê.', 'Could not load statistics.'))
            return
        m1, m2, m3 = st.columns(3)
        m1.metric(tr('Tài khoản khách mới', 'New visitor accounts'), s['new_visitors'])
        m2.metric(tr('Khách đã ghé ≥1 khu', 'Visitors at ≥1 zone'), s['active_visitors'])
        m3.metric(tr('Điểm lưu vết', 'Track points'), s['track_points'])
        label_zone, label_count = tr('Phân khu', 'Zone'), tr('Số khách', 'Visitors')
        data = {label_zone: [r['name'] for r in rows], label_count: [int(r['visitors']) for r in rows]}
        st.bar_chart(data, x=label_zone, y=label_count, horizontal=True)
        st.dataframe(data, hide_index=True, use_container_width=True)
        period = tr('mỗi ngày', 'daily') if tracking.RESET_PERIOD == 'day' else tr('mỗi tuần (thứ Hai)', 'weekly (Monday)')
        st.caption(tr(f'Tài khoản khách tạm tự reset {period}. Mỗi khách được đếm 1 lần / phân khu / ngày.',
                      f'Temporary visitor accounts reset {period}. Each visitor counts once per zone per day.'))


def _qr_code(tr):
    with st.expander(tr('📱 Mã QR vào web', '📱 Entry QR code')):
        url = st.text_input(tr('Địa chỉ web', 'Web address'), PUBLIC_URL, key='qr_url')
        st.caption(tr('In mã này ở cổng. Mỗi lần quét sẽ tạo một tài khoản khách tạm mới.',
                      'Print this at the entrance. Each scan creates a new temporary visitor account.'))
        try:
            import qrcode
        except ImportError:
            st.info('pip install "qrcode[pil]"')
            return
        buf = io.BytesIO()
        qrcode.make(url, box_size=10, border=2).save(buf, format='PNG')
        st.image(buf.getvalue(), width=240)
        st.download_button(tr('⬇️ Tải mã QR (PNG)', '⬇️ Download QR (PNG)'), buf.getvalue(),
                           file_name='thao_cam_vien_qr.png', mime='image/png')
