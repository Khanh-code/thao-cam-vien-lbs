"""Tài khoản khách tạm + lưu vết lộ trình + thống kê lượt ghé (migration 003).

Luồng hoạt động:
1. Khách quét mã QR -> mở web không có tham số ?v= -> tạo tài khoản tạm (UUID) và gắn vào URL (?v=...),
   nên tải lại trang vẫn giữ đúng tài khoản.
2. Tài khoản chỉ có hiệu lực trong 1 chu kỳ (ngày hoặc tuần, cấu hình [visitor] reset_period).
   Sang chu kỳ mới, ?v= cũ hết hạn -> hệ thống tự cấp tài khoản mới (reset).
3. Mỗi lần khách đổi vị trí -> lưu 1 điểm vào visitor_tracks (lưu vết lộ trình).
4. Phân khu nào đã phát thuyết minh -> ghi vào exhibit_visits (dùng để ưu tiên và thống kê theo ngày).

Mọi hàm đều "xuống cấp nhẹ nhàng": chưa chạy migration 003 thì app vẫn chạy như cũ (không lưu vết).
"""
import uuid
from psycopg2.errors import UndefinedTable, UndefinedColumn
from config import setting
from db_services import database_cursor, active_sql

TIMEZONE = 'Asia/Ho_Chi_Minh'
RESET_PERIOD = str(setting('visitor', 'reset_period', 'day')).lower()
if RESET_PERIOD not in ('day', 'week'):
    raise ValueError('visitor.reset_period must be "day" or "week"')
# Hai phân khu có khoảng cách chênh nhau <= ngưỡng này (mét) được xem là "cùng khoảng cách"
TIE_METRES = float(setting('visitor', 'tie_metres', 5.0))

# Ngày hiện tại theo giờ Việt Nam (database Neon chạy giờ UTC)
LOCAL_TODAY = f"(now() AT TIME ZONE '{TIMEZONE}')::date"
PERIOD_START = LOCAL_TODAY if RESET_PERIOD == 'day' else f"date_trunc('week', now() AT TIME ZONE '{TIMEZONE}')::date"


def _valid_uuid(value):
    try:
        return str(uuid.UUID(str(value)))
    except (ValueError, TypeError, AttributeError):
        return None


def get_or_create_visitor(candidate_id=None):
    """Trả về id khách còn hiệu lực trong chu kỳ hiện tại; nếu không có/hết hạn thì tạo mới.
    Trả về None nếu chưa chạy migration 003."""
    candidate = _valid_uuid(candidate_id)
    try:
        with database_cursor() as cur:
            if candidate:
                cur.execute(f'''UPDATE visitors SET last_seen = now()
                                WHERE id = %s AND period_start = {PERIOD_START}
                                RETURNING id''', (candidate,))
                row = cur.fetchone()
                if row:
                    return str(row['id'])
            new_id = str(uuid.uuid4())
            cur.execute(f'INSERT INTO visitors(id, period_start) VALUES (%s, {PERIOD_START})', (new_id,))
            return new_id
    except UndefinedTable:
        return None


def record_position(visitor_id, lat, lng):
    """Lưu vết: thêm 1 điểm vị trí vào lộ trình của khách."""
    with database_cursor() as cur:
        cur.execute('''INSERT INTO visitor_tracks(visitor_id, geom)
                       VALUES (%s, ST_SetSRID(ST_MakePoint(%s, %s), 4326))''', (visitor_id, lng, lat))


