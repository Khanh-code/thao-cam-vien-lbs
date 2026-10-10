-- DÁN TOÀN BỘ FILE NÀY VÀO Neon Console -> SQL Editor -> Run (chạy lại nhiều lần vẫn an toàn)
-- Gộp migrations/001, 002, 003: bản dịch Việt/Anh, index GiST, admin (admin/123456), khách tạm & lưu vết

-- ===== 001_multilingual.sql =====
BEGIN;
CREATE TABLE IF NOT EXISTS exhibit_translations (
    exhibit_id integer NOT NULL REFERENCES exhibits(id) ON DELETE CASCADE,
    language text NOT NULL CHECK(language IN ('vi', 'en')),
    name text NOT NULL CHECK(length(trim(name)) > 0),
    description text NOT NULL CHECK(length(trim(description)) > 0),
    audio_file text,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY(exhibit_id, language)
);
CREATE INDEX IF NOT EXISTS idx_exhibits_detection_geog
ON exhibits USING gist ((COALESCE(geom_poly::geography, geom::geography)));
COMMIT;

-- ===== 002_english_starter.sql =====
-- Optional starter translations derived from the original narration/config.
-- Review wording on site. Does not overwrite translations already edited by admin.
BEGIN;
INSERT INTO exhibit_translations(exhibit_id, language, name, description)
SELECT e.id, 'en', t.english_name, t.description
FROM exhibits e
JOIN (VALUES
 ('Khu Thú Ăn Thịt', 'Carnivore Zone', 'This zone houses carnivorous animals such as lions, Bengal white tigers, Indochinese tigers and leopards.'),
 ('Khu Chuồng Voi', 'Elephant Enclosure', 'The elephants live in a spacious enclosure near the giraffes, beside the river.'),
 ('Khu Vực Linh Trưởng & Thú Nhỏ', 'Primates and Small Mammals', 'This zone is home to monkeys, gibbons and active small mammals.'),
 ('Khu Bò Sát', 'Reptile Zone', 'See pythons, snakes, crocodiles and tropical turtles in this zone.'),
 ('Vườn Lan & Xương Rồng', 'Orchid and Cactus Garden', 'Located to the left of the main stage, this green garden is a popular place to take photographs.'),
 ('Khu Vui Chơi Giải Trí (Đu Quay)', 'Amusement Zone', 'This zone offers amusement rides and outdoor activities for children.'),
 ('Khu Vui Chơi Giải Trí', 'Amusement Zone', 'This zone offers amusement rides and outdoor activities for children.')
) AS t(vietnamese_name, english_name, description) ON e.name = t.vietnamese_name
ON CONFLICT(exhibit_id, language) DO NOTHING;
COMMIT;

-- ===== 003_admin_and_visitors.sql =====
-- 003: Tài khoản admin trong database + tài khoản khách tạm (lưu vết lộ trình, thống kê lượt ghé).
-- Chạy lại nhiều lần vẫn an toàn (IF NOT EXISTS / ON CONFLICT DO NOTHING).
BEGIN;

-- ===== 1. Admin =====
CREATE TABLE IF NOT EXISTS admin_users (
    username      text PRIMARY KEY,
    password_hash text NOT NULL,
    updated_at    timestamptz NOT NULL DEFAULT now()
);
-- Tài khoản mặc định: admin / 123456 (hash PBKDF2-SHA256). Không ghi đè nếu admin đã đổi mật khẩu.
INSERT INTO admin_users(username, password_hash)
VALUES ('admin', 'pbkdf2_sha256$600000$gtuVnszT84s7bFHnIEn8aw==$NV6qOaXLSGQ3w6kq41AgyLaUqj3LJpnJ4uvu9V8Rntw=')
ON CONFLICT (username) DO NOTHING;

-- ===== 2. Khách tạm (mỗi lần quét QR -> 1 tài khoản, hết hạn theo ngày/tuần) =====
CREATE TABLE IF NOT EXISTS visitors (
    id           uuid PRIMARY KEY,
    period_start date NOT NULL,              -- ngày bắt đầu chu kỳ (ngày hoặc thứ Hai đầu tuần)
    created_at   timestamptz NOT NULL DEFAULT now(),
    last_seen    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_visitors_period ON visitors(period_start);

-- Lưu vết: mỗi lần khách đổi vị trí -> 1 điểm
CREATE TABLE IF NOT EXISTS visitor_tracks (
    id          bigserial PRIMARY KEY,
    visitor_id  uuid NOT NULL REFERENCES visitors(id) ON DELETE CASCADE,
    geom        geometry(Point, 4326) NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_visitor_tracks_visitor_time ON visitor_tracks(visitor_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_visitor_tracks_geom ON visitor_tracks USING gist(geom);

-- Phân khu khách đã được thuyết minh (1 dòng / khách / phân khu / ngày) -> dùng cho ưu tiên & thống kê
CREATE TABLE IF NOT EXISTS exhibit_visits (
    visitor_id       uuid    NOT NULL REFERENCES visitors(id) ON DELETE CASCADE,
    exhibit_id       integer NOT NULL REFERENCES exhibits(id) ON DELETE CASCADE,
    visit_date       date    NOT NULL,
    first_visited_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (visitor_id, exhibit_id, visit_date)
);
CREATE INDEX IF NOT EXISTS idx_exhibit_visits_date ON exhibit_visits(visit_date, exhibit_id);

COMMIT;

-- Kiểm tra:
SELECT username FROM admin_users;
