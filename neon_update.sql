-- CẬP NHẬT NEON (chỉ phần còn thiếu: migration 004, 005, 006)
-- Neon Console -> SQL Editor -> chọn đúng database 'neondb' -> dán TOÀN BỘ file này -> Run

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

-- Kiểm tra (phải ra 2 dòng: audio_data, quality và số thuật ngữ = 23):
SELECT column_name FROM information_schema.columns WHERE table_name='exhibit_translations' AND column_name IN ('audio_data','quality');
SELECT count(*) AS so_thuat_ngu FROM glossary;
