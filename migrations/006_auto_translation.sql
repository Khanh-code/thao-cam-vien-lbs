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
