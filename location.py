"""Vị trí thật của khách (GPS trình duyệt) — chế độ tuỳ chọn bên cạnh chế độ mô phỏng (chạm bản đồ).

- Đang ở trong / gần Thảo Cầm Viên  -> dùng vị trí GPS.
- Ở xa (ví dụ đang ở nhà, ở trường) -> báo khoảng cách và GIỮ vị trí mô phỏng, để vẫn demo / tìm đường được.
- Trình duyệt chặn quyền vị trí hoặc không có GPS -> báo lỗi, giữ vị trí mô phỏng.
"""
import math

MAX_DISTANCE_FROM_ZOO_M = 1000   # xa hơn mức này coi như đang ở ngoài Thảo Cầm Viên


def distance_m(lat1, lng1, lat2, lng2):
    """Khoảng cách đường chim bay (mét), công thức haversine."""
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def interpret(result, zoo_lat, zoo_lng):
    """Diễn giải kết quả navigator.geolocation trả về.

    Trả về dict với 'status':
      'waiting' : chưa có kết quả (trình duyệt đang hỏi quyền / đang dò vị trí)
      'error'   : bị chặn quyền hoặc lỗi; 'message'
      'outside' : ở xa vườn; 'distance_m', 'accuracy_m'
      'inside'  : dùng được; 'lat', 'lng', 'accuracy_m'
    """
    if not result:
        return {'status': 'waiting'}
    if not isinstance(result, dict) or 'coords' not in result:
        message = ''
        if isinstance(result, dict):
            err = result.get('error') or {}
            message = err.get('message', '') if isinstance(err, dict) else str(err)
        return {'status': 'error', 'message': message}
    coords = result['coords'] or {}
    try:
        lat, lng = float(coords['latitude']), float(coords['longitude'])
    except (KeyError, TypeError, ValueError):
        return {'status': 'error', 'message': 'invalid coordinates'}
    accuracy = coords.get('accuracy')
    accuracy = round(float(accuracy)) if accuracy is not None else None
    far = distance_m(lat, lng, zoo_lat, zoo_lng)
    if far > MAX_DISTANCE_FROM_ZOO_M:
        return {'status': 'outside', 'distance_m': far, 'accuracy_m': accuracy}
    return {'status': 'inside', 'lat': lat, 'lng': lng, 'accuracy_m': accuracy}
