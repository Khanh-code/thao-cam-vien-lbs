"""Tìm khu theo Ý ĐỊNH của khách, không chỉ theo tên.

Khách có thể gõ rất tự nhiên: "ăn", "đói bụng", "mắc vệ sinh", "con nít muốn chơi",
"tôi muốn dẫn con đi xem khỉ rồi kiếm chỗ ăn trưa", gõ không dấu, sai chính tả nhẹ,
hoặc gõ tiếng Anh / tiếng Trung. Cách làm (chạy ngay trong app, không cần dịch vụ ngoài):

1. Chuẩn hoá câu: chữ thường, bỏ dấu tiếng Việt, bỏ từ đệm ("tôi", "muốn", "ở đâu"...).
2. Từ điển ý định: mỗi nhu cầu (đi vệ sinh, ăn, uống, trẻ em chơi, chụp ảnh, mỏi chân, thú lớn...)
   có nhiều cách nói (Việt, Anh, Trung) và trỏ tới các khu đáp ứng nhu cầu đó.
3. Khớp tên và thuyết minh của khu (cả ba ngôn ngữ), có chấm điểm; từ gõ sai được sửa
   bằng so khớp gần đúng (difflib).
4. Tiện ích có nhiều điểm (nhà vệ sinh, nhà ăn...) được xếp theo điểm GẦN khách nhất.
"""
import math
import re
import unicodedata
from difflib import get_close_matches


def norm(text):
    """Chữ thường, bỏ dấu tiếng Việt (đ -> d), gom khoảng trắng. Giữ nguyên chữ Hán."""
    text = (text or '').lower().replace('đ', 'd')
    text = ''.join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    return re.sub(r'\s+', ' ', re.sub(r'[^\w一-鿿]+', ' ', text)).strip()


STOP = set('''toi minh tao em anh chi ban muon can tim kiem xem coi o dau cho nao gi di den toi voi va hay
la co khong duoc nhe nha nhi a oi ah thi ma de rat qua lam may cai con nhung cac mot hai the vay roi luon
dang se da bi phai giup chi duong gan nhat khu vuc
i want to the a an where is are can see find me my please some near nearest go get how'''.split())
STOP -= {'an'}          # "ăn" sau khi bỏ dấu là "an": phải giữ lại

