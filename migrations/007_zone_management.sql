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
