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
    # Menu: mỗi chức năng một nút, chỉ hiện phần đang chọn cho dễ nhìn
    menu = {'edit': 'Sửa / xoá phân khu', 'new': 'Thêm phân khu', 'stats': 'Thống kê khách', 'qr': 'Mã QR'}
    choice = st.segmented_control('Chức năng', list(menu), format_func=menu.get, default='edit',
                                  key='admin_menu', label_visibility='collapsed') or 'edit'
    hints = {'edit': 'Chọn một khu để sửa tên, thuyết minh, ảnh, vị trí hoặc xoá khu.',
             'new': 'Chạm vào bản đồ ở chỗ khách đứng xem, điền tên và thuyết minh rồi bấm Thêm phân khu.',
             'stats': 'Xem khu nào đông, khu nào vắng trong tuần để có cách cải thiện.',
             'qr': 'In mã này đặt ở cổng: khách quét là mở được trang hướng dẫn.'}
    st.markdown(f'<p class="tcv-admin-hint">{hints[choice]}</p>', unsafe_allow_html=True)
    with st.container(key='admin_card'):
        if choice == 'edit':
            _edit_zone(exhibits)
        elif choice == 'new':
            _new_zone(exhibits)
        elif choice == 'stats':
            _visitor_stats(tr)
        else:
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
    'overlap': 'Vùng nghe thuyết minh chồng lên khu khác: {}. Hãy chọn điểm xa hơn hoặc giảm bán kính.',
    'far_from_paths': 'Điểm này quá xa lối đi bộ nên khách không được chỉ đường tới. Hãy chọn điểm sát một lối đi trong vườn.',
    'duplicate_name': 'Đã có khu tên "{}". Hãy đặt tên khác.',
    'bad_image': 'Có file không phải ảnh hoặc ảnh bị lỗi.',
    'no_point': 'Chưa chọn điểm trên bản đồ. Hãy chạm vào chỗ khách đứng xem khu.',
    'bad_radius': 'Bán kính phải từ {} m.',
}


def _zone_error(e):
    msg = ZONE_ERRORS.get(e.code, e.code)
    return msg.format(e.detail) if '{}' in msg else msg


def _pick_map(key, exhibits, pick=None, radius=None, editing=None):
    """Bản đồ ảnh vệ tinh để admin CHẠM chọn điểm tham quan. Vùng tròn xem trước vẽ quanh điểm đã chọn.
    Trả về toạ độ vừa chạm (lat, lng) hoặc None."""
    import folium
    from streamlit_folium import st_folium
    import ui
    if pick:
        lat, lng = pick
    elif editing:
        lat, lng = editing['lat'], editing['lng']
    else:
        lat = sum(x['lat'] for x in exhibits) / len(exhibits) if exhibits else 10.7877
        lng = sum(x['lng'] for x in exhibits) / len(exhibits) if exhibits else 106.7056
    m = folium.Map(location=[lat, lng], zoom_start=19, tiles=None)
    ui.add_base_layers(m, 'Bản đồ', 'Ảnh vệ tinh', imagery_first=True)
    for x in exhibits:
        if editing is not None and x['id'] == editing['id']:
            continue
        if x.get('poly_geojson'):   # vùng của các khu khác (để tránh chồng lên)
            folium.GeoJson(json.loads(x['poly_geojson']), tooltip=x['name'], control=False,
                           style_function=lambda _: {'color': '#FFFFFF', 'weight': 1.5, 'dashArray': '5 5',
                                                     'fillColor': '#FFFFFF', 'fillOpacity': 0.18}).add_to(m)
        for lat_p, lng_p in [(x['lat'], x['lng'])] + [tuple(p) for p in (x.get('extra_pins') or [])]:
            folium.Marker([lat_p, lng_p], tooltip=ui.zone_label(x), icon=ui.pin_icon(x.get('map_no'))).add_to(m)
    if pick and radius:
        color = (editing or {}).get('color') or '#C8406E'
        folium.Circle(pick, radius=radius, color=color, weight=3, dash_array='6 6', fill=True,
                      fill_color=color, fill_opacity=0.25, tooltip=f'Vùng nghe thuyết minh: bán kính {radius} m').add_to(m)
        folium.Marker(pick, icon=folium.Icon(color='pink', icon='map-marker', prefix='fa')).add_to(m)
    out = st_folium(m, height=420, width='100%', key=key, returned_objects=['last_clicked']) or {}
    clicked = out.get('last_clicked')
    return (round(clicked['lat'], 6), round(clicked['lng'], 6)) if clicked else None


