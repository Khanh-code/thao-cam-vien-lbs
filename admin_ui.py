import io
import logging
import time
from pathlib import Path
import streamlit as st
from auth import is_admin, login, logout, change_password, MIN_PASSWORD_LENGTH
from config import setting
from content import (LANGUAGES, translations, localize, save_translation, generated_audio, AudioError,
                     save_with_auto_translation, check_translation, is_unchanged, missing_translations)
import translator
import tracking

PUBLIC_URL = str(setting('app', 'public_url', 'https://hdvthaocamvien.streamlit.app/'))


def render_admin(exhibits, language):
    def tr(vi, en, zh=None):
        return {'vi': vi, 'zh': zh or en}.get(language, en)

    st.sidebar.caption(tr('Vai trò: ', 'Role: ', '角色：') + ('Admin' if is_admin() else tr('Khách', 'Guest', '游客')))
    with st.sidebar.expander(tr('Quản trị', 'Administration', '管理'), expanded=is_admin()):
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
                username = st.text_input(tr('Tài khoản', 'Username', '账号'), max_chars=100)
                password = st.text_input(tr('Mật khẩu', 'Password', '密码'), type='password', max_chars=512)
                submit = st.form_submit_button(tr('Đăng nhập admin', 'Admin sign in', '管理员登录'))
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
                    st.warning(tr('Đăng nhập thất bại. Thử lại sau.', 'Sign in failed. Retry later.', '登录失败，请稍后再试。'))

    if not is_admin():
        return

    if st.session_state.get('admin_default_pw'):
        st.warning(tr('⚠️ Bạn đang dùng mật khẩu mặc định **123456**. Hãy bấm **🔑 Đổi mật khẩu** ở thanh bên trái.',
                      '⚠️ You are using the default password **123456**. Click **🔑 Change password** in the sidebar.'))

    _content_editor(exhibits, tr)
    _glossary_editor(tr)
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


VERDICT_TEXT = {
    'good': ('✅ Khớp nghĩa tốt', 'success'),
    'review': ('⚠️ Nên xem lại — nghĩa có thể lệch một phần', 'warning'),
    'bad': ('❌ Có thể sai nghĩa — nên sửa tay', 'error'),
    'none': ('ℹ️ Chưa kiểm tra được', 'info'),
}


def _show_review(lang_label, text, back, score, missing=(), machine=True):
    """Khung kiểm tra để người chỉ biết tiếng Việt vẫn duyệt được bản dịch."""
    label, kind = VERDICT_TEXT[translator.verdict(score) if score is not None else 'none']
    who = '🤖 Máy dịch' if machine else '✍️ Admin chỉnh tay'
    with st.container(border=True):
        st.markdown(f'**{lang_label}** · {who}')
        getattr(st, kind)(label + (f' (độ khớp {int(score * 100)}%)' if score is not None else ''))
        st.text_area('Bản dịch', text or '', disabled=True, height=90, key=f'rv_t_{lang_label}_{hash(text)}')
        st.markdown('**Dịch ngược lại tiếng Việt** (đọc phần này để kiểm tra nghĩa):')
        st.info(back or '—')
        if missing:
            st.error('Máy dịch làm mất thuật ngữ: ' + ', '.join(missing) + '. Hãy sửa tay bản dịch này.')


