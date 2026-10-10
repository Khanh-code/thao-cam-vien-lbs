-- 004: Thêm tiếng Trung + lưu giọng đọc do hệ thống tự tạo (gTTS) ngay trong database.
-- Admin sửa thuyết minh + bấm Lưu -> MP3 mới được lưu vào cột này (không cần upload file).
BEGIN;
ALTER TABLE exhibit_translations ADD COLUMN IF NOT EXISTS audio_data bytea;
-- Thêm tiếng Trung (zh) vào danh sách ngôn ngữ hợp lệ
ALTER TABLE exhibit_translations DROP CONSTRAINT IF EXISTS exhibit_translations_language_check;
ALTER TABLE exhibit_translations ADD CONSTRAINT exhibit_translations_language_check CHECK (language IN ('vi', 'en', 'zh'));
COMMIT;