def _radius_slider(key, pick, exclude_id=None, current=None):
    """Thanh trượt bán kính. Mỗi lần chọn điểm mới, đặt sẵn giá trị gợi ý (không chồng khu khác)."""
    marker = f'{key}_for'
    if st.session_state.get(marker) != pick:
        st.session_state[marker] = pick
        st.session_state[key] = current or zones.suggest_radius(pick[0], pick[1], exclude_id)
    suggested = zones.suggest_radius(pick[0], pick[1], exclude_id)
    return st.slider('Bán kính vùng nghe thuyết minh (m)', zones.MIN_RADIUS_M, zones.MAX_RADIUS_M, key=key,
                     help=f'Gợi ý: {suggested} m (bằng nửa khoảng cách tới khu gần nhất, để hai vùng không chồng nhau).')


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
    import ui
    options = {x['id']: ui.zone_label(x) for x in exhibits}
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
                st.warning(f'{LANGUAGES[code]}: chưa dịch được (lỗi kết nối dịch vụ dịch). Bản cũ được giữ nguyên. '
                           'Chờ vài phút rồi bấm Lưu thay đổi lại.')
                st.code(res['error'][:800], language=None)
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

    # Đổi vị trí / bán kính vùng nghe thuyết minh
    with st.expander('Đổi vị trí vùng nghe thuyết minh'):
        st.caption('Chạm vào điểm khách đứng xem khu này trên ảnh vệ tinh, chỉnh bán kính rồi bấm Lưu vị trí. '
                   'Vùng tròn sẽ tự tạo quanh điểm đó.')
        pick_key = f'move_pick_{exhibit_id}'
        pick = st.session_state.get(pick_key) or (round(original['lat'], 6), round(original['lng'], 6))
        current_r = zones.current_radius(exhibit_id) if pick == (round(original['lat'], 6), round(original['lng'], 6)) else None
        radius = st.session_state.get(f'move_r_{exhibit_id}') or current_r or zones.MAX_SUGGESTED_RADIUS_M
        clicked = _pick_map(f'move_map_{exhibit_id}', exhibits, pick=pick, radius=radius, editing=original)
        if clicked and clicked != st.session_state.get(f'move_last_{exhibit_id}'):
            st.session_state[f'move_last_{exhibit_id}'] = clicked
            st.session_state[pick_key] = clicked
            st.rerun()
        radius = _radius_slider(f'move_r_{exhibit_id}', pick, exclude_id=exhibit_id, current=current_r)
        if st.button('Lưu vị trí', key=f'save_move_{exhibit_id}'):
            if _run_save(lambda: zones.move_zone(exhibit_id, pick[0], pick[1], radius)):
                st.session_state.pop(pick_key, None)
                st.session_state['save_message'] = ('success', f'Đã lưu vị trí mới (bán kính {radius} m).')
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
    st.caption('Bước 1: chạm vào điểm khách đứng xem khu trên ảnh vệ tinh (lối vào chuồng hoặc chỗ ngắm). '
               'Vùng nghe thuyết minh hình tròn sẽ tự tạo. Bước 2: điền tên, thuyết minh rồi bấm Thêm phân khu.')
    pick = st.session_state.get('new_pick')
    radius = st.session_state.get('new_r') if pick else None
    clicked = _pick_map('new_zone_map', exhibits, pick=pick, radius=radius)
    if clicked and clicked != st.session_state.get('new_last'):
        st.session_state['new_last'] = clicked
        st.session_state['new_pick'] = clicked
        st.rerun()
    if pick:
        radius = _radius_slider('new_r', pick)
    else:
        st.info('Chưa chọn điểm. Hãy chạm vào bản đồ ở chỗ khách đứng xem khu mới.')
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
            if not pick:
                raise zones.ZoneError('no_point')
            new_id = zones.create_zone_at(name, description, color, pick[0], pick[1], radius)
            msgs = []
            try:
                kind, msg = _save_texts(new_id, name, description, auto)
                msgs.append(msg)
            except AudioError:
                kind = 'warning'
                msgs.append('Đã thêm khu nhưng chưa tạo được giọng đọc. Vào thẻ "Sửa / xoá phân khu" bấm Lưu thay đổi để tạo lại.')
            except Exception as text_error:      # khu đã được tạo: không báo "không lưu được" gây hiểu lầm
                logging.exception('Saving texts for new zone failed')
                kind = 'warning'
                msgs.append(f'Đã thêm khu nhưng chưa lưu được bản dịch / giọng đọc ({type(text_error).__name__}: '
                            f'{str(text_error).strip()[:300]}). Vào thẻ "Sửa / xoá phân khu" bấm Lưu thay đổi để thử lại.')
            if photos:
                try:
                    zones.add_images(new_id, [f.getvalue() for f in photos])
                except Exception as image_error:
                    logging.exception('Saving images for new zone failed')
                    kind = 'warning'
                    msgs.append(f'Chưa lưu được ảnh ({type(image_error).__name__}: {str(image_error).strip()[:300]}). '
                                'Thêm lại ảnh trong thẻ "Sửa / xoá phân khu".')
            st.session_state['new_round'] = st.session_state.get('new_round', 0) + 1
            st.session_state.pop('new_pick', None)
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
    st.code(f'{type(error).__name__}: {str(error).strip()[:800]}', language=None)


