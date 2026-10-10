import io
import logging
import time
from pathlib import Path
import streamlit as st
from auth import is_admin, login, logout, change_password, MIN_PASSWORD_LENGTH
from config import setting
from content import (LANGUAGES, translations, localize, save_translation, generated_audio, AudioError,
                     save_with_auto_translation, is_unchanged, missing_translations)
from moderation import ProfanityError, mask
import zones
from config import COLOR_PALETTE
import json
import translator
import tracking

PUBLIC_URL = str(setting('app', 'public_url', 'https://hdvthaocamvien.streamlit.app/'))


def render_admin(exhibits, language):
    def tr(vi, en, zh=None):
        return {'vi': vi, 'zh': zh or en}.get(language, en)

    with st.sidebar.expander(tr('Quản trị', 'Administration', '管理'), expanded=is_admin()):
        if is_admin():
            st.write(tr('Đang đăng nhập: ', 'Signed in as: ') + f"**{st.session_state.get('admin_user', 'admin')}**")
            if st.button(tr('Đổi mật khẩu', 'Change password'), use_container_width=True):
                st.session_state['show_change_pw'] = not st.session_state.get('show_change_pw', False)
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


    st.header(tr('Trang quản trị', 'Administration'))
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
            st.success(tr('Đã đổi mật khẩu.', 'Password changed.'))


VERDICT_TEXT = {
    'good': ('Khớp nghĩa tốt', 'success'),
    'review': ('Nên xem lại: nghĩa có thể lệch một phần', 'warning'),
    'bad': ('Có thể sai nghĩa, nên viết lại câu tiếng Việt', 'error'),
    'none': ('Chưa kiểm tra được', 'info'),
}


def _show_review(lang_label, text, back, score, missing=(), machine=True):
    """Khung kiểm tra để người chỉ biết tiếng Việt vẫn duyệt được bản dịch."""
    label, kind = VERDICT_TEXT[translator.verdict(score) if score is not None else 'none']
    who = 'Máy dịch' if machine else 'Admin chỉnh tay'
    with st.container(border=True):
        st.markdown(f'**{lang_label}** · {who}')
        getattr(st, kind)(label + (f' (độ khớp {int(score * 100)}%)' if score is not None else ''))
        st.text_area('Bản dịch', text or '', disabled=True, height=90, key=f'rv_t_{lang_label}_{hash(text)}')
        st.markdown('**Dịch ngược lại tiếng Việt** (đọc phần này để kiểm tra nghĩa):')
        st.info(back or '—')
        if missing:
            st.error('Máy dịch làm mất thuật ngữ: ' + ', '.join(missing) + '. Hãy sửa tay bản dịch này.')


ZONE_ERRORS = {
    'no_db': 'Database chưa có phần quản lý phân khu. Hãy chạy file neon_update.sql mới nhất trên Neon.',
    'empty': 'Tên và nội dung thuyết minh không được để trống.',
    'bad_color': 'Màu không hợp lệ.',
    'no_shape': 'Chưa vẽ ranh giới. Bấm biểu tượng đa giác (hoặc hình chữ nhật) trên bản đồ rồi chấm các góc của khu.',
    'not_polygon': 'Ranh giới phải là một vùng khép kín (đa giác hoặc hình chữ nhật).',
    'too_few_points': 'Ranh giới cần ít nhất 3 góc.',
    'invalid': 'Ranh giới bị tự cắt nhau. Hãy vẽ lại theo một vòng, không để các cạnh cắt chéo.',
    'too_small': 'Khu quá nhỏ ({} m²), có thể do bấm nhầm. Hãy vẽ lại.',
    'too_big': 'Khu quá lớn ({} m²). Hãy vẽ sát ranh giới thật của khu.',
    'overlap': 'Ranh giới chồng lên khu khác: {}. Hãy vẽ lại để hai khu không đè lên nhau.',
    'far_from_paths': 'Khu nằm quá xa lối đi bộ nên khách không được chỉ đường tới. Hãy vẽ sát một lối đi trong vườn.',
    'duplicate_name': 'Đã có khu tên "{}". Hãy đặt tên khác.',
    'bad_image': 'Có file không phải ảnh hoặc ảnh bị lỗi.',
}


def _zone_error(e):
    msg = ZONE_ERRORS.get(e.code, e.code)
    return msg.format(e.detail) if '{}' in msg else msg


