-- CẬP NHẬT NEON: chỉ phần mới (migration 004 -> 007). Neon Console -> SQL Editor -> chọn database 'neondb' -> dán TOÀN BỘ -> Run
-- Chạy lại nhiều lần vẫn an toàn.

-- ===== 004_generated_audio.sql =====
-- 004: Thêm tiếng Trung + lưu giọng đọc do hệ thống tự tạo (gTTS) ngay trong database.
-- Admin sửa thuyết minh + bấm Lưu -> MP3 mới được lưu vào cột này (không cần upload file).
BEGIN;
ALTER TABLE exhibit_translations ADD COLUMN IF NOT EXISTS audio_data bytea;
-- Thêm tiếng Trung (zh) vào danh sách ngôn ngữ hợp lệ
ALTER TABLE exhibit_translations DROP CONSTRAINT IF EXISTS exhibit_translations_language_check;
ALTER TABLE exhibit_translations ADD CONSTRAINT exhibit_translations_language_check CHECK (language IN ('vi', 'en', 'zh'));
COMMIT;

-- ===== 005_refine_english.sql =====
-- 005: Bản dịch tiếng Anh sát nghĩa tiếng Việt hơn.
-- Chỉ cập nhật những dòng vẫn còn đúng bản dịch khởi đầu cũ (002) và chưa có giọng đọc tự tạo,
-- nên KHÔNG ghi đè nội dung admin đã sửa.
BEGIN;
UPDATE exhibit_translations t
SET name = v.new_name, description = v.new_description, audio_file = NULL, updated_at = now()
FROM exhibits e
JOIN (VALUES
 ('Khu Thú Ăn Thịt', 'Carnivore Zone', 'This zone houses carnivorous animals such as lions, Bengal white tigers, Indochinese tigers and leopards.', 'Carnivore Zone', 'This zone cares for and conserves powerful predators such as lions, white Bengal tigers, Indochinese tigers and leopards.'),
 ('Khu Vực Linh Trưởng & Thú Nhỏ', 'Primates and Small Mammals', 'This zone is home to monkeys, gibbons and active small mammals.', 'Primates and Small Mammals Area', 'The natural home of monkeys, gibbons and many lively small mammals.'),
 ('Khu Bò Sát', 'Reptile Zone', 'See pythons, snakes, crocodiles and tropical turtles in this zone.', 'Reptile Zone', 'Home to pythons, snakes, crocodiles and rare tropical turtles.'),
 ('Vườn Lan & Xương Rồng', 'Orchid and Cactus Garden', 'Located to the left of the main stage, this green garden is a popular place to take photographs.', 'Orchid and Cactus Garden', 'Located to the left of the main stage, this cool green garden is a popular photo spot.'),
 ('Khu Vui Chơi Giải Trí (Đu Quay)', 'Amusement Zone', 'This zone offers amusement rides and outdoor activities for children.', 'Amusement Area', 'An area with thrill rides and outdoor play spaces for children.'),
 ('Khu Vui Chơi Giải Trí', 'Amusement Zone', 'This zone offers amusement rides and outdoor activities for children.', 'Amusement Area', 'An area with thrill rides and outdoor play spaces for children.')
) AS v(vietnamese_name, old_name, old_description, new_name, new_description) ON e.name = v.vietnamese_name
WHERE t.exhibit_id = e.id AND t.language = 'en'
  AND t.name = v.old_name AND t.description = v.old_description
  AND t.audio_data IS NULL;
COMMIT;

-- ===== 006_auto_translation.sql =====
-- 006: Tự dịch Việt -> Anh/Trung có kiểm tra bằng dịch ngược + bảng thuật ngữ cố định.
BEGIN;
-- Kết quả kiểm tra bản dịch máy (hiển thị cho admin duyệt)
ALTER TABLE exhibit_translations ADD COLUMN IF NOT EXISTS machine_translated boolean NOT NULL DEFAULT false;
ALTER TABLE exhibit_translations ADD COLUMN IF NOT EXISTS back_translation text;   -- dịch ngược về tiếng Việt
ALTER TABLE exhibit_translations ADD COLUMN IF NOT EXISTS quality real;            -- độ khớp 0..1

