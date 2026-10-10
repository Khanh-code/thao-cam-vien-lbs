-- ĐỔI CÁC KHU ĐANG CÓ TỪ Ô VUÔNG VẼ TAY SANG "VÙNG NGHE THUYẾT MINH" HÌNH TRÒN
-- Neon Console -> SQL Editor -> chọn database 'neondb' -> dán TOÀN BỘ -> Run (cần đã chạy neon_update.sql trước).
-- Tâm giữ nguyên. Bán kính = bán kính tương đương diện tích ô cũ, nhưng không quá 40 m
-- và không quá nửa khoảng cách tới khu gần nhất (trừ 2 m) để hai vùng không chồng nhau; tối thiểu 10 m.
BEGIN;
UPDATE exhibits e
SET geom_poly = ST_Buffer(e.geom::geography, r.radius, 'quad_segs=16')::geometry
FROM (
    SELECT x.id,
           GREATEST(10, LEAST(40,
               sqrt(ST_Area(x.geom_poly::geography) / pi()),
               (SELECT MIN(ST_Distance(x.geom::geography, y.geom::geography)) / 2 - 2
                FROM exhibits y WHERE y.id <> x.id AND y.is_active))) AS radius
    FROM exhibits x
    WHERE x.is_active
) r
WHERE e.id = r.id;
COMMIT;
-- Kiểm tra: tên khu và bán kính vùng (mét)
SELECT name, round(sqrt(ST_Area(geom_poly::geography) / pi())) AS ban_kinh_m FROM exhibits WHERE is_active ORDER BY id;
