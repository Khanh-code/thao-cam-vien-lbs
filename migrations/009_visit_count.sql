-- 009: Đếm SỐ LƯỢT GHÉ mỗi khu (khách quay lại cùng khu nhiều lần thì đếm nhiều lần).
BEGIN;
ALTER TABLE exhibit_visits ADD COLUMN IF NOT EXISTS visit_count integer NOT NULL DEFAULT 1;
ALTER TABLE exhibit_visits ADD COLUMN IF NOT EXISTS last_visited_at timestamptz NOT NULL DEFAULT now();
COMMIT;