def _content_editor(exhibits, tr):
    with st.expander(tr('✏️ Biên tập nội dung', '✏️ Edit content')):
        st.caption(tr('Chọn phân khu và ngôn ngữ, sửa nội dung rồi bấm Lưu. Hệ thống sẽ tự tạo giọng đọc đúng theo đoạn thuyết minh.',
                      'Choose a zone and language, edit the text and click Save. A matching voice narration is generated automatically.'))
        options = {x['id']: x['name'] for x in exhibits}
        exhibit_id = st.selectbox(tr('Phân khu', 'Zone'), list(options), format_func=options.get, key='edit_id')
        lang = st.selectbox(tr('Ngôn ngữ nội dung', 'Content language'), list(LANGUAGES), format_func=LANGUAGES.get, key='edit_lang')
        original = next(x for x in exhibits if x['id'] == exhibit_id)
        item = localize(original, lang, translations(lang))
        vi_item = localize(original, 'vi', translations('vi'))
        with st.form(f'edit_{exhibit_id}_{lang}'):
            name = st.text_input(tr('Tên phân khu', 'Zone name'), item['name'], max_chars=300)
            description = st.text_area(tr('Thuyết minh (nội dung sẽ được đọc thành audio)', 'Narration (this text will be read aloud)'),
                                       item['description'] or '', max_chars=5000, height=160)
            auto = False
            if lang == 'vi':
                auto = st.checkbox(tr('🌐 Tự dịch sang English & 中文 (có kiểm tra bằng dịch ngược)',
                                      '🌐 Auto-translate to English & 中文 (checked by back-translation)'), value=True,
                                   help=tr('Bỏ tick nếu chỉ sửa lỗi chính tả tiếng Việt và không muốn ghi đè bản dịch đã chỉnh tay.',
                                           'Untick to keep manually edited translations.'))
            save = st.form_submit_button(tr('💾 Lưu & tạo giọng đọc', '💾 Save & generate voice'))
        unchanged = save and is_unchanged(item, name, description)
        todo = missing_translations(exhibit_id) if (save and auto) else []
        if save and unchanged and not todo:
            # Không có gì mới -> không lưu lại, không tạo lại giọng đọc / không dịch lại
            save = False
            st.info(tr('ℹ️ Nội dung **giống hệt** bản đang lưu nên không cần lưu lại. Hãy sửa tên hoặc thuyết minh rồi bấm Lưu.',
                       'ℹ️ Nothing changed, so nothing was saved.'))
        if save:
            try:
                with st.spinner(tr('Đang lưu, dịch và tạo giọng đọc...', 'Saving, translating and generating voice...')):
                    if auto:
                        # Tiếng Việt không đổi -> chỉ dịch bổ sung ngôn ngữ còn thiếu
                        results = save_with_auto_translation(exhibit_id, name, description, save_vi=not unchanged,
                                                             languages=todo if unchanged else None)
                        st.session_state['auto_results'] = (exhibit_id, results)
                    else:
                        review = None
                        if lang != 'vi':
                            review = check_translation(lang, description)
                            if review['back_translation']:
                                review['quality'] = translator.similarity(vi_item['description'] or '', review['back_translation'])
                        save_translation(exhibit_id, lang, name, description, review=review)
                        st.session_state.pop('auto_results', None)
            except AudioError:
                logging.exception('Text-to-speech failed')
                st.error(tr('Không tạo được giọng đọc (không kết nối được Google TTS). Nội dung CHƯA được lưu, hãy thử lại.',
                            'Could not generate the voice (Google TTS unreachable). Nothing was saved; please retry.'))
            except ValueError:
                st.error(tr('Tên và nội dung thuyết minh không được để trống.', 'Name and narration are required.'))
            except Exception as save_error:
                logging.exception('Admin save failed')
                _explain_save_error(save_error, tr)
            else:
                st.session_state['edit_saved'] = (exhibit_id, lang)
                st.rerun()
        if st.session_state.get('edit_saved') == (exhibit_id, lang):
            st.success(tr('✅ Đã lưu và tạo giọng đọc mới.', '✅ Saved with a new voice narration.'))

        # Kết quả tự dịch vừa chạy: hiện cả 2 bản để duyệt
        results = st.session_state.get('auto_results')
        if lang == 'vi' and results and results[0] == exhibit_id:
            st.markdown('#### 🌐 Kết quả tự dịch — hãy đọc phần "dịch ngược" để kiểm tra')
            for code, res in results[1].items():
                if 'error' in res:
                    st.warning(f'{LANGUAGES[code]}: chưa dịch được (lỗi kết nối dịch vụ dịch). Bản cũ được giữ nguyên, hãy thử Lưu lại.')
                else:
                    _show_review(f'{LANGUAGES[code]} — {res["name"]}', res['text'], res['back'], res['score'], res['missing_terms'])
            st.caption('Chỗ nào ⚠️/❌: đổi "Ngôn ngữ nội dung" sang ngôn ngữ đó, sửa câu rồi Lưu. '
                       'Mẹo: viết câu tiếng Việt ngắn, rõ chủ ngữ, mỗi câu một ý thì máy dịch sát nghĩa hơn.')

        # Bản Anh/Trung đang lưu: hiện kết quả kiểm tra đã lưu
        review = item.get('review') or {}
        if lang != 'vi' and (review.get('back_translation') or review.get('machine_translated')):
            _show_review(LANGUAGES[lang], item['description'], review.get('back_translation'), review.get('quality'),
                         machine=bool(review.get('machine_translated')))

        # Nghe thử audio hiện tại của phân khu / ngôn ngữ đang chọn
        current = generated_audio(*item['audio_key']) if item.get('audio_key') else None
        if current:
            st.caption(tr('🎧 Giọng đọc hiện tại (tự tạo):', '🎧 Current narration (generated):'))
            st.audio(current, format='audio/mp3')
        elif item.get('audio_file') and (Path(__file__).resolve().parent / 'audio' / item['audio_file']).is_file():
            st.caption(tr('🎧 Giọng đọc hiện tại (file gốc):', '🎧 Current narration (original file):'))
            st.audio(str(Path(__file__).resolve().parent / 'audio' / item['audio_file']), format='audio/mp3')
        else:
            st.caption(tr('Chưa có giọng đọc cho ngôn ngữ này — bấm Lưu để tạo.', 'No narration for this language yet — click Save to create one.'))