def nearby_for_visitor(visitor_id, lat, lng, radius=50.0, tie_metres=None):
    """Geofencing có ngữ cảnh khách.

    - Lọc các phân khu trong bán kính bằng ST_DWithin (dùng index GiST biểu thức của migration 001).
    - Nhóm "gần nhất": các phân khu cách xa hơn phân khu gần nhất không quá tie_metres.
    - Trong nhóm đó, phân khu khách CHƯA ghé (không có trong exhibit_visits) được xếp lên trước.
    - Nếu vẫn ngang nhau (vd. cả hai đều chưa ghé): ưu tiên khu nằm BÊN PHẢI hướng khách đang đi.
      Hướng đi = ST_Azimuth từ điểm lưu vết trước đó tới vị trí hiện tại. Chưa có hướng đi
      (khách mới vào) thì coi như đang nhìn về hướng bắc -> bên phải là phía đông của bản đồ.
      right_score = sin(góc tới khu - hướng đi): > 0 là bên phải, càng gần 1 càng ở ngay bên phải.
    - Còn lại xếp theo khoảng cách tăng dần.
    """
    tie = TIE_METRES if tie_metres is None else float(tie_metres)
    active = active_sql('e.')
    query = f'''
        WITH me AS (
            SELECT ST_SetSRID(ST_MakePoint(%(lng)s, %(lat)s), 4326)::geography AS g
        ),
        previous_point AS (            -- vị trí gần nhất TRƯỚC vị trí hiện tại trong lộ trình đã lưu
            SELECT t.geom::geography AS g
            FROM visitor_tracks t, me
            WHERE t.visitor_id = %(vid)s AND NOT ST_DWithin(t.geom::geography, me.g, 1)
            ORDER BY t.recorded_at DESC, t.id DESC
            LIMIT 1
        ),
        heading AS (                   -- hướng đi (radian, tính từ hướng bắc theo chiều kim đồng hồ)
            SELECT COALESCE((SELECT ST_Azimuth(p.g, me.g) FROM previous_point p, me), 0) AS h
        ),
        candidates AS (
            SELECT e.id, e.name, e.description, e.audio_file, e.geom,
                   ROUND(COALESCE(ST_Distance(e.geom_poly::geography, me.g),
                                  ST_Distance(e.geom::geography, me.g))::numeric, 1) AS distance_meters
            FROM exhibits e, me
            WHERE {active} AND ST_DWithin(COALESCE(e.geom_poly::geography, e.geom::geography), me.g, %(radius)s)
        ),
        ranked AS (
            SELECT c.*,
                   EXISTS (SELECT 1 FROM exhibit_visits v
                           WHERE v.visitor_id = %(vid)s AND v.exhibit_id = c.id) AS visited,
                   c.distance_meters - MIN(c.distance_meters) OVER () <= %(tie)s AS in_tie_group,
                   ROUND(SIN(COALESCE(ST_Azimuth(me.g, c.geom::geography), 0) - heading.h)::numeric, 3) AS right_score
            FROM candidates c, me, heading
        )
        SELECT id, name, description, audio_file, distance_meters, visited, in_tie_group, right_score
        FROM ranked
        ORDER BY in_tie_group DESC,          -- nhóm gần nhất lên trước
                 visited ASC,                -- trong nhóm: chưa ghé trước
                 right_score DESC,           -- vẫn ngang nhau: khu bên phải hướng đi trước
                 distance_meters ASC, id ASC;
    '''
    with database_cursor() as cur:
        cur.execute(query, {'lng': lng, 'lat': lat, 'radius': radius, 'vid': visitor_id, 'tie': tie})
        return cur.fetchall()


def mark_visited(visitor_id, exhibit_id):
    """Ghi nhận MỘT LƯỢT GHÉ: mỗi lần khách đi vào vùng thuyết minh của khu (quay lại thì đếm thêm lượt)."""
    with database_cursor() as cur:
        try:
            cur.execute(f'''INSERT INTO exhibit_visits(visitor_id, exhibit_id, visit_date)
                            VALUES (%s, %s, {LOCAL_TODAY})
                            ON CONFLICT (visitor_id, exhibit_id, visit_date)
                            DO UPDATE SET visit_count = exhibit_visits.visit_count + 1, last_visited_at = now()''',
                        (visitor_id, exhibit_id))
        except UndefinedColumn:          # database chưa có cột visit_count (migration 009)
            cur.connection.rollback()
            cur.execute(f'''INSERT INTO exhibit_visits(visitor_id, exhibit_id, visit_date)
                            VALUES (%s, %s, {LOCAL_TODAY}) ON CONFLICT DO NOTHING''', (visitor_id, exhibit_id))


def _visits_expr(alias='v'):
    """Số lượt ghé: SUM(visit_count); database cũ chưa có cột -> đếm số dòng."""
    with database_cursor() as cur:
        cur.execute("""SELECT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'exhibit_visits' AND column_name = 'visit_count') AS ok""")
        has = cur.fetchone()['ok']
    return f'COALESCE(SUM({alias}.visit_count), 0)' if has else f'COUNT({alias}.visitor_id)'