# (cách nói, các số khu đáp ứng theo thứ tự ưu tiên, lý do hiển thị cho khách: Việt, Anh, Trung)
# Viết CÓ DẤU: khách gõ có dấu thì so có dấu (phân biệt "hổ"/"hồ", "đền"/"đến"); gõ không dấu thì so không dấu.
INTENTS = [
    (['vệ sinh', 'nhà vệ sinh', 'đi vệ sinh', 'mắc vệ sinh', 'toilet', 'wc', 'đi tiểu', 'mắc tiểu', 'tiểu tiện', 'đi cầu',
      'rửa tay', 'restroom', 'bathroom', 'washroom', 'loo', 'lavatory', '厕所', '洗手间', '卫生间'],
     [36], ('Nhà vệ sinh', 'Toilet', '洗手间')),
    (['ăn', 'đồ ăn', 'ăn uống', 'đói', 'đói bụng', 'bụng đói', 'cơm', 'bún', 'phở', 'mì', 'nhà ăn', 'nhà hàng', 'quán ăn',
      'ăn trưa', 'ăn sáng', 'ăn tối', 'eat', 'food', 'hungry', 'lunch', 'dinner', 'breakfast', 'restaurant', 'canteen', 'meal',
      '吃', '饭', '餐', '饿', '吃饭', '餐厅'],
     [31, 29], ('Ăn uống', 'Food', '餐饮')),
    (['khát', 'uống', 'nước uống', 'giải khát', 'cafe', 'cà phê', 'trà sữa', 'kem', 'ăn vặt', 'nước mía', 'drink',
      'thirsty', 'coffee', 'water', 'snack', 'ice cream', 'juice', '渴', '喝', '饮料', '咖啡', '冰淇淋'],
     [29, 31], ('Nước uống, ăn nhẹ', 'Drinks & snacks', '饮品小吃')),
    (['trẻ em', 'trẻ con', 'con nít', 'em bé', 'bé', 'các bé', 'thiếu nhi', 'chơi', 'trò chơi', 'vui chơi', 'cầu trượt',
      'đu quay', 'kid', 'kids', 'child', 'children', 'play', 'playground', 'family', '孩子', '儿童', '小孩', '玩', '游乐'],
     [39, 38, 15, 28], ('Cho các bé', 'For kids', '适合孩子')),
    (['chơi nước', 'tắm', 'bơi', 'water park', 'splash', 'swim', '戏水', '玩水'],
     [38], ('Chơi nước', 'Water play', '戏水')),
    (['chụp ảnh', 'chụp hình', 'sống ảo', 'cảnh đẹp', 'check in', 'photo', 'picture', 'selfie', 'view', '拍照', '风景'],
     [24, 37, 42, 13, 1], ('Chụp ảnh đẹp', 'Photo spots', '拍照胜地')),
    (['nghỉ', 'nghỉ chân', 'ngồi', 'bóng mát', 'mát', 'mệt', 'nóng', 'rest', 'shade', 'sit', 'tired', 'hot', '休息', '阴凉'],
     [42, 24, 29, 4], ('Nghỉ chân, bóng mát', 'Rest & shade', '休息')),
    (['mỏi chân', 'xe điện', 'xe lửa', 'tàu', 'đi xe', 'người già', 'xe lăn', 'train', 'tram', 'shuttle', 'ride',
      'elderly', 'wheelchair', '小火车', '电瓶车', '坐车'],
     [9], ('Đi xe điện, đỡ mỏi chân', 'Tourist train', '游览车')),
    (['lịch sử', 'văn hoá', 'văn hóa', 'bảo tàng', 'cổ vật', 'di tích', 'đền', 'đền hùng', 'chùa', 'thắp hương', 'cúng',
      'tâm linh', 'museum', 'history', 'historic', 'temple', 'culture', '历史', '博物馆', '庙', '文化'],
     [10, 11, 49, 14], ('Lịch sử, văn hoá', 'History & culture', '历史文化')),
    (['hổ', 'cọp', 'sư tử', 'báo', 'thú dữ', 'thú ăn thịt', 'mèo lớn', 'tiger', 'lion', 'leopard', 'big cat', 'carnivore',
      '虎', '老虎', '狮', '狮子', '豹'],
     [19, 32, 18, 45, 5, 27], ('Thú ăn thịt', 'Big cats & carnivores', '猛兽')),
    (['khỉ', 'vượn', 'tinh tinh', 'dã nhân', 'đười ươi', 'linh trưởng', 'voọc', 'monkey', 'ape', 'gibbon', 'chimp',
      'orangutan', 'primate', 'lemur', '猴', '猩猩', '长臂猿'],
     [20, 33, 34, 23, 12, 51, 17], ('Khỉ, vượn, linh trưởng', 'Monkeys & apes', '猴与猿')),
    (['chim', 'công', 'vẹt', 'hồng hạc', 'hạc', 'sếu', 'cò', 'trĩ', 'bird', 'birds', 'parrot', 'peacock', 'flamingo',
      'crane', 'stork', '鸟', '孔雀', '鹦鹉', '火烈鸟', '鹤'],
     [22, 37, 41, 47, 52, 17], ('Các loài chim', 'Birds', '鸟类')),
    (['rắn', 'cá sấu', 'rùa', 'bò sát', 'kỳ đà', 'thằn lằn', 'snake', 'cobra', 'crocodile', 'turtle', 'tortoise', 'reptile',
      'lizard', '蛇', '鳄鱼', '龟', '爬行'],
     [6, 46, 35, 26], ('Bò sát', 'Reptiles', '爬行动物')),
    (['voi', 'elephant', '大象', '象'], [2], ('Voi', 'Elephant', '大象')),
    (['hươu cao cổ', 'cao cổ', 'giraffe', '长颈鹿'], [1, 8], ('Hươu cao cổ', 'Giraffe', '长颈鹿')),
    (['hà mã', 'hippo', 'hippopotamus', '河马'], [16], ('Hà mã', 'Hippo', '河马')),
    (['gấu', 'bear', '熊'], [30], ('Gấu', 'Bear', '熊')),
    (['rái cá', 'otter', '水獭'], [43, 17], ('Rái cá', 'Otters', '水獭')),
    (['ngựa vằn', 'tê giác', 'đà điểu', 'châu phi', 'zebra', 'rhino', 'ostrich', 'africa', 'african', '斑马', '犀牛', '鸵鸟', '非洲'],
     [7, 8], ('Động vật châu Phi', 'African animals', '非洲动物')),
    (['hươu', 'nai', 'linh dương', 'thú móng guốc', 'deer', 'antelope', '鹿', '羚羊'], [3, 7], ('Hươu nai', 'Deer & antelope', '鹿')),
    (['ngựa', 'ngựa lùn', 'pony', 'horse', '马'], [28], ('Ngựa lùn', 'Pony', '矮种马')),
    (['heo rừng', 'lợn rừng', 'boar', 'pig', '猪', '野猪'], [25], ('Heo rừng', 'Wild boar', '野猪')),
    (['hoa', 'lan', 'hoa lan', 'cây', 'cây kiểng', 'cây cảnh', 'mua cây', 'thực vật', 'orchid', 'flower', 'plant', 'garden',
      'botanic', '花', '兰', '植物'],
     [13, 42, 40, 48, 50], ('Hoa và cây xanh', 'Flowers & plants', '花草植物')),
    (['bướm', 'butterfly', '蝴蝶'], [48], ('Vườn bướm', 'Butterflies', '蝴蝶')),
    (['ếch', 'nhái', 'lưỡng cư', 'frog', 'amphibian', '蛙'], [26, 48], ('Ếch nhái', 'Frogs', '蛙类')),
    (['lúa', 'nông nghiệp', 'rau', 'ruộng', 'farm', 'rice', 'vegetable', '农业', '水稻'], [50], ('Nông nghiệp', 'Farming', '农业')),
    (['ca nhạc', 'biểu diễn', 'show', 'sự kiện', 'văn nghệ', 'concert', 'music', 'stage', '演出', '音乐', '舞台'],
     [4], ('Biểu diễn', 'Shows', '演出')),
    (['hội trường', 'hội nghị', 'lớp học', 'hall', 'meeting', '礼堂'], [21], ('Hội trường', 'Hall', '礼堂')),
]

