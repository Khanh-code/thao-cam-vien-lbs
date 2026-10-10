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
