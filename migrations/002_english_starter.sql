-- Optional starter translations derived from the original narration/config.
-- Review wording on site. Does not overwrite translations already edited by admin.
BEGIN;
INSERT INTO exhibit_translations(exhibit_id, language, name, description)
SELECT e.id, 'en', t.english_name, t.description
FROM exhibits e
JOIN (VALUES
 ('Khu Thú Ăn Thịt', 'Carnivore Zone', 'This zone cares for and conserves powerful predators such as lions, white Bengal tigers, Indochinese tigers and leopards.'),
 ('Khu Chuồng Voi', 'Elephant Enclosure', 'The elephants live in a spacious enclosure near the giraffes, beside the river.'),
 ('Khu Vực Linh Trưởng & Thú Nhỏ', 'Primates and Small Mammals Area', 'The natural home of monkeys, gibbons and many lively small mammals.'),
 ('Khu Bò Sát', 'Reptile Zone', 'Home to pythons, snakes, crocodiles and rare tropical turtles.'),
 ('Vườn Lan & Xương Rồng', 'Orchid and Cactus Garden', 'Located to the left of the main stage, this cool green garden is a popular photo spot.'),
 ('Khu Vui Chơi Giải Trí (Đu Quay)', 'Amusement Area', 'An area with thrill rides and outdoor play spaces for children.'),
 ('Khu Vui Chơi Giải Trí', 'Amusement Area', 'An area with thrill rides and outdoor play spaces for children.')
) AS t(vietnamese_name, english_name, description) ON e.name = t.vietnamese_name
ON CONFLICT(exhibit_id, language) DO NOTHING;
COMMIT;