-- Bảng thuật ngữ: tên riêng / tên loài / tên khu luôn dịch đúng theo bảng này
CREATE TABLE IF NOT EXISTS glossary (
    vi text PRIMARY KEY CHECK (length(trim(vi)) > 0),
    en text NOT NULL CHECK (length(trim(en)) > 0),
    zh text NOT NULL CHECK (length(trim(zh)) > 0)
);
INSERT INTO glossary(vi, en, zh) VALUES
 ('Thảo Cầm Viên Sài Gòn', 'Saigon Zoo and Botanical Gardens (Thảo Cầm Viên)', '西贡动植物园（Thảo Cầm Viên）'),
 ('Thảo Cầm Viên', 'Saigon Zoo and Botanical Gardens (Thảo Cầm Viên)', '西贡动植物园（Thảo Cầm Viên）'),
 ('Sài Gòn', 'Saigon', '西贡'),
 ('Việt Nam', 'Vietnam', '越南'),
 ('Khu Thú Ăn Thịt', 'Carnivore Zone', '食肉动物区'),
 ('Khu Chuồng Voi', 'Elephant Enclosure', '大象馆'),
 ('Khu Vực Linh Trưởng & Thú Nhỏ', 'Primates and Small Mammals Area', '灵长类与小型动物区'),
 ('Khu Bò Sát', 'Reptile Zone', '爬行动物区'),
 ('Vườn Lan & Xương Rồng', 'Orchid and Cactus Garden', '兰花与仙人掌园'),
 ('Khu Vui Chơi Giải Trí (Đu Quay)', 'Amusement Area', '游乐区'),
 ('Khu Vui Chơi Giải Trí', 'Amusement Area', '游乐区'),
 ('hổ trắng Bengal', 'white Bengal tigers', '孟加拉白虎'),
 ('hổ Đông Dương', 'Indochinese tigers', '印度支那虎'),
 ('báo hoa mai', 'leopards', '花豹'),
 ('sư tử', 'lions', '狮子'),
 ('hươu cao cổ', 'giraffes', '长颈鹿'),
 ('linh trưởng', 'primates', '灵长类动物'),
 ('vượn', 'gibbons', '长臂猿'),
 ('trăn', 'pythons', '蟒蛇'),
 ('cá sấu', 'crocodiles', '鳄鱼'),
 ('bò sát', 'reptiles', '爬行动物'),
 ('xương rồng', 'cacti', '仙人掌'),
 ('đu quay', 'Ferris wheel', '摩天轮')
ON CONFLICT (vi) DO NOTHING;
COMMIT;

-- ===== 007_zone_management.sql =====
-- 007: Admin thêm / sửa / xoá phân khu.
BEGIN;
-- Xoá = ẩn khỏi khách (is_active = false); dữ liệu cũ và thống kê lượt ghé vẫn được giữ.
ALTER TABLE exhibits ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true;
-- Màu của khu trên bản đồ (trước đây cố định trong config.py theo tên khu)
ALTER TABLE exhibits ADD COLUMN IF NOT EXISTS color text;
UPDATE exhibits SET color = CASE name
    WHEN 'Khu Thú Ăn Thịt' THEN '#e74c3c'
    WHEN 'Khu Chuồng Voi' THEN '#8e44ad'
    WHEN 'Khu Vực Linh Trưởng & Thú Nhỏ' THEN '#e67e22'
    WHEN 'Khu Bò Sát' THEN '#27ae60'
    WHEN 'Vườn Lan & Xương Rồng' THEN '#2ecc71'
    WHEN 'Khu Vui Chơi Giải Trí (Đu Quay)' THEN '#3498db'
    WHEN 'Khu Vui Chơi Giải Trí' THEN '#3498db'
    ELSE '#1F5C43' END
WHERE color IS NULL;
CREATE INDEX IF NOT EXISTS idx_exhibits_geom_poly ON exhibits USING gist (geom_poly);

-- Ảnh admin tải lên (lưu trong database vì Streamlit Cloud xoá file tạo lúc chạy khi khởi động lại)
CREATE TABLE IF NOT EXISTS exhibit_images (
    id          serial PRIMARY KEY,
    exhibit_id  integer NOT NULL REFERENCES exhibits(id) ON DELETE CASCADE,
    data        bytea   NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_exhibit_images_exhibit ON exhibit_images(exhibit_id, id);
COMMIT;

-- Kiểm tra: phải ra is_active, color và bảng exhibit_images
SELECT column_name FROM information_schema.columns WHERE table_name='exhibits' AND column_name IN ('is_active','color');
SELECT to_regclass('public.exhibit_images') AS bang_anh;

-- ===== 008_map_numbers.sql =====
-- 008: Số hiệu phân khu theo bản đồ chính thức "Khám phá Thảo Cầm Viên" + các cọc phụ.
-- map_no: số in trên bản đồ (1..52), hiện trên cọc đỏ. Một số khu có nhiều điểm (nhà vệ sinh 36, nhà ăn 31...):
-- điểm chính nằm ở exhibits.geom, các điểm còn lại lưu ở exhibit_pins (chỉ để hiển thị, không phát thuyết minh).
BEGIN;
ALTER TABLE exhibits ADD COLUMN IF NOT EXISTS map_no integer;
CREATE TABLE IF NOT EXISTS exhibit_pins (
    id          serial PRIMARY KEY,
    exhibit_id  integer NOT NULL REFERENCES exhibits(id) ON DELETE CASCADE,
    geom        geometry(Point, 4326) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_exhibit_pins_exhibit ON exhibit_pins(exhibit_id);
COMMIT;

-- ===== 009_visit_count.sql =====
-- 009: Đếm SỐ LƯỢT GHÉ mỗi khu (khách quay lại cùng khu nhiều lần thì đếm nhiều lần).
BEGIN;
ALTER TABLE exhibit_visits ADD COLUMN IF NOT EXISTS visit_count integer NOT NULL DEFAULT 1;
ALTER TABLE exhibit_visits ADD COLUMN IF NOT EXISTS last_visited_at timestamptz NOT NULL DEFAULT now();
COMMIT;
