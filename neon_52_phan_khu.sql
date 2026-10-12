-- NẠP 52 PHÂN KHU THEO BẢN ĐỒ "KHÁM PHÁ THẢO CẦM VIÊN SÀI GÒN"
-- Neon Console -> SQL Editor -> chọn database 'neondb' -> dán TOÀN BỘ file -> Run. Chạy lại nhiều lần vẫn an toàn.
-- Việc file này làm:
--   1. Thêm cột số hiệu map_no + bảng exhibit_pins (migration 008).
--   2. ẨN (không xoá) các khu cũ chưa có số hiệu. Thống kê lượt ghé cũ vẫn giữ. Muốn hiện lại: UPDATE exhibits SET is_active = true WHERE id = ...;
--   3. Thêm / cập nhật 52 khu (id 1001..1052), vùng nghe thuyết minh hình tròn, kèm thuyết minh Việt - Anh - Trung.
--   4. Thêm các cọc phụ cho khu có nhiều điểm (nhà vệ sinh 36, nhà ăn 31, quán giải khát 29, khu vui chơi 39, bò sát 6, vượn 20).
-- Tọa độ được tính bằng cách căn bản đồ minh hoạ theo mạng lối đi OpenStreetMap (sai lệch thường khoảng 10-30 m).
-- Admin chỉnh lại từng khu trong "Quản lý phân khu" -> "Đổi vị trí vùng nghe thuyết minh".
BEGIN;
ALTER TABLE exhibits ADD COLUMN IF NOT EXISTS map_no integer;
CREATE TABLE IF NOT EXISTS exhibit_pins (
    id          serial PRIMARY KEY,
    exhibit_id  integer NOT NULL REFERENCES exhibits(id) ON DELETE CASCADE,
    geom        geometry(Point, 4326) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_exhibit_pins_exhibit ON exhibit_pins(exhibit_id);

UPDATE exhibits SET is_active = false WHERE is_active AND map_no IS NULL;

INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1001, 1, 'Hươu cao cổ', 'Hươu cao cổ là loài động vật cao nhất trên cạn, con đực có thể cao gần 6 mét. Chiếc lưỡi dài khoảng nửa mét giúp chúng tuốt lá trên những cành cây cao. Mỗi con có bộ hoa văn trên lông riêng, không con nào giống con nào.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.708338, 10.788138), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.708338, 10.788138), 4326)::geography, 24.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1001, 'vi', 'Hươu cao cổ', 'Hươu cao cổ là loài động vật cao nhất trên cạn, con đực có thể cao gần 6 mét. Chiếc lưỡi dài khoảng nửa mét giúp chúng tuốt lá trên những cành cây cao. Mỗi con có bộ hoa văn trên lông riêng, không con nào giống con nào.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1001, 'en', 'Giraffe', 'The giraffe is the tallest land animal; males can reach almost six metres. Its tongue, about half a metre long, strips leaves from high branches. Every giraffe has its own coat pattern, and no two are alike.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1001, 'zh', '长颈鹿', '长颈鹿是陆地上最高的动物，雄性身高可接近六米。它约半米长的舌头能卷下高处树枝上的叶子。每只长颈鹿的斑纹都独一无二。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1002, 2, 'Voi', 'Voi là loài thú trên cạn lớn nhất. Chiếc vòi vừa là mũi vừa là tay, dùng để thở, ngửi, uống nước và nhặt thức ăn. Voi sống theo đàn, có trí nhớ tốt và rất gắn bó với nhau.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707804, 10.788383), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707804, 10.788383), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1002, 'vi', 'Voi', 'Voi là loài thú trên cạn lớn nhất. Chiếc vòi vừa là mũi vừa là tay, dùng để thở, ngửi, uống nước và nhặt thức ăn. Voi sống theo đàn, có trí nhớ tốt và rất gắn bó với nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1002, 'en', 'Elephant', 'Elephants are the largest land mammals. The trunk works as both nose and hand: for breathing, smelling, drinking and picking up food. Elephants live in herds, have excellent memories and form strong bonds.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1002, 'zh', '大象', '大象是陆地上最大的哺乳动物。象鼻既是鼻子也是手，可用来呼吸、闻气味、喝水和取食。大象群居生活，记忆力强，彼此感情深厚。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1003, 3, 'Khu thú móng guốc', 'Khu này nuôi các loài thú ăn cỏ có móng guốc như hươu, nai và linh dương. Móng guốc cứng giúp chúng chạy nhanh trên nền đất cứng. Hãy quan sát cặp sừng của con đực, mỗi loài có một kiểu sừng khác nhau.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707012, 10.789363), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707012, 10.789363), 4326)::geography, 15.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1003, 'vi', 'Khu thú móng guốc', 'Khu này nuôi các loài thú ăn cỏ có móng guốc như hươu, nai và linh dương. Móng guốc cứng giúp chúng chạy nhanh trên nền đất cứng. Hãy quan sát cặp sừng của con đực, mỗi loài có một kiểu sừng khác nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1003, 'en', 'Herbivores (hoofed animals)', 'This area houses hoofed plant-eaters such as deer and antelope. Hard hooves let them run fast on firm ground. Look at the males'' antlers and horns: each species has its own shape.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1003, 'zh', '有蹄类动物区', '这里饲养鹿、羚羊等食草有蹄类动物。坚硬的蹄子让它们能在坚实的地面上快速奔跑。请留意雄性的角，每个物种的角形状都不一样。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1004, 4, 'Sân khấu ca nhạc', 'Sân khấu ca nhạc là nơi tổ chức các chương trình biểu diễn và sự kiện vào dịp lễ, cuối tuần. Đây cũng là điểm hẹn dễ tìm nếu bạn đi theo nhóm và lạc nhau.', '#EF6C00', true, ST_SetSRID(ST_MakePoint(106.706846, 10.788585), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706846, 10.788585), 4326)::geography, 24.9, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1004, 'vi', 'Sân khấu ca nhạc', 'Sân khấu ca nhạc là nơi tổ chức các chương trình biểu diễn và sự kiện vào dịp lễ, cuối tuần. Đây cũng là điểm hẹn dễ tìm nếu bạn đi theo nhóm và lạc nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1004, 'en', 'Music stage', 'The music stage hosts performances and events on holidays and weekends. It is also an easy meeting point if your group gets separated.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1004, 'zh', '音乐舞台', '音乐舞台在节假日和周末举办演出与活动。如果同行的人走散了，这里也是一个容易找到的集合点。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1005, 5, 'Khu thú ăn thịt nhỏ', 'Khu này giới thiệu các loài thú ăn thịt cỡ nhỏ như cầy, chồn và mèo rừng. Phần lớn chúng hoạt động mạnh vào lúc chiều tối và ban đêm. Dù nhỏ, chúng là những thợ săn nhanh nhẹn, giúp kiểm soát chuột và côn trùng trong tự nhiên.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.70644, 10.789421), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.70644, 10.789421), 4326)::geography, 14.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1005, 'vi', 'Khu thú ăn thịt nhỏ', 'Khu này giới thiệu các loài thú ăn thịt cỡ nhỏ như cầy, chồn và mèo rừng. Phần lớn chúng hoạt động mạnh vào lúc chiều tối và ban đêm. Dù nhỏ, chúng là những thợ săn nhanh nhẹn, giúp kiểm soát chuột và côn trùng trong tự nhiên.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1005, 'en', 'Small carnivores', 'This area features small carnivores such as civets, weasels and wild cats. Most are active at dusk and at night. Though small, they are agile hunters that help control rodents and insects in the wild.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1005, 'zh', '小型食肉动物区', '这里展示灵猫、鼬和野猫等小型食肉动物。它们大多在黄昏和夜间活动。体型虽小，却是敏捷的猎手，在野外能帮助控制鼠类和昆虫的数量。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1006, 6, 'Khu bò sát', 'Khu bò sát có rắn, rùa, kỳ đà và nhiều loài khác. Bò sát là động vật biến nhiệt nên thường nằm phơi nắng để làm ấm cơ thể. Lớp da có vảy giúp chúng giữ nước và bảo vệ cơ thể.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.706012, 10.790054), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706012, 10.790054), 4326)::geography, 19.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1006, 'vi', 'Khu bò sát', 'Khu bò sát có rắn, rùa, kỳ đà và nhiều loài khác. Bò sát là động vật biến nhiệt nên thường nằm phơi nắng để làm ấm cơ thể. Lớp da có vảy giúp chúng giữ nước và bảo vệ cơ thể.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1006, 'en', 'Reptiles', 'The reptile area has snakes, turtles, monitor lizards and more. Reptiles are cold-blooded, so they often bask in the sun to warm up. Their scaly skin keeps in moisture and protects the body.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1006, 'zh', '爬行动物区', '爬行动物区有蛇、龟、巨蜥等多种动物。爬行动物是变温动物，常常晒太阳来暖和身体。它们带鳞片的皮肤能保持水分并保护身体。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1007, 7, 'Động vật châu Phi: tê giác, đà điểu, linh dương', 'Khu động vật châu Phi có tê giác trắng, đà điểu và linh dương. Tê giác trắng là một trong những loài tê giác lớn nhất và đang bị đe dọa do nạn săn trộm lấy sừng. Đà điểu là loài chim lớn nhất thế giới, không bay được nhưng chạy rất nhanh.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.705544, 10.788831), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.705544, 10.788831), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1007, 'vi', 'Động vật châu Phi: tê giác, đà điểu, linh dương', 'Khu động vật châu Phi có tê giác trắng, đà điểu và linh dương. Tê giác trắng là một trong những loài tê giác lớn nhất và đang bị đe dọa do nạn săn trộm lấy sừng. Đà điểu là loài chim lớn nhất thế giới, không bay được nhưng chạy rất nhanh.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1007, 'en', 'African animals: white rhino, ostrich, antelope', 'The African area has white rhinos, ostriches and antelope. The white rhino is one of the largest rhino species and is threatened by poaching for its horn. The ostrich is the world''s largest bird; it cannot fly but runs very fast.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1007, 'zh', '非洲动物：白犀牛、鸵鸟、羚羊', '非洲动物区有白犀牛、鸵鸟和羚羊。白犀牛是体型最大的犀牛之一，因犀角遭盗猎而受到威胁。鸵鸟是世界上最大的鸟，不会飞，但跑得非常快。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1008, 8, 'Hươu cao cổ, đà điểu, ngựa vằn', 'Khu này mô phỏng đồng cỏ châu Phi với hươu cao cổ, đà điểu và ngựa vằn. Ngoài tự nhiên, ba loài này thường sống gần nhau: hươu cao cổ đứng cao nhìn xa, giúp cả nhóm sớm phát hiện thú săn mồi. Sọc của mỗi con ngựa vằn là duy nhất, như dấu vân tay.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.704942, 10.78833), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.704942, 10.78833), 4326)::geography, 21.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1008, 'vi', 'Hươu cao cổ, đà điểu, ngựa vằn', 'Khu này mô phỏng đồng cỏ châu Phi với hươu cao cổ, đà điểu và ngựa vằn. Ngoài tự nhiên, ba loài này thường sống gần nhau: hươu cao cổ đứng cao nhìn xa, giúp cả nhóm sớm phát hiện thú săn mồi. Sọc của mỗi con ngựa vằn là duy nhất, như dấu vân tay.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1008, 'en', 'Giraffe, ostrich, zebra', 'This area recreates the African savanna with giraffes, ostriches and zebras. In the wild these species often graze near each other, and tall giraffes spot predators early. Each zebra''s stripes are unique, like a fingerprint.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1008, 'zh', '长颈鹿、鸵鸟、斑马', '这里模拟非洲草原，有长颈鹿、鸵鸟和斑马。在野外，这三种动物常常生活在一起：长颈鹿站得高、看得远，能及早发现捕食者。每匹斑马的条纹都独一无二，就像指纹一样。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1009, 9, 'Trạm xe điện, xe lửa', 'Đây là trạm xe điện và xe lửa tham quan. Tuyến xe chạy vòng quanh vườn theo đường kẻ đỏ trên bản đồ, phù hợp với người lớn tuổi và gia đình có trẻ nhỏ.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.705493, 10.787709), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.705493, 10.787709), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1009, 'vi', 'Trạm xe điện, xe lửa', 'Đây là trạm xe điện và xe lửa tham quan. Tuyến xe chạy vòng quanh vườn theo đường kẻ đỏ trên bản đồ, phù hợp với người lớn tuổi và gia đình có trẻ nhỏ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1009, 'en', 'Tourist train station', 'This is the tourist train and electric car station. The route circles the park along the red line on the map, which suits older visitors and families with young children.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1009, 'zh', '游览车站', '这里是游览电瓶车和小火车站。线路沿地图上的红线环绕园区，适合老人和带小孩的家庭。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1010, 10, 'Bảo tàng', 'Bảo tàng Lịch sử Việt Nam Thành phố Hồ Chí Minh nằm cạnh cổng chính. Tòa nhà được xây vào cuối thập niên 1920, mang phong cách kiến trúc Á Đông. Bảo tàng trưng bày hiện vật về lịch sử và văn hóa Việt Nam qua nhiều thời kỳ.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.704671, 10.788017), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.704671, 10.788017), 4326)::geography, 21.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1010, 'vi', 'Bảo tàng', 'Bảo tàng Lịch sử Việt Nam Thành phố Hồ Chí Minh nằm cạnh cổng chính. Tòa nhà được xây vào cuối thập niên 1920, mang phong cách kiến trúc Á Đông. Bảo tàng trưng bày hiện vật về lịch sử và văn hóa Việt Nam qua nhiều thời kỳ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1010, 'en', 'Museum of Vietnamese History', 'The Museum of Vietnamese History, Ho Chi Minh City, stands next to the main gate. The building dates from the late 1920s and has an Asian architectural style. It displays artefacts of Vietnamese history and culture across many periods.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1010, 'zh', '越南历史博物馆', '胡志明市越南历史博物馆位于正门旁。建筑建于二十世纪二十年代末，具有东方建筑风格。馆内展出越南各个时期的历史文化文物。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1011, 11, 'Đền Hùng', 'Đền Hùng trong Thảo Cầm Viên là nơi tưởng niệm các Vua Hùng, những vị vua dựng nước theo truyền thuyết của người Việt. Vào ngày Giỗ Tổ Hùng Vương mùng 10 tháng 3 âm lịch, nơi đây thường có lễ dâng hương.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.706004, 10.787015), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706004, 10.787015), 4326)::geography, 14.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1011, 'vi', 'Đền Hùng', 'Đền Hùng trong Thảo Cầm Viên là nơi tưởng niệm các Vua Hùng, những vị vua dựng nước theo truyền thuyết của người Việt. Vào ngày Giỗ Tổ Hùng Vương mùng 10 tháng 3 âm lịch, nơi đây thường có lễ dâng hương.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1011, 'en', 'Hung Kings Temple', 'The Hung Kings Temple honours the Hung Kings, the legendary founders of the Vietnamese nation. On the Hung Kings Commemoration Day, the 10th day of the 3rd lunar month, incense-offering ceremonies are usually held here.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1011, 'zh', '雄王庙', '园内的雄王庙供奉雄王，即越南传说中的建国先王。每年农历三月初十雄王祭祖日，这里通常会举行上香仪式。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1012, 12, 'Voọc bạc, Nhím', 'Voọc bạc có bộ lông xám bạc, còn con non mới sinh lại có màu cam sáng. Chúng ăn lá cây là chủ yếu. Bên cạnh là nhím, loài gặm nhấm có bộ lông gai sắc để tự vệ, khi gặp nguy hiểm sẽ dựng gai và lùi về phía kẻ thù.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7072, 10.787672), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7072, 10.787672), 4326)::geography, 18.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1012, 'vi', 'Voọc bạc, Nhím', 'Voọc bạc có bộ lông xám bạc, còn con non mới sinh lại có màu cam sáng. Chúng ăn lá cây là chủ yếu. Bên cạnh là nhím, loài gặm nhấm có bộ lông gai sắc để tự vệ, khi gặp nguy hiểm sẽ dựng gai và lùi về phía kẻ thù.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1012, 'en', 'Silvered leaf monkey, porcupine', 'The silvered leaf monkey has silver-grey fur, while newborns are bright orange. It feeds mainly on leaves. Next door is the porcupine, a rodent with sharp quills for defence; when threatened it raises them and backs into its enemy.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1012, 'zh', '银叶猴、豪猪', '银叶猴毛色银灰，而刚出生的幼崽却是亮橙色。它们主要以树叶为食。旁边是豪猪，一种长着锋利棘刺的啮齿动物；遇到危险时，它会竖起棘刺，倒退着冲向敌人。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1013, 13, 'Khu sưu tập hoa lan cây kiểng', 'Khu sưu tập hoa lan và cây kiểng trưng bày nhiều loài lan cùng các chậu cây cảnh được tạo dáng công phu. Thảo Cầm Viên ban đầu được xây dựng như một vườn thực vật, nên cây xanh luôn là phần quan trọng của nơi này.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.707292, 10.787342), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707292, 10.787342), 4326)::geography, 18.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1013, 'vi', 'Khu sưu tập hoa lan cây kiểng', 'Khu sưu tập hoa lan và cây kiểng trưng bày nhiều loài lan cùng các chậu cây cảnh được tạo dáng công phu. Thảo Cầm Viên ban đầu được xây dựng như một vườn thực vật, nên cây xanh luôn là phần quan trọng của nơi này.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1013, 'en', 'Orchid house', 'The orchid house shows many orchid species alongside carefully shaped ornamental plants. Thảo Cầm Viên began as a botanical garden, so plants have always been central to the park.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1013, 'zh', '兰花盆景园', '兰花盆景园展示多种兰花和精心造型的盆景。西贡动植物园最初是作为植物园建立的，因此植物一直是这里的重要组成部分。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1014, 14, 'Bảo tàng động thực vật', 'Bảo tàng động thực vật trưng bày mẫu vật và tư liệu về các loài động vật, thực vật. Đây là nơi phù hợp để các em nhỏ tìm hiểu thêm về thiên nhiên trước khi đi xem các chuồng thú.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.707704, 10.78754), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707704, 10.78754), 4326)::geography, 7.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1014, 'vi', 'Bảo tàng động thực vật', 'Bảo tàng động thực vật trưng bày mẫu vật và tư liệu về các loài động vật, thực vật. Đây là nơi phù hợp để các em nhỏ tìm hiểu thêm về thiên nhiên trước khi đi xem các chuồng thú.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1014, 'en', 'Fauna & Flora museum', 'The Fauna & Flora museum displays specimens and information about animals and plants. It is a good place for children to learn about nature before visiting the enclosures.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1014, 'zh', '动植物博物馆', '动植物博物馆展出动植物标本和资料，适合孩子们在参观兽舍前先了解大自然。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1015, 15, 'Vườn thú thiếu nhi', 'Vườn thú thiếu nhi có các con vật hiền lành, quen thuộc như dê, cừu để các em nhỏ quan sát gần. Nhớ rửa tay sau khi chạm vào thú và không cho thú ăn đồ ăn của người.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707675, 10.787906), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707675, 10.787906), 4326)::geography, 6.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1015, 'vi', 'Vườn thú thiếu nhi', 'Vườn thú thiếu nhi có các con vật hiền lành, quen thuộc như dê, cừu để các em nhỏ quan sát gần. Nhớ rửa tay sau khi chạm vào thú và không cho thú ăn đồ ăn của người.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1015, 'en', 'Children''s zoo', 'The children''s zoo has gentle, familiar animals such as goats and sheep that children can see up close. Wash your hands after touching animals, and do not feed them human food.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1015, 'zh', '儿童动物园', '儿童动物园里有山羊、绵羊等温顺常见的动物，孩子们可以近距离观察。触摸动物后请洗手，不要给动物喂人类的食物。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1016, 16, 'Hà mã', 'Hà mã dành phần lớn ban ngày ngâm mình dưới nước để giữ mát, đến tối mới lên bờ ăn cỏ. Trông chậm chạp nhưng hà mã rất khỏe và có thể chạy nhanh trên cạn. Da hà mã tiết ra chất nhờn màu đỏ giúp chống nắng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.708146, 10.787725), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.708146, 10.787725), 4326)::geography, 18.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1016, 'vi', 'Hà mã', 'Hà mã dành phần lớn ban ngày ngâm mình dưới nước để giữ mát, đến tối mới lên bờ ăn cỏ. Trông chậm chạp nhưng hà mã rất khỏe và có thể chạy nhanh trên cạn. Da hà mã tiết ra chất nhờn màu đỏ giúp chống nắng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1016, 'en', 'Hippopotamus', 'Hippos spend most of the day in water to stay cool and come ashore at night to graze. They look slow but are very strong and can run fast on land. Their skin secretes a reddish fluid that acts like sunscreen.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1016, 'zh', '河马', '河马白天大部分时间泡在水里降温，晚上才上岸吃草。它们看起来笨重，其实力气很大，在陆地上也能跑得很快。河马皮肤会分泌一种红色黏液，起到防晒作用。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1017, 17, 'Khu trưng bày chim nước, rái cá, linh trưởng', 'Khu này giới thiệu các loài chim nước, rái cá và một số loài linh trưởng. Rái cá bơi rất giỏi, dùng ria mép nhạy cảm để tìm cá dưới nước. Chim nước có chân dài hoặc chân có màng, thích nghi với cuộc sống quanh ao hồ.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707629, 10.786988), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707629, 10.786988), 4326)::geography, 7.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1017, 'vi', 'Khu trưng bày chim nước, rái cá, linh trưởng', 'Khu này giới thiệu các loài chim nước, rái cá và một số loài linh trưởng. Rái cá bơi rất giỏi, dùng ria mép nhạy cảm để tìm cá dưới nước. Chim nước có chân dài hoặc chân có màng, thích nghi với cuộc sống quanh ao hồ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1017, 'en', 'Water birds, otters, primates', 'This area features water birds, otters and some primates. Otters are excellent swimmers and use sensitive whiskers to find fish underwater. Water birds have long legs or webbed feet adapted to life around ponds and lakes.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1017, 'zh', '水禽、水獭、灵长类展区', '这里展示水禽、水獭和一些灵长类动物。水獭善于游泳，用灵敏的胡须在水下寻找鱼。水禽有长腿或蹼足，适应在池塘湖泊边生活。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1018, 18, 'Sư tử, Cáo tuyết', 'Sư tử là loài mèo lớn duy nhất sống theo bầy. Con đực có bờm, tiếng gầm có thể vang xa nhiều cây số. Cáo tuyết sống ở vùng lạnh phương Bắc, bộ lông dày giúp chúng chịu được cái lạnh khắc nghiệt.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707965, 10.786629), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707965, 10.786629), 4326)::geography, 21.1, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1018, 'vi', 'Sư tử, Cáo tuyết', 'Sư tử là loài mèo lớn duy nhất sống theo bầy. Con đực có bờm, tiếng gầm có thể vang xa nhiều cây số. Cáo tuyết sống ở vùng lạnh phương Bắc, bộ lông dày giúp chúng chịu được cái lạnh khắc nghiệt.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1018, 'en', 'Lion, Arctic fox', 'Lions are the only big cats that live in groups. Males have manes, and a roar can carry for several kilometres. The Arctic fox lives in the cold far north; its thick fur protects it from harsh cold.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1018, 'zh', '狮子、北极狐', '狮子是唯一群居的大型猫科动物。雄狮长有鬃毛，吼声可传到几公里外。北极狐生活在寒冷的北方，厚厚的皮毛帮助它们抵御严寒。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1019, 19, 'Hổ trắng', 'Hổ trắng là hổ Bengal mang gen lặn làm bộ lông trắng sọc đen, không phải một loài riêng. Ngoài tự nhiên hổ trắng rất hiếm. Như mọi loài hổ, chúng sống đơn độc và bơi rất giỏi.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707986, 10.787064), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707986, 10.787064), 4326)::geography, 10.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1019, 'vi', 'Hổ trắng', 'Hổ trắng là hổ Bengal mang gen lặn làm bộ lông trắng sọc đen, không phải một loài riêng. Ngoài tự nhiên hổ trắng rất hiếm. Như mọi loài hổ, chúng sống đơn độc và bơi rất giỏi.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1019, 'en', 'White tiger', 'White tigers are Bengal tigers carrying a recessive gene that gives white fur with black stripes; they are not a separate species. They are very rare in the wild. Like all tigers, they live alone and swim well.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1019, 'zh', '白虎', '白虎是携带隐性基因的孟加拉虎，毛色白底黑纹，并不是一个独立的物种。白虎在野外极为罕见。和所有老虎一样，它们独居生活，而且擅长游泳。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1020, 20, 'Vượn', 'Vượn có cánh tay rất dài, đu từ cành này sang cành khác nhanh và khéo léo. Buổi sáng, vượn thường hót thành từng tràng vang xa để giữ lãnh thổ và liên lạc với bạn đời. Khác với khỉ, vượn không có đuôi.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707542, 10.787958), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707542, 10.787958), 4326)::geography, 6.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1020, 'vi', 'Vượn', 'Vượn có cánh tay rất dài, đu từ cành này sang cành khác nhanh và khéo léo. Buổi sáng, vượn thường hót thành từng tràng vang xa để giữ lãnh thổ và liên lạc với bạn đời. Khác với khỉ, vượn không có đuôi.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1020, 'en', 'Gibbon', 'Gibbons have very long arms and swing from branch to branch quickly and skilfully. In the morning they often sing loud calls to mark territory and keep in touch with their mate. Unlike monkeys, gibbons have no tail.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1020, 'zh', '长臂猿', '长臂猿手臂很长，能在树枝间快速灵巧地荡来荡去。早晨，它们常发出响亮的鸣叫来宣示领地、与伴侣联络。和猴子不同，长臂猿没有尾巴。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1021, 21, 'Hội trường', 'Hội trường là nơi tổ chức hội nghị, lớp học và các hoạt động giáo dục về bảo tồn thiên nhiên.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.706952, 10.786939), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706952, 10.786939), 4326)::geography, 17.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1021, 'vi', 'Hội trường', 'Hội trường là nơi tổ chức hội nghị, lớp học và các hoạt động giáo dục về bảo tồn thiên nhiên.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1021, 'en', 'Hall', 'The hall is used for meetings, classes and nature-conservation education activities.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1021, 'zh', '礼堂', '礼堂用于举办会议、课程以及自然保护教育活动。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1022, 22, 'Khu chim trĩ, công, vẹt', 'Khu chim có trĩ, công và vẹt với bộ lông sặc sỡ. Ở nhiều loài chim, con trống có màu sắc rực rỡ hơn để thu hút con mái. Vẹt rất thông minh và có thể bắt chước âm thanh.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.706665, 10.785748), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706665, 10.785748), 4326)::geography, 8.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1022, 'vi', 'Khu chim trĩ, công, vẹt', 'Khu chim có trĩ, công và vẹt với bộ lông sặc sỡ. Ở nhiều loài chim, con trống có màu sắc rực rỡ hơn để thu hút con mái. Vẹt rất thông minh và có thể bắt chước âm thanh.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1022, 'en', 'Birds: pheasants, peafowl, parrots', 'The bird area has pheasants, peafowl and parrots with colourful plumage. In many bird species, males are brighter to attract females. Parrots are clever and can mimic sounds.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1022, 'zh', '鸟类区：雉鸡、孔雀、鹦鹉', '鸟类区有羽毛艳丽的雉鸡、孔雀和鹦鹉。很多鸟类中，雄鸟颜色更鲜艳，用来吸引雌鸟。鹦鹉很聪明，还能模仿声音。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1023, 23, 'Voọc chà vá', 'Voọc chà vá được mệnh danh là nữ hoàng linh trưởng nhờ bộ lông nhiều màu: mặt vàng, tay trắng, chân nâu đỏ. Đây là loài chỉ có ở Đông Dương, trong đó có Việt Nam, và đang bị đe dọa tuyệt chủng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.706908, 10.786569), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706908, 10.786569), 4326)::geography, 16.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1023, 'vi', 'Voọc chà vá', 'Voọc chà vá được mệnh danh là nữ hoàng linh trưởng nhờ bộ lông nhiều màu: mặt vàng, tay trắng, chân nâu đỏ. Đây là loài chỉ có ở Đông Dương, trong đó có Việt Nam, và đang bị đe dọa tuyệt chủng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1023, 'en', 'Douc langur', 'The douc langur is called the ''queen of primates'' for its colourful coat: golden face, white forearms and reddish-brown legs. It lives only in Indochina, including Vietnam, and is endangered.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1023, 'zh', '白臀叶猴', '白臀叶猴因毛色缤纷被誉为“灵长类皇后”：金色的脸、白色的前臂和红棕色的小腿。它们只分布在印度支那地区，包括越南，属于濒危物种。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1024, 24, 'Đảo hồ sen', 'Đảo hồ sen nằm giữa hồ nước, là nơi nhiều loài chim nước làm tổ và nghỉ ngơi. Mùa sen nở, mặt hồ rất đẹp. Đây là chỗ nghỉ chân mát mẻ, hợp để chụp ảnh.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.707081, 10.786311), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707081, 10.786311), 4326)::geography, 16.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1024, 'vi', 'Đảo hồ sen', 'Đảo hồ sen nằm giữa hồ nước, là nơi nhiều loài chim nước làm tổ và nghỉ ngơi. Mùa sen nở, mặt hồ rất đẹp. Đây là chỗ nghỉ chân mát mẻ, hợp để chụp ảnh.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1024, 'en', 'Lotus island', 'Lotus island lies in the middle of the lake, where many water birds nest and rest. When the lotus blooms, the lake is beautiful. It is a cool spot to rest and take photos.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1024, 'zh', '莲花岛', '莲花岛位于湖中央，许多水鸟在这里筑巢栖息。荷花盛开时，湖面非常美丽。这里凉爽宜人，适合休息和拍照。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1025, 25, 'Heo rừng', 'Heo rừng là tổ tiên của heo nhà. Chúng dùng chiếc mõm khỏe để đào đất tìm củ, rễ cây và côn trùng. Con đực có răng nanh chìa ra ngoài để tự vệ.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707176, 10.785413), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707176, 10.785413), 4326)::geography, 19.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1025, 'vi', 'Heo rừng', 'Heo rừng là tổ tiên của heo nhà. Chúng dùng chiếc mõm khỏe để đào đất tìm củ, rễ cây và côn trùng. Con đực có răng nanh chìa ra ngoài để tự vệ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1025, 'en', 'Wild boar', 'The wild boar is the ancestor of the domestic pig. It uses its strong snout to dig for roots, tubers and insects. Males have protruding tusks for defence.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1025, 'zh', '野猪', '野猪是家猪的祖先。它们用有力的鼻子拱土，寻找块根和昆虫。雄野猪长有外露的獠牙用于自卫。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1026, 26, 'Khu lưỡng cư (ếch)', 'Lưỡng cư như ếch, nhái sống được cả dưới nước lẫn trên cạn. Chúng thở một phần qua da nên rất nhạy cảm với ô nhiễm, vì vậy được xem là chỉ dấu cho sức khỏe của môi trường.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.707237, 10.786766), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707237, 10.786766), 4326)::geography, 17.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1026, 'vi', 'Khu lưỡng cư (ếch)', 'Lưỡng cư như ếch, nhái sống được cả dưới nước lẫn trên cạn. Chúng thở một phần qua da nên rất nhạy cảm với ô nhiễm, vì vậy được xem là chỉ dấu cho sức khỏe của môi trường.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1026, 'en', 'Amphibians (frogs)', 'Amphibians such as frogs live both in water and on land. They partly breathe through their skin, so they are very sensitive to pollution and are seen as indicators of environmental health.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1026, 'zh', '两栖动物区（蛙类）', '蛙类等两栖动物既能在水中也能在陆地上生活。它们部分通过皮肤呼吸，对污染非常敏感，因此被视为环境健康的指示物种。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1027, 27, 'Linh cẩu, Cáo tuyết', 'Linh cẩu có bộ hàm cực khỏe, có thể nghiền cả xương. Chúng không chỉ ăn xác mà còn là thợ săn giỏi, sống theo bầy do con cái đứng đầu. Cáo tuyết đổi màu lông theo mùa để ngụy trang.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.70711, 10.785774), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.70711, 10.785774), 4326)::geography, 16.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1027, 'vi', 'Linh cẩu, Cáo tuyết', 'Linh cẩu có bộ hàm cực khỏe, có thể nghiền cả xương. Chúng không chỉ ăn xác mà còn là thợ săn giỏi, sống theo bầy do con cái đứng đầu. Cáo tuyết đổi màu lông theo mùa để ngụy trang.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1027, 'en', 'Hyena, Arctic fox', 'Hyenas have extremely strong jaws that can crush bone. They are not just scavengers but skilled hunters, living in clans led by females. The Arctic fox changes coat colour with the seasons for camouflage.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1027, 'zh', '鬣狗、北极狐', '鬣狗咬合力极强，能咬碎骨头。它们不只是食腐动物，也是出色的猎手，群体由雌性领导。北极狐会随季节换毛变色来伪装自己。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1028, 28, 'Ngựa lùn', 'Ngựa lùn là những giống ngựa nhỏ, thấp nhưng khỏe và bền bỉ. Chúng hiền lành, thân thiện và rất được trẻ em yêu thích.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707558, 10.78552), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707558, 10.78552), 4326)::geography, 14.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1028, 'vi', 'Ngựa lùn', 'Ngựa lùn là những giống ngựa nhỏ, thấp nhưng khỏe và bền bỉ. Chúng hiền lành, thân thiện và rất được trẻ em yêu thích.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1028, 'en', 'Pony', 'Ponies are small horse breeds, short but strong and hardy. They are gentle and friendly, and children love them.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1028, 'zh', '矮种马', '矮种马体型矮小，但强壮耐劳，性情温顺友好，深受孩子们喜爱。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1029, 29, 'Quán giải khát', 'Quán giải khát phục vụ nước uống và đồ ăn nhẹ. Trong vườn có nhiều quán, hãy tìm các cọc số 29 trên bản đồ. Xin bỏ rác đúng nơi quy định để giữ vườn sạch đẹp.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.707035, 10.788153), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707035, 10.788153), 4326)::geography, 11.9, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1029, 'vi', 'Quán giải khát', 'Quán giải khát phục vụ nước uống và đồ ăn nhẹ. Trong vườn có nhiều quán, hãy tìm các cọc số 29 trên bản đồ. Xin bỏ rác đúng nơi quy định để giữ vườn sạch đẹp.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1029, 'en', 'Café', 'The café serves drinks and snacks. There are several cafés in the park; look for pin 29 on the map. Please put rubbish in the bins to keep the park clean.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1029, 'zh', '饮品店', '饮品店供应饮料和小吃。园内有多家饮品店，请在地图上找29号标记。请把垃圾丢进垃圾桶，保持园区整洁。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1030, 30, 'Gấu', 'Gấu là loài ăn tạp, thức ăn gồm trái cây, mật ong, côn trùng và cả thịt. Ở Việt Nam có gấu ngựa và gấu chó, cả hai đều đang bị đe dọa. Nạn nuôi nhốt lấy mật là mối đe dọa lớn với gấu ở châu Á.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707611, 10.786201), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707611, 10.786201), 4326)::geography, 24.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1030, 'vi', 'Gấu', 'Gấu là loài ăn tạp, thức ăn gồm trái cây, mật ong, côn trùng và cả thịt. Ở Việt Nam có gấu ngựa và gấu chó, cả hai đều đang bị đe dọa. Nạn nuôi nhốt lấy mật là mối đe dọa lớn với gấu ở châu Á.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1030, 'en', 'Bear', 'Bears are omnivores, eating fruit, honey, insects and meat. Vietnam has Asiatic black bears and sun bears, both threatened. Bile farming is a major threat to bears in Asia.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1030, 'zh', '熊', '熊是杂食动物，吃水果、蜂蜜、昆虫，也吃肉。越南有亚洲黑熊和马来熊，两者都受到威胁。活熊取胆是亚洲熊类面临的一大威胁。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1031, 31, 'Nhà ăn', 'Nhà ăn phục vụ các bữa ăn chính cho khách tham quan. Trong vườn có nhiều nhà ăn, hãy tìm các cọc số 31 trên bản đồ.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.706929, 10.789043), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706929, 10.789043), 4326)::geography, 17.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1031, 'vi', 'Nhà ăn', 'Nhà ăn phục vụ các bữa ăn chính cho khách tham quan. Trong vườn có nhiều nhà ăn, hãy tìm các cọc số 31 trên bản đồ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1031, 'en', 'Canteen', 'The canteen serves meals for visitors. There are several canteens in the park; look for pin 31 on the map.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1031, 'zh', '餐厅', '餐厅为游客提供正餐。园内有多家餐厅，请在地图上找31号标记。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1032, 32, 'Hổ Đông Dương', 'Hổ Đông Dương nhỏ hơn hổ Bengal, sọc trên lông hẹp và dày hơn. Loài hổ này đang bị đe dọa nghiêm trọng, số lượng ngoài tự nhiên còn rất ít. Là chúa sơn lâm, hổ đứng đầu chuỗi thức ăn trong rừng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707961, 10.785893), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707961, 10.785893), 4326)::geography, 20.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1032, 'vi', 'Hổ Đông Dương', 'Hổ Đông Dương nhỏ hơn hổ Bengal, sọc trên lông hẹp và dày hơn. Loài hổ này đang bị đe dọa nghiêm trọng, số lượng ngoài tự nhiên còn rất ít. Là chúa sơn lâm, hổ đứng đầu chuỗi thức ăn trong rừng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1032, 'en', 'Indochinese tiger', 'The Indochinese tiger is smaller than the Bengal tiger, with narrower, denser stripes. It is critically threatened, with very few left in the wild. As top predator, the tiger sits at the head of the forest food chain.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1032, 'zh', '印度支那虎', '印度支那虎体型比孟加拉虎小，条纹更窄更密。该亚种受到严重威胁，野外数量已非常稀少。作为顶级捕食者，老虎处于森林食物链的顶端。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1033, 33, 'Dã nhân', 'Dã nhân, hay tinh tinh, là họ hàng gần nhất của con người, chia sẻ khoảng 98% bộ gen với chúng ta. Chúng biết dùng que để bắt mối và dùng đá để đập hạt. Tinh tinh sống theo bầy và giao tiếp bằng nhiều âm thanh, cử chỉ.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.708478, 10.785437), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.708478, 10.785437), 4326)::geography, 10.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1033, 'vi', 'Dã nhân', 'Dã nhân, hay tinh tinh, là họ hàng gần nhất của con người, chia sẻ khoảng 98% bộ gen với chúng ta. Chúng biết dùng que để bắt mối và dùng đá để đập hạt. Tinh tinh sống theo bầy và giao tiếp bằng nhiều âm thanh, cử chỉ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1033, 'en', 'Chimpanzee', 'Chimpanzees are our closest living relatives, sharing about 98% of our DNA. They use sticks to fish for termites and stones to crack nuts. Chimps live in groups and communicate with many sounds and gestures.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1033, 'zh', '黑猩猩', '黑猩猩是人类现存最近的亲属，与我们约有98%的基因相同。它们会用树枝钓白蚁、用石头砸坚果。黑猩猩群居生活，用多种声音和手势交流。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1034, 34, 'Đười ươi', 'Đười ươi là loài vượn lớn sống trên cây, có bộ lông nâu đỏ. Tên tiếng Anh orangutan có nghĩa là người của rừng theo tiếng Mã Lai. Ngoài tự nhiên chúng chỉ còn ở hai đảo Borneo và Sumatra, và đang bị đe dọa nghiêm trọng do mất rừng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.708004, 10.785273), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.708004, 10.785273), 4326)::geography, 15.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1034, 'vi', 'Đười ươi', 'Đười ươi là loài vượn lớn sống trên cây, có bộ lông nâu đỏ. Tên tiếng Anh orangutan có nghĩa là người của rừng theo tiếng Mã Lai. Ngoài tự nhiên chúng chỉ còn ở hai đảo Borneo và Sumatra, và đang bị đe dọa nghiêm trọng do mất rừng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1034, 'en', 'Orangutan', 'The orangutan is a great ape that lives in trees and has reddish-brown hair. Its name means ''person of the forest'' in Malay. In the wild it survives only on Borneo and Sumatra and is critically endangered due to forest loss.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1034, 'zh', '红毛猩猩', '红毛猩猩是生活在树上的大型类人猿，毛色红褐。它的名字在马来语中意为“森林之人”。野外的红毛猩猩只分布在婆罗洲和苏门答腊岛，因森林消失而极度濒危。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1035, 35, 'Vườn cá sấu', 'Cá sấu đã tồn tại từ thời khủng long. Chúng có thể nằm bất động rất lâu rồi tấn công cực nhanh. Mắt và mũi nằm trên đỉnh đầu nên cá sấu vẫn quan sát và thở được khi gần như chìm hẳn dưới nước.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.708685, 10.786355), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.708685, 10.786355), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1035, 'vi', 'Vườn cá sấu', 'Cá sấu đã tồn tại từ thời khủng long. Chúng có thể nằm bất động rất lâu rồi tấn công cực nhanh. Mắt và mũi nằm trên đỉnh đầu nên cá sấu vẫn quan sát và thở được khi gần như chìm hẳn dưới nước.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1035, 'en', 'Crocodile garden', 'Crocodiles have existed since the age of dinosaurs. They can lie still for a long time and then strike extremely fast. Their eyes and nostrils sit on top of the head, so they can see and breathe while almost fully submerged.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1035, 'zh', '鳄鱼园', '鳄鱼从恐龙时代就已存在。它们能长时间一动不动，然后以极快的速度发动攻击。鳄鱼的眼睛和鼻孔长在头顶，几乎完全潜入水中时仍能观察和呼吸。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1036, 36, 'Nhà vệ sinh', 'Nhà vệ sinh công cộng. Trong vườn có nhiều điểm, hãy tìm các cọc số 36 trên bản đồ để đến chỗ gần nhất.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.706727, 10.78945), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706727, 10.78945), 4326)::geography, 14.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1036, 'vi', 'Nhà vệ sinh', 'Nhà vệ sinh công cộng. Trong vườn có nhiều điểm, hãy tìm các cọc số 36 trên bản đồ để đến chỗ gần nhất.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1036, 'en', 'Toilet (WC)', 'Public toilets. There are several in the park; look for pin 36 on the map to find the nearest one.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1036, 'zh', '洗手间', '公共洗手间。园内有多处，请在地图上找36号标记，寻找最近的一处。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1037, 37, 'Vườn hồng hạc', 'Hồng hạc có màu hồng là nhờ sắc tố trong tảo và tôm tép mà chúng ăn. Chúng thường đứng một chân để giữ nhiệt và nghỉ ngơi. Hồng hạc sống theo đàn đông, cùng nhau kiếm ăn và di chuyển.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.706499, 10.787753), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706499, 10.787753), 4326)::geography, 23.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1037, 'vi', 'Vườn hồng hạc', 'Hồng hạc có màu hồng là nhờ sắc tố trong tảo và tôm tép mà chúng ăn. Chúng thường đứng một chân để giữ nhiệt và nghỉ ngơi. Hồng hạc sống theo đàn đông, cùng nhau kiếm ăn và di chuyển.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1037, 'en', 'Flamingo garden', 'Flamingos get their pink colour from pigments in the algae and shrimp they eat. They often stand on one leg to save body heat and rest. They live in large flocks that feed and move together.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1037, 'zh', '火烈鸟园', '火烈鸟的粉红色来自它们所吃的藻类和小虾中的色素。它们常单脚站立，以保存体温和休息。火烈鸟成大群生活，一起觅食和迁移。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1038, 38, 'Sân chơi nước', 'Sân chơi nước dành cho trẻ em vui chơi giải nhiệt. Phụ huynh nhớ chuẩn bị quần áo thay và luôn để mắt tới các bé.', '#EF6C00', true, ST_SetSRID(ST_MakePoint(106.706183, 10.788464), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706183, 10.788464), 4326)::geography, 22.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1038, 'vi', 'Sân chơi nước', 'Sân chơi nước dành cho trẻ em vui chơi giải nhiệt. Phụ huynh nhớ chuẩn bị quần áo thay và luôn để mắt tới các bé.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1038, 'en', 'Mini water park', 'The mini water park lets children cool off and play. Parents, bring a change of clothes and keep an eye on the kids at all times.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1038, 'zh', '戏水乐园', '戏水乐园供孩子们玩水消暑。家长请带好替换衣物，并时刻照看孩子。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1039, 39, 'Khu vui chơi thiếu nhi', 'Khu vui chơi thiếu nhi có các trò chơi dành cho các bé. Trong vườn có nhiều khu vui chơi, hãy tìm các cọc số 39 trên bản đồ. Một số trò chơi có thể thu phí riêng.', '#EF6C00', true, ST_SetSRID(ST_MakePoint(106.707989, 10.787336), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707989, 10.787336), 4326)::geography, 11.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1039, 'vi', 'Khu vui chơi thiếu nhi', 'Khu vui chơi thiếu nhi có các trò chơi dành cho các bé. Trong vườn có nhiều khu vui chơi, hãy tìm các cọc số 39 trên bản đồ. Một số trò chơi có thể thu phí riêng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1039, 'en', 'Children''s amusement park', 'The children''s amusement area has rides for young kids. There are several in the park; look for pin 39 on the map. Some rides may charge a separate fee.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1039, 'zh', '儿童游乐区', '儿童游乐区有适合小朋友的游乐设施。园内有多处，请在地图上找39号标记。部分项目可能另外收费。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1040, 40, 'Quầy bán hoa kiểng', 'Quầy bán hoa kiểng có cây cảnh, hoa và vật dụng làm vườn. Bạn có thể mua một chậu cây nhỏ làm kỷ niệm chuyến tham quan.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.70582, 10.790449), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.70582, 10.790449), 4326)::geography, 23.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1040, 'vi', 'Quầy bán hoa kiểng', 'Quầy bán hoa kiểng có cây cảnh, hoa và vật dụng làm vườn. Bạn có thể mua một chậu cây nhỏ làm kỷ niệm chuyến tham quan.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1040, 'en', 'Garden center', 'The garden centre sells ornamental plants, flowers and gardening supplies. You can buy a small potted plant as a souvenir of your visit.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1040, 'zh', '花卉盆景店', '花卉盆景店出售盆栽、鲜花和园艺用品。您可以买一盆小植物作为游园纪念。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1041, 41, 'Chuồng sếu', 'Sếu là loài chim lớn, chân dài và cổ dài. Sếu đầu đỏ từng xuất hiện nhiều ở Đồng Tháp Mười và Tràm Chim, nay rất hiếm và được bảo vệ nghiêm ngặt. Vào mùa sinh sản, sếu có điệu nhảy ve vãn rất đẹp.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.706892, 10.787968), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706892, 10.787968), 4326)::geography, 11.9, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1041, 'vi', 'Chuồng sếu', 'Sếu là loài chim lớn, chân dài và cổ dài. Sếu đầu đỏ từng xuất hiện nhiều ở Đồng Tháp Mười và Tràm Chim, nay rất hiếm và được bảo vệ nghiêm ngặt. Vào mùa sinh sản, sếu có điệu nhảy ve vãn rất đẹp.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1041, 'en', 'Cranes', 'Cranes are large birds with long legs and necks. The sarus crane was once common in Vietnam''s Đồng Tháp Mười wetlands and Tràm Chim, but is now very rare and strictly protected. In breeding season, cranes perform beautiful courtship dances.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1041, 'zh', '鹤园', '鹤是腿长颈长的大型鸟类。赤颈鹤曾大量出现在越南同塔梅平原和茶林地区，如今十分稀少，受到严格保护。繁殖季节，鹤会跳起优美的求偶舞。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1042, 42, 'Vườn hoa', 'Vườn hoa trồng nhiều loại hoa và cây cảnh theo mùa. Đây là chỗ nghỉ chân nhiều bóng mát, hợp để chụp ảnh gia đình.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.706292, 10.787013), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706292, 10.787013), 4326)::geography, 14.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1042, 'vi', 'Vườn hoa', 'Vườn hoa trồng nhiều loại hoa và cây cảnh theo mùa. Đây là chỗ nghỉ chân nhiều bóng mát, hợp để chụp ảnh gia đình.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1042, 'en', 'Flower garden', 'The flower garden has seasonal flowers and ornamental plants. It is a shady spot to rest and good for family photos.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1042, 'zh', '花园', '花园里种着各种应季花卉和观赏植物。这里绿荫多，适合歇脚和拍全家福。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1043, 43, 'Rái cá', 'Rái cá là loài thú bơi lội cừ khôi, có màng giữa các ngón chân và bộ lông dày không thấm nước. Chúng ăn cá, cua và ếch. Rái cá rất hiếu động và hay chơi đùa với nhau.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.706821, 10.785662), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706821, 10.785662), 4326)::geography, 8.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1043, 'vi', 'Rái cá', 'Rái cá là loài thú bơi lội cừ khôi, có màng giữa các ngón chân và bộ lông dày không thấm nước. Chúng ăn cá, cua và ếch. Rái cá rất hiếu động và hay chơi đùa với nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1043, 'en', 'Otter', 'Otters are expert swimmers with webbed toes and thick waterproof fur. They eat fish, crabs and frogs. Otters are lively and often play with each other.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1043, 'zh', '水獭', '水獭是游泳高手，脚趾间有蹼，皮毛厚实防水。它们以鱼、蟹和蛙为食。水獭活泼好动，常常互相嬉戏。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1044, 44, 'Cầy mực', 'Cầy mực có bộ lông đen rậm và chiếc đuôi dài biết quấn vào cành cây như một bàn tay thứ năm. Điều thú vị là cơ thể chúng có mùi giống bắp rang bơ. Cầy mực sống trên cây và hoạt động chủ yếu về đêm.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.706296, 10.788871), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706296, 10.788871), 4326)::geography, 22.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1044, 'vi', 'Cầy mực', 'Cầy mực có bộ lông đen rậm và chiếc đuôi dài biết quấn vào cành cây như một bàn tay thứ năm. Điều thú vị là cơ thể chúng có mùi giống bắp rang bơ. Cầy mực sống trên cây và hoạt động chủ yếu về đêm.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1044, 'en', 'Binturong', 'The binturong, or bearcat, has shaggy black fur and a long tail that grips branches like a fifth hand. Curiously, it smells like popcorn. Binturongs live in trees and are active mostly at night.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1044, 'zh', '熊狸', '熊狸毛色乌黑蓬松，长尾巴能像“第五只手”一样缠住树枝。有趣的是，它身上有一股爆米花的味道。熊狸生活在树上，主要在夜间活动。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1045, 45, 'Báo hoa mai', 'Báo hoa mai có bộ lông vàng với những đốm hình hoa mai. Chúng rất khỏe, có thể tha con mồi nặng hơn mình lên cây để cất giữ. Ở Việt Nam, báo hoa mai ngoài tự nhiên nay cực kỳ hiếm.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.705988, 10.7893), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.705988, 10.7893), 4326)::geography, 24.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1045, 'vi', 'Báo hoa mai', 'Báo hoa mai có bộ lông vàng với những đốm hình hoa mai. Chúng rất khỏe, có thể tha con mồi nặng hơn mình lên cây để cất giữ. Ở Việt Nam, báo hoa mai ngoài tự nhiên nay cực kỳ hiếm.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1045, 'en', 'Leopard', 'The leopard has a golden coat with rosette-shaped spots. It is very strong and can haul prey heavier than itself up into trees. Wild leopards are now extremely rare in Vietnam.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1045, 'zh', '豹', '豹的金色皮毛上布满梅花状斑点。它们力气很大，能把比自己还重的猎物拖上树储藏。在越南，野生豹已极为罕见。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1046, 46, 'Rắn hổ chúa', 'Rắn hổ chúa là loài rắn độc dài nhất thế giới, có thể dài hơn 5 mét. Khi bị đe dọa, nó dựng cao phần đầu và bạnh cổ. Thức ăn chính của rắn hổ chúa là các loài rắn khác.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.706319, 10.789794), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706319, 10.789794), 4326)::geography, 15.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1046, 'vi', 'Rắn hổ chúa', 'Rắn hổ chúa là loài rắn độc dài nhất thế giới, có thể dài hơn 5 mét. Khi bị đe dọa, nó dựng cao phần đầu và bạnh cổ. Thức ăn chính của rắn hổ chúa là các loài rắn khác.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1046, 'en', 'King cobra', 'The king cobra is the world''s longest venomous snake and can exceed five metres. When threatened, it raises its head high and spreads its hood. It feeds mainly on other snakes.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1046, 'zh', '眼镜王蛇', '眼镜王蛇是世界上最长的毒蛇，体长可超过五米。受到威胁时，它会高高竖起头部并张开颈部皮褶。眼镜王蛇主要以其他蛇类为食。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1047, 47, 'Chim già đẫy', 'Già đẫy là loài cò lớn, đầu và cổ gần như trụi lông, chiếc mỏ to và dài. Chúng hay đứng yên rất lâu bên bờ nước. Già đẫy là loài chim quý hiếm đang được bảo vệ.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.706392, 10.790073), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706392, 10.790073), 4326)::geography, 15.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1047, 'vi', 'Chim già đẫy', 'Già đẫy là loài cò lớn, đầu và cổ gần như trụi lông, chiếc mỏ to và dài. Chúng hay đứng yên rất lâu bên bờ nước. Già đẫy là loài chim quý hiếm đang được bảo vệ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1047, 'en', 'Adjutant stork (Leptoptilos)', 'The adjutant is a large stork with an almost bare head and neck and a huge, long bill. It often stands still for a long time at the water’s edge. It is a rare, protected bird.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1047, 'zh', '秃鹳', '秃鹳是一种大型鹳类，头颈几乎无毛，嘴又大又长。它们常在水边长时间一动不动地站着。秃鹳是受保护的珍稀鸟类。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1048, 48, 'Vườn bướm, lưỡng cư (ếch)', 'Vườn bướm trồng các loại cây chủ để bướm đẻ trứng và cây có hoa để bướm hút mật. Bạn có thể thấy đủ vòng đời của bướm: trứng, sâu, nhộng và bướm trưởng thành. Gần đó là khu ếch nhái lưỡng cư.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.706941, 10.787352), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706941, 10.787352), 4326)::geography, 18.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1048, 'vi', 'Vườn bướm, lưỡng cư (ếch)', 'Vườn bướm trồng các loại cây chủ để bướm đẻ trứng và cây có hoa để bướm hút mật. Bạn có thể thấy đủ vòng đời của bướm: trứng, sâu, nhộng và bướm trưởng thành. Gần đó là khu ếch nhái lưỡng cư.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1048, 'en', 'Butterfly garden, amphibians (frogs)', 'The butterfly garden has host plants where butterflies lay eggs and flowering plants for nectar. You may see the whole life cycle: egg, caterpillar, pupa and adult. Nearby is a frog and amphibian area.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1048, 'zh', '蝴蝶园、两栖动物（蛙类）', '蝴蝶园种有供蝴蝶产卵的寄主植物和供其采蜜的开花植物。您可以看到蝴蝶完整的生命周期：卵、幼虫、蛹和成虫。旁边是蛙类两栖动物区。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1049, 49, 'Di tích lịch sử Quán Nhan Hương', 'Di tích lịch sử Quán Nhan Hương nằm trong khuôn viên Thảo Cầm Viên. Khi tham quan di tích, xin giữ trật tự, không leo trèo và không viết vẽ lên công trình.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.707844, 10.78552), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707844, 10.78552), 4326)::geography, 14.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1049, 'vi', 'Di tích lịch sử Quán Nhan Hương', 'Di tích lịch sử Quán Nhan Hương nằm trong khuôn viên Thảo Cầm Viên. Khi tham quan di tích, xin giữ trật tự, không leo trèo và không viết vẽ lên công trình.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1049, 'en', 'Quán Nhan Hương historic site', 'The Quán Nhan Hương historic site lies within the park grounds. When visiting, please keep quiet and do not climb on or write on the structure.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1049, 'zh', 'Quán Nhan Hương 历史遗迹', 'Quán Nhan Hương 历史遗迹位于园区内。参观时请保持安静，不要攀爬或在建筑上涂写。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1050, 50, 'Vườn nông nghiệp', 'Vườn nông nghiệp giới thiệu các loại cây trồng quen thuộc của nhà nông Việt Nam. Đây là nơi các bé ở thành phố có thể biết cây lúa, cây rau trông như thế nào.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.70786, 10.787525), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.70786, 10.787525), 4326)::geography, 7.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1050, 'vi', 'Vườn nông nghiệp', 'Vườn nông nghiệp giới thiệu các loại cây trồng quen thuộc của nhà nông Việt Nam. Đây là nơi các bé ở thành phố có thể biết cây lúa, cây rau trông như thế nào.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1050, 'en', 'Agricultural garden', 'The agricultural garden introduces familiar Vietnamese crops and farm life. City children can see what rice plants and vegetables really look like.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1050, 'zh', '农业园', '农业园介绍越南农家常见的农作物，城市里的孩子可以在这里看看水稻和蔬菜是什么样子。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1051, 51, 'Vượn cáo, Trĩ sao', 'Vượn cáo chỉ sống tự nhiên trên đảo Madagascar, nổi bật với chiếc đuôi dài khoang trắng đen. Chúng thích ngồi phơi nắng, dang tay như đang tập thể dục. Bên cạnh là trĩ sao, loài chim quý của rừng Trường Sơn, lông đuôi rất dài với nhiều đốm hình sao.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707788, 10.786987), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707788, 10.786987), 4326)::geography, 7.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1051, 'vi', 'Vượn cáo, Trĩ sao', 'Vượn cáo chỉ sống tự nhiên trên đảo Madagascar, nổi bật với chiếc đuôi dài khoang trắng đen. Chúng thích ngồi phơi nắng, dang tay như đang tập thể dục. Bên cạnh là trĩ sao, loài chim quý của rừng Trường Sơn, lông đuôi rất dài với nhiều đốm hình sao.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1051, 'en', 'Lemurs, crested argus pheasant', 'Lemurs live in the wild only on Madagascar; the ring-tailed lemur has a long black-and-white banded tail. They love sunbathing with arms spread wide. Next to them is the crested argus, a rare pheasant of the Annamite forests whose very long tail feathers are covered in star-like spots.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1051, 'zh', '狐猴、冠眼斑雉', '狐猴只在马达加斯加岛野生分布，环尾狐猴有一条黑白相间的长尾巴。它们喜欢张开双臂晒太阳。旁边是冠眼斑雉，一种产于越南长山山脉森林的珍稀雉类，长长的尾羽上布满星状斑点。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1052, 52, 'Công', 'Công trống có bộ lông đuôi dài với những đốm hình mắt óng ánh, xòe ra như chiếc quạt để thu hút công mái. Công xanh là loài có ở Việt Nam và đang bị đe dọa.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.708357, 10.785267), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.708357, 10.785267), 4326)::geography, 10.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1052, 'vi', 'Công', 'Công trống có bộ lông đuôi dài với những đốm hình mắt óng ánh, xòe ra như chiếc quạt để thu hút công mái. Công xanh là loài có ở Việt Nam và đang bị đe dọa.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1052, 'en', 'Peafowl', 'The peacock has long tail feathers with shimmering eye spots, spread like a fan to attract peahens. The green peafowl is native to Vietnam and is endangered.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1052, 'zh', '孔雀', '雄孔雀的长尾羽上有闪亮的眼状斑，开屏像一把扇子，用来吸引雌孔雀。绿孔雀原产越南，属于濒危物种。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();

