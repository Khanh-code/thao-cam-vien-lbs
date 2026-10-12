"""Tìm khu theo ý định: câu tự nhiên, không dấu, sai chính tả, tiếng Anh / Trung, tiện ích gần nhất."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import search

def zone(no, name, desc='', lat=10.788, lng=106.706, extra=None, color='#1F5C43'):
    return {'id': no, 'map_no': no, 'name': name, 'description': desc, 'lat': lat, 'lng': lng, 'extra_pins': extra or [], 'color': color}

ITEMS = [zone(1, 'Hươu cao cổ', 'Hươu cao cổ là loài động vật cao nhất trên cạn.'),
         zone(2, 'Voi'), zone(19, 'Hổ trắng'), zone(20, 'Vượn'), zone(24, 'Đảo hồ sen'), zone(11, 'Đền Hùng'),
         zone(29, 'Quán giải khát'), zone(31, 'Nhà ăn'), zone(39, 'Khu vui chơi thiếu nhi'), zone(38, 'Sân chơi nước'),
         zone(36, 'Nhà vệ sinh', lat=10.790, lng=106.708, extra=[[10.7881, 106.7061]]), zone(9, 'Trạm xe điện, xe lửa')]

def top(q, **kw):
    found, note = search.search(q, ITEMS, **kw)
    return [it['map_no'] for it, *_ in found], note

def test_needs_in_everyday_words():
    assert top('mắc vệ sinh')[0][0] == 36
    assert top('toi muon di ve sinh')[0][0] == 36          # không dấu
    assert top('tolet')[0][0] == 36                        # gõ sai chính tả
    assert top('厕所')[0][0] == 36 and top('where is the restroom')[0][0] == 36
    assert top('ăn')[0][:2] == [31, 29] and top('đói bụng quá')[0][0] == 31
    assert top('khát nước')[0][0] == 29
    assert top('mỏi chân quá')[0][0] == 9

def test_long_sentence_returns_every_need():
    found = top('tôi muốn dẫn con đi xem mấy con khỉ rồi kiếm chỗ ăn trưa')[0]
    assert 31 in found and 20 in found

def test_accents_tell_apart_similar_words():
    assert top('con hổ')[0][0] == 19 and top('hồ sen')[0][0] == 24
    assert top('đền hùng')[0][0] == 11 and top('den hung')[0][0] == 11
    assert top('ho')[0]                                   # không dấu, mơ hồ: vẫn có gợi ý

def test_nearest_spot_for_amenities():
    user = (10.7881, 106.7060)                            # đứng sát cọc phụ của nhà vệ sinh
    found, _ = search.search('nhà vệ sinh', ITEMS, user=user)
    item, _, _, dist = found[0]
    assert item['map_no'] == 36 and dist < 20
    spot, d = search.nearest_spot(item, *user)
    assert spot == (10.7881, 106.7061)

def test_notes_and_nothing_found():
    assert top('bị đau bụng')[1] and top('cổng ra ở đâu')[1]
    assert top('abcxyz') == ([], None)

def test_groups():
    groups = dict(search.group_items(ITEMS + [zone(77, 'Khu mới', color='#123456')]))
    assert 'Động vật' in groups and 'Khu khác' in groups
