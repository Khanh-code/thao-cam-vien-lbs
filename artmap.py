"""Sơ đồ minh hoạ chính thức của Thảo Cầm Viên làm nền bản đồ cho khách (giống bản đồ in),
trong khi mọi phép tính (định vị GPS, vùng thuyết minh, tìm đường) vẫn dùng toạ độ thật trong PostGIS.

Sơ đồ vẽ tay không đúng tỉ lệ, nên phải "nắn" (georeference): so_do_tcv.json chứa các điểm khống chế
(pixel trên sơ đồ <-> kinh/vĩ độ thật: góc đường, bờ rạch, ngã ba, hồ...). Giữa các điểm dùng nội suy
thin-plate spline, nên mỗi pixel của sơ đồ ứng với một toạ độ thật và ngược lại.
"""
import json
import math
from functools import lru_cache
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parent
CONTROL_FILE = ROOT / 'so_do_tcv.json'
IMAGE_FILE = ROOT / 'static' / 'so_do_tcv.jpg'
# Ảnh sơ đồ lấy thẳng từ repo GitHub (trình duyệt tự lưu đệm, không phải gửi ảnh mỗi lần app chạy lại).
# Streamlit Cloud chạy app dưới đường dẫn con nên địa chỉ /app/static/... không dùng được.
# Đổi nguồn ảnh: [app] map_image_url trong secrets.
try:
    from config import setting
    IMAGE_URL = setting('app', 'map_image_url',
                        'https://raw.githubusercontent.com/Khanh-code/thao-cam-vien-lbs/main/static/so_do_tcv.jpg')
except Exception:
    IMAGE_URL = 'https://raw.githubusercontent.com/Khanh-code/thao-cam-vien-lbs/main/static/so_do_tcv.jpg'
CROP_X = 495                                # ảnh đã cắt bỏ cột chú thích bên trái của bản in
WIDTH, HEIGHT = 1553, 1388

_R = 6371000.0
_LAT0, _LNG0 = 10.7880, 106.7060
_K = math.cos(math.radians(_LAT0))


def available():
    return CONTROL_FILE.exists() and IMAGE_FILE.exists()


def _to_m(lat, lng):
    """Kinh/vĩ độ -> mét (đông, bắc) quanh tâm vườn."""
    return np.c_[(np.asarray(lng, float) - _LNG0) * math.radians(1) * _R * _K,
                 (np.asarray(lat, float) - _LAT0) * math.radians(1) * _R]


def _from_m(en):
    return (_LAT0 + en[:, 1] / (math.radians(1) * _R), _LNG0 + en[:, 0] / (math.radians(1) * _R * _K))


class _TPS:
    """Thin-plate spline 2D -> 2D, đi qua đúng các điểm khống chế."""
    def __init__(self, src, dst):
        self.src = np.asarray(src, float)
        n = len(self.src)
        L = np.zeros((n + 3, n + 3))
        L[:n, :n] = self._u(self.src[:, None, :] - self.src[None, :, :])
        P = np.c_[np.ones(n), self.src]
        L[:n, n:] = P
        L[n:, :n] = P.T
        rhs = np.zeros((n + 3, 2))
        rhs[:n] = np.asarray(dst, float)
        self.coef = np.linalg.solve(L, rhs)

    @staticmethod
    def _u(d):
        r2 = (d ** 2).sum(-1)
        with np.errstate(divide='ignore', invalid='ignore'):
            out = 0.5 * r2 * np.log(r2)
        return np.nan_to_num(out)

    def __call__(self, pts):
        pts = np.atleast_2d(np.asarray(pts, float))
        n = len(self.src)
        U = self._u(pts[:, None, :] - self.src[None, :, :])
        return U @ self.coef[:n] + np.c_[np.ones(len(pts)), pts] @ self.coef[n:]


@lru_cache(maxsize=1)
def _model():
    cps = json.loads(CONTROL_FILE.read_text(encoding='utf-8'))
    px = np.array([[x - CROP_X, y] for (x, y), _ in cps], float)
    en = _to_m([ll[0] for _, ll in cps], [ll[1] for _, ll in cps])
    return _TPS(px, en), _TPS(en, px)


def to_latlng(x, y):
    """Pixel trên sơ đồ -> (lat, lng) thật."""
    fwd, _ = _model()
    lat, lng = _from_m(fwd([[x, y]]))
    return float(lat[0]), float(lng[0])


def to_art_many(points):
    """[(lat, lng), ...] -> [(x, y), ...] trên sơ đồ. Giải ngược đúng phép nắn ở trên (Newton),
    nên một khu đặt ở toạ độ thật sẽ hiện đúng chỗ số in trên sơ đồ."""
    if not points:
        return []
    fwd, inv = _model()
    target = _to_m([p[0] for p in points], [p[1] for p in points])
    guess = inv(target)
    h = 0.5
    for _ in range(4):
        f0 = fwd(guess)
        fx = (fwd(guess + [h, 0]) - f0) / h
        fy = (fwd(guess + [0, h]) - f0) / h
        err = target - f0
        det = fx[:, 0] * fy[:, 1] - fy[:, 0] * fx[:, 1]
        dx = (err[:, 0] * fy[:, 1] - fy[:, 0] * err[:, 1]) / det
        dy = (fx[:, 0] * err[:, 1] - err[:, 0] * fx[:, 1]) / det
        guess = guess + np.c_[dx, dy]
    return [(float(x), float(y)) for x, y in guess]


def to_art(lat, lng):
    return to_art_many([(lat, lng)])[0]


def leaflet(x, y):
    """Toạ độ Leaflet (CRS.Simple): trục dọc hướng lên nên đảo dấu y."""
    return [-y, x]


def from_leaflet(lat, lng):
    return lng, -lat


def metres_to_px(lat, lng, metres):
    """Đổi khoảng cách thật sang pixel sơ đồ quanh một điểm (sơ đồ co giãn khác nhau từng vùng)."""
    dlat = metres / (math.radians(1) * _R)
    dlng = metres / (math.radians(1) * _R * _K)
    (x0, y0), (x1, y1), (x2, y2) = to_art_many([(lat, lng), (lat + dlat, lng), (lat, lng + dlng)])
    return (math.hypot(x1 - x0, y1 - y0) + math.hypot(x2 - x0, y2 - y0)) / 2


def bounds():
    return [[-HEIGHT, 0], [0, WIDTH]]
