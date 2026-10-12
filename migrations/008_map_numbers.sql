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