# Nhu cầu không phải phân khu: trả lời bằng lời nhắn
NOTES = [
    (['y tế', 'bị thương', 'bị đau', 'đau bụng', 'cấp cứu', 'sơ cứu', 'thuốc', 'xỉu', 'medical', 'first aid', 'injured', 'hurt',
      'doctor', '医疗', '急救', '受伤'],
     ('Trạm y tế (dấu chữ thập đỏ trên sơ đồ) ở gần cổng chính, đường Nguyễn Bỉnh Khiêm. Cần gấp, hãy báo nhân viên gần nhất.',
      'The first-aid station (red cross on the map) is near the main gate on Nguyễn Bỉnh Khiêm street. In an emergency, ask any staff member.',
      '医疗站（地图上的红十字）在正门附近（Nguyễn Bỉnh Khiêm 街）。紧急情况请联系附近的工作人员。')),
    (['cổng', 'cổng chính', 'lối ra', 'ra về', 'gửi xe', 'bãi xe', 'exit', 'gate', 'parking', 'entrance', '出口', '大门', '停车'],
     ('Cổng chính ở đường Nguyễn Bỉnh Khiêm (đầu đường Lê Duẩn); cổng phụ ở đường Nguyễn Thị Minh Khai.',
      'The main gate is on Nguyễn Bỉnh Khiêm street (end of Lê Duẩn); a side gate is on Nguyễn Thị Minh Khai.',
      '正门在 Nguyễn Bỉnh Khiêm 街（Lê Duẩn 路尽头），侧门在 Nguyễn Thị Minh Khai 街。')),
]