DELETE FROM exhibit_pins WHERE exhibit_id BETWEEN 1001 AND 1052;
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1006, ST_SetSRID(ST_MakePoint(106.707513, 10.787256), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1020, ST_SetSRID(ST_MakePoint(106.708141, 10.786346), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1029, ST_SetSRID(ST_MakePoint(106.707752, 10.785798), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1029, ST_SetSRID(ST_MakePoint(106.70725, 10.786092), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1031, ST_SetSRID(ST_MakePoint(106.705934, 10.789072), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1031, ST_SetSRID(ST_MakePoint(106.707833, 10.787935), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1036, ST_SetSRID(ST_MakePoint(106.707315, 10.788018), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1036, ST_SetSRID(ST_MakePoint(106.708722, 10.786586), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1036, ST_SetSRID(ST_MakePoint(106.70774, 10.787207), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1036, ST_SetSRID(ST_MakePoint(106.707541, 10.786005), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1036, ST_SetSRID(ST_MakePoint(106.704956, 10.787957), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1036, ST_SetSRID(ST_MakePoint(106.706796, 10.786287), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1039, ST_SetSRID(ST_MakePoint(106.704936, 10.789571), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (1039, ST_SetSRID(ST_MakePoint(106.708271, 10.787254), 4326));
COMMIT;

-- Kiểm tra: phải ra 52 khu, 156 bản dịch, 14 cọc phụ
SELECT (SELECT count(*) FROM exhibits WHERE is_active AND map_no IS NOT NULL) AS so_khu,
       (SELECT count(*) FROM exhibit_translations WHERE exhibit_id BETWEEN 1001 AND 1052) AS so_ban_dich,
       (SELECT count(*) FROM exhibit_pins) AS so_coc_phu;