def _draw_map(key, exhibits, editing=None):
    """Bản đồ để admin vẽ ranh giới. Trả về hình vừa vẽ (GeoJSON) hoặc None."""
    import folium
    from folium.plugins import Draw
    from streamlit_folium import st_folium
    lat = sum(x['lat'] for x in exhibits) / len(exhibits) if exhibits else 10.7877
    lng = sum(x['lng'] for x in exhibits) / len(exhibits) if exhibits else 106.7056
    if editing:
        lat, lng = editing['lat'], editing['lng']
    m = folium.Map(location=[lat, lng], zoom_start=18, tiles=None)
    for x in exhibits:
        if x.get('poly_geojson'):
            mine = editing is not None and x['id'] == editing['id']
            folium.GeoJson(json.loads(x['poly_geojson']), tooltip=x['name'],
                           style_function=lambda _, mine=mine, c=x.get('color') or '#1F5C43': {
                               'color': c if mine else '#7C8A80', 'weight': 2, 'dashArray': '6 6' if mine else None,
                               'fillColor': c if mine else '#7C8A80', 'fillOpacity': 0.15 if mine else 0.25}).add_to(m)
    # Mặc định ảnh vệ tinh để admin vẽ theo đúng hàng rào / mái chuồng thật
    import ui
    ui.add_base_layers(m, 'Bản đồ', 'Ảnh vệ tinh', imagery_first=True)
    Draw(draw_options={'polygon': {'allowIntersection': False, 'showArea': True}, 'rectangle': True,
                       'polyline': False, 'circle': False, 'marker': False, 'circlemarker': False},
         edit_options={'edit': False, 'remove': True}).add_to(m)
    out = st_folium(m, height=420, width='100%', key=key, returned_objects=['all_drawings', 'last_active_drawing']) or {}
    drawings = out.get('all_drawings') or []
    return drawings[-1] if drawings else out.get('last_active_drawing')


def _save_texts(exhibit_id, name, description, auto, translate_only=None):
    """Lưu tên + thuyết minh tiếng Việt (có giọng đọc), tự dịch nếu được chọn. Trả về thông báo."""
    if auto:
        results = save_with_auto_translation(exhibit_id, name, description, save_vi=translate_only is None,
                                             languages=translate_only)
        st.session_state['auto_results'] = (exhibit_id, results)
        failed = [LANGUAGES[c] for c, r in results.items() if 'error' in r]
        if failed:
            return 'warning', 'Đã lưu. Chưa dịch được: ' + ', '.join(failed) + ' (giữ bản cũ, thử lại sau ít phút).'
        return 'success', 'Đã lưu, tạo giọng đọc và dịch sang English, 中文.'
    save_translation(exhibit_id, 'vi', name, description)
    st.session_state.pop('auto_results', None)
    return 'success', 'Đã lưu và tạo giọng đọc mới.'


def _run_save(action):
    """Chạy một thao tác lưu, hiển thị lỗi dễ hiểu. Trả về True nếu thành công."""
    try:
        with st.spinner('Đang lưu...'):
            return action() or True
    except zones.ZoneError as e:
        st.error(_zone_error(e))
    except AudioError:
        logging.exception('Text-to-speech failed')
        st.error('Không tạo được giọng đọc (không kết nối được Google TTS). Nội dung chưa được lưu, hãy thử lại.')
    except ProfanityError as e:
        st.error('Nội dung có từ ngữ không phù hợp: **' + ', '.join(map(mask, e.words)) + '**. Vui lòng sửa lại, chưa lưu gì.')
    except ValueError:
        st.error('Tên và nội dung thuyết minh không được để trống.')
    except Exception as save_error:
        logging.exception('Admin save failed')
        _explain_save_error(save_error, lambda vi, en=None, zh=None: vi)
    return False


def _content_editor(exhibits, tr):
    with st.expander('Quản lý phân khu', expanded=True):
        tab_edit, tab_new = st.tabs(['Sửa / xoá phân khu', 'Thêm phân khu mới'])
        with tab_edit:
            _edit_zone(exhibits)
        with tab_new:
            _new_zone(exhibits)


