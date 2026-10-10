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