def visited_ids(visitor_id):
    with database_cursor() as cur:
        cur.execute('SELECT DISTINCT exhibit_id FROM exhibit_visits WHERE visitor_id = %s', (visitor_id,))
        return {row['exhibit_id'] for row in cur.fetchall()}


def visitor_track(visitor_id):
    """Lộ trình đã đi: danh sách (lat, lng) theo thời gian."""
    with database_cursor() as cur:
        cur.execute('''SELECT ST_Y(geom) AS lat, ST_X(geom) AS lng
                       FROM visitor_tracks WHERE visitor_id = %s
                       ORDER BY recorded_at, id''', (visitor_id,))
        return [(row['lat'], row['lng']) for row in cur.fetchall()]


def track_length_metres(visitor_id):
    """Tổng quãng đường đã đi (mét) = độ dài LineString nối các điểm lưu vết."""
    with database_cursor() as cur:
        cur.execute('''SELECT COALESCE(ST_Length(ST_MakeLine(geom ORDER BY recorded_at, id)::geography), 0) AS m
                       FROM visitor_tracks WHERE visitor_id = %s''', (visitor_id,))
        return float(cur.fetchone()['m'])


def daily_stats(day):
    """Số khách (distinct) đã ghé từng phân khu trong 1 ngày. Phân khu 0 lượt vẫn hiển thị."""
    visits = _visits_expr()
    with database_cursor() as cur:
        cur.execute(f'''SELECT e.id, e.name, {visits} AS visitors
                       FROM exhibits e
                       LEFT JOIN exhibit_visits v ON v.exhibit_id = e.id AND v.visit_date = %s
                       GROUP BY e.id, e.name
                       ORDER BY visitors DESC, e.id''', (day,))
        return cur.fetchall()


def weekly_stats(end_day, days=7):
    """Số khách (distinct) mỗi ngày của từng phân khu trong `days` ngày kết thúc ở end_day.
    Trả về các dòng (id, name, map_no, day, visitors); ngày không ai ghé vẫn có dòng với 0 khách."""
    numbered = "COALESCE(e.map_no, NULL)" if _has_map_no() else "NULL::integer"
    visits = _visits_expr()
    with database_cursor() as cur:
        cur.execute(f'''WITH d AS (SELECT generate_series(%(end)s::date - (%(n)s - 1), %(end)s::date, interval '1 day')::date AS day)
                       SELECT e.id, e.name, {numbered} AS map_no, d.day, {visits} AS visitors
                       FROM exhibits e CROSS JOIN d
                       LEFT JOIN exhibit_visits v ON v.exhibit_id = e.id AND v.visit_date = d.day
                       WHERE {active_sql('e.')}
                       GROUP BY 1, 2, 3, 4
                       ORDER BY d.day, e.id''', {'end': end_day, 'n': days})
        return cur.fetchall()


def _has_map_no():
    try:
        from db_services import map_numbers
        return map_numbers()
    except Exception:
        return False


def summary(day):
    """Tổng quan 1 ngày: số tài khoản khách tạo mới, số khách có ghé ít nhất 1 phân khu, số điểm lưu vết."""
    with database_cursor() as cur:
        cur.execute(f'''SELECT
              (SELECT COUNT(*) FROM visitors
                 WHERE (created_at AT TIME ZONE '{TIMEZONE}')::date = %(d)s) AS new_visitors,
              (SELECT COUNT(DISTINCT visitor_id) FROM exhibit_visits WHERE visit_date = %(d)s) AS active_visitors,
              (SELECT {_visits_expr('x')} FROM exhibit_visits x WHERE x.visit_date = %(d)s) AS visits,
              (SELECT COUNT(*) FROM visitor_tracks
                 WHERE (recorded_at AT TIME ZONE '{TIMEZONE}')::date = %(d)s) AS track_points''', {'d': day})
        return cur.fetchone()


def today():
    with database_cursor() as cur:
        cur.execute(f'SELECT {LOCAL_TODAY} AS d')
        return cur.fetchone()['d']