def _explain_save_error(error, tr):
    """Báo rõ nguyên nhân lỗi lưu: thiếu migration nào, hay lỗi gì khác."""
    from db_services import missing_schema
    try:
        missing = missing_schema()
    except Exception:
        missing = None
    if missing:
        items = ''.join(f'\n- {label} (migration {m})' for m, label in missing)
        st.error(tr('Không lưu được vì database Neon **chưa được cập nhật**. Đang thiếu:' + items +
                    '\n\n👉 Mở Neon → SQL Editor, dán **toàn bộ** file `neon_setup.sql` mới nhất rồi bấm **Run**, sau đó bấm Lưu lại.',
                    'Save failed: the database is missing:' + items + '\n\nRun the latest neon_setup.sql in the Neon SQL Editor.'))
    else:
        st.error(tr('Không lưu được. Database đã đủ bảng, lỗi khác như sau:', 'Save failed with this error:'))
    with st.expander(tr('Chi tiết lỗi', 'Error details')):
        st.code(f'{type(error).__name__}: {str(error).strip()[:800]}')


def _glossary_editor(tr):
    with st.expander(tr('📖 Bảng thuật ngữ (tên riêng luôn dịch cố định)', '📖 Glossary (fixed translations)')):
        st.caption(tr('Các từ trong bảng này luôn được dịch đúng như ghi ở đây, máy dịch không được tự đổi. '
                      'Thêm tên riêng, tên loài, tên khu mới vào đây trước khi viết thuyết minh có chứa chúng.',
                      'Terms here are always translated exactly as listed.'))
        try:
            rows = translator.glossary()
        except Exception:
            st.error(tr('Không tải được bảng thuật ngữ.', 'Could not load the glossary.'))
            return
        edited = st.data_editor(rows, num_rows='dynamic', use_container_width=True, key='glossary_editor',
                                column_config={'vi': 'Tiếng Việt', 'en': 'English', 'zh': '中文'})
        if st.button(tr('💾 Lưu bảng thuật ngữ', '💾 Save glossary')):
            try:
                n = translator.save_glossary(edited)
            except Exception:
                logging.exception('Glossary save failed')
                st.error(tr('Không lưu được (đã chạy neon_setup.sql chưa?).', 'Save failed (run neon_setup.sql).'))
            else:
                st.success(tr(f'✅ Đã lưu {n} thuật ngữ.', f'✅ Saved {n} terms.'))


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