def _edit_zone(exhibits):
    if not exhibits:
        st.info('Chưa có phân khu nào. Hãy thêm ở thẻ "Thêm phân khu mới".')
        return
    options = {x['id']: x['name'] for x in exhibits}
    exhibit_id = st.selectbox('Phân khu', list(options), format_func=options.get, key='edit_id')
    original = next(x for x in exhibits if x['id'] == exhibit_id)
    item = localize(original, 'vi', translations('vi'))
    current_color = original.get('color') or COLOR_PALETTE.get(original['name'], '#1F5C43')
    with st.form(f'edit_{exhibit_id}'):
        name = st.text_input('Tên phân khu', item['name'], max_chars=120)
        description = st.text_area('Thuyết minh (nội dung sẽ được đọc thành audio)', item['description'] or '',
                                   max_chars=5000, height=160)
        c1, c2 = st.columns([1, 3])
        color = c1.color_picker('Màu trên bản đồ', current_color)
        photos = c2.file_uploader('Thêm ảnh', type=['jpg', 'jpeg', 'png', 'webp'], accept_multiple_files=True,
                                  key=f'photos_{exhibit_id}_{st.session_state.get("upload_round", 0)}')
        auto = st.checkbox('Tự dịch sang English & 中文 (có kiểm tra bằng dịch ngược)', value=True,
                           help='Bỏ tick nếu chỉ sửa lỗi chính tả nhỏ và không muốn dịch lại.')
        save = st.form_submit_button('Lưu thay đổi', type='primary')

    if save:
        text_changed = not is_unchanged(item, name, description)
        no_voice = not item.get('audio_key') and not item.get('audio_file')
        todo = missing_translations(exhibit_id) if auto else []
        color_changed = color.lower() != current_color.lower()
        if not (text_changed or no_voice or todo or color_changed or photos):
            st.session_state.pop('edit_saved', None)
            st.session_state.pop('auto_results', None)
            st.info('Nội dung **giống hệt** bản đang lưu nên không cần lưu lại. Hãy sửa tên, thuyết minh, màu hoặc thêm ảnh rồi bấm Lưu.')
        else:
            def action():
                messages = []
                if text_changed or no_voice:
                    if text_changed:
                        zones.check_name(name, exhibit_id)
                    kind, msg = _save_texts(exhibit_id, name, description, auto)
                    if text_changed:
                        zones.update_zone(exhibit_id, name=name, description=description)
                    messages.append((kind, msg))
                elif todo:
                    messages.append(_save_texts(exhibit_id, name, description, True, translate_only=todo))
                if color_changed:
                    zones.update_zone(exhibit_id, color=color)
                    messages.append(('success', 'Đã đổi màu.'))
                if photos:
                    n = zones.add_images(exhibit_id, [f.getvalue() for f in photos])
                    st.session_state['upload_round'] = st.session_state.get('upload_round', 0) + 1
                    messages.append(('success', f'Đã thêm {n} ảnh.'))
                kind = 'warning' if any(k == 'warning' for k, _ in messages) else 'success'
                st.session_state['save_message'] = (kind, ' '.join(m for _, m in messages))
                st.session_state['edit_saved'] = exhibit_id
            if _run_save(action):
                st.rerun()

    if st.session_state.get('edit_saved') == exhibit_id and st.session_state.get('save_message'):
        kind, message = st.session_state['save_message']
        getattr(st, kind)(message)

    results = st.session_state.get('auto_results')
    if results and results[0] == exhibit_id:
        st.markdown('#### Kết quả tự dịch')
        for code, res in results[1].items():
            if 'error' in res:
                st.warning(f'{LANGUAGES[code]}: chưa dịch được (lỗi kết nối dịch vụ dịch). Bản cũ được giữ nguyên.')
                with st.expander(f'Chi tiết lỗi, {LANGUAGES[code]}'):
                    st.code(res['error'][:800])
            else:
                _show_review(f'{LANGUAGES[code]}: {res["name"]}', res['text'], res['back'], res['score'], res['missing_terms'])
        st.caption('Bản nào bị đánh dấu vàng hoặc đỏ: viết lại câu tiếng Việt ngắn gọn, rõ chủ ngữ, mỗi câu một ý rồi bấm Lưu lại.')

    # Giọng đọc hiện tại
    current = generated_audio(*item['audio_key']) if item.get('audio_key') else None
    if current:
        st.caption('Giọng đọc hiện tại')
        st.audio(current, format='audio/mp3')
    elif item.get('audio_file') and (Path(__file__).resolve().parent / 'audio' / item['audio_file']).is_file():
        st.caption('Giọng đọc hiện tại (file gốc)')
        st.audio(str(Path(__file__).resolve().parent / 'audio' / item['audio_file']), format='audio/mp3')

    # Ảnh đã tải lên
    uploaded = zones.zone_images(exhibit_id)
    if uploaded:
        st.markdown('**Ảnh đã tải lên**')
        cols = st.columns(4)
        for k, (img_id, data) in enumerate(uploaded):
            with cols[k % 4]:
                st.image(data, use_container_width=True)
                if st.button('Xoá ảnh', key=f'del_img_{img_id}', use_container_width=True):
                    if _run_save(lambda img_id=img_id: zones.delete_image(img_id)):
                        st.rerun()

    # Vẽ lại ranh giới
    with st.expander('Vẽ lại ranh giới'):
        st.caption('Vùng nét đứt là ranh giới hiện tại. Vẽ ranh giới mới bằng công cụ đa giác hoặc hình chữ nhật, rồi bấm Lưu ranh giới.')
        drawing = _draw_map(f'redraw_{exhibit_id}', exhibits, editing=original)
        if st.button('Lưu ranh giới', key=f'save_shape_{exhibit_id}'):
            if _run_save(lambda: zones.update_zone(exhibit_id, drawing=drawing)):
                st.session_state['save_message'] = ('success', 'Đã lưu ranh giới mới.')
                st.session_state['edit_saved'] = exhibit_id
                st.rerun()

    # Xoá
    with st.expander('Xoá phân khu'):
        st.caption('Khu sẽ biến mất khỏi bản đồ, danh sách và chỉ đường của khách. '
                   'Số liệu thống kê lượt ghé trước đây vẫn được giữ.')
        sure = st.checkbox(f'Tôi chắc chắn muốn xoá "{item["name"]}"', key=f'sure_{exhibit_id}')
        if st.button('Xoá phân khu', key=f'delete_{exhibit_id}', disabled=not sure):
            if _run_save(lambda: zones.delete_zone(exhibit_id)):
                st.session_state.pop('edit_id', None)
                st.session_state['deleted_message'] = f'Đã xoá "{item["name"]}".'
                st.rerun()
    if st.session_state.get('deleted_message'):
        st.success(st.session_state.pop('deleted_message'))