# Gõ KHÔNG dấu thì các từ một tiếng này mơ hồ ("ho" = hổ/hồ, "den" = đền/đến...) -> chỉ dùng khi gõ có dấu
AMBIGUOUS = set('ho bao khi vuon cong co den mat tam tau ran rua mi be lan hoa nghi choi uong cay cao lon heo met nong nai'.split())

_VOCAB = sorted({w for phrases, *_ in INTENTS + NOTES for p in phrases for w in norm(p).split() if len(w) >= 3} - AMBIGUOUS)


def keep(text):
    """Chữ thường, giữ dấu, bỏ dấu câu."""
    text = unicodedata.normalize('NFC', (text or '').lower())
    return re.sub(r'\s+', ' ', re.sub(r'[^\w\u4e00-\u9fff]+', ' ', text)).strip()


def _phrases_in(raw, plain, phrases, accented, strict=True):
    """Cụm nào xuất hiện trong câu. accented: khách gõ có dấu -> so có dấu; không thì so không dấu (bỏ từ mơ hồ)."""
    hits = []
    for p in phrases:
        if re.search(r'[\u4e00-\u9fff]', p):
            if p in raw:
                hits.append(p)
            continue
        if accented:
            if f' {keep(p)} ' in f' {raw} ':
                hits.append(p)
        else:
            pn = norm(p)
            if pn in AMBIGUOUS and strict:
                continue
            if f' {pn} ' in f' {plain} ':
                hits.append(p)
    return hits


def _fix_typos(words):
    """Sửa từ gõ sai nhẹ theo từ điển ý định: "tolet" -> "toilet", "nha vs" giữ nguyên."""
    out = []
    for w in words:
        if len(w) >= 4 and w not in _VOCAB:
            close = get_close_matches(w, _VOCAB, n=1, cutoff=0.8)
            out.append(close[0] if close else w)
        else:
            out.append(w)
    return out