def _visitor_stats(tr):
    import datetime as dt
    import altair as alt
    try:
        default_day = tracking.today()
    except Exception:
        st.info(tr('Chưa có dữ liệu khách. Hãy chạy migration 003 (python run_migrations.py).',
                   'No visitor data yet. Run migration 003 (python run_migrations.py).'))
        return
    day = st.date_input('Xem tuần kết thúc ngày', value=default_day, key='stats_day', format='DD/MM/YYYY')
    try:
        s = tracking.summary(day)
        week = tracking.weekly_stats(day, 7)
        prev = tracking.weekly_stats(day - dt.timedelta(days=7), 7)
    except Exception:
        logging.exception('Visitor statistics failed')
        st.error('Không tải được thống kê.')
        return
    m1, m2, m3 = st.columns(3)
    m1.metric('Khách mới trong ngày', s['new_visitors'])
    m2.metric('Khách đã ghé ít nhất 1 khu', s['active_visitors'])
    m3.metric('Điểm lưu vết trong ngày', s['track_points'])

    label = lambda r: f"{r['map_no']} · {r['name']}" if r.get('map_no') is not None else r['name']
    totals, before = {}, {}
    for r in week:
        totals[label(r)] = totals.get(label(r), 0) + int(r['visitors'])
    for r in prev:
        before[label(r)] = before.get(label(r), 0) + int(r['visitors'])
    if not totals:
        st.info('Chưa có phân khu nào.')
        return
    ranked = sorted(totals, key=lambda k: (-totals[k], k))
    weekday = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']

    st.markdown('#### Lượt khách theo ngày trong tuần')
    picked = st.multiselect('Khu hiển thị trên biểu đồ', ranked, default=ranked[:5], key='stats_zones',
                            help='Mặc định là 5 khu đông nhất tuần. Thêm hoặc bớt khu để so sánh.')
    rows = [{'Ngày': f"{weekday[r['day'].weekday()]} {r['day']:%d/%m}", 'Thứ tự': r['day'].toordinal(),
             'Phân khu': label(r), 'Số khách': int(r['visitors'])} for r in week if label(r) in picked]
    if rows:
        chart = (alt.Chart(alt.Data(values=rows))
                 .mark_line(point=alt.OverlayMarkDef(size=60, filled=True), strokeWidth=2.5)
                 .encode(x=alt.X('Ngày:N', sort=alt.SortField('Thứ tự'), title=None, axis=alt.Axis(labelAngle=0)),
                         y=alt.Y('Số khách:Q', title='Số khách', axis=alt.Axis(tickMinStep=1)),
                         color=alt.Color('Phân khu:N', legend=alt.Legend(orient='bottom', columns=2, title=None)),
                         tooltip=['Ngày:N', 'Phân khu:N', 'Số khách:Q'])
                 .properties(height=360))
        st.altair_chart(chart, use_container_width=True)
    else:
        st.caption('Chọn ít nhất một khu để xem biểu đồ.')

    def change(k):
        diff = totals[k] - before.get(k, 0)
        return f'+{diff}' if diff > 0 else str(diff)
    busy, quiet = st.columns(2)
    with busy:
        st.markdown('**Đông nhất tuần**')
        st.dataframe([{'Phân khu': k, 'Lượt khách': totals[k], 'So với tuần trước': change(k)} for k in ranked[:5]],
                     hide_index=True, use_container_width=True)
    with quiet:
        st.markdown('**Vắng nhất tuần**')
        st.dataframe([{'Phân khu': k, 'Lượt khách': totals[k], 'So với tuần trước': change(k)} for k in ranked[::-1][:5]],
                     hide_index=True, use_container_width=True)
    period = 'mỗi ngày' if tracking.RESET_PERIOD == 'day' else 'mỗi tuần (thứ Hai)'
    st.caption(f'Mỗi khách được đếm 1 lần cho mỗi khu mỗi ngày. Tài khoản khách tạm tự reset {period}.')


def _qr_code(tr):
    if True:
        url = PUBLIC_URL   # địa chỉ cố định trong Secrets ([app] public_url) để không in nhầm mã QR
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