def _new_zone(exhibits):
    st.caption('Bước 1: vẽ ranh giới khu trên bản đồ (biểu tượng đa giác hoặc hình chữ nhật ở góc trái). '
               'Bước 2: điền tên, thuyết minh rồi bấm Thêm phân khu.')
    drawing = _draw_map('draw_new_zone', exhibits)
    with st.form('new_zone', clear_on_submit=False):
        name = st.text_input('Tên phân khu', max_chars=120, placeholder='Ví dụ: Khu Chim Cảnh')
        description = st.text_area('Thuyết minh (nội dung sẽ được đọc thành audio)', max_chars=5000, height=140)
        c1, c2 = st.columns([1, 3])
        color = c1.color_picker('Màu trên bản đồ', '#1F5C43')
        photos = c2.file_uploader('Ảnh của khu', type=['jpg', 'jpeg', 'png', 'webp'], accept_multiple_files=True,
                                  key=f'new_photos_{st.session_state.get("new_round", 0)}')
        auto = st.checkbox('Tự dịch sang English & 中文 (có kiểm tra bằng dịch ngược)', value=True)
        add = st.form_submit_button('Thêm phân khu', type='primary')
    if add:
        def action():
            zones.check_name(name, None)
            new_id = zones.create_zone(name, description, color, drawing)
            msgs = []
            try:
                kind, msg = _save_texts(new_id, name, description, auto)
                msgs.append(msg)
            except AudioError:
                kind = 'warning'
                msgs.append('Đã thêm khu nhưng chưa tạo được giọng đọc. Vào thẻ "Sửa / xoá phân khu" bấm Lưu thay đổi để tạo lại.')
            if photos:
                zones.add_images(new_id, [f.getvalue() for f in photos])
            st.session_state['new_round'] = st.session_state.get('new_round', 0) + 1
            st.session_state['edit_id'] = new_id
            st.session_state['edit_saved'] = new_id
            st.session_state['save_message'] = (kind, f'Đã thêm "{name.strip()}". ' + ' '.join(msgs))
        if _run_save(action):
            st.rerun()


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
                    '\n\nMở Neon → SQL Editor, dán **toàn bộ** file `neon_setup.sql` mới nhất rồi bấm **Run**, sau đó bấm Lưu lại.',
                    'Save failed: the database is missing:' + items + '\n\nRun the latest neon_setup.sql in the Neon SQL Editor.'))
    else:
        st.error(tr('Không lưu được. Database đã đủ bảng, lỗi khác như sau:', 'Save failed with this error:'))
    with st.expander(tr('Chi tiết lỗi', 'Error details')):
        st.code(f'{type(error).__name__}: {str(error).strip()[:800]}')


def _visitor_stats(tr):
    with st.expander(tr('Thống kê khách tham quan', 'Visitor statistics')):
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
    with st.expander(tr('Mã QR vào web', 'Entry QR code')):
        url = PUBLIC_URL   # địa chỉ cố định trong Secrets ([app] public_url) để không in nhầm mã QR
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
        st.download_button(tr('Tải mã QR (PNG)', 'Download QR (PNG)'), buf.getvalue(),
                           file_name='thao_cam_vien_qr.png', mime='image/png')