def _dist(lat1, lng1, lat2, lng2):
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    a = math.sin((p2 - p1) / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(math.radians(lng2 - lng1) / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def nearest_spot(item, lat, lng):
    """Điểm gần khách nhất của một khu (điểm chính hoặc cọc phụ) và khoảng cách (m)."""
    spots = [(item['lat'], item['lng'])] + [tuple(p) for p in (item.get('extra_pins') or [])]
    best = min(spots, key=lambda s: _dist(lat, lng, s[0], s[1]))
    return best, _dist(lat, lng, best[0], best[1])


def search(query, items, texts=None, user=None, lang='vi', limit=6, _strict=True):
    """Trả về (kết_quả, lời_nhắn). kết_quả: [(item, điểm, lý_do, khoảng_cách_m)] xếp giảm dần.
    items: các khu (có map_no, name, description, lat, lng, extra_pins).
    texts: {id: [chuỗi tên/thuyết minh ở các ngôn ngữ khác]} để khớp cả tiếng Anh, tiếng Trung."""
    li = {'vi': 0, 'en': 1, 'zh': 2}.get(lang, 0)
    q = norm(query)
    if not q:
        return [], None
    raw = keep(query)
    accented = norm(raw) != raw.replace('đ', 'd') or 'đ' in raw     # khách có gõ dấu tiếng Việt?
    words = _fix_typos([w for w in q.split() if w not in STOP])
    plain = ' '.join([q] + words)
    rwords = [w for w in raw.split() if norm(w) not in STOP] if accented else words
    by_no = {it.get('map_no'): it for it in items if it.get('map_no') is not None}
    score, reason = {}, {}
    for phrases, numbers, label in INTENTS:
        hits = _phrases_in(raw, plain, phrases, accented, _strict)
        if not hits:
            continue
        weight = 10 + 2 * max(len(h.split()) for h in hits)        # cụm dài (vd "mắc vệ sinh") đáng tin hơn
        for rank, no in enumerate(numbers):
            it = by_no.get(no)
            if it is None:
                continue
            score[it['id']] = score.get(it['id'], 0) + weight - 1.5 * rank
            reason.setdefault(it['id'], label[li])
    f = keep if accented else norm
    qn = ' '.join(rwords)
    for it in items:                                               # khớp tên + thuyết minh (cả 3 ngôn ngữ)
        name_n = f(it['name'])
        body = f(' '.join([it.get('description') or ''] + (texts or {}).get(it['id'], [])))
        s = 0.0
        if len(qn) >= 3 and qn in name_n:
            s += 9
        for w in rwords:
            cjk = re.search(r'[\u4e00-\u9fff]', w)
            if len(w) < 2 and not cjk:
                continue
            if not accented and w in AMBIGUOUS and _strict:
                continue
            if cjk:
                s += 3 if w in name_n else (1 if w in body else 0)
            elif re.search(rf'(?<!\w){re.escape(w)}(?!\w)', name_n):
                s += 3
            elif re.search(rf'(?<!\w){re.escape(w)}(?!\w)', body):
                s += 1
        if s:
            score[it['id']] = score.get(it['id'], 0) + s
    notes = [msg[li] for phrases, msg in NOTES if _phrases_in(raw, plain, phrases, accented)]
    results = []
    for it in items:
        if it['id'] not in score:
            continue
        d = nearest_spot(it, *user)[1] if user else None
        s = score[it['id']] + (max(0.0, 3 - d / 100) if d is not None else 0)   # ngang điểm: gần hơn lên trước
        results.append((it, s, reason.get(it['id']), d))
    results.sort(key=lambda r: (-r[1], r[3] if r[3] is not None else 0))
    if results:      # bỏ kết quả "ăn theo" yếu hơn hẳn kết quả tốt nhất
        top = results[0][1]
        results = [r for r in results if r[1] >= max(3.5, 0.35 * top)]
    if not results and not notes and _strict:      # gõ không dấu toàn từ mơ hồ ("ho", "khi"): thử lại nới lỏng
        return search(query, items, texts, user, lang, limit, _strict=False)
    return results[:limit], (notes[0] if notes else None)


# ===== Nhóm khu trong danh sách bên trái (theo màu đã gán cho từng khu) =====
GROUPS = [
    ('#1F5C43', ('Động vật', 'Animals', '动物')),
    ('#1565C0', ('Các loài chim', 'Birds', '鸟类')),
    ('#6D4C41', ('Bò sát, lưỡng cư', 'Reptiles & amphibians', '爬行与两栖动物')),
    ('#558B2F', ('Vườn, cây xanh', 'Gardens & plants', '园林植物')),
    ('#8E24AA', ('Di tích, bảo tàng', 'Heritage & museums', '古迹与博物馆')),
    ('#EF6C00', ('Vui chơi, biểu diễn', 'Fun & shows', '游乐与演出')),
    ('#607D8B', ('Dịch vụ, tiện ích', 'Services', '服务设施')),
]


def group_items(items, lang='vi'):
    """[(tên nhóm, [khu...])] theo thứ tự cố định; khu có màu khác xếp vào nhóm "Khác"."""
    li = {'vi': 0, 'en': 1, 'zh': 2}.get(lang, 0)
    known = {c.lower(): names[li] for c, names in GROUPS}
    buckets = {names[li]: [] for _, names in GROUPS}
    other = ('Khu khác', 'Other', '其他')[li]
    for it in items:
        buckets.setdefault(known.get((it.get('color') or '').lower(), other), []).append(it)
    return [(name, lst) for name, lst in buckets.items() if lst]
