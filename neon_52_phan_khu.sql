-- NẠP 52 PHÂN KHU ĐÚNG THEO SƠ ĐỒ "KHÁM PHÁ THẢO CẦM VIÊN SÀI GÒN"
-- Neon Console -> SQL Editor -> chọn database 'neondb' -> dán TOÀN BỘ file -> Run. CHỈ CẦN CHẠY MỘT LẦN.
-- Việc file này làm:
--   1. Thêm cột số hiệu map_no + bảng exhibit_pins (migration 008).
--   2. XOÁ HẲN mọi phân khu cũ không có trên sơ đồ (kèm bản dịch, ảnh, giọng đọc, thống kê lượt ghé của các khu đó).
--   3. Thêm 52 phân khu đúng số trên sơ đồ (id = số trên sơ đồ), vùng nghe thuyết minh hình tròn, thuyết minh Việt - Anh - Trung.
--   4. Thêm cọc phụ cho khu có nhiều điểm trên sơ đồ (nhà vệ sinh 36, nhà ăn 31, quán giải khát 29, khu vui chơi 39, bò sát 6, vượn 20).
-- Khu admin thêm sau này được cấp số 53, 54... và KHÔNG bị file này đụng tới.
-- Lưu ý: chạy lại file sẽ ghi đè những gì admin đã sửa ở 52 khu này (tên, thuyết minh, vị trí).
--   5. Thay mạng lối đi bằng mạng LIỀN MẠCH: lối đi OpenStreetMap trong vườn + đoạn nối các mảnh rời + lối nối từ mỗi khu ra lối đi
--      (trước đây mạng bị đứt thành nhiều mảnh nên nhiều khu không tìm được đường).
-- Toạ độ: căn sơ đồ minh hoạ theo bờ rạch Thị Nghè, đường Nguyễn Bỉnh Khiêm, Nguyễn Hữu Cảnh (bản đồ thật) và lối đi OpenStreetMap.
-- Sai lệch thường khoảng 10-20 m; admin tinh chỉnh bằng "Đổi vị trí vùng nghe thuyết minh".
BEGIN;
ALTER TABLE exhibits ADD COLUMN IF NOT EXISTS map_no integer;
CREATE TABLE IF NOT EXISTS exhibit_pins (
    id          serial PRIMARY KEY,
    exhibit_id  integer NOT NULL REFERENCES exhibits(id) ON DELETE CASCADE,
    geom        geometry(Point, 4326) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_exhibit_pins_exhibit ON exhibit_pins(exhibit_id);

-- Bỏ các điểm cũ: khu chưa có số trên sơ đồ, bản nạp lần đầu (id 1001..1052), khu cũ đang chiếm id 1..52
DELETE FROM exhibits WHERE map_no IS NULL OR id BETWEEN 1001 AND 1052   -- 1001..1052: bản nạp lần đầu (trùng cọc)
   OR (id BETWEEN 1 AND 52 AND map_no IS DISTINCT FROM id);

INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (1, 1, 'Hươu cao cổ', 'Hươu cao cổ là loài động vật cao nhất trên cạn, con đực có thể cao gần 6 mét. Chiếc lưỡi dài khoảng nửa mét giúp chúng tuốt lá trên những cành cây cao. Mỗi con có bộ hoa văn trên lông riêng, không con nào giống con nào.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7080247, 10.7879154), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7080247, 10.7879154), 4326)::geography, 20.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1, 'vi', 'Hươu cao cổ', 'Hươu cao cổ là loài động vật cao nhất trên cạn, con đực có thể cao gần 6 mét. Chiếc lưỡi dài khoảng nửa mét giúp chúng tuốt lá trên những cành cây cao. Mỗi con có bộ hoa văn trên lông riêng, không con nào giống con nào.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1, 'en', 'Giraffe', 'The giraffe is the tallest land animal; males can reach almost six metres. Its tongue, about half a metre long, strips leaves from high branches. Every giraffe has its own coat pattern, and no two are alike.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (1, 'zh', '长颈鹿', '长颈鹿是陆地上最高的动物，雄性身高可接近六米。它约半米长的舌头能卷下高处树枝上的叶子。每只长颈鹿的斑纹都独一无二。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (2, 2, 'Voi', 'Voi là loài thú trên cạn lớn nhất. Chiếc vòi vừa là mũi vừa là tay, dùng để thở, ngửi, uống nước và nhặt thức ăn. Voi sống theo đàn, có trí nhớ tốt và rất gắn bó với nhau.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7075765, 10.7881947), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7075765, 10.7881947), 4326)::geography, 22.1, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (2, 'vi', 'Voi', 'Voi là loài thú trên cạn lớn nhất. Chiếc vòi vừa là mũi vừa là tay, dùng để thở, ngửi, uống nước và nhặt thức ăn. Voi sống theo đàn, có trí nhớ tốt và rất gắn bó với nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (2, 'en', 'Elephant', 'Elephants are the largest land mammals. The trunk works as both nose and hand: for breathing, smelling, drinking and picking up food. Elephants live in herds, have excellent memories and form strong bonds.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (2, 'zh', '大象', '大象是陆地上最大的哺乳动物。象鼻既是鼻子也是手，可用来呼吸、闻气味、喝水和取食。大象群居生活，记忆力强，彼此感情深厚。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (3, 3, 'Khu thú móng guốc', 'Khu này nuôi các loài thú ăn cỏ có móng guốc như hươu, nai và linh dương. Móng guốc cứng giúp chúng chạy nhanh trên nền đất cứng. Hãy quan sát cặp sừng của con đực, mỗi loài có một kiểu sừng khác nhau.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.706968, 10.7893878), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706968, 10.7893878), 4326)::geography, 11.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (3, 'vi', 'Khu thú móng guốc', 'Khu này nuôi các loài thú ăn cỏ có móng guốc như hươu, nai và linh dương. Móng guốc cứng giúp chúng chạy nhanh trên nền đất cứng. Hãy quan sát cặp sừng của con đực, mỗi loài có một kiểu sừng khác nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (3, 'en', 'Herbivores (hoofed animals)', 'This area houses hoofed plant-eaters such as deer and antelope. Hard hooves let them run fast on firm ground. Look at the males'' antlers and horns: each species has its own shape.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (3, 'zh', '有蹄类动物区', '这里饲养鹿、羚羊等食草有蹄类动物。坚硬的蹄子让它们能在坚实的地面上快速奔跑。请留意雄性的角，每个物种的角形状都不一样。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (4, 4, 'Sân khấu ca nhạc', 'Sân khấu ca nhạc là nơi tổ chức các chương trình biểu diễn và sự kiện vào dịp lễ, cuối tuần. Đây cũng là điểm hẹn dễ tìm nếu bạn đi theo nhóm và lạc nhau.', '#EF6C00', true, ST_SetSRID(ST_MakePoint(106.7068688, 10.7886139), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7068688, 10.7886139), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (4, 'vi', 'Sân khấu ca nhạc', 'Sân khấu ca nhạc là nơi tổ chức các chương trình biểu diễn và sự kiện vào dịp lễ, cuối tuần. Đây cũng là điểm hẹn dễ tìm nếu bạn đi theo nhóm và lạc nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (4, 'en', 'Music stage', 'The music stage hosts performances and events on holidays and weekends. It is also an easy meeting point if your group gets separated.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (4, 'zh', '音乐舞台', '音乐舞台在节假日和周末举办演出与活动。如果同行的人走散了，这里也是一个容易找到的集合点。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (5, 5, 'Khu thú ăn thịt nhỏ', 'Khu này giới thiệu các loài thú ăn thịt cỡ nhỏ như cầy, chồn và mèo rừng. Phần lớn chúng hoạt động mạnh vào lúc chiều tối và ban đêm. Dù nhỏ, chúng là những thợ săn nhanh nhẹn, giúp kiểm soát chuột và côn trùng trong tự nhiên.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7064648, 10.7894045), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7064648, 10.7894045), 4326)::geography, 14.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (5, 'vi', 'Khu thú ăn thịt nhỏ', 'Khu này giới thiệu các loài thú ăn thịt cỡ nhỏ như cầy, chồn và mèo rừng. Phần lớn chúng hoạt động mạnh vào lúc chiều tối và ban đêm. Dù nhỏ, chúng là những thợ săn nhanh nhẹn, giúp kiểm soát chuột và côn trùng trong tự nhiên.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (5, 'en', 'Small carnivores', 'This area features small carnivores such as civets, weasels and wild cats. Most are active at dusk and at night. Though small, they are agile hunters that help control rodents and insects in the wild.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (5, 'zh', '小型食肉动物区', '这里展示灵猫、鼬和野猫等小型食肉动物。它们大多在黄昏和夜间活动。体型虽小，却是敏捷的猎手，在野外能帮助控制鼠类和昆虫的数量。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (6, 6, 'Khu bò sát', 'Khu bò sát có rắn, rùa, kỳ đà và nhiều loài khác. Bò sát là động vật biến nhiệt nên thường nằm phơi nắng để làm ấm cơ thể. Lớp da có vảy giúp chúng giữ nước và bảo vệ cơ thể.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.7059874, 10.7899821), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7059874, 10.7899821), 4326)::geography, 22.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (6, 'vi', 'Khu bò sát', 'Khu bò sát có rắn, rùa, kỳ đà và nhiều loài khác. Bò sát là động vật biến nhiệt nên thường nằm phơi nắng để làm ấm cơ thể. Lớp da có vảy giúp chúng giữ nước và bảo vệ cơ thể.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (6, 'en', 'Reptiles', 'The reptile area has snakes, turtles, monitor lizards and more. Reptiles are cold-blooded, so they often bask in the sun to warm up. Their scaly skin keeps in moisture and protects the body.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (6, 'zh', '爬行动物区', '爬行动物区有蛇、龟、巨蜥等多种动物。爬行动物是变温动物，常常晒太阳来暖和身体。它们带鳞片的皮肤能保持水分并保护身体。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (7, 7, 'Động vật châu Phi: tê giác, đà điểu, linh dương', 'Khu động vật châu Phi có tê giác trắng, đà điểu và linh dương. Tê giác trắng là một trong những loài tê giác lớn nhất và đang bị đe dọa do nạn săn trộm lấy sừng. Đà điểu là loài chim lớn nhất thế giới, không bay được nhưng chạy rất nhanh.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7055464, 10.7888441), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7055464, 10.7888441), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (7, 'vi', 'Động vật châu Phi: tê giác, đà điểu, linh dương', 'Khu động vật châu Phi có tê giác trắng, đà điểu và linh dương. Tê giác trắng là một trong những loài tê giác lớn nhất và đang bị đe dọa do nạn săn trộm lấy sừng. Đà điểu là loài chim lớn nhất thế giới, không bay được nhưng chạy rất nhanh.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (7, 'en', 'African animals: white rhino, ostrich, antelope', 'The African area has white rhinos, ostriches and antelope. The white rhino is one of the largest rhino species and is threatened by poaching for its horn. The ostrich is the world''s largest bird; it cannot fly but runs very fast.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (7, 'zh', '非洲动物：白犀牛、鸵鸟、羚羊', '非洲动物区有白犀牛、鸵鸟和羚羊。白犀牛是体型最大的犀牛之一，因犀角遭盗猎而受到威胁。鸵鸟是世界上最大的鸟，不会飞，但跑得非常快。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (8, 8, 'Hươu cao cổ, đà điểu, ngựa vằn', 'Khu này mô phỏng đồng cỏ châu Phi với hươu cao cổ, đà điểu và ngựa vằn. Ngoài tự nhiên, ba loài này thường sống gần nhau: hươu cao cổ đứng cao nhìn xa, giúp cả nhóm sớm phát hiện thú săn mồi. Sọc của mỗi con ngựa vằn là duy nhất, như dấu vân tay.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7049359, 10.7883321), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7049359, 10.7883321), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (8, 'vi', 'Hươu cao cổ, đà điểu, ngựa vằn', 'Khu này mô phỏng đồng cỏ châu Phi với hươu cao cổ, đà điểu và ngựa vằn. Ngoài tự nhiên, ba loài này thường sống gần nhau: hươu cao cổ đứng cao nhìn xa, giúp cả nhóm sớm phát hiện thú săn mồi. Sọc của mỗi con ngựa vằn là duy nhất, như dấu vân tay.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (8, 'en', 'Giraffe, ostrich, zebra', 'This area recreates the African savanna with giraffes, ostriches and zebras. In the wild these species often graze near each other, and tall giraffes spot predators early. Each zebra''s stripes are unique, like a fingerprint.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (8, 'zh', '长颈鹿、鸵鸟、斑马', '这里模拟非洲草原，有长颈鹿、鸵鸟和斑马。在野外，这三种动物常常生活在一起：长颈鹿站得高、看得远，能及早发现捕食者。每匹斑马的条纹都独一无二，就像指纹一样。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (9, 9, 'Trạm xe điện, xe lửa', 'Đây là trạm xe điện và xe lửa tham quan. Tuyến xe chạy vòng quanh vườn theo đường kẻ đỏ trên bản đồ, phù hợp với người lớn tuổi và gia đình có trẻ nhỏ.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.7054875, 10.787725), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7054875, 10.787725), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (9, 'vi', 'Trạm xe điện, xe lửa', 'Đây là trạm xe điện và xe lửa tham quan. Tuyến xe chạy vòng quanh vườn theo đường kẻ đỏ trên bản đồ, phù hợp với người lớn tuổi và gia đình có trẻ nhỏ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (9, 'en', 'Tourist train station', 'This is the tourist train and electric car station. The route circles the park along the red line on the map, which suits older visitors and families with young children.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (9, 'zh', '游览车站', '这里是游览电瓶车和小火车站。线路沿地图上的红线环绕园区，适合老人和带小孩的家庭。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (10, 10, 'Bảo tàng', 'Bảo tàng Lịch sử Việt Nam Thành phố Hồ Chí Minh nằm cạnh cổng chính. Tòa nhà được xây vào cuối thập niên 1920, mang phong cách kiến trúc Á Đông. Bảo tàng trưng bày hiện vật về lịch sử và văn hóa Việt Nam qua nhiều thời kỳ.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.7047762, 10.7876001), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7047762, 10.7876001), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (10, 'vi', 'Bảo tàng', 'Bảo tàng Lịch sử Việt Nam Thành phố Hồ Chí Minh nằm cạnh cổng chính. Tòa nhà được xây vào cuối thập niên 1920, mang phong cách kiến trúc Á Đông. Bảo tàng trưng bày hiện vật về lịch sử và văn hóa Việt Nam qua nhiều thời kỳ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (10, 'en', 'Museum of Vietnamese History', 'The Museum of Vietnamese History, Ho Chi Minh City, stands next to the main gate. The building dates from the late 1920s and has an Asian architectural style. It displays artefacts of Vietnamese history and culture across many periods.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (10, 'zh', '越南历史博物馆', '胡志明市越南历史博物馆位于正门旁。建筑建于二十世纪二十年代末，具有东方建筑风格。馆内展出越南各个时期的历史文化文物。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (11, 11, 'Đền Hùng', 'Đền Hùng trong Thảo Cầm Viên là nơi tưởng niệm các Vua Hùng, những vị vua dựng nước theo truyền thuyết của người Việt. Vào ngày Giỗ Tổ Hùng Vương mùng 10 tháng 3 âm lịch, nơi đây thường có lễ dâng hương.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.7060188, 10.7870082), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7060188, 10.7870082), 4326)::geography, 15.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (11, 'vi', 'Đền Hùng', 'Đền Hùng trong Thảo Cầm Viên là nơi tưởng niệm các Vua Hùng, những vị vua dựng nước theo truyền thuyết của người Việt. Vào ngày Giỗ Tổ Hùng Vương mùng 10 tháng 3 âm lịch, nơi đây thường có lễ dâng hương.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (11, 'en', 'Hung Kings Temple', 'The Hung Kings Temple honours the Hung Kings, the legendary founders of the Vietnamese nation. On the Hung Kings Commemoration Day, the 10th day of the 3rd lunar month, incense-offering ceremonies are usually held here.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (11, 'zh', '雄王庙', '园内的雄王庙供奉雄王，即越南传说中的建国先王。每年农历三月初十雄王祭祖日，这里通常会举行上香仪式。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (12, 12, 'Voọc bạc, Nhím', 'Voọc bạc có bộ lông xám bạc, còn con non mới sinh lại có màu cam sáng. Chúng ăn lá cây là chủ yếu. Bên cạnh là nhím, loài gặm nhấm có bộ lông gai sắc để tự vệ, khi gặp nguy hiểm sẽ dựng gai và lùi về phía kẻ thù.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7071477, 10.7875772), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7071477, 10.7875772), 4326)::geography, 18.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (12, 'vi', 'Voọc bạc, Nhím', 'Voọc bạc có bộ lông xám bạc, còn con non mới sinh lại có màu cam sáng. Chúng ăn lá cây là chủ yếu. Bên cạnh là nhím, loài gặm nhấm có bộ lông gai sắc để tự vệ, khi gặp nguy hiểm sẽ dựng gai và lùi về phía kẻ thù.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (12, 'en', 'Silvered leaf monkey, porcupine', 'The silvered leaf monkey has silver-grey fur, while newborns are bright orange. It feeds mainly on leaves. Next door is the porcupine, a rodent with sharp quills for defence; when threatened it raises them and backs into its enemy.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (12, 'zh', '银叶猴、豪猪', '银叶猴毛色银灰，而刚出生的幼崽却是亮橙色。它们主要以树叶为食。旁边是豪猪，一种长着锋利棘刺的啮齿动物；遇到危险时，它会竖起棘刺，倒退着冲向敌人。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (13, 13, 'Khu sưu tập hoa lan cây kiểng', 'Khu sưu tập hoa lan và cây kiểng trưng bày nhiều loài lan cùng các chậu cây cảnh được tạo dáng công phu. Thảo Cầm Viên ban đầu được xây dựng như một vườn thực vật, nên cây xanh luôn là phần quan trọng của nơi này.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.7072637, 10.7872477), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7072637, 10.7872477), 4326)::geography, 17.1, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (13, 'vi', 'Khu sưu tập hoa lan cây kiểng', 'Khu sưu tập hoa lan và cây kiểng trưng bày nhiều loài lan cùng các chậu cây cảnh được tạo dáng công phu. Thảo Cầm Viên ban đầu được xây dựng như một vườn thực vật, nên cây xanh luôn là phần quan trọng của nơi này.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (13, 'en', 'Orchid house', 'The orchid house shows many orchid species alongside carefully shaped ornamental plants. Thảo Cầm Viên began as a botanical garden, so plants have always been central to the park.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (13, 'zh', '兰花盆景园', '兰花盆景园展示多种兰花和精心造型的盆景。西贡动植物园最初是作为植物园建立的，因此植物一直是这里的重要组成部分。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (14, 14, 'Bảo tàng động thực vật', 'Bảo tàng động thực vật trưng bày mẫu vật và tư liệu về các loài động vật, thực vật. Đây là nơi phù hợp để các em nhỏ tìm hiểu thêm về thiên nhiên trước khi đi xem các chuồng thú.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.7076377, 10.7874018), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7076377, 10.7874018), 4326)::geography, 8.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (14, 'vi', 'Bảo tàng động thực vật', 'Bảo tàng động thực vật trưng bày mẫu vật và tư liệu về các loài động vật, thực vật. Đây là nơi phù hợp để các em nhỏ tìm hiểu thêm về thiên nhiên trước khi đi xem các chuồng thú.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (14, 'en', 'Fauna & Flora museum', 'The Fauna & Flora museum displays specimens and information about animals and plants. It is a good place for children to learn about nature before visiting the enclosures.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (14, 'zh', '动植物博物馆', '动植物博物馆展出动植物标本和资料，适合孩子们在参观兽舍前先了解大自然。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (15, 15, 'Vườn thú thiếu nhi', 'Vườn thú thiếu nhi có các con vật hiền lành, quen thuộc như dê, cừu để các em nhỏ quan sát gần. Nhớ rửa tay sau khi chạm vào thú và không cho thú ăn đồ ăn của người.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7075304, 10.7877378), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7075304, 10.7877378), 4326)::geography, 6.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (15, 'vi', 'Vườn thú thiếu nhi', 'Vườn thú thiếu nhi có các con vật hiền lành, quen thuộc như dê, cừu để các em nhỏ quan sát gần. Nhớ rửa tay sau khi chạm vào thú và không cho thú ăn đồ ăn của người.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (15, 'en', 'Children''s zoo', 'The children''s zoo has gentle, familiar animals such as goats and sheep that children can see up close. Wash your hands after touching animals, and do not feed them human food.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (15, 'zh', '儿童动物园', '儿童动物园里有山羊、绵羊等温顺常见的动物，孩子们可以近距离观察。触摸动物后请洗手，不要给动物喂人类的食物。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (16, 16, 'Hà mã', 'Hà mã dành phần lớn ban ngày ngâm mình dưới nước để giữ mát, đến tối mới lên bờ ăn cỏ. Trông chậm chạp nhưng hà mã rất khỏe và có thể chạy nhanh trên cạn. Da hà mã tiết ra chất nhờn màu đỏ giúp chống nắng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7080523, 10.7875285), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7080523, 10.7875285), 4326)::geography, 14.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (16, 'vi', 'Hà mã', 'Hà mã dành phần lớn ban ngày ngâm mình dưới nước để giữ mát, đến tối mới lên bờ ăn cỏ. Trông chậm chạp nhưng hà mã rất khỏe và có thể chạy nhanh trên cạn. Da hà mã tiết ra chất nhờn màu đỏ giúp chống nắng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (16, 'en', 'Hippopotamus', 'Hippos spend most of the day in water to stay cool and come ashore at night to graze. They look slow but are very strong and can run fast on land. Their skin secretes a reddish fluid that acts like sunscreen.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (16, 'zh', '河马', '河马白天大部分时间泡在水里降温，晚上才上岸吃草。它们看起来笨重，其实力气很大，在陆地上也能跑得很快。河马皮肤会分泌一种红色黏液，起到防晒作用。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (17, 17, 'Khu trưng bày chim nước, rái cá, linh trưởng', 'Khu này giới thiệu các loài chim nước, rái cá và một số loài linh trưởng. Rái cá bơi rất giỏi, dùng ria mép nhạy cảm để tìm cá dưới nước. Chim nước có chân dài hoặc chân có màng, thích nghi với cuộc sống quanh ao hồ.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7076363, 10.7869622), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7076363, 10.7869622), 4326)::geography, 9.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (17, 'vi', 'Khu trưng bày chim nước, rái cá, linh trưởng', 'Khu này giới thiệu các loài chim nước, rái cá và một số loài linh trưởng. Rái cá bơi rất giỏi, dùng ria mép nhạy cảm để tìm cá dưới nước. Chim nước có chân dài hoặc chân có màng, thích nghi với cuộc sống quanh ao hồ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (17, 'en', 'Water birds, otters, primates', 'This area features water birds, otters and some primates. Otters are excellent swimmers and use sensitive whiskers to find fish underwater. Water birds have long legs or webbed feet adapted to life around ponds and lakes.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (17, 'zh', '水禽、水獭、灵长类展区', '这里展示水禽、水獭和一些灵长类动物。水獭善于游泳，用灵敏的胡须在水下寻找鱼。水禽有长腿或蹼足，适应在池塘湖泊边生活。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (18, 18, 'Sư tử, Cáo tuyết', 'Sư tử là loài mèo lớn duy nhất sống theo bầy. Con đực có bờm, tiếng gầm có thể vang xa nhiều cây số. Cáo tuyết sống ở vùng lạnh phương Bắc, bộ lông dày giúp chúng chịu được cái lạnh khắc nghiệt.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7080062, 10.7867223), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7080062, 10.7867223), 4326)::geography, 16.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (18, 'vi', 'Sư tử, Cáo tuyết', 'Sư tử là loài mèo lớn duy nhất sống theo bầy. Con đực có bờm, tiếng gầm có thể vang xa nhiều cây số. Cáo tuyết sống ở vùng lạnh phương Bắc, bộ lông dày giúp chúng chịu được cái lạnh khắc nghiệt.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (18, 'en', 'Lion, Arctic fox', 'Lions are the only big cats that live in groups. Males have manes, and a roar can carry for several kilometres. The Arctic fox lives in the cold far north; its thick fur protects it from harsh cold.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (18, 'zh', '狮子、北极狐', '狮子是唯一群居的大型猫科动物。雄狮长有鬃毛，吼声可传到几公里外。北极狐生活在寒冷的北方，厚厚的皮毛帮助它们抵御严寒。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (19, 19, 'Hổ trắng', 'Hổ trắng là hổ Bengal mang gen lặn làm bộ lông trắng sọc đen, không phải một loài riêng. Ngoài tự nhiên hổ trắng rất hiếm. Như mọi loài hổ, chúng sống đơn độc và bơi rất giỏi.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7080695, 10.7870899), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7080695, 10.7870899), 4326)::geography, 8.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (19, 'vi', 'Hổ trắng', 'Hổ trắng là hổ Bengal mang gen lặn làm bộ lông trắng sọc đen, không phải một loài riêng. Ngoài tự nhiên hổ trắng rất hiếm. Như mọi loài hổ, chúng sống đơn độc và bơi rất giỏi.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (19, 'en', 'White tiger', 'White tigers are Bengal tigers carrying a recessive gene that gives white fur with black stripes; they are not a separate species. They are very rare in the wild. Like all tigers, they live alone and swim well.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (19, 'zh', '白虎', '白虎是携带隐性基因的孟加拉虎，毛色白底黑纹，并不是一个独立的物种。白虎在野外极为罕见。和所有老虎一样，它们独居生活，而且擅长游泳。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (20, 20, 'Vượn', 'Vượn có cánh tay rất dài, đu từ cành này sang cành khác nhanh và khéo léo. Buổi sáng, vượn thường hót thành từng tràng vang xa để giữ lãnh thổ và liên lạc với bạn đời. Khác với khỉ, vượn không có đuôi.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7074149, 10.7878105), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7074149, 10.7878105), 4326)::geography, 6.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (20, 'vi', 'Vượn', 'Vượn có cánh tay rất dài, đu từ cành này sang cành khác nhanh và khéo léo. Buổi sáng, vượn thường hót thành từng tràng vang xa để giữ lãnh thổ và liên lạc với bạn đời. Khác với khỉ, vượn không có đuôi.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (20, 'en', 'Gibbon', 'Gibbons have very long arms and swing from branch to branch quickly and skilfully. In the morning they often sing loud calls to mark territory and keep in touch with their mate. Unlike monkeys, gibbons have no tail.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (20, 'zh', '长臂猿', '长臂猿手臂很长，能在树枝间快速灵巧地荡来荡去。早晨，它们常发出响亮的鸣叫来宣示领地、与伴侣联络。和猴子不同，长臂猿没有尾巴。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (21, 21, 'Hội trường', 'Hội trường là nơi tổ chức hội nghị, lớp học và các hoạt động giáo dục về bảo tồn thiên nhiên.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.7069863, 10.7868793), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7069863, 10.7868793), 4326)::geography, 15.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (21, 'vi', 'Hội trường', 'Hội trường là nơi tổ chức hội nghị, lớp học và các hoạt động giáo dục về bảo tồn thiên nhiên.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (21, 'en', 'Hall', 'The hall is used for meetings, classes and nature-conservation education activities.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (21, 'zh', '礼堂', '礼堂用于举办会议、课程以及自然保护教育活动。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (22, 22, 'Khu chim trĩ, công, vẹt', 'Khu chim có trĩ, công và vẹt với bộ lông sặc sỡ. Ở nhiều loài chim, con trống có màu sắc rực rỡ hơn để thu hút con mái. Vẹt rất thông minh và có thể bắt chước âm thanh.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.7067686, 10.7858057), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7067686, 10.7858057), 4326)::geography, 5.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (22, 'vi', 'Khu chim trĩ, công, vẹt', 'Khu chim có trĩ, công và vẹt với bộ lông sặc sỡ. Ở nhiều loài chim, con trống có màu sắc rực rỡ hơn để thu hút con mái. Vẹt rất thông minh và có thể bắt chước âm thanh.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (22, 'en', 'Birds: pheasants, peafowl, parrots', 'The bird area has pheasants, peafowl and parrots with colourful plumage. In many bird species, males are brighter to attract females. Parrots are clever and can mimic sounds.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (22, 'zh', '鸟类区：雉鸡、孔雀、鹦鹉', '鸟类区有羽毛艳丽的雉鸡、孔雀和鹦鹉。很多鸟类中，雄鸟颜色更鲜艳，用来吸引雌鸟。鹦鹉很聪明，还能模仿声音。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (23, 23, 'Voọc chà vá', 'Voọc chà vá được mệnh danh là nữ hoàng linh trưởng nhờ bộ lông nhiều màu: mặt vàng, tay trắng, chân nâu đỏ. Đây là loài chỉ có ở Đông Dương, trong đó có Việt Nam, và đang bị đe dọa tuyệt chủng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7069709, 10.7865279), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7069709, 10.7865279), 4326)::geography, 12.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (23, 'vi', 'Voọc chà vá', 'Voọc chà vá được mệnh danh là nữ hoàng linh trưởng nhờ bộ lông nhiều màu: mặt vàng, tay trắng, chân nâu đỏ. Đây là loài chỉ có ở Đông Dương, trong đó có Việt Nam, và đang bị đe dọa tuyệt chủng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (23, 'en', 'Douc langur', 'The douc langur is called the ''queen of primates'' for its colourful coat: golden face, white forearms and reddish-brown legs. It lives only in Indochina, including Vietnam, and is endangered.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (23, 'zh', '白臀叶猴', '白臀叶猴因毛色缤纷被誉为“灵长类皇后”：金色的脸、白色的前臂和红棕色的小腿。它们只分布在印度支那地区，包括越南，属于濒危物种。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (24, 24, 'Đảo hồ sen', 'Đảo hồ sen nằm giữa hồ nước, là nơi nhiều loài chim nước làm tổ và nghỉ ngơi. Mùa sen nở, mặt hồ rất đẹp. Đây là chỗ nghỉ chân mát mẻ, hợp để chụp ảnh.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.7070795, 10.7863065), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7070795, 10.7863065), 4326)::geography, 12.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (24, 'vi', 'Đảo hồ sen', 'Đảo hồ sen nằm giữa hồ nước, là nơi nhiều loài chim nước làm tổ và nghỉ ngơi. Mùa sen nở, mặt hồ rất đẹp. Đây là chỗ nghỉ chân mát mẻ, hợp để chụp ảnh.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (24, 'en', 'Lotus island', 'Lotus island lies in the middle of the lake, where many water birds nest and rest. When the lotus blooms, the lake is beautiful. It is a cool spot to rest and take photos.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (24, 'zh', '莲花岛', '莲花岛位于湖中央，许多水鸟在这里筑巢栖息。荷花盛开时，湖面非常美丽。这里凉爽宜人，适合休息和拍照。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (25, 25, 'Heo rừng', 'Heo rừng là tổ tiên của heo nhà. Chúng dùng chiếc mõm khỏe để đào đất tìm củ, rễ cây và côn trùng. Con đực có răng nanh chìa ra ngoài để tự vệ.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7074041, 10.7854182), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7074041, 10.7854182), 4326)::geography, 18.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (25, 'vi', 'Heo rừng', 'Heo rừng là tổ tiên của heo nhà. Chúng dùng chiếc mõm khỏe để đào đất tìm củ, rễ cây và côn trùng. Con đực có răng nanh chìa ra ngoài để tự vệ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (25, 'en', 'Wild boar', 'The wild boar is the ancestor of the domestic pig. It uses its strong snout to dig for roots, tubers and insects. Males have protruding tusks for defence.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (25, 'zh', '野猪', '野猪是家猪的祖先。它们用有力的鼻子拱土，寻找块根和昆虫。雄野猪长有外露的獠牙用于自卫。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (26, 26, 'Khu lưỡng cư (ếch)', 'Lưỡng cư như ếch, nhái sống được cả dưới nước lẫn trên cạn. Chúng thở một phần qua da nên rất nhạy cảm với ô nhiễm, vì vậy được xem là chỉ dấu cho sức khỏe của môi trường.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.7072498, 10.7867345), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7072498, 10.7867345), 4326)::geography, 15.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (26, 'vi', 'Khu lưỡng cư (ếch)', 'Lưỡng cư như ếch, nhái sống được cả dưới nước lẫn trên cạn. Chúng thở một phần qua da nên rất nhạy cảm với ô nhiễm, vì vậy được xem là chỉ dấu cho sức khỏe của môi trường.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (26, 'en', 'Amphibians (frogs)', 'Amphibians such as frogs live both in water and on land. They partly breathe through their skin, so they are very sensitive to pollution and are seen as indicators of environmental health.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (26, 'zh', '两栖动物区（蛙类）', '蛙类等两栖动物既能在水中也能在陆地上生活。它们部分通过皮肤呼吸，对污染非常敏感，因此被视为环境健康的指示物种。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (27, 27, 'Linh cẩu, Cáo tuyết', 'Linh cẩu có bộ hàm cực khỏe, có thể nghiền cả xương. Chúng không chỉ ăn xác mà còn là thợ săn giỏi, sống theo bầy do con cái đứng đầu. Cáo tuyết đổi màu lông theo mùa để ngụy trang.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7071256, 10.7858181), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7071256, 10.7858181), 4326)::geography, 13.1, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (27, 'vi', 'Linh cẩu, Cáo tuyết', 'Linh cẩu có bộ hàm cực khỏe, có thể nghiền cả xương. Chúng không chỉ ăn xác mà còn là thợ săn giỏi, sống theo bầy do con cái đứng đầu. Cáo tuyết đổi màu lông theo mùa để ngụy trang.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (27, 'en', 'Hyena, Arctic fox', 'Hyenas have extremely strong jaws that can crush bone. They are not just scavengers but skilled hunters, living in clans led by females. The Arctic fox changes coat colour with the seasons for camouflage.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (27, 'zh', '鬣狗、北极狐', '鬣狗咬合力极强，能咬碎骨头。它们不只是食腐动物，也是出色的猎手，群体由雌性领导。北极狐会随季节换毛变色来伪装自己。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (28, 28, 'Ngựa lùn', 'Ngựa lùn là những giống ngựa nhỏ, thấp nhưng khỏe và bền bỉ. Chúng hiền lành, thân thiện và rất được trẻ em yêu thích.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7077358, 10.7855339), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7077358, 10.7855339), 4326)::geography, 13.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (28, 'vi', 'Ngựa lùn', 'Ngựa lùn là những giống ngựa nhỏ, thấp nhưng khỏe và bền bỉ. Chúng hiền lành, thân thiện và rất được trẻ em yêu thích.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (28, 'en', 'Pony', 'Ponies are small horse breeds, short but strong and hardy. They are gentle and friendly, and children love them.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (28, 'zh', '矮种马', '矮种马体型矮小，但强壮耐劳，性情温顺友好，深受孩子们喜爱。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (29, 29, 'Quán giải khát', 'Quán giải khát phục vụ nước uống và đồ ăn nhẹ. Trong vườn có nhiều quán, hãy tìm các cọc số 29 trên bản đồ. Xin bỏ rác đúng nơi quy định để giữ vườn sạch đẹp.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.7070092, 10.7881158), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7070092, 10.7881158), 4326)::geography, 11.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (29, 'vi', 'Quán giải khát', 'Quán giải khát phục vụ nước uống và đồ ăn nhẹ. Trong vườn có nhiều quán, hãy tìm các cọc số 29 trên bản đồ. Xin bỏ rác đúng nơi quy định để giữ vườn sạch đẹp.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (29, 'en', 'Café', 'The café serves drinks and snacks. There are several cafés in the park; look for pin 29 on the map. Please put rubbish in the bins to keep the park clean.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (29, 'zh', '饮品店', '饮品店供应饮料和小吃。园内有多家饮品店，请在地图上找29号标记。请把垃圾丢进垃圾桶，保持园区整洁。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (30, 30, 'Gấu', 'Gấu là loài ăn tạp, thức ăn gồm trái cây, mật ong, côn trùng và cả thịt. Ở Việt Nam có gấu ngựa và gấu chó, cả hai đều đang bị đe dọa. Nạn nuôi nhốt lấy mật là mối đe dọa lớn với gấu ở châu Á.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7075941, 10.786251), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7075941, 10.786251), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (30, 'vi', 'Gấu', 'Gấu là loài ăn tạp, thức ăn gồm trái cây, mật ong, côn trùng và cả thịt. Ở Việt Nam có gấu ngựa và gấu chó, cả hai đều đang bị đe dọa. Nạn nuôi nhốt lấy mật là mối đe dọa lớn với gấu ở châu Á.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (30, 'en', 'Bear', 'Bears are omnivores, eating fruit, honey, insects and meat. Vietnam has Asiatic black bears and sun bears, both threatened. Bile farming is a major threat to bears in Asia.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (30, 'zh', '熊', '熊是杂食动物，吃水果、蜂蜜、昆虫，也吃肉。越南有亚洲黑熊和马来熊，两者都受到威胁。活熊取胆是亚洲熊类面临的一大威胁。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (31, 31, 'Nhà ăn', 'Nhà ăn phục vụ các bữa ăn chính cho khách tham quan. Trong vườn có nhiều nhà ăn, hãy tìm các cọc số 31 trên bản đồ.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.7069324, 10.7890976), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7069324, 10.7890976), 4326)::geography, 15.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (31, 'vi', 'Nhà ăn', 'Nhà ăn phục vụ các bữa ăn chính cho khách tham quan. Trong vườn có nhiều nhà ăn, hãy tìm các cọc số 31 trên bản đồ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (31, 'en', 'Canteen', 'The canteen serves meals for visitors. There are several canteens in the park; look for pin 31 on the map.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (31, 'zh', '餐厅', '餐厅为游客提供正餐。园内有多家餐厅，请在地图上找31号标记。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (32, 32, 'Hổ Đông Dương', 'Hổ Đông Dương nhỏ hơn hổ Bengal, sọc trên lông hẹp và dày hơn. Loài hổ này đang bị đe dọa nghiêm trọng, số lượng ngoài tự nhiên còn rất ít. Là chúa sơn lâm, hổ đứng đầu chuỗi thức ăn trong rừng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.707976, 10.7859433), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707976, 10.7859433), 4326)::geography, 21.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (32, 'vi', 'Hổ Đông Dương', 'Hổ Đông Dương nhỏ hơn hổ Bengal, sọc trên lông hẹp và dày hơn. Loài hổ này đang bị đe dọa nghiêm trọng, số lượng ngoài tự nhiên còn rất ít. Là chúa sơn lâm, hổ đứng đầu chuỗi thức ăn trong rừng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (32, 'en', 'Indochinese tiger', 'The Indochinese tiger is smaller than the Bengal tiger, with narrower, denser stripes. It is critically threatened, with very few left in the wild. As top predator, the tiger sits at the head of the forest food chain.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (32, 'zh', '印度支那虎', '印度支那虎体型比孟加拉虎小，条纹更窄更密。该亚种受到严重威胁，野外数量已非常稀少。作为顶级捕食者，老虎处于森林食物链的顶端。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (33, 33, 'Dã nhân', 'Dã nhân, hay tinh tinh, là họ hàng gần nhất của con người, chia sẻ khoảng 98% bộ gen với chúng ta. Chúng biết dùng que để bắt mối và dùng đá để đập hạt. Tinh tinh sống theo bầy và giao tiếp bằng nhiều âm thanh, cử chỉ.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7082665, 10.7854508), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7082665, 10.7854508), 4326)::geography, 12.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (33, 'vi', 'Dã nhân', 'Dã nhân, hay tinh tinh, là họ hàng gần nhất của con người, chia sẻ khoảng 98% bộ gen với chúng ta. Chúng biết dùng que để bắt mối và dùng đá để đập hạt. Tinh tinh sống theo bầy và giao tiếp bằng nhiều âm thanh, cử chỉ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (33, 'en', 'Chimpanzee', 'Chimpanzees are our closest living relatives, sharing about 98% of our DNA. They use sticks to fish for termites and stones to crack nuts. Chimps live in groups and communicate with many sounds and gestures.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (33, 'zh', '黑猩猩', '黑猩猩是人类现存最近的亲属，与我们约有98%的基因相同。它们会用树枝钓白蚁、用石头砸坚果。黑猩猩群居生活，用多种声音和手势交流。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (34, 34, 'Đười ươi', 'Đười ươi là loài vượn lớn sống trên cây, có bộ lông nâu đỏ. Tên tiếng Anh orangutan có nghĩa là người của rừng theo tiếng Mã Lai. Ngoài tự nhiên chúng chỉ còn ở hai đảo Borneo và Sumatra, và đang bị đe dọa nghiêm trọng do mất rừng.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7081876, 10.7852255), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7081876, 10.7852255), 4326)::geography, 6.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (34, 'vi', 'Đười ươi', 'Đười ươi là loài vượn lớn sống trên cây, có bộ lông nâu đỏ. Tên tiếng Anh orangutan có nghĩa là người của rừng theo tiếng Mã Lai. Ngoài tự nhiên chúng chỉ còn ở hai đảo Borneo và Sumatra, và đang bị đe dọa nghiêm trọng do mất rừng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (34, 'en', 'Orangutan', 'The orangutan is a great ape that lives in trees and has reddish-brown hair. Its name means ''person of the forest'' in Malay. In the wild it survives only on Borneo and Sumatra and is critically endangered due to forest loss.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (34, 'zh', '红毛猩猩', '红毛猩猩是生活在树上的大型类人猿，毛色红褐。它的名字在马来语中意为“森林之人”。野外的红毛猩猩只分布在婆罗洲和苏门答腊岛，因森林消失而极度濒危。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (35, 35, 'Vườn cá sấu', 'Cá sấu đã tồn tại từ thời khủng long. Chúng có thể nằm bất động rất lâu rồi tấn công cực nhanh. Mắt và mũi nằm trên đỉnh đầu nên cá sấu vẫn quan sát và thở được khi gần như chìm hẳn dưới nước.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.7085566, 10.7860866), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7085566, 10.7860866), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (35, 'vi', 'Vườn cá sấu', 'Cá sấu đã tồn tại từ thời khủng long. Chúng có thể nằm bất động rất lâu rồi tấn công cực nhanh. Mắt và mũi nằm trên đỉnh đầu nên cá sấu vẫn quan sát và thở được khi gần như chìm hẳn dưới nước.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (35, 'en', 'Crocodile garden', 'Crocodiles have existed since the age of dinosaurs. They can lie still for a long time and then strike extremely fast. Their eyes and nostrils sit on top of the head, so they can see and breathe while almost fully submerged.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (35, 'zh', '鳄鱼园', '鳄鱼从恐龙时代就已存在。它们能长时间一动不动，然后以极快的速度发动攻击。鳄鱼的眼睛和鼻孔长在头顶，几乎完全潜入水中时仍能观察和呼吸。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (36, 36, 'Nhà vệ sinh', 'Nhà vệ sinh công cộng. Trong vườn có nhiều điểm, hãy tìm các cọc số 36 trên bản đồ để đến chỗ gần nhất.', '#607D8B', true, ST_SetSRID(ST_MakePoint(106.7067466, 10.7894321), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7067466, 10.7894321), 4326)::geography, 11.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (36, 'vi', 'Nhà vệ sinh', 'Nhà vệ sinh công cộng. Trong vườn có nhiều điểm, hãy tìm các cọc số 36 trên bản đồ để đến chỗ gần nhất.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (36, 'en', 'Toilet (WC)', 'Public toilets. There are several in the park; look for pin 36 on the map to find the nearest one.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (36, 'zh', '洗手间', '公共洗手间。园内有多处，请在地图上找36号标记，寻找最近的一处。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (37, 37, 'Vườn hồng hạc', 'Hồng hạc có màu hồng là nhờ sắc tố trong tảo và tôm tép mà chúng ăn. Chúng thường đứng một chân để giữ nhiệt và nghỉ ngơi. Hồng hạc sống theo đàn đông, cùng nhau kiếm ăn và di chuyển.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.7065001, 10.7877418), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7065001, 10.7877418), 4326)::geography, 22.1, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (37, 'vi', 'Vườn hồng hạc', 'Hồng hạc có màu hồng là nhờ sắc tố trong tảo và tôm tép mà chúng ăn. Chúng thường đứng một chân để giữ nhiệt và nghỉ ngơi. Hồng hạc sống theo đàn đông, cùng nhau kiếm ăn và di chuyển.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (37, 'en', 'Flamingo garden', 'Flamingos get their pink colour from pigments in the algae and shrimp they eat. They often stand on one leg to save body heat and rest. They live in large flocks that feed and move together.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (37, 'zh', '火烈鸟园', '火烈鸟的粉红色来自它们所吃的藻类和小虾中的色素。它们常单脚站立，以保存体温和休息。火烈鸟成大群生活，一起觅食和迁移。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (38, 38, 'Sân chơi nước', 'Sân chơi nước dành cho trẻ em vui chơi giải nhiệt. Phụ huynh nhớ chuẩn bị quần áo thay và luôn để mắt tới các bé.', '#EF6C00', true, ST_SetSRID(ST_MakePoint(106.7062079, 10.7884938), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7062079, 10.7884938), 4326)::geography, 22.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (38, 'vi', 'Sân chơi nước', 'Sân chơi nước dành cho trẻ em vui chơi giải nhiệt. Phụ huynh nhớ chuẩn bị quần áo thay và luôn để mắt tới các bé.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (38, 'en', 'Mini water park', 'The mini water park lets children cool off and play. Parents, bring a change of clothes and keep an eye on the kids at all times.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (38, 'zh', '戏水乐园', '戏水乐园供孩子们玩水消暑。家长请带好替换衣物，并时刻照看孩子。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (39, 39, 'Khu vui chơi thiếu nhi', 'Khu vui chơi thiếu nhi có các trò chơi dành cho các bé. Trong vườn có nhiều khu vui chơi, hãy tìm các cọc số 39 trên bản đồ. Một số trò chơi có thể thu phí riêng.', '#EF6C00', true, ST_SetSRID(ST_MakePoint(106.7080245, 10.787252), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7080245, 10.787252), 4326)::geography, 8.3, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (39, 'vi', 'Khu vui chơi thiếu nhi', 'Khu vui chơi thiếu nhi có các trò chơi dành cho các bé. Trong vườn có nhiều khu vui chơi, hãy tìm các cọc số 39 trên bản đồ. Một số trò chơi có thể thu phí riêng.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (39, 'en', 'Children''s amusement park', 'The children''s amusement area has rides for young kids. There are several in the park; look for pin 39 on the map. Some rides may charge a separate fee.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (39, 'zh', '儿童游乐区', '儿童游乐区有适合小朋友的游乐设施。园内有多处，请在地图上找39号标记。部分项目可能另外收费。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (40, 40, 'Quầy bán hoa kiểng', 'Quầy bán hoa kiểng có cây cảnh, hoa và vật dụng làm vườn. Bạn có thể mua một chậu cây nhỏ làm kỷ niệm chuyến tham quan.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.7057894, 10.790392), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7057894, 10.790392), 4326)::geography, 24.2, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (40, 'vi', 'Quầy bán hoa kiểng', 'Quầy bán hoa kiểng có cây cảnh, hoa và vật dụng làm vườn. Bạn có thể mua một chậu cây nhỏ làm kỷ niệm chuyến tham quan.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (40, 'en', 'Garden center', 'The garden centre sells ornamental plants, flowers and gardening supplies. You can buy a small potted plant as a souvenir of your visit.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (40, 'zh', '花卉盆景店', '花卉盆景店出售盆栽、鲜花和园艺用品。您可以买一盆小植物作为游园纪念。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (41, 41, 'Chuồng sếu', 'Sếu là loài chim lớn, chân dài và cổ dài. Sếu đầu đỏ từng xuất hiện nhiều ở Đồng Tháp Mười và Tràm Chim, nay rất hiếm và được bảo vệ nghiêm ngặt. Vào mùa sinh sản, sếu có điệu nhảy ve vãn rất đẹp.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.7068748, 10.7879351), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7068748, 10.7879351), 4326)::geography, 11.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (41, 'vi', 'Chuồng sếu', 'Sếu là loài chim lớn, chân dài và cổ dài. Sếu đầu đỏ từng xuất hiện nhiều ở Đồng Tháp Mười và Tràm Chim, nay rất hiếm và được bảo vệ nghiêm ngặt. Vào mùa sinh sản, sếu có điệu nhảy ve vãn rất đẹp.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (41, 'en', 'Cranes', 'Cranes are large birds with long legs and necks. The sarus crane was once common in Vietnam''s Đồng Tháp Mười wetlands and Tràm Chim, but is now very rare and strictly protected. In breeding season, cranes perform beautiful courtship dances.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (41, 'zh', '鹤园', '鹤是腿长颈长的大型鸟类。赤颈鹤曾大量出现在越南同塔梅平原和茶林地区，如今十分稀少，受到严格保护。繁殖季节，鹤会跳起优美的求偶舞。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (42, 42, 'Vườn hoa', 'Vườn hoa trồng nhiều loại hoa và cây cảnh theo mùa. Đây là chỗ nghỉ chân nhiều bóng mát, hợp để chụp ảnh gia đình.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.7063252, 10.7869887), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7063252, 10.7869887), 4326)::geography, 15.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (42, 'vi', 'Vườn hoa', 'Vườn hoa trồng nhiều loại hoa và cây cảnh theo mùa. Đây là chỗ nghỉ chân nhiều bóng mát, hợp để chụp ảnh gia đình.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (42, 'en', 'Flower garden', 'The flower garden has seasonal flowers and ornamental plants. It is a shady spot to rest and good for family photos.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (42, 'zh', '花园', '花园里种着各种应季花卉和观赏植物。这里绿荫多，适合歇脚和拍全家福。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (43, 43, 'Rái cá', 'Rái cá là loài thú bơi lội cừ khôi, có màng giữa các ngón chân và bộ lông dày không thấm nước. Chúng ăn cá, cua và ếch. Rái cá rất hiếu động và hay chơi đùa với nhau.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.706875, 10.785754), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.706875, 10.785754), 4326)::geography, 5.5, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (43, 'vi', 'Rái cá', 'Rái cá là loài thú bơi lội cừ khôi, có màng giữa các ngón chân và bộ lông dày không thấm nước. Chúng ăn cá, cua và ếch. Rái cá rất hiếu động và hay chơi đùa với nhau.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (43, 'en', 'Otter', 'Otters are expert swimmers with webbed toes and thick waterproof fur. They eat fish, crabs and frogs. Otters are lively and often play with each other.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (43, 'zh', '水獭', '水獭是游泳高手，脚趾间有蹼，皮毛厚实防水。它们以鱼、蟹和蛙为食。水獭活泼好动，常常互相嬉戏。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (44, 44, 'Cầy mực', 'Cầy mực có bộ lông đen rậm và chiếc đuôi dài biết quấn vào cành cây như một bàn tay thứ năm. Điều thú vị là cơ thể chúng có mùi giống bắp rang bơ. Cầy mực sống trên cây và hoạt động chủ yếu về đêm.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7063256, 10.788905), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7063256, 10.788905), 4326)::geography, 22.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (44, 'vi', 'Cầy mực', 'Cầy mực có bộ lông đen rậm và chiếc đuôi dài biết quấn vào cành cây như một bàn tay thứ năm. Điều thú vị là cơ thể chúng có mùi giống bắp rang bơ. Cầy mực sống trên cây và hoạt động chủ yếu về đêm.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (44, 'en', 'Binturong', 'The binturong, or bearcat, has shaggy black fur and a long tail that grips branches like a fifth hand. Curiously, it smells like popcorn. Binturongs live in trees and are active mostly at night.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (44, 'zh', '熊狸', '熊狸毛色乌黑蓬松，长尾巴能像“第五只手”一样缠住树枝。有趣的是，它身上有一股爆米花的味道。熊狸生活在树上，主要在夜间活动。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (45, 45, 'Báo hoa mai', 'Báo hoa mai có bộ lông vàng với những đốm hình hoa mai. Chúng rất khỏe, có thể tha con mồi nặng hơn mình lên cây để cất giữ. Ở Việt Nam, báo hoa mai ngoài tự nhiên nay cực kỳ hiếm.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7059916, 10.7893005), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7059916, 10.7893005), 4326)::geography, 25.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (45, 'vi', 'Báo hoa mai', 'Báo hoa mai có bộ lông vàng với những đốm hình hoa mai. Chúng rất khỏe, có thể tha con mồi nặng hơn mình lên cây để cất giữ. Ở Việt Nam, báo hoa mai ngoài tự nhiên nay cực kỳ hiếm.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (45, 'en', 'Leopard', 'The leopard has a golden coat with rosette-shaped spots. It is very strong and can haul prey heavier than itself up into trees. Wild leopards are now extremely rare in Vietnam.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (45, 'zh', '豹', '豹的金色皮毛上布满梅花状斑点。它们力气很大，能把比自己还重的猎物拖上树储藏。在越南，野生豹已极为罕见。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (46, 46, 'Rắn hổ chúa', 'Rắn hổ chúa là loài rắn độc dài nhất thế giới, có thể dài hơn 5 mét. Khi bị đe dọa, nó dựng cao phần đầu và bạnh cổ. Thức ăn chính của rắn hổ chúa là các loài rắn khác.', '#6D4C41', true, ST_SetSRID(ST_MakePoint(106.7063293, 10.7897131), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7063293, 10.7897131), 4326)::geography, 11.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (46, 'vi', 'Rắn hổ chúa', 'Rắn hổ chúa là loài rắn độc dài nhất thế giới, có thể dài hơn 5 mét. Khi bị đe dọa, nó dựng cao phần đầu và bạnh cổ. Thức ăn chính của rắn hổ chúa là các loài rắn khác.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (46, 'en', 'King cobra', 'The king cobra is the world''s longest venomous snake and can exceed five metres. When threatened, it raises its head high and spreads its hood. It feeds mainly on other snakes.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (46, 'zh', '眼镜王蛇', '眼镜王蛇是世界上最长的毒蛇，体长可超过五米。受到威胁时，它会高高竖起头部并张开颈部皮褶。眼镜王蛇主要以其他蛇类为食。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (47, 47, 'Chim già đẫy', 'Già đẫy là loài cò lớn, đầu và cổ gần như trụi lông, chiếc mỏ to và dài. Chúng hay đứng yên rất lâu bên bờ nước. Già đẫy là loài chim quý hiếm đang được bảo vệ.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.7064109, 10.7899275), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7064109, 10.7899275), 4326)::geography, 11.7, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (47, 'vi', 'Chim già đẫy', 'Già đẫy là loài cò lớn, đầu và cổ gần như trụi lông, chiếc mỏ to và dài. Chúng hay đứng yên rất lâu bên bờ nước. Già đẫy là loài chim quý hiếm đang được bảo vệ.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (47, 'en', 'Adjutant stork (Leptoptilos)', 'The adjutant is a large stork with an almost bare head and neck and a huge, long bill. It often stands still for a long time at the water’s edge. It is a rare, protected bird.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (47, 'zh', '秃鹳', '秃鹳是一种大型鹳类，头颈几乎无毛，嘴又大又长。它们常在水边长时间一动不动地站着。秃鹳是受保护的珍稀鸟类。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (48, 48, 'Vườn bướm, lưỡng cư (ếch)', 'Vườn bướm trồng các loại cây chủ để bướm đẻ trứng và cây có hoa để bướm hút mật. Bạn có thể thấy đủ vòng đời của bướm: trứng, sâu, nhộng và bướm trưởng thành. Gần đó là khu ếch nhái lưỡng cư.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.7069344, 10.7872847), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7069344, 10.7872847), 4326)::geography, 17.1, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (48, 'vi', 'Vườn bướm, lưỡng cư (ếch)', 'Vườn bướm trồng các loại cây chủ để bướm đẻ trứng và cây có hoa để bướm hút mật. Bạn có thể thấy đủ vòng đời của bướm: trứng, sâu, nhộng và bướm trưởng thành. Gần đó là khu ếch nhái lưỡng cư.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (48, 'en', 'Butterfly garden, amphibians (frogs)', 'The butterfly garden has host plants where butterflies lay eggs and flowering plants for nectar. You may see the whole life cycle: egg, caterpillar, pupa and adult. Nearby is a frog and amphibian area.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (48, 'zh', '蝴蝶园、两栖动物（蛙类）', '蝴蝶园种有供蝴蝶产卵的寄主植物和供其采蜜的开花植物。您可以看到蝴蝶完整的生命周期：卵、幼虫、蛹和成虫。旁边是蛙类两栖动物区。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (49, 49, 'Di tích lịch sử Quán Nhan Hương', 'Di tích lịch sử Quán Nhan Hương nằm trong khuôn viên Thảo Cầm Viên. Khi tham quan di tích, xin giữ trật tự, không leo trèo và không viết vẽ lên công trình.', '#8E24AA', true, ST_SetSRID(ST_MakePoint(106.7079908, 10.7855487), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7079908, 10.7855487), 4326)::geography, 13.0, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (49, 'vi', 'Di tích lịch sử Quán Nhan Hương', 'Di tích lịch sử Quán Nhan Hương nằm trong khuôn viên Thảo Cầm Viên. Khi tham quan di tích, xin giữ trật tự, không leo trèo và không viết vẽ lên công trình.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (49, 'en', 'Quán Nhan Hương historic site', 'The Quán Nhan Hương historic site lies within the park grounds. When visiting, please keep quiet and do not climb on or write on the structure.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (49, 'zh', 'Quán Nhan Hương 历史遗迹', 'Quán Nhan Hương 历史遗迹位于园区内。参观时请保持安静，不要攀爬或在建筑上涂写。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (50, 50, 'Vườn nông nghiệp', 'Vườn nông nghiệp giới thiệu các loại cây trồng quen thuộc của nhà nông Việt Nam. Đây là nơi các bé ở thành phố có thể biết cây lúa, cây rau trông như thế nào.', '#558B2F', true, ST_SetSRID(ST_MakePoint(106.707813, 10.7873802), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.707813, 10.7873802), 4326)::geography, 8.6, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (50, 'vi', 'Vườn nông nghiệp', 'Vườn nông nghiệp giới thiệu các loại cây trồng quen thuộc của nhà nông Việt Nam. Đây là nơi các bé ở thành phố có thể biết cây lúa, cây rau trông như thế nào.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (50, 'en', 'Agricultural garden', 'The agricultural garden introduces familiar Vietnamese crops and farm life. City children can see what rice plants and vegetables really look like.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (50, 'zh', '农业园', '农业园介绍越南农家常见的农作物，城市里的孩子可以在这里看看水稻和蔬菜是什么样子。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (51, 51, 'Vượn cáo, Trĩ sao', 'Vượn cáo chỉ sống tự nhiên trên đảo Madagascar, nổi bật với chiếc đuôi dài khoang trắng đen. Chúng thích ngồi phơi nắng, dang tay như đang tập thể dục. Bên cạnh là trĩ sao, loài chim quý của rừng Trường Sơn, lông đuôi rất dài với nhiều đốm hình sao.', '#1F5C43', true, ST_SetSRID(ST_MakePoint(106.7078257, 10.7869884), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7078257, 10.7869884), 4326)::geography, 9.4, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (51, 'vi', 'Vượn cáo, Trĩ sao', 'Vượn cáo chỉ sống tự nhiên trên đảo Madagascar, nổi bật với chiếc đuôi dài khoang trắng đen. Chúng thích ngồi phơi nắng, dang tay như đang tập thể dục. Bên cạnh là trĩ sao, loài chim quý của rừng Trường Sơn, lông đuôi rất dài với nhiều đốm hình sao.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (51, 'en', 'Lemurs, crested argus pheasant', 'Lemurs live in the wild only on Madagascar; the ring-tailed lemur has a long black-and-white banded tail. They love sunbathing with arms spread wide. Next to them is the crested argus, a rare pheasant of the Annamite forests whose very long tail feathers are covered in star-like spots.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (51, 'zh', '狐猴、冠眼斑雉', '狐猴只在马达加斯加岛野生分布，环尾狐猴有一条黑白相间的长尾巴。它们喜欢张开双臂晒太阳。旁边是冠眼斑雉，一种产于越南长山山脉森林的珍稀雉类，长长的尾羽上布满星状斑点。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibits (id, map_no, name, description, color, is_active, geom, geom_poly)
VALUES (52, 52, 'Công', 'Công trống có bộ lông đuôi dài với những đốm hình mắt óng ánh, xòe ra như chiếc quạt để thu hút công mái. Công xanh là loài có ở Việt Nam và đang bị đe dọa.', '#1565C0', true, ST_SetSRID(ST_MakePoint(106.7082444, 10.7850967), 4326),
        ST_Buffer(ST_SetSRID(ST_MakePoint(106.7082444, 10.7850967), 4326)::geography, 6.8, 'quad_segs=16')::geometry)
ON CONFLICT (id) DO UPDATE SET map_no = EXCLUDED.map_no, name = EXCLUDED.name, description = EXCLUDED.description,
    color = EXCLUDED.color, is_active = true, geom = EXCLUDED.geom, geom_poly = EXCLUDED.geom_poly;
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (52, 'vi', 'Công', 'Công trống có bộ lông đuôi dài với những đốm hình mắt óng ánh, xòe ra như chiếc quạt để thu hút công mái. Công xanh là loài có ở Việt Nam và đang bị đe dọa.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (52, 'en', 'Peafowl', 'The peacock has long tail feathers with shimmering eye spots, spread like a fan to attract peahens. The green peafowl is native to Vietnam and is endangered.')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();
INSERT INTO exhibit_translations (exhibit_id, language, name, description) VALUES (52, 'zh', '孔雀', '雄孔雀的长尾羽上有闪亮的眼状斑，开屏像一把扇子，用来吸引雌孔雀。绿孔雀原产越南，属于濒危物种。')
ON CONFLICT (exhibit_id, language) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description, audio_file = NULL, audio_data = NULL, updated_at = now();

DELETE FROM exhibit_pins WHERE exhibit_id BETWEEN 1 AND 52;
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (6, ST_SetSRID(ST_MakePoint(106.7074904, 10.7871668), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (20, ST_SetSRID(ST_MakePoint(106.7081274, 10.7863698), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (29, ST_SetSRID(ST_MakePoint(106.7078062, 10.7858471), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (29, ST_SetSRID(ST_MakePoint(106.7072169, 10.7861202), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (31, ST_SetSRID(ST_MakePoint(106.7059429, 10.7890874), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (31, ST_SetSRID(ST_MakePoint(106.7076596, 10.7877443), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (36, ST_SetSRID(ST_MakePoint(106.7072322, 10.7879162), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (36, ST_SetSRID(ST_MakePoint(106.7087786, 10.7867524), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (36, ST_SetSRID(ST_MakePoint(106.7077461, 10.7871386), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (36, ST_SetSRID(ST_MakePoint(106.7075403, 10.7860499), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (36, ST_SetSRID(ST_MakePoint(106.7049529, 10.7879751), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (36, ST_SetSRID(ST_MakePoint(106.7068765, 10.7862533), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (39, ST_SetSRID(ST_MakePoint(106.7049198, 10.7895924), 4326));
INSERT INTO exhibit_pins (exhibit_id, geom) VALUES (39, ST_SetSRID(ST_MakePoint(106.7083507, 10.7872375), 4326));

-- ===== Mạng lối đi liền mạch (pgRouting dùng source/target + cost theo mét) =====
TRUNCATE walkways_vertices_pgr;
TRUNCATE walkways RESTART IDENTITY;
INSERT INTO walkways_vertices_pgr (id, the_geom) VALUES
(1, ST_SetSRID(ST_MakePoint(106.705557, 10.7906122), 4326)),
(2, ST_SetSRID(ST_MakePoint(106.7055455, 10.7905459), 4326)),
(3, ST_SetSRID(ST_MakePoint(106.7055269, 10.7904341), 4326)),
(4, ST_SetSRID(ST_MakePoint(106.7055018, 10.790283), 4326)),
(5, ST_SetSRID(ST_MakePoint(106.7054939, 10.7902068), 4326)),
(6, ST_SetSRID(ST_MakePoint(106.7049198, 10.7895924), 4326)),
(7, ST_SetSRID(ST_MakePoint(106.7054924, 10.7901302), 4326)),
(8, ST_SetSRID(ST_MakePoint(106.7057894, 10.790392), 4326)),
(9, ST_SetSRID(ST_MakePoint(106.7054985, 10.7900455), 4326)),
(10, ST_SetSRID(ST_MakePoint(106.7055126, 10.7899617), 4326)),
(11, ST_SetSRID(ST_MakePoint(106.7055243, 10.789915), 4326)),
(12, ST_SetSRID(ST_MakePoint(106.70554, 10.7898694), 4326)),
(13, ST_SetSRID(ST_MakePoint(106.7055642, 10.7898163), 4326)),
(14, ST_SetSRID(ST_MakePoint(106.7058291, 10.7900275), 4326)),
(15, ST_SetSRID(ST_MakePoint(106.7055937, 10.789766), 4326)),
(16, ST_SetSRID(ST_MakePoint(106.7058916, 10.7900156), 4326)),
(17, ST_SetSRID(ST_MakePoint(106.7059534, 10.7900008), 4326)),
(18, ST_SetSRID(ST_MakePoint(106.7059898, 10.7899898), 4326)),
(19, ST_SetSRID(ST_MakePoint(106.7059874, 10.7899821), 4326)),
(20, ST_SetSRID(ST_MakePoint(106.706034, 10.7899765), 4326)),
(21, ST_SetSRID(ST_MakePoint(106.7057198, 10.7895907), 4326)),
(22, ST_SetSRID(ST_MakePoint(106.7061127, 10.7899471), 4326)),
(23, ST_SetSRID(ST_MakePoint(106.7054898, 10.7893332), 4326)),
(24, ST_SetSRID(ST_MakePoint(106.705364, 10.7891968), 4326)),
(25, ST_SetSRID(ST_MakePoint(106.7051849, 10.7890028), 4326)),
(26, ST_SetSRID(ST_MakePoint(106.704878, 10.7886714), 4326)),
(27, ST_SetSRID(ST_MakePoint(106.7058474, 10.7894286), 4326)),
(28, ST_SetSRID(ST_MakePoint(106.706411, 10.7899275), 4326)),
(29, ST_SetSRID(ST_MakePoint(106.7058778, 10.7893932), 4326)),
(30, ST_SetSRID(ST_MakePoint(106.7063499, 10.7898423), 4326)),
(31, ST_SetSRID(ST_MakePoint(106.7063142, 10.7897879), 4326)),
(32, ST_SetSRID(ST_MakePoint(106.7063682, 10.7898342), 4326)),
(33, ST_SetSRID(ST_MakePoint(106.706283, 10.7897476), 4326)),
(34, ST_SetSRID(ST_MakePoint(106.7062743, 10.7897363), 4326)),
(35, ST_SetSRID(ST_MakePoint(106.7062396, 10.7896974), 4326)),
(36, ST_SetSRID(ST_MakePoint(106.7062026, 10.7896606), 4326)),
(37, ST_SetSRID(ST_MakePoint(106.7059324, 10.7893296), 4326)),
(38, ST_SetSRID(ST_MakePoint(106.7067634, 10.790144), 4326)),
(39, ST_SetSRID(ST_MakePoint(106.7050817, 10.7884902), 4326)),
(40, ST_SetSRID(ST_MakePoint(106.7063293, 10.7897131), 4326)),
(41, ST_SetSRID(ST_MakePoint(106.7057319, 10.7891164), 4326)),
(42, ST_SetSRID(ST_MakePoint(106.7049359, 10.7883322), 4326)),
(43, ST_SetSRID(ST_MakePoint(106.7059716, 10.7892839), 4326)),
(44, ST_SetSRID(ST_MakePoint(106.7059916, 10.7893004), 4326)),
(45, ST_SetSRID(ST_MakePoint(106.706741, 10.7900354), 4326)),
(46, ST_SetSRID(ST_MakePoint(106.7064914, 10.7897798), 4326)),
(47, ST_SetSRID(ST_MakePoint(106.7057778, 10.7890753), 4326)),
(48, ST_SetSRID(ST_MakePoint(106.7059819, 10.7892719), 4326)),
(49, ST_SetSRID(ST_MakePoint(106.7055464, 10.7888441), 4326)),
(50, ST_SetSRID(ST_MakePoint(106.7067382, 10.7900045), 4326)),
(51, ST_SetSRID(ST_MakePoint(106.7055535, 10.7888376), 4326)),
(52, ST_SetSRID(ST_MakePoint(106.7054697, 10.7887487), 4326)),
(53, ST_SetSRID(ST_MakePoint(106.7067395, 10.7899736), 4326)),
(54, ST_SetSRID(ST_MakePoint(106.7051601, 10.7884204), 4326)),
(55, ST_SetSRID(ST_MakePoint(106.706745, 10.7899431), 4326)),
(56, ST_SetSRID(ST_MakePoint(106.706756, 10.7899102), 4326)),
(57, ST_SetSRID(ST_MakePoint(106.7065814, 10.789735), 4326)),
(58, ST_SetSRID(ST_MakePoint(106.7060542, 10.7892069), 4326)),
(59, ST_SetSRID(ST_MakePoint(106.7059429, 10.7890874), 4326)),
(60, ST_SetSRID(ST_MakePoint(106.7066043, 10.7897189), 4326)),
(61, ST_SetSRID(ST_MakePoint(106.7067717, 10.7898793), 4326)),
(62, ST_SetSRID(ST_MakePoint(106.7066237, 10.7896989), 4326)),
(63, ST_SetSRID(ST_MakePoint(106.706792, 10.7898509), 4326)),
(64, ST_SetSRID(ST_MakePoint(106.7066391, 10.7896757), 4326)),
(65, ST_SetSRID(ST_MakePoint(106.7068092, 10.789817), 4326)),
(66, ST_SetSRID(ST_MakePoint(106.706649, 10.7896526), 4326)),
(67, ST_SetSRID(ST_MakePoint(106.7049529, 10.7879751), 4326)),
(68, ST_SetSRID(ST_MakePoint(106.7066549, 10.7896283), 4326)),
(69, ST_SetSRID(ST_MakePoint(106.7068215, 10.7897811), 4326)),
(70, ST_SetSRID(ST_MakePoint(106.7064909, 10.7894412), 4326)),
(71, ST_SetSRID(ST_MakePoint(106.7066565, 10.7896033), 4326)),
(72, ST_SetSRID(ST_MakePoint(106.7064734, 10.7894138), 4326)),
(73, ST_SetSRID(ST_MakePoint(106.7064676, 10.7894031), 4326)),
(74, ST_SetSRID(ST_MakePoint(106.706458, 10.7893852), 4326)),
(75, ST_SetSRID(ST_MakePoint(106.7068279, 10.7897483), 4326)),
(76, ST_SetSRID(ST_MakePoint(106.7058847, 10.7888187), 4326)),
(77, ST_SetSRID(ST_MakePoint(106.7064929, 10.789416), 4326)),
(78, ST_SetSRID(ST_MakePoint(106.7066546, 10.7895621), 4326)),
(79, ST_SetSRID(ST_MakePoint(106.7064448, 10.7893557), 4326)),
(80, ST_SetSRID(ST_MakePoint(106.7056623, 10.7885769), 4326)),
(81, ST_SetSRID(ST_MakePoint(106.7065003, 10.7893918), 4326)),
(82, ST_SetSRID(ST_MakePoint(106.7068302, 10.789715), 4326)),
(83, ST_SetSRID(ST_MakePoint(106.7064339, 10.7893253), 4326)),
(84, ST_SetSRID(ST_MakePoint(106.7066471, 10.7895216), 4326)),
(85, ST_SetSRID(ST_MakePoint(106.7053572, 10.7882451), 4326)),
(86, ST_SetSRID(ST_MakePoint(106.7068282, 10.7896816), 4326)),
(87, ST_SetSRID(ST_MakePoint(106.7065119, 10.7893707), 4326)),
(88, ST_SetSRID(ST_MakePoint(106.7066319, 10.7894588), 4326)),
(89, ST_SetSRID(ST_MakePoint(106.7058465, 10.7886854), 4326)),
(90, ST_SetSRID(ST_MakePoint(106.7065275, 10.7893522), 4326)),
(91, ST_SetSRID(ST_MakePoint(106.7068281, 10.7896441), 4326)),
(92, ST_SetSRID(ST_MakePoint(106.7057093, 10.7885349), 4326)),
(93, ST_SetSRID(ST_MakePoint(106.7055802, 10.7883933), 4326)),
(94, ST_SetSRID(ST_MakePoint(106.7066216, 10.7894162), 4326)),
(95, ST_SetSRID(ST_MakePoint(106.7047762, 10.7876001), 4326)),
(96, ST_SetSRID(ST_MakePoint(106.7065465, 10.7893371), 4326)),
(97, ST_SetSRID(ST_MakePoint(106.7055688, 10.7883755), 4326)),
(98, ST_SetSRID(ST_MakePoint(106.7066119, 10.7893921), 4326)),
(99, ST_SetSRID(ST_MakePoint(106.7065337, 10.7893145), 4326)),
(100, ST_SetSRID(ST_MakePoint(106.7068326, 10.7896068), 4326)),
(101, ST_SetSRID(ST_MakePoint(106.7066033, 10.7893798), 4326)),
(102, ST_SetSRID(ST_MakePoint(106.7065928, 10.7893691), 4326)),
(103, ST_SetSRID(ST_MakePoint(106.7055636, 10.7883551), 4326)),
(104, ST_SetSRID(ST_MakePoint(106.7065264, 10.7892897), 4326)),
(105, ST_SetSRID(ST_MakePoint(106.7055651, 10.7883342), 4326)),
(106, ST_SetSRID(ST_MakePoint(106.7065251, 10.7892621), 4326)),
(107, ST_SetSRID(ST_MakePoint(106.7068416, 10.7895703), 4326)),
(108, ST_SetSRID(ST_MakePoint(106.7055732, 10.7883147), 4326)),
(109, ST_SetSRID(ST_MakePoint(106.7065305, 10.789235), 4326)),
(110, ST_SetSRID(ST_MakePoint(106.705587, 10.7882987), 4326)),
(111, ST_SetSRID(ST_MakePoint(106.7067466, 10.7894321), 4326)),
(112, ST_SetSRID(ST_MakePoint(106.7056044, 10.788288), 4326)),
(113, ST_SetSRID(ST_MakePoint(106.7068618, 10.789521), 4326)),
(114, ST_SetSRID(ST_MakePoint(106.706316, 10.7889717), 4326)),
(115, ST_SetSRID(ST_MakePoint(106.7056242, 10.7882829), 4326)),
(116, ST_SetSRID(ST_MakePoint(106.7059508, 10.7885981), 4326)),
(117, ST_SetSRID(ST_MakePoint(106.7051149, 10.7877754), 4326)),
(118, ST_SetSRID(ST_MakePoint(106.7058446, 10.7884823), 4326)),
(119, ST_SetSRID(ST_MakePoint(106.7056447, 10.7882839), 4326)),
(120, ST_SetSRID(ST_MakePoint(106.7056639, 10.7882908), 4326)),
(121, ST_SetSRID(ST_MakePoint(106.7056802, 10.788303), 4326)),
(122, ST_SetSRID(ST_MakePoint(106.7068903, 10.7894758), 4326)),
(123, ST_SetSRID(ST_MakePoint(106.706355, 10.7889366), 4326)),
(124, ST_SetSRID(ST_MakePoint(106.7061764, 10.7887595), 4326)),
(125, ST_SetSRID(ST_MakePoint(106.7063256, 10.788905), 4326)),
(126, ST_SetSRID(ST_MakePoint(106.7059827, 10.7885476), 4326)),
(127, ST_SetSRID(ST_MakePoint(106.705888, 10.7884439), 4326)),
(128, ST_SetSRID(ST_MakePoint(106.7065794, 10.7891211), 4326)),
(129, ST_SetSRID(ST_MakePoint(106.7057908, 10.7883369), 4326)),
(130, ST_SetSRID(ST_MakePoint(106.7069261, 10.7894359), 4326)),
(131, ST_SetSRID(ST_MakePoint(106.7055474, 10.7880758), 4326)),
(132, ST_SetSRID(ST_MakePoint(106.7069495, 10.7893964), 4326)),
(133, ST_SetSRID(ST_MakePoint(106.7069555, 10.7893826), 4326)),
(134, ST_SetSRID(ST_MakePoint(106.706968, 10.7893878), 4326)),
(135, ST_SetSRID(ST_MakePoint(106.7063148, 10.7887253), 4326)),
(136, ST_SetSRID(ST_MakePoint(106.7062692, 10.7886768), 4326)),
(137, ST_SetSRID(ST_MakePoint(106.7069677, 10.7893543), 4326)),
(138, ST_SetSRID(ST_MakePoint(106.7060716, 10.7884663), 4326)),
(139, ST_SetSRID(ST_MakePoint(106.7059768, 10.7883653), 4326)),
(140, ST_SetSRID(ST_MakePoint(106.7058776, 10.7882596), 4326)),
(141, ST_SetSRID(ST_MakePoint(106.7064735, 10.7888303), 4326)),
(142, ST_SetSRID(ST_MakePoint(106.7056892, 10.7880589), 4326)),
(143, ST_SetSRID(ST_MakePoint(106.706981, 10.789307), 4326)),
(144, ST_SetSRID(ST_MakePoint(106.7056678, 10.7879686), 4326)),
(145, ST_SetSRID(ST_MakePoint(106.7062079, 10.7884938), 4326)),
(146, ST_SetSRID(ST_MakePoint(106.7069877, 10.7892583), 4326)),
(147, ST_SetSRID(ST_MakePoint(106.7063843, 10.7886624), 4326)),
(148, ST_SetSRID(ST_MakePoint(106.7063265, 10.7886008), 4326)),
(149, ST_SetSRID(ST_MakePoint(106.7054625, 10.7877473), 4326)),
(150, ST_SetSRID(ST_MakePoint(106.7050221, 10.787313), 4326)),
(151, ST_SetSRID(ST_MakePoint(106.7062177, 10.7884849), 4326)),
(152, ST_SetSRID(ST_MakePoint(106.706114, 10.7883744), 4326)),
(153, ST_SetSRID(ST_MakePoint(106.7053183, 10.787592), 4326)),
(154, ST_SetSRID(ST_MakePoint(106.7060174, 10.7882715), 4326)),
(155, ST_SetSRID(ST_MakePoint(106.7059075, 10.7881543), 4326)),
(156, ST_SetSRID(ST_MakePoint(106.7050373, 10.7872995), 4326)),
(157, ST_SetSRID(ST_MakePoint(106.7069878, 10.7892092), 4326)),
(158, ST_SetSRID(ST_MakePoint(106.7050786, 10.7873336), 4326)),
(159, ST_SetSRID(ST_MakePoint(106.7050469, 10.7872995), 4326)),
(160, ST_SetSRID(ST_MakePoint(106.7057588, 10.7879959), 4326)),
(161, ST_SetSRID(ST_MakePoint(106.7054875, 10.787725), 4326)),
(162, ST_SetSRID(ST_MakePoint(106.7065732, 10.7887854), 4326)),
(163, ST_SetSRID(ST_MakePoint(106.7069811, 10.7891606), 4326)),
(164, ST_SetSRID(ST_MakePoint(106.7069324, 10.7890976), 4326)),
(165, ST_SetSRID(ST_MakePoint(106.7050909, 10.7872511), 4326)),
(166, ST_SetSRID(ST_MakePoint(106.7050944, 10.7872479), 4326)),
(167, ST_SetSRID(ST_MakePoint(106.7069731, 10.789093), 4326)),
(168, ST_SetSRID(ST_MakePoint(106.706415, 10.7885199), 4326)),
(169, ST_SetSRID(ST_MakePoint(106.7069696, 10.7890633), 4326)),
(170, ST_SetSRID(ST_MakePoint(106.7062044, 10.7882936), 4326)),
(171, ST_SetSRID(ST_MakePoint(106.7061076, 10.7881896), 4326)),
(172, ST_SetSRID(ST_MakePoint(106.7066709, 10.7887365), 4326)),
(173, ST_SetSRID(ST_MakePoint(106.706, 10.7880741), 4326)),
(174, ST_SetSRID(ST_MakePoint(106.7057963, 10.7878552), 4326)),
(175, ST_SetSRID(ST_MakePoint(106.7069608, 10.7889656), 4326)),
(176, ST_SetSRID(ST_MakePoint(106.7067665, 10.7886837), 4326)),
(177, ST_SetSRID(ST_MakePoint(106.7069583, 10.7888701), 4326)),
(178, ST_SetSRID(ST_MakePoint(106.7052207, 10.7871332), 4326)),
(179, ST_SetSRID(ST_MakePoint(106.7052266, 10.7871279), 4326)),
(180, ST_SetSRID(ST_MakePoint(106.7065934, 10.7884623), 4326)),
(181, ST_SetSRID(ST_MakePoint(106.7065786, 10.7884468), 4326)),
(182, ST_SetSRID(ST_MakePoint(106.7069558, 10.7888171), 4326)),
(183, ST_SetSRID(ST_MakePoint(106.7066127, 10.788472), 4326)),
(184, ST_SetSRID(ST_MakePoint(106.7065702, 10.7884273), 4326)),
(185, ST_SetSRID(ST_MakePoint(106.7069499, 10.7887904), 4326)),
(186, ST_SetSRID(ST_MakePoint(106.7066341, 10.7884746), 4326)),
(187, ST_SetSRID(ST_MakePoint(106.706569, 10.788406), 4326)),
(188, ST_SetSRID(ST_MakePoint(106.7069374, 10.7887613), 4326)),
(189, ST_SetSRID(ST_MakePoint(106.7069194, 10.7887351), 4326)),
(190, ST_SetSRID(ST_MakePoint(106.7066552, 10.7884698), 4326)),
(191, ST_SetSRID(ST_MakePoint(106.7065753, 10.7883857), 4326)),
(192, ST_SetSRID(ST_MakePoint(106.7068368, 10.7886403), 4326)),
(193, ST_SetSRID(ST_MakePoint(106.7066733, 10.7884582), 4326)),
(194, ST_SetSRID(ST_MakePoint(106.7065884, 10.7883687), 4326)),
(195, ST_SetSRID(ST_MakePoint(106.7065847, 10.7883647), 4326)),
(196, ST_SetSRID(ST_MakePoint(106.7052875, 10.7870725), 4326)),
(197, ST_SetSRID(ST_MakePoint(106.7063754, 10.7881385), 4326)),
(198, ST_SetSRID(ST_MakePoint(106.706352, 10.7881132), 4326)),
(199, ST_SetSRID(ST_MakePoint(106.7066864, 10.7884412), 4326)),
(200, ST_SetSRID(ST_MakePoint(106.7068718, 10.7886187), 4326));
INSERT INTO walkways_vertices_pgr (id, the_geom) VALUES
(201, ST_SetSRID(ST_MakePoint(106.7066065, 10.7883572), 4326)),
(202, ST_SetSRID(ST_MakePoint(106.7068688, 10.7886139), 4326)),
(203, ST_SetSRID(ST_MakePoint(106.7061873, 10.7879343), 4326)),
(204, ST_SetSRID(ST_MakePoint(106.7061708, 10.7879163), 4326)),
(205, ST_SetSRID(ST_MakePoint(106.7066927, 10.7884209), 4326)),
(206, ST_SetSRID(ST_MakePoint(106.7066276, 10.7883524), 4326)),
(207, ST_SetSRID(ST_MakePoint(106.7059718, 10.7877001), 4326)),
(208, ST_SetSRID(ST_MakePoint(106.7068963, 10.7886036), 4326)),
(209, ST_SetSRID(ST_MakePoint(106.7066915, 10.7883997), 4326)),
(210, ST_SetSRID(ST_MakePoint(106.706649, 10.788355), 4326)),
(211, ST_SetSRID(ST_MakePoint(106.7066831, 10.7883801), 4326)),
(212, ST_SetSRID(ST_MakePoint(106.7066683, 10.7883646), 4326)),
(213, ST_SetSRID(ST_MakePoint(106.7056131, 10.7873261), 4326)),
(214, ST_SetSRID(ST_MakePoint(106.7053266, 10.787037), 4326)),
(215, ST_SetSRID(ST_MakePoint(106.7060466, 10.7876341), 4326)),
(216, ST_SetSRID(ST_MakePoint(106.7060567, 10.7876422), 4326)),
(217, ST_SetSRID(ST_MakePoint(106.7064473, 10.788025), 4326)),
(218, ST_SetSRID(ST_MakePoint(106.7060376, 10.7876198), 4326)),
(219, ST_SetSRID(ST_MakePoint(106.7060684, 10.7876479), 4326)),
(220, ST_SetSRID(ST_MakePoint(106.7063744, 10.7879472), 4326)),
(221, ST_SetSRID(ST_MakePoint(106.7060327, 10.7876037), 4326)),
(222, ST_SetSRID(ST_MakePoint(106.706282, 10.7878485), 4326)),
(223, ST_SetSRID(ST_MakePoint(106.7053945, 10.7869754), 4326)),
(224, ST_SetSRID(ST_MakePoint(106.7060929, 10.7876561), 4326)),
(225, ST_SetSRID(ST_MakePoint(106.7054017, 10.7869688), 4326)),
(226, ST_SetSRID(ST_MakePoint(106.706032, 10.7875874), 4326)),
(227, ST_SetSRID(ST_MakePoint(106.7061183, 10.7876583), 4326)),
(228, ST_SetSRID(ST_MakePoint(106.7060356, 10.7875715), 4326)),
(229, ST_SetSRID(ST_MakePoint(106.7061435, 10.7876545), 4326)),
(230, ST_SetSRID(ST_MakePoint(106.7070316, 10.7885092), 4326)),
(231, ST_SetSRID(ST_MakePoint(106.7054356, 10.7869381), 4326)),
(232, ST_SetSRID(ST_MakePoint(106.7060495, 10.7875388), 4326)),
(233, ST_SetSRID(ST_MakePoint(106.7067512, 10.7882124), 4326)),
(234, ST_SetSRID(ST_MakePoint(106.7061728, 10.7876429), 4326)),
(235, ST_SetSRID(ST_MakePoint(106.7054577, 10.786918), 4326)),
(236, ST_SetSRID(ST_MakePoint(106.7064447, 10.7878834), 4326)),
(237, ST_SetSRID(ST_MakePoint(106.7060715, 10.7875106), 4326)),
(238, ST_SetSRID(ST_MakePoint(106.706363, 10.7877956), 4326)),
(239, ST_SetSRID(ST_MakePoint(106.7062019, 10.7876227), 4326)),
(240, ST_SetSRID(ST_MakePoint(106.7060976, 10.7874904), 4326)),
(241, ST_SetSRID(ST_MakePoint(106.7054882, 10.7868903), 4326)),
(242, ST_SetSRID(ST_MakePoint(106.706221, 10.7876034), 4326)),
(243, ST_SetSRID(ST_MakePoint(106.7061274, 10.7874763), 4326)),
(244, ST_SetSRID(ST_MakePoint(106.7064804, 10.787823), 4326)),
(245, ST_SetSRID(ST_MakePoint(106.7062354, 10.7875819), 4326)),
(246, ST_SetSRID(ST_MakePoint(106.7055116, 10.7868691), 4326)),
(247, ST_SetSRID(ST_MakePoint(106.7065077, 10.7878294), 4326)),
(248, ST_SetSRID(ST_MakePoint(106.7068322, 10.7881383), 4326)),
(249, ST_SetSRID(ST_MakePoint(106.7067531, 10.7880586), 4326)),
(250, ST_SetSRID(ST_MakePoint(106.7061536, 10.7874697), 4326)),
(251, ST_SetSRID(ST_MakePoint(106.7062459, 10.7875583), 4326)),
(252, ST_SetSRID(ST_MakePoint(106.7067665, 10.7880685), 4326)),
(253, ST_SetSRID(ST_MakePoint(106.7067425, 10.7880436), 4326)),
(254, ST_SetSRID(ST_MakePoint(106.7067823, 10.7880741), 4326)),
(255, ST_SetSRID(ST_MakePoint(106.7067375, 10.7880261), 4326)),
(256, ST_SetSRID(ST_MakePoint(106.7061804, 10.7874677), 4326)),
(257, ST_SetSRID(ST_MakePoint(106.706799, 10.7880747), 4326)),
(258, ST_SetSRID(ST_MakePoint(106.7062522, 10.7875333), 4326)),
(259, ST_SetSRID(ST_MakePoint(106.7067387, 10.7880079), 4326)),
(260, ST_SetSRID(ST_MakePoint(106.7071595, 10.7884182), 4326)),
(261, ST_SetSRID(ST_MakePoint(106.705553, 10.7868315), 4326)),
(262, ST_SetSRID(ST_MakePoint(106.7068177, 10.7880731), 4326)),
(263, ST_SetSRID(ST_MakePoint(106.706251, 10.787516), 4326)),
(264, ST_SetSRID(ST_MakePoint(106.7062072, 10.7874704), 4326)),
(265, ST_SetSRID(ST_MakePoint(106.7062448, 10.7874997), 4326)),
(266, ST_SetSRID(ST_MakePoint(106.7062223, 10.7874767), 4326)),
(267, ST_SetSRID(ST_MakePoint(106.706747, 10.7879914), 4326)),
(268, ST_SetSRID(ST_MakePoint(106.7066018, 10.7878481), 4326)),
(269, ST_SetSRID(ST_MakePoint(106.7062351, 10.7874867), 4326)),
(270, ST_SetSRID(ST_MakePoint(106.7068362, 10.7880761), 4326)),
(271, ST_SetSRID(ST_MakePoint(106.7065001, 10.7877418), 4326)),
(272, ST_SetSRID(ST_MakePoint(106.7068533, 10.7880836), 4326)),
(273, ST_SetSRID(ST_MakePoint(106.7068673, 10.7880945), 4326)),
(274, ST_SetSRID(ST_MakePoint(106.7062049, 10.7874401), 4326)),
(275, ST_SetSRID(ST_MakePoint(106.7067487, 10.787973), 4326)),
(276, ST_SetSRID(ST_MakePoint(106.7068835, 10.7881019), 4326)),
(277, ST_SetSRID(ST_MakePoint(106.7067066, 10.787923), 4326)),
(278, ST_SetSRID(ST_MakePoint(106.7067182, 10.7879318), 4326)),
(279, ST_SetSRID(ST_MakePoint(106.7066979, 10.7879114), 4326)),
(280, ST_SetSRID(ST_MakePoint(106.7067438, 10.7879559), 4326)),
(281, ST_SetSRID(ST_MakePoint(106.7067332, 10.7879416), 4326)),
(282, ST_SetSRID(ST_MakePoint(106.7069009, 10.7881054), 4326)),
(283, ST_SetSRID(ST_MakePoint(106.7066927, 10.7878979), 4326)),
(284, ST_SetSRID(ST_MakePoint(106.7057599, 10.7869778), 4326)),
(285, ST_SetSRID(ST_MakePoint(106.7055838, 10.7868035), 4326)),
(286, ST_SetSRID(ST_MakePoint(106.7057155, 10.7869317), 4326)),
(287, ST_SetSRID(ST_MakePoint(106.7056218, 10.7868343), 4326)),
(288, ST_SetSRID(ST_MakePoint(106.7055906, 10.7868018), 4326)),
(289, ST_SetSRID(ST_MakePoint(106.7066917, 10.7878809), 4326)),
(290, ST_SetSRID(ST_MakePoint(106.7069196, 10.7881046), 4326)),
(291, ST_SetSRID(ST_MakePoint(106.7069634, 10.7881443), 4326)),
(292, ST_SetSRID(ST_MakePoint(106.7069338, 10.7880985), 4326)),
(293, ST_SetSRID(ST_MakePoint(106.7066964, 10.7878645), 4326)),
(294, ST_SetSRID(ST_MakePoint(106.7067061, 10.7878505), 4326)),
(295, ST_SetSRID(ST_MakePoint(106.7069499, 10.7880843), 4326)),
(296, ST_SetSRID(ST_MakePoint(106.7069569, 10.7880695), 4326)),
(297, ST_SetSRID(ST_MakePoint(106.7056299, 10.7867614), 4326)),
(298, ST_SetSRID(ST_MakePoint(106.7070092, 10.7881158), 4326)),
(299, ST_SetSRID(ST_MakePoint(106.7058847, 10.7869988), 4326)),
(300, ST_SetSRID(ST_MakePoint(106.7069586, 10.7880533), 4326)),
(301, ST_SetSRID(ST_MakePoint(106.706957, 10.7880295), 4326)),
(302, ST_SetSRID(ST_MakePoint(106.7068748, 10.7879351), 4326)),
(303, ST_SetSRID(ST_MakePoint(106.7069606, 10.7880059), 4326)),
(304, ST_SetSRID(ST_MakePoint(106.7067626, 10.787806), 4326)),
(305, ST_SetSRID(ST_MakePoint(106.7059672, 10.7870156), 4326)),
(306, ST_SetSRID(ST_MakePoint(106.7063933, 10.7874317), 4326)),
(307, ST_SetSRID(ST_MakePoint(106.7069687, 10.7879846), 4326)),
(308, ST_SetSRID(ST_MakePoint(106.7067801, 10.787795), 4326)),
(309, ST_SetSRID(ST_MakePoint(106.7060132, 10.7870281), 4326)),
(310, ST_SetSRID(ST_MakePoint(106.7067993, 10.7877875), 4326)),
(311, ST_SetSRID(ST_MakePoint(106.7058264, 10.7868314), 4326)),
(312, ST_SetSRID(ST_MakePoint(106.7069811, 10.7879654), 4326)),
(313, ST_SetSRID(ST_MakePoint(106.7068984, 10.7878832), 4326)),
(314, ST_SetSRID(ST_MakePoint(106.7069063, 10.7878883), 4326)),
(315, ST_SetSRID(ST_MakePoint(106.7069138, 10.7878932), 4326)),
(316, ST_SetSRID(ST_MakePoint(106.7068904, 10.7878681), 4326)),
(317, ST_SetSRID(ST_MakePoint(106.7060483, 10.7870376), 4326)),
(318, ST_SetSRID(ST_MakePoint(106.7060188, 10.7870082), 4326)),
(319, ST_SetSRID(ST_MakePoint(106.7070702, 10.7880332), 4326)),
(320, ST_SetSRID(ST_MakePoint(106.7069323, 10.7878943), 4326)),
(321, ST_SetSRID(ST_MakePoint(106.7068203, 10.7877837), 4326)),
(322, ST_SetSRID(ST_MakePoint(106.7068905, 10.7878511), 4326)),
(323, ST_SetSRID(ST_MakePoint(106.7069876, 10.7879455), 4326)),
(324, ST_SetSRID(ST_MakePoint(106.7069471, 10.7878943), 4326)),
(325, ST_SetSRID(ST_MakePoint(106.7069848, 10.7879248), 4326)),
(326, ST_SetSRID(ST_MakePoint(106.70657, 10.7875173), 4326)),
(327, ST_SetSRID(ST_MakePoint(106.7068415, 10.7877839), 4326)),
(328, ST_SetSRID(ST_MakePoint(106.706893, 10.787832), 4326)),
(329, ST_SetSRID(ST_MakePoint(106.7069611, 10.7878988), 4326)),
(330, ST_SetSRID(ST_MakePoint(106.7069732, 10.7879073), 4326)),
(331, ST_SetSRID(ST_MakePoint(106.7061216, 10.7870625), 4326)),
(332, ST_SetSRID(ST_MakePoint(106.7068624, 10.7877882), 4326)),
(333, ST_SetSRID(ST_MakePoint(106.7068882, 10.7878132), 4326)),
(334, ST_SetSRID(ST_MakePoint(106.7068776, 10.7877985), 4326)),
(335, ST_SetSRID(ST_MakePoint(106.7057298, 10.78667), 4326)),
(336, ST_SetSRID(ST_MakePoint(106.7066694, 10.7875879), 4326)),
(337, ST_SetSRID(ST_MakePoint(106.7064846, 10.7873856), 4326)),
(338, ST_SetSRID(ST_MakePoint(106.7067533, 10.7876422), 4326)),
(339, ST_SetSRID(ST_MakePoint(106.7061932, 10.7870916), 4326)),
(340, ST_SetSRID(ST_MakePoint(106.7067718, 10.7876542), 4326)),
(341, ST_SetSRID(ST_MakePoint(106.7057551, 10.7866468), 4326)),
(342, ST_SetSRID(ST_MakePoint(106.7062385, 10.7871204), 4326)),
(343, ST_SetSRID(ST_MakePoint(106.7064366, 10.7873116), 4326)),
(344, ST_SetSRID(ST_MakePoint(106.7062604, 10.7871343), 4326)),
(345, ST_SetSRID(ST_MakePoint(106.706402, 10.7872662), 4326)),
(346, ST_SetSRID(ST_MakePoint(106.7063226, 10.7871838), 4326)),
(347, ST_SetSRID(ST_MakePoint(106.7063639, 10.7872235), 4326)),
(348, ST_SetSRID(ST_MakePoint(106.7071759, 10.7880136), 4326)),
(349, ST_SetSRID(ST_MakePoint(106.7058919, 10.7867512), 4326)),
(350, ST_SetSRID(ST_MakePoint(106.7066763, 10.7875162), 4326)),
(351, ST_SetSRID(ST_MakePoint(106.7066471, 10.7874862), 4326)),
(352, ST_SetSRID(ST_MakePoint(106.7066869, 10.7875201), 4326)),
(353, ST_SetSRID(ST_MakePoint(106.7066416, 10.7874732), 4326)),
(354, ST_SetSRID(ST_MakePoint(106.7069043, 10.7877312), 4326)),
(355, ST_SetSRID(ST_MakePoint(106.7066981, 10.7875218), 4326)),
(356, ST_SetSRID(ST_MakePoint(106.7057829, 10.7866214), 4326)),
(357, ST_SetSRID(ST_MakePoint(106.7057725, 10.7866109), 4326)),
(358, ST_SetSRID(ST_MakePoint(106.7066408, 10.7874592), 4326)),
(359, ST_SetSRID(ST_MakePoint(106.7067926, 10.7876075), 4326)),
(360, ST_SetSRID(ST_MakePoint(106.7065392, 10.7873584), 4326)),
(361, ST_SetSRID(ST_MakePoint(106.7068262, 10.7876332), 4326)),
(362, ST_SetSRID(ST_MakePoint(106.7067121, 10.7875206), 4326)),
(363, ST_SetSRID(ST_MakePoint(106.7066435, 10.7874484), 4326)),
(364, ST_SetSRID(ST_MakePoint(106.7068614, 10.7876568), 4326)),
(365, ST_SetSRID(ST_MakePoint(106.7057968, 10.7866087), 4326)),
(366, ST_SetSRID(ST_MakePoint(106.7067252, 10.7875158), 4326)),
(367, ST_SetSRID(ST_MakePoint(106.7066491, 10.7874388), 4326)),
(368, ST_SetSRID(ST_MakePoint(106.7069274, 10.7876929), 4326)),
(369, ST_SetSRID(ST_MakePoint(106.7070407, 10.7878011), 4326)),
(370, ST_SetSRID(ST_MakePoint(106.7072176, 10.7879687), 4326)),
(371, ST_SetSRID(ST_MakePoint(106.7074601, 10.7882042), 4326)),
(372, ST_SetSRID(ST_MakePoint(106.7069618, 10.7877083), 4326)),
(373, ST_SetSRID(ST_MakePoint(106.7073385, 10.7880751), 4326)),
(374, ST_SetSRID(ST_MakePoint(106.7070851, 10.787825), 4326)),
(375, ST_SetSRID(ST_MakePoint(106.7071678, 10.7879041), 4326)),
(376, ST_SetSRID(ST_MakePoint(106.7071477, 10.7878788), 4326)),
(377, ST_SetSRID(ST_MakePoint(106.7071249, 10.7878557), 4326)),
(378, ST_SetSRID(ST_MakePoint(106.7067457, 10.7874783), 4326)),
(379, ST_SetSRID(ST_MakePoint(106.7069972, 10.7877213), 4326)),
(380, ST_SetSRID(ST_MakePoint(106.7066632, 10.7873828), 4326)),
(381, ST_SetSRID(ST_MakePoint(106.7067512, 10.7874645), 4326)),
(382, ST_SetSRID(ST_MakePoint(106.7059632, 10.786676), 4326)),
(383, ST_SetSRID(ST_MakePoint(106.7070429, 10.7877342), 4326)),
(384, ST_SetSRID(ST_MakePoint(106.7067543, 10.7874481), 4326)),
(385, ST_SetSRID(ST_MakePoint(106.7072322, 10.7879162), 4326)),
(386, ST_SetSRID(ST_MakePoint(106.7066197, 10.7873145), 4326)),
(387, ST_SetSRID(ST_MakePoint(106.7073545, 10.7880358), 4326)),
(388, ST_SetSRID(ST_MakePoint(106.7067343, 10.7874213), 4326)),
(389, ST_SetSRID(ST_MakePoint(106.7067429, 10.7874288), 4326)),
(390, ST_SetSRID(ST_MakePoint(106.7067541, 10.7874315), 4326)),
(391, ST_SetSRID(ST_MakePoint(106.706712, 10.7873864), 4326)),
(392, ST_SetSRID(ST_MakePoint(106.7072486, 10.7879097), 4326)),
(393, ST_SetSRID(ST_MakePoint(106.7072442, 10.7879051), 4326)),
(394, ST_SetSRID(ST_MakePoint(106.7071902, 10.7878485), 4326)),
(395, ST_SetSRID(ST_MakePoint(106.7071409, 10.7877968), 4326)),
(396, ST_SetSRID(ST_MakePoint(106.7067665, 10.7874282), 4326)),
(397, ST_SetSRID(ST_MakePoint(106.7070897, 10.7877431), 4326)),
(398, ST_SetSRID(ST_MakePoint(106.7063252, 10.7869886), 4326)),
(399, ST_SetSRID(ST_MakePoint(106.7067754, 10.787419), 4326)),
(400, ST_SetSRID(ST_MakePoint(106.7073774, 10.788), 4326));
INSERT INTO walkways_vertices_pgr (id, the_geom) VALUES
(401, ST_SetSRID(ST_MakePoint(106.7075765, 10.7881948), 4326)),
(402, ST_SetSRID(ST_MakePoint(106.7067843, 10.7874137), 4326)),
(403, ST_SetSRID(ST_MakePoint(106.7075339, 10.7881442), 4326)),
(404, ST_SetSRID(ST_MakePoint(106.7067918, 10.787414), 4326)),
(405, ST_SetSRID(ST_MakePoint(106.7066661, 10.7872892), 4326)),
(406, ST_SetSRID(ST_MakePoint(106.7067983, 10.7874177), 4326)),
(407, ST_SetSRID(ST_MakePoint(106.7071105, 10.78772), 4326)),
(408, ST_SetSRID(ST_MakePoint(106.7068094, 10.7874223), 4326)),
(409, ST_SetSRID(ST_MakePoint(106.7067355, 10.7873495), 4326)),
(410, ST_SetSRID(ST_MakePoint(106.7070857, 10.7876924), 4326)),
(411, ST_SetSRID(ST_MakePoint(106.7072801, 10.7878801), 4326)),
(412, ST_SetSRID(ST_MakePoint(106.7072405, 10.7878383), 4326)),
(413, ST_SetSRID(ST_MakePoint(106.707223, 10.7878198), 4326)),
(414, ST_SetSRID(ST_MakePoint(106.7072036, 10.7877994), 4326)),
(415, ST_SetSRID(ST_MakePoint(106.7071734, 10.7877675), 4326)),
(416, ST_SetSRID(ST_MakePoint(106.7068215, 10.7874218), 4326)),
(417, ST_SetSRID(ST_MakePoint(106.707144, 10.7877365), 4326)),
(418, ST_SetSRID(ST_MakePoint(106.7068724, 10.7874681), 4326)),
(419, ST_SetSRID(ST_MakePoint(106.7068894, 10.7874813), 4326)),
(420, ST_SetSRID(ST_MakePoint(106.7060194, 10.7866237), 4326)),
(421, ST_SetSRID(ST_MakePoint(106.7068624, 10.7874509), 4326)),
(422, ST_SetSRID(ST_MakePoint(106.7067487, 10.7873391), 4326)),
(423, ST_SetSRID(ST_MakePoint(106.7069137, 10.7875004), 4326)),
(424, ST_SetSRID(ST_MakePoint(106.7068315, 10.787417), 4326)),
(425, ST_SetSRID(ST_MakePoint(106.7069103, 10.7874872), 4326)),
(426, ST_SetSRID(ST_MakePoint(106.7068592, 10.7874314), 4326)),
(427, ST_SetSRID(ST_MakePoint(106.7074065, 10.7879685), 4326)),
(428, ST_SetSRID(ST_MakePoint(106.7068387, 10.7874086), 4326)),
(429, ST_SetSRID(ST_MakePoint(106.7067646, 10.7873335), 4326)),
(430, ST_SetSRID(ST_MakePoint(106.7068579, 10.7874171), 4326)),
(431, ST_SetSRID(ST_MakePoint(106.7069318, 10.7874849), 4326)),
(432, ST_SetSRID(ST_MakePoint(106.7067801, 10.7873332), 4326)),
(433, ST_SetSRID(ST_MakePoint(106.7068537, 10.7874035), 4326)),
(434, ST_SetSRID(ST_MakePoint(106.7068476, 10.7873926), 4326)),
(435, ST_SetSRID(ST_MakePoint(106.7068396, 10.7873829), 4326)),
(436, ST_SetSRID(ST_MakePoint(106.7067949, 10.7873374), 4326)),
(437, ST_SetSRID(ST_MakePoint(106.7068174, 10.7873576), 4326)),
(438, ST_SetSRID(ST_MakePoint(106.7068077, 10.7873458), 4326)),
(439, ST_SetSRID(ST_MakePoint(106.7072885, 10.7877951), 4326)),
(440, ST_SetSRID(ST_MakePoint(106.7074409, 10.7879427), 4326)),
(441, ST_SetSRID(ST_MakePoint(106.7072523, 10.7877569), 4326)),
(442, ST_SetSRID(ST_MakePoint(106.7060626, 10.7865877), 4326)),
(443, ST_SetSRID(ST_MakePoint(106.7072933, 10.7877846), 4326)),
(444, ST_SetSRID(ST_MakePoint(106.7072647, 10.7877528), 4326)),
(445, ST_SetSRID(ST_MakePoint(106.706965, 10.7874566), 4326)),
(446, ST_SetSRID(ST_MakePoint(106.7059554, 10.7864635), 4326)),
(447, ST_SetSRID(ST_MakePoint(106.7072932, 10.7877731), 4326)),
(448, ST_SetSRID(ST_MakePoint(106.705958, 10.7864611), 4326)),
(449, ST_SetSRID(ST_MakePoint(106.7068877, 10.7873736), 4326)),
(450, ST_SetSRID(ST_MakePoint(106.7072776, 10.7877549), 4326)),
(451, ST_SetSRID(ST_MakePoint(106.7068491, 10.7873321), 4326)),
(452, ST_SetSRID(ST_MakePoint(106.707288, 10.7877627), 4326)),
(453, ST_SetSRID(ST_MakePoint(106.7060785, 10.7865745), 4326)),
(454, ST_SetSRID(ST_MakePoint(106.7067585, 10.7872349), 4326)),
(455, ST_SetSRID(ST_MakePoint(106.7074794, 10.7879234), 4326)),
(456, ST_SetSRID(ST_MakePoint(106.7071477, 10.7875772), 4326)),
(457, ST_SetSRID(ST_MakePoint(106.7068871, 10.7873193), 4326)),
(458, ST_SetSRID(ST_MakePoint(106.7068778, 10.787309), 4326)),
(459, ST_SetSRID(ST_MakePoint(106.7068979, 10.7873281), 4326)),
(460, ST_SetSRID(ST_MakePoint(106.707386, 10.7878062), 4326)),
(461, ST_SetSRID(ST_MakePoint(106.7068733, 10.7872998), 4326)),
(462, ST_SetSRID(ST_MakePoint(106.7069109, 10.7873355), 4326)),
(463, ST_SetSRID(ST_MakePoint(106.707319, 10.7877355), 4326)),
(464, ST_SetSRID(ST_MakePoint(106.7067906, 10.7872161), 4326)),
(465, ST_SetSRID(ST_MakePoint(106.7068708, 10.7872899), 4326)),
(466, ST_SetSRID(ST_MakePoint(106.7069251, 10.7873406), 4326)),
(467, ST_SetSRID(ST_MakePoint(106.7071936, 10.7876002), 4326)),
(468, ST_SetSRID(ST_MakePoint(106.7071617, 10.787565), 4326)),
(469, ST_SetSRID(ST_MakePoint(106.7060006, 10.7864222), 4326)),
(470, ST_SetSRID(ST_MakePoint(106.7074149, 10.7878105), 4326)),
(471, ST_SetSRID(ST_MakePoint(106.7068712, 10.7872732), 4326)),
(472, ST_SetSRID(ST_MakePoint(106.7075209, 10.7879111), 4326)),
(473, ST_SetSRID(ST_MakePoint(106.7071029, 10.7875002), 4326)),
(474, ST_SetSRID(ST_MakePoint(106.7069406, 10.7873378), 4326)),
(475, ST_SetSRID(ST_MakePoint(106.7074125, 10.7878002), 4326)),
(476, ST_SetSRID(ST_MakePoint(106.7070211, 10.78741), 4326)),
(477, ST_SetSRID(ST_MakePoint(106.7070131, 10.787401), 4326)),
(478, ST_SetSRID(ST_MakePoint(106.7069506, 10.7873321), 4326)),
(479, ST_SetSRID(ST_MakePoint(106.7068772, 10.7872576), 4326)),
(480, ST_SetSRID(ST_MakePoint(106.7069542, 10.7873301), 4326)),
(481, ST_SetSRID(ST_MakePoint(106.7071198, 10.787485), 4326)),
(482, ST_SetSRID(ST_MakePoint(106.7071122, 10.7874745), 4326)),
(483, ST_SetSRID(ST_MakePoint(106.7071081, 10.7874623), 4326)),
(484, ST_SetSRID(ST_MakePoint(106.7068882, 10.7872448), 4326)),
(485, ST_SetSRID(ST_MakePoint(106.7069344, 10.7872847), 4326)),
(486, ST_SetSRID(ST_MakePoint(106.7069665, 10.7873151), 4326)),
(487, ST_SetSRID(ST_MakePoint(106.7071078, 10.7874511), 4326)),
(488, ST_SetSRID(ST_MakePoint(106.7070783, 10.7874221), 4326)),
(489, ST_SetSRID(ST_MakePoint(106.7070912, 10.7874346), 4326)),
(490, ST_SetSRID(ST_MakePoint(106.7071041, 10.7874447), 4326)),
(491, ST_SetSRID(ST_MakePoint(106.7070508, 10.7873892), 4326)),
(492, ST_SetSRID(ST_MakePoint(106.7070697, 10.7874063), 4326)),
(493, ST_SetSRID(ST_MakePoint(106.7070401, 10.7873768), 4326)),
(494, ST_SetSRID(ST_MakePoint(106.7070581, 10.7873909), 4326)),
(495, ST_SetSRID(ST_MakePoint(106.7070679, 10.7874003), 4326)),
(496, ST_SetSRID(ST_MakePoint(106.7070642, 10.7873951), 4326)),
(497, ST_SetSRID(ST_MakePoint(106.7069026, 10.7872345), 4326)),
(498, ST_SetSRID(ST_MakePoint(106.706974, 10.7872975), 4326)),
(499, ST_SetSRID(ST_MakePoint(106.7070451, 10.7873653), 4326)),
(500, ST_SetSRID(ST_MakePoint(106.706975, 10.7872894), 4326)),
(501, ST_SetSRID(ST_MakePoint(106.7070513, 10.7873606), 4326)),
(502, ST_SetSRID(ST_MakePoint(106.7071504, 10.7874575), 4326)),
(503, ST_SetSRID(ST_MakePoint(106.706919, 10.787228), 4326)),
(504, ST_SetSRID(ST_MakePoint(106.7069763, 10.7872782), 4326)),
(505, ST_SetSRID(ST_MakePoint(106.7070588, 10.7873584), 4326)),
(506, ST_SetSRID(ST_MakePoint(106.7068676, 10.7871649), 4326)),
(507, ST_SetSRID(ST_MakePoint(106.7069735, 10.787266), 4326)),
(508, ST_SetSRID(ST_MakePoint(106.7069381, 10.7872286), 4326)),
(509, ST_SetSRID(ST_MakePoint(106.707067, 10.7873548), 4326)),
(510, ST_SetSRID(ST_MakePoint(106.7071606, 10.7874457), 4326)),
(511, ST_SetSRID(ST_MakePoint(106.706972, 10.7872593), 4326)),
(512, ST_SetSRID(ST_MakePoint(106.706965, 10.7872471), 4326)),
(513, ST_SetSRID(ST_MakePoint(106.7069552, 10.7872369), 4326)),
(514, ST_SetSRID(ST_MakePoint(106.7076137, 10.7878806), 4326)),
(515, ST_SetSRID(ST_MakePoint(106.7070733, 10.7873485), 4326)),
(516, ST_SetSRID(ST_MakePoint(106.7071665, 10.7874312), 4326)),
(517, ST_SetSRID(ST_MakePoint(106.7070772, 10.7873372), 4326)),
(518, ST_SetSRID(ST_MakePoint(106.7071673, 10.7874153), 4326)),
(519, ST_SetSRID(ST_MakePoint(106.7070143, 10.7872622), 4326)),
(520, ST_SetSRID(ST_MakePoint(106.7070853, 10.7873284), 4326)),
(521, ST_SetSRID(ST_MakePoint(106.7075384, 10.7877718), 4326)),
(522, ST_SetSRID(ST_MakePoint(106.7071627, 10.7874), 4326)),
(523, ST_SetSRID(ST_MakePoint(106.7071534, 10.7873871), 4326)),
(524, ST_SetSRID(ST_MakePoint(106.707146, 10.7873712), 4326)),
(525, ST_SetSRID(ST_MakePoint(106.7070984, 10.7873232), 4326)),
(526, ST_SetSRID(ST_MakePoint(106.7071219, 10.787339), 4326)),
(527, ST_SetSRID(ST_MakePoint(106.7075304, 10.7877378), 4326)),
(528, ST_SetSRID(ST_MakePoint(106.7071165, 10.7873307), 4326)),
(529, ST_SetSRID(ST_MakePoint(106.7071125, 10.7873245), 4326)),
(530, ST_SetSRID(ST_MakePoint(106.7070481, 10.7872556), 4326)),
(531, ST_SetSRID(ST_MakePoint(106.7071168, 10.7873106), 4326)),
(532, ST_SetSRID(ST_MakePoint(106.7072345, 10.787423), 4326)),
(533, ST_SetSRID(ST_MakePoint(106.707063, 10.7872539), 4326)),
(534, ST_SetSRID(ST_MakePoint(106.7071148, 10.7872988), 4326)),
(535, ST_SetSRID(ST_MakePoint(106.7070776, 10.787257), 4326)),
(536, ST_SetSRID(ST_MakePoint(106.7075899, 10.7877602), 4326)),
(537, ST_SetSRID(ST_MakePoint(106.7070998, 10.7872754), 4326)),
(538, ST_SetSRID(ST_MakePoint(106.7070902, 10.7872644), 4326)),
(539, ST_SetSRID(ST_MakePoint(106.706956, 10.7871104), 4326)),
(540, ST_SetSRID(ST_MakePoint(106.7077039, 10.7878432), 4326)),
(541, ST_SetSRID(ST_MakePoint(106.7071588, 10.7872925), 4326)),
(542, ST_SetSRID(ST_MakePoint(106.7071437, 10.7872645), 4326)),
(543, ST_SetSRID(ST_MakePoint(106.7071252, 10.7872385), 4326)),
(544, ST_SetSRID(ST_MakePoint(106.7070877, 10.787201), 4326)),
(545, ST_SetSRID(ST_MakePoint(106.7071074, 10.7872188), 4326)),
(546, ST_SetSRID(ST_MakePoint(106.7076614, 10.7877434), 4326)),
(547, ST_SetSRID(ST_MakePoint(106.706182, 10.7862562), 4326)),
(548, ST_SetSRID(ST_MakePoint(106.7078488, 10.787888), 4326)),
(549, ST_SetSRID(ST_MakePoint(106.7077881, 10.7878008), 4326)),
(550, ST_SetSRID(ST_MakePoint(106.7073304, 10.7873406), 4326)),
(551, ST_SetSRID(ST_MakePoint(106.7077307, 10.7877194), 4326)),
(552, ST_SetSRID(ST_MakePoint(106.7070543, 10.7870539), 4326)),
(553, ST_SetSRID(ST_MakePoint(106.7073356, 10.7873235), 4326)),
(554, ST_SetSRID(ST_MakePoint(106.7072637, 10.7872477), 4326)),
(555, ST_SetSRID(ST_MakePoint(106.7073438, 10.7873077), 4326)),
(556, ST_SetSRID(ST_MakePoint(106.7062305, 10.7862118), 4326)),
(557, ST_SetSRID(ST_MakePoint(106.7078298, 10.7877786), 4326)),
(558, ST_SetSRID(ST_MakePoint(106.7073592, 10.7872892), 4326)),
(559, ST_SetSRID(ST_MakePoint(106.7080247, 10.7879154), 4326)),
(560, ST_SetSRID(ST_MakePoint(106.7073786, 10.787275), 4326)),
(561, ST_SetSRID(ST_MakePoint(106.7078689, 10.7877523), 4326)),
(562, ST_SetSRID(ST_MakePoint(106.7078034, 10.7876851), 4326)),
(563, ST_SetSRID(ST_MakePoint(106.7079369, 10.7878142), 4326)),
(564, ST_SetSRID(ST_MakePoint(106.7069863, 10.7868793), 4326)),
(565, ST_SetSRID(ST_MakePoint(106.707401, 10.7872658), 4326)),
(566, ST_SetSRID(ST_MakePoint(106.707425, 10.7872622), 4326)),
(567, ST_SetSRID(ST_MakePoint(106.7064802, 10.7863315), 4326)),
(568, ST_SetSRID(ST_MakePoint(106.7078384, 10.7876655), 4326)),
(569, ST_SetSRID(ST_MakePoint(106.7071648, 10.7869961), 4326)),
(570, ST_SetSRID(ST_MakePoint(106.7079102, 10.7877174), 4326)),
(571, ST_SetSRID(ST_MakePoint(106.7079801, 10.7877781), 4326)),
(572, ST_SetSRID(ST_MakePoint(106.7078716, 10.787643), 4326)),
(573, ST_SetSRID(ST_MakePoint(106.7076377, 10.7874018), 4326)),
(574, ST_SetSRID(ST_MakePoint(106.7079469, 10.7876779), 4326)),
(575, ST_SetSRID(ST_MakePoint(106.7069357, 10.7866766), 4326)),
(576, ST_SetSRID(ST_MakePoint(106.7069812, 10.7867178), 4326)),
(577, ST_SetSRID(ST_MakePoint(106.7068939, 10.7866319), 4326)),
(578, ST_SetSRID(ST_MakePoint(106.7072391, 10.7869672), 4326)),
(579, ST_SetSRID(ST_MakePoint(106.7068712, 10.7866028), 4326)),
(580, ST_SetSRID(ST_MakePoint(106.70703, 10.786755), 4326)),
(581, ST_SetSRID(ST_MakePoint(106.7068528, 10.7865792), 4326)),
(582, ST_SetSRID(ST_MakePoint(106.7070499, 10.7867657), 4326)),
(583, ST_SetSRID(ST_MakePoint(106.7068331, 10.7865522), 4326)),
(584, ST_SetSRID(ST_MakePoint(106.7079147, 10.7876064), 4326)),
(585, ST_SetSRID(ST_MakePoint(106.7068168, 10.7865232), 4326)),
(586, ST_SetSRID(ST_MakePoint(106.7070961, 10.7867907), 4326)),
(587, ST_SetSRID(ST_MakePoint(106.7068045, 10.7864938), 4326)),
(588, ST_SetSRID(ST_MakePoint(106.7074904, 10.7871668), 4326)),
(589, ST_SetSRID(ST_MakePoint(106.7073658, 10.7870393), 4326)),
(590, ST_SetSRID(ST_MakePoint(106.7079786, 10.7876343), 4326)),
(591, ST_SetSRID(ST_MakePoint(106.7076399, 10.7872985), 4326)),
(592, ST_SetSRID(ST_MakePoint(106.7079801, 10.7876316), 4326)),
(593, ST_SetSRID(ST_MakePoint(106.7076169, 10.7872713), 4326)),
(594, ST_SetSRID(ST_MakePoint(106.7067957, 10.7864632), 4326)),
(595, ST_SetSRID(ST_MakePoint(106.7071648, 10.7868211), 4326)),
(596, ST_SetSRID(ST_MakePoint(106.7076606, 10.7873031), 4326)),
(597, ST_SetSRID(ST_MakePoint(106.7073985, 10.7870389), 4326)),
(598, ST_SetSRID(ST_MakePoint(106.7076818, 10.7873018), 4326)),
(599, ST_SetSRID(ST_MakePoint(106.7072125, 10.7868377), 4326)),
(600, ST_SetSRID(ST_MakePoint(106.7079529, 10.7875649), 4326));
INSERT INTO walkways_vertices_pgr (id, the_geom) VALUES
(601, ST_SetSRID(ST_MakePoint(106.7073123, 10.7869355), 4326)),
(602, ST_SetSRID(ST_MakePoint(106.7074307, 10.7870452), 4326)),
(603, ST_SetSRID(ST_MakePoint(106.7076246, 10.7872354), 4326)),
(604, ST_SetSRID(ST_MakePoint(106.7072359, 10.7868459), 4326)),
(605, ST_SetSRID(ST_MakePoint(106.7080015, 10.7875935), 4326)),
(606, ST_SetSRID(ST_MakePoint(106.7074556, 10.7870553), 4326)),
(607, ST_SetSRID(ST_MakePoint(106.7077014, 10.7872948), 4326)),
(608, ST_SetSRID(ST_MakePoint(106.7075349, 10.7871302), 4326)),
(609, ST_SetSRID(ST_MakePoint(106.7080067, 10.7875897), 4326)),
(610, ST_SetSRID(ST_MakePoint(106.7080049, 10.7875874), 4326)),
(611, ST_SetSRID(ST_MakePoint(106.7074784, 10.7870695), 4326)),
(612, ST_SetSRID(ST_MakePoint(106.7067743, 10.7863762), 4326)),
(613, ST_SetSRID(ST_MakePoint(106.7074984, 10.7870873), 4326)),
(614, ST_SetSRID(ST_MakePoint(106.7073354, 10.786925), 4326)),
(615, ST_SetSRID(ST_MakePoint(106.7079704, 10.7875428), 4326)),
(616, ST_SetSRID(ST_MakePoint(106.7067714, 10.7863605), 4326)),
(617, ST_SetSRID(ST_MakePoint(106.7078129, 10.7873802), 4326)),
(618, ST_SetSRID(ST_MakePoint(106.7077183, 10.7872827), 4326)),
(619, ST_SetSRID(ST_MakePoint(106.7077255, 10.7872768), 4326)),
(620, ST_SetSRID(ST_MakePoint(106.7069709, 10.7865279), 4326)),
(621, ST_SetSRID(ST_MakePoint(106.7079855, 10.7875191), 4326)),
(622, ST_SetSRID(ST_MakePoint(106.7073671, 10.7869107), 4326)),
(623, ST_SetSRID(ST_MakePoint(106.7073271, 10.7868689), 4326)),
(624, ST_SetSRID(ST_MakePoint(106.7067583, 10.7862881), 4326)),
(625, ST_SetSRID(ST_MakePoint(106.7079942, 10.7875012), 4326)),
(626, ST_SetSRID(ST_MakePoint(106.7067558, 10.7862672), 4326)),
(627, ST_SetSRID(ST_MakePoint(106.708001, 10.7874873), 4326)),
(628, ST_SetSRID(ST_MakePoint(106.7080523, 10.7875284), 4326)),
(629, ST_SetSRID(ST_MakePoint(106.7072498, 10.7867346), 4326)),
(630, ST_SetSRID(ST_MakePoint(106.7074203, 10.7868828), 4326)),
(631, ST_SetSRID(ST_MakePoint(106.7080123, 10.7874539), 4326)),
(632, ST_SetSRID(ST_MakePoint(106.7067477, 10.7861992), 4326)),
(633, ST_SetSRID(ST_MakePoint(106.7080192, 10.7874193), 4326)),
(634, ST_SetSRID(ST_MakePoint(106.7078068, 10.7872105), 4326)),
(635, ST_SetSRID(ST_MakePoint(106.7067418, 10.7861636), 4326)),
(636, ST_SetSRID(ST_MakePoint(106.7077461, 10.7871386), 4326)),
(637, ST_SetSRID(ST_MakePoint(106.7067402, 10.7861274), 4326)),
(638, ST_SetSRID(ST_MakePoint(106.7068766, 10.7862533), 4326)),
(639, ST_SetSRID(ST_MakePoint(106.7065432, 10.7859257), 4326)),
(640, ST_SetSRID(ST_MakePoint(106.707481, 10.786846), 4326)),
(641, ST_SetSRID(ST_MakePoint(106.7080224, 10.7873672), 4326)),
(642, ST_SetSRID(ST_MakePoint(106.7082294, 10.7875652), 4326)),
(643, ST_SetSRID(ST_MakePoint(106.7067432, 10.7860914), 4326)),
(644, ST_SetSRID(ST_MakePoint(106.7065624, 10.7859082), 4326)),
(645, ST_SetSRID(ST_MakePoint(106.7076363, 10.7869622), 4326)),
(646, ST_SetSRID(ST_MakePoint(106.7080173, 10.7873153), 4326)),
(647, ST_SetSRID(ST_MakePoint(106.7067532, 10.7860468), 4326)),
(648, ST_SetSRID(ST_MakePoint(106.7078823, 10.7871489), 4326)),
(649, ST_SetSRID(ST_MakePoint(106.7080039, 10.7872648), 4326)),
(650, ST_SetSRID(ST_MakePoint(106.7080024, 10.7872615), 4326)),
(651, ST_SetSRID(ST_MakePoint(106.707539, 10.7868051), 4326)),
(652, ST_SetSRID(ST_MakePoint(106.7077782, 10.7870279), 4326)),
(653, ST_SetSRID(ST_MakePoint(106.7066055, 10.7858688), 4326)),
(654, ST_SetSRID(ST_MakePoint(106.7079827, 10.787217), 4326)),
(655, ST_SetSRID(ST_MakePoint(106.707686, 10.7869209), 4326)),
(656, ST_SetSRID(ST_MakePoint(106.7080245, 10.787252), 4326)),
(657, ST_SetSRID(ST_MakePoint(106.70677, 10.7860042), 4326)),
(658, ST_SetSRID(ST_MakePoint(106.7070795, 10.7863065), 4326)),
(659, ST_SetSRID(ST_MakePoint(106.707567, 10.7867827), 4326)),
(660, ST_SetSRID(ST_MakePoint(106.7078257, 10.7869885), 4326)),
(661, ST_SetSRID(ST_MakePoint(106.7075484, 10.7867095), 4326)),
(662, ST_SetSRID(ST_MakePoint(106.7067933, 10.7859646), 4326)),
(663, ST_SetSRID(ST_MakePoint(106.7080825, 10.7872062), 4326)),
(664, ST_SetSRID(ST_MakePoint(106.7076214, 10.7867392), 4326)),
(665, ST_SetSRID(ST_MakePoint(106.7068219, 10.7859365), 4326)),
(666, ST_SetSRID(ST_MakePoint(106.7076458, 10.7867173), 4326)),
(667, ST_SetSRID(ST_MakePoint(106.7075497, 10.7866134), 4326)),
(668, ST_SetSRID(ST_MakePoint(106.7068484, 10.7859184), 4326)),
(669, ST_SetSRID(ST_MakePoint(106.706855, 10.7859139), 4326)),
(670, ST_SetSRID(ST_MakePoint(106.7080695, 10.7870899), 4326)),
(671, ST_SetSRID(ST_MakePoint(106.7076644, 10.7866905), 4326)),
(672, ST_SetSRID(ST_MakePoint(106.7067686, 10.7858057), 4326)),
(673, ST_SetSRID(ST_MakePoint(106.7076761, 10.7866601), 4326)),
(674, ST_SetSRID(ST_MakePoint(106.7068981, 10.7858952), 4326)),
(675, ST_SetSRID(ST_MakePoint(106.7075432, 10.7865207), 4326)),
(676, ST_SetSRID(ST_MakePoint(106.7069055, 10.7858936), 4326)),
(677, ST_SetSRID(ST_MakePoint(106.7084375, 10.7873848), 4326)),
(678, ST_SetSRID(ST_MakePoint(106.7076804, 10.7866279), 4326)),
(679, ST_SetSRID(ST_MakePoint(106.7069442, 10.7858855), 4326)),
(680, ST_SetSRID(ST_MakePoint(106.70768, 10.786601), 4326)),
(681, ST_SetSRID(ST_MakePoint(106.7083507, 10.7872374), 4326)),
(682, ST_SetSRID(ST_MakePoint(106.7075286, 10.786429), 4326)),
(683, ST_SetSRID(ST_MakePoint(106.7072169, 10.7861202), 4326)),
(684, ST_SetSRID(ST_MakePoint(106.7076825, 10.7865742), 4326)),
(685, ST_SetSRID(ST_MakePoint(106.7069894, 10.7858831), 4326)),
(686, ST_SetSRID(ST_MakePoint(106.706875, 10.7857539), 4326)),
(687, ST_SetSRID(ST_MakePoint(106.7084906, 10.7873319), 4326)),
(688, ST_SetSRID(ST_MakePoint(106.7083441, 10.7871781), 4326)),
(689, ST_SetSRID(ST_MakePoint(106.7076918, 10.7865345), 4326)),
(690, ST_SetSRID(ST_MakePoint(106.7070346, 10.7858853), 4326)),
(691, ST_SetSRID(ST_MakePoint(106.7075056, 10.7863372), 4326)),
(692, ST_SetSRID(ST_MakePoint(106.707051, 10.7858878), 4326)),
(693, ST_SetSRID(ST_MakePoint(106.7070793, 10.7858921), 4326)),
(694, ST_SetSRID(ST_MakePoint(106.707488, 10.7862866), 4326)),
(695, ST_SetSRID(ST_MakePoint(106.7077076, 10.7864969), 4326)),
(696, ST_SetSRID(ST_MakePoint(106.707058, 10.7858491), 4326)),
(697, ST_SetSRID(ST_MakePoint(106.7074746, 10.7862478), 4326)),
(698, ST_SetSRID(ST_MakePoint(106.7071272, 10.7859048), 4326)),
(699, ST_SetSRID(ST_MakePoint(106.7085398, 10.7872756), 4326)),
(700, ST_SetSRID(ST_MakePoint(106.7071734, 10.7859227), 4326)),
(701, ST_SetSRID(ST_MakePoint(106.707447, 10.7861882), 4326)),
(702, ST_SetSRID(ST_MakePoint(106.7077295, 10.7864622), 4326)),
(703, ST_SetSRID(ST_MakePoint(106.7070682, 10.7858111), 4326)),
(704, ST_SetSRID(ST_MakePoint(106.7080062, 10.7867223), 4326)),
(705, ST_SetSRID(ST_MakePoint(106.7072172, 10.7859457), 4326)),
(706, ST_SetSRID(ST_MakePoint(106.7070732, 10.7857983), 4326)),
(707, ST_SetSRID(ST_MakePoint(106.7074132, 10.7861318), 4326)),
(708, ST_SetSRID(ST_MakePoint(106.707258, 10.7859735), 4326)),
(709, ST_SetSRID(ST_MakePoint(106.7073733, 10.7860792), 4326)),
(710, ST_SetSRID(ST_MakePoint(106.7072994, 10.7860055), 4326)),
(711, ST_SetSRID(ST_MakePoint(106.7073135, 10.7860183), 4326)),
(712, ST_SetSRID(ST_MakePoint(106.707338, 10.7860408), 4326)),
(713, ST_SetSRID(ST_MakePoint(106.7071256, 10.7858181), 4326)),
(714, ST_SetSRID(ST_MakePoint(106.7077569, 10.7864316), 4326)),
(715, ST_SetSRID(ST_MakePoint(106.7075942, 10.7862511), 4326)),
(716, ST_SetSRID(ST_MakePoint(106.7070909, 10.7857531), 4326)),
(717, ST_SetSRID(ST_MakePoint(106.708585, 10.7872161), 4326)),
(718, ST_SetSRID(ST_MakePoint(106.707105, 10.7857252), 4326)),
(719, ST_SetSRID(ST_MakePoint(106.7071212, 10.7856985), 4326)),
(720, ST_SetSRID(ST_MakePoint(106.7086289, 10.7871474), 4326)),
(721, ST_SetSRID(ST_MakePoint(106.7074406, 10.7859752), 4326)),
(722, ST_SetSRID(ST_MakePoint(106.7075403, 10.78605), 4326)),
(723, ST_SetSRID(ST_MakePoint(106.7074922, 10.7859948), 4326)),
(724, ST_SetSRID(ST_MakePoint(106.7071517, 10.785658), 4326)),
(725, ST_SetSRID(ST_MakePoint(106.7078675, 10.7863512), 4326)),
(726, ST_SetSRID(ST_MakePoint(106.7075457, 10.7860087), 4326)),
(727, ST_SetSRID(ST_MakePoint(106.7086608, 10.7870934), 4326)),
(728, ST_SetSRID(ST_MakePoint(106.707894, 10.786332), 4326)),
(729, ST_SetSRID(ST_MakePoint(106.7071869, 10.7856214), 4326)),
(730, ST_SetSRID(ST_MakePoint(106.7076067, 10.7860174), 4326)),
(731, ST_SetSRID(ST_MakePoint(106.7079158, 10.7863078), 4326)),
(732, ST_SetSRID(ST_MakePoint(106.7086843, 10.7870435), 4326)),
(733, ST_SetSRID(ST_MakePoint(106.7072156, 10.7855953), 4326)),
(734, ST_SetSRID(ST_MakePoint(106.7074357, 10.7858104), 4326)),
(735, ST_SetSRID(ST_MakePoint(106.7076684, 10.7860186), 4326)),
(736, ST_SetSRID(ST_MakePoint(106.7079328, 10.7862776), 4326)),
(737, ST_SetSRID(ST_MakePoint(106.7086919, 10.7870102), 4326)),
(738, ST_SetSRID(ST_MakePoint(106.7079426, 10.7862445), 4326)),
(739, ST_SetSRID(ST_MakePoint(106.7086946, 10.7869762), 4326)),
(740, ST_SetSRID(ST_MakePoint(106.7086923, 10.7869421), 4326)),
(741, ST_SetSRID(ST_MakePoint(106.7081274, 10.7863697), 4326)),
(742, ST_SetSRID(ST_MakePoint(106.7086841, 10.7869057), 4326)),
(743, ST_SetSRID(ST_MakePoint(106.7086701, 10.7868711), 4326)),
(744, ST_SetSRID(ST_MakePoint(106.7086508, 10.786839), 4326)),
(745, ST_SetSRID(ST_MakePoint(106.7086266, 10.7868104), 4326)),
(746, ST_SetSRID(ST_MakePoint(106.70857, 10.7867315), 4326)),
(747, ST_SetSRID(ST_MakePoint(106.7079721, 10.7861174), 4326)),
(748, ST_SetSRID(ST_MakePoint(106.708518, 10.7866496), 4326)),
(749, ST_SetSRID(ST_MakePoint(106.7077951, 10.785931), 4326)),
(750, ST_SetSRID(ST_MakePoint(106.7078959, 10.7860176), 4326)),
(751, ST_SetSRID(ST_MakePoint(106.7078796, 10.7859992), 4326)),
(752, ST_SetSRID(ST_MakePoint(106.7079155, 10.7860328), 4326)),
(753, ST_SetSRID(ST_MakePoint(106.7078065, 10.7859239), 4326)),
(754, ST_SetSRID(ST_MakePoint(106.707867, 10.7859778), 4326)),
(755, ST_SetSRID(ST_MakePoint(106.7084746, 10.7865726), 4326)),
(756, ST_SetSRID(ST_MakePoint(106.7078197, 10.7859212), 4326)),
(757, ST_SetSRID(ST_MakePoint(106.7079874, 10.7860829), 4326)),
(758, ST_SetSRID(ST_MakePoint(106.7078588, 10.7859544), 4326)),
(759, ST_SetSRID(ST_MakePoint(106.707833, 10.7859231), 4326)),
(760, ST_SetSRID(ST_MakePoint(106.7078545, 10.7859409), 4326)),
(761, ST_SetSRID(ST_MakePoint(106.7078455, 10.78593), 4326)),
(762, ST_SetSRID(ST_MakePoint(106.7073721, 10.7854528), 4326)),
(763, ST_SetSRID(ST_MakePoint(106.7084352, 10.7864935), 4326)),
(764, ST_SetSRID(ST_MakePoint(106.7078061, 10.7858471), 4326)),
(765, ST_SetSRID(ST_MakePoint(106.7080143, 10.7860456), 4326)),
(766, ST_SetSRID(ST_MakePoint(106.7083999, 10.7864125), 4326)),
(767, ST_SetSRID(ST_MakePoint(106.7074068, 10.7854211), 4326)),
(768, ST_SetSRID(ST_MakePoint(106.7087786, 10.7867524), 4326)),
(769, ST_SetSRID(ST_MakePoint(106.7080415, 10.7860219), 4326)),
(770, ST_SetSRID(ST_MakePoint(106.707976, 10.7859434), 4326)),
(771, ST_SetSRID(ST_MakePoint(106.7083672, 10.7863246), 4326)),
(772, ST_SetSRID(ST_MakePoint(106.7077556, 10.7856889), 4326)),
(773, ST_SetSRID(ST_MakePoint(106.7073008, 10.7852325), 4326)),
(774, ST_SetSRID(ST_MakePoint(106.7083393, 10.7862351), 4326)),
(775, ST_SetSRID(ST_MakePoint(106.7074639, 10.7853691), 4326)),
(776, ST_SetSRID(ST_MakePoint(106.7077723, 10.785651), 4326)),
(777, ST_SetSRID(ST_MakePoint(106.707822, 10.7856662), 4326)),
(778, ST_SetSRID(ST_MakePoint(106.707787, 10.7856254), 4326)),
(779, ST_SetSRID(ST_MakePoint(106.7083164, 10.7861442), 4326)),
(780, ST_SetSRID(ST_MakePoint(106.7083136, 10.7861284), 4326)),
(781, ST_SetSRID(ST_MakePoint(106.7078038, 10.785601), 4326)),
(782, ST_SetSRID(ST_MakePoint(106.7081632, 10.785954), 4326)),
(783, ST_SetSRID(ST_MakePoint(106.7077358, 10.7855339), 4326)),
(784, ST_SetSRID(ST_MakePoint(106.7083074, 10.7860937), 4326)),
(785, ST_SetSRID(ST_MakePoint(106.7078087, 10.7855954), 4326)),
(786, ST_SetSRID(ST_MakePoint(106.708179, 10.7859468), 4326)),
(787, ST_SetSRID(ST_MakePoint(106.7078903, 10.7856497), 4326)),
(788, ST_SetSRID(ST_MakePoint(106.7082901, 10.7860361), 4326)),
(789, ST_SetSRID(ST_MakePoint(106.7081961, 10.7859434), 4326)),
(790, ST_SetSRID(ST_MakePoint(106.7082135, 10.7859442), 4326)),
(791, ST_SetSRID(ST_MakePoint(106.7082346, 10.7859509), 4326)),
(792, ST_SetSRID(ST_MakePoint(106.7082658, 10.7859811), 4326)),
(793, ST_SetSRID(ST_MakePoint(106.7082526, 10.7859636), 4326)),
(794, ST_SetSRID(ST_MakePoint(106.7078427, 10.7855565), 4326)),
(795, ST_SetSRID(ST_MakePoint(106.7079604, 10.7856395), 4326)),
(796, ST_SetSRID(ST_MakePoint(106.7082719, 10.7859397), 4326)),
(797, ST_SetSRID(ST_MakePoint(106.7082847, 10.7859117), 4326)),
(798, ST_SetSRID(ST_MakePoint(106.707888, 10.7855182), 4326)),
(799, ST_SetSRID(ST_MakePoint(106.7080311, 10.7856359), 4326)),
(800, ST_SetSRID(ST_MakePoint(106.70829, 10.7858816), 4326));
INSERT INTO walkways_vertices_pgr (id, the_geom) VALUES
(801, ST_SetSRID(ST_MakePoint(106.708065, 10.785638), 4326)),
(802, ST_SetSRID(ST_MakePoint(106.7082878, 10.7858523), 4326)),
(803, ST_SetSRID(ST_MakePoint(106.7079908, 10.7855487), 4326)),
(804, ST_SetSRID(ST_MakePoint(106.7082786, 10.7858243), 4326)),
(805, ST_SetSRID(ST_MakePoint(106.7080983, 10.7856446), 4326)),
(806, ST_SetSRID(ST_MakePoint(106.7079386, 10.785487), 4326)),
(807, ST_SetSRID(ST_MakePoint(106.7085566, 10.7860866), 4326)),
(808, ST_SetSRID(ST_MakePoint(106.7081304, 10.7856557), 4326)),
(809, ST_SetSRID(ST_MakePoint(106.708171, 10.7856775), 4326)),
(810, ST_SetSRID(ST_MakePoint(106.7082068, 10.7857064), 4326)),
(811, ST_SetSRID(ST_MakePoint(106.7079994, 10.7854967), 4326)),
(812, ST_SetSRID(ST_MakePoint(106.7075489, 10.7850055), 4326)),
(813, ST_SetSRID(ST_MakePoint(106.7075408, 10.7849974), 4326)),
(814, ST_SetSRID(ST_MakePoint(106.7081392, 10.7855189), 4326)),
(815, ST_SetSRID(ST_MakePoint(106.7081498, 10.7855206), 4326)),
(816, ST_SetSRID(ST_MakePoint(106.7082665, 10.7854508), 4326)),
(817, ST_SetSRID(ST_MakePoint(106.7078736, 10.7849946), 4326)),
(818, ST_SetSRID(ST_MakePoint(106.707729, 10.7848415), 4326)),
(819, ST_SetSRID(ST_MakePoint(106.7081876, 10.7852255), 4326)),
(820, ST_SetSRID(ST_MakePoint(106.707816, 10.7847623), 4326)),
(821, ST_SetSRID(ST_MakePoint(106.7082444, 10.7850967), 4326));
INSERT INTO walkways (id, name, geom, cost, reverse_cost, source, target) VALUES
(1, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056678 10.7879686, 106.7057963 10.7878552)', 4326), 18.87, 18.87, 144, 174),
(2, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057963 10.7878552, 106.7059718 10.7877001)', 4326), 25.79, 25.79, 174, 207),
(3, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059718 10.7877001, 106.7060466 10.7876341)', 4326), 10.98, 10.98, 207, 215),
(4, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079827 10.787217, 106.7080024 10.7872615)', 4326), 5.4, 5.4, 654, 650),
(5, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080024 10.7872615, 106.7080039 10.7872648)', 4326), 0.4, 0.4, 650, 649),
(6, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080039 10.7872648, 106.7080173 10.7873153)', 4326), 5.8, 5.8, 649, 646),
(7, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080173 10.7873153, 106.7080224 10.7873672)', 4326), 5.8, 5.8, 646, 641),
(8, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080224 10.7873672, 106.7080192 10.7874193)', 4326), 5.8, 5.8, 641, 633),
(9, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080192 10.7874193, 106.7080123 10.7874539)', 4326), 3.92, 3.92, 633, 631),
(10, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080123 10.7874539, 106.708001 10.7874873)', 4326), 3.91, 3.91, 631, 627),
(11, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.708001 10.7874873, 106.7079942 10.7875011)', 4326), 1.71, 1.71, 627, 625),
(12, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079942 10.7875011, 106.7079855 10.7875191)', 4326), 2.21, 2.21, 625, 621),
(13, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079855 10.7875191, 106.7079704 10.7875428)', 4326), 3.11, 3.11, 621, 615),
(14, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079704 10.7875428, 106.7079529 10.7875649)', 4326), 3.11, 3.11, 615, 600),
(15, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079529 10.7875649, 106.7079147 10.7876064)', 4326), 6.22, 6.22, 600, 584),
(16, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079147 10.7876064, 106.7078716 10.787643)', 4326), 6.22, 6.22, 584, 572),
(17, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078716 10.787643, 106.7078384 10.7876655)', 4326), 4.41, 4.41, 572, 568),
(18, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078384 10.7876655, 106.7078034 10.7876851)', 4326), 4.4, 4.4, 568, 562),
(19, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078034 10.7876851, 106.7077307 10.7877194)', 4326), 8.81, 8.81, 562, 551),
(20, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077307 10.7877194, 106.7076614 10.7877434)', 4326), 8.03, 8.03, 551, 546),
(21, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076595 10.7877438, 106.7075899 10.7877602)', 4326), 7.82, 7.82, 546, 536),
(22, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075899 10.7877602, 106.7075384 10.7877718)', 4326), 5.77, 5.77, 536, 521),
(23, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075384 10.7877718, 106.7074124 10.7878002)', 4326), 14.11, 14.11, 521, 475),
(24, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074124 10.7878002, 106.707386 10.7878062)', 4326), 2.96, 2.96, 475, 460),
(25, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707386 10.7878062, 106.7072176 10.7879687)', 4326), 25.78, 25.78, 460, 370),
(26, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072176 10.7879687, 106.7071759 10.7880136)', 4326), 6.76, 6.76, 370, 348),
(27, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071759 10.7880136, 106.7070702 10.7880332)', 4326), 11.75, 11.75, 348, 319),
(28, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070702 10.7880332, 106.7069586 10.7880533)', 4326), 12.39, 12.39, 319, 300),
(29, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063754 10.7881385, 106.7062044 10.7882936)', 4326), 25.42, 25.42, 197, 170),
(30, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062044 10.7882936, 106.706114 10.7883744)', 4326), 13.35, 13.35, 170, 152),
(31, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707447 10.7861882, 106.7074406 10.7859752)', 4326), 23.69, 23.69, 701, 721),
(32, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074406 10.7859752, 106.7074357 10.7858104)', 4326), 18.33, 18.33, 721, 734),
(33, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074357 10.7858104, 106.7074639 10.7853691)', 4326), 49.17, 49.17, 734, 775),
(34, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066733 10.7884582, 106.7068368 10.7886403)', 4326), 27.0, 27.0, 193, 192),
(35, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057963 10.7878552, 106.706 10.7880741)', 4326), 32.98, 32.98, 174, 173),
(36, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706 10.7880741, 106.7061076 10.7881896)', 4326), 17.41, 17.41, 173, 171),
(37, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061076 10.7881896, 106.7062044 10.7882936)', 4326), 15.67, 15.67, 171, 170),
(38, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062044 10.7882936, 106.706415 10.7885199)', 4326), 34.09, 34.09, 170, 168),
(39, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079827 10.787217, 106.7078823 10.7871489)', 4326), 13.33, 13.33, 654, 648),
(40, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078823 10.7871489, 106.7077782 10.7870279)', 4326), 17.61, 17.61, 648, 652),
(41, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077782 10.7870279, 106.707686 10.7869209)', 4326), 15.59, 15.59, 652, 655),
(42, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707686 10.7869209, 106.707567 10.7867827)', 4326), 20.13, 20.13, 655, 659),
(43, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067626 10.787806, 106.7067801 10.787795)', 4326), 2.27, 2.27, 304, 308),
(44, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067801 10.787795, 106.7067993 10.7877875)', 4326), 2.26, 2.26, 308, 310),
(45, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067993 10.7877875, 106.7068203 10.7877837)', 4326), 2.33, 2.33, 310, 321),
(46, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068203 10.7877837, 106.7068415 10.7877839)', 4326), 2.32, 2.32, 321, 327),
(47, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068415 10.7877839, 106.7068624 10.7877882)', 4326), 2.33, 2.33, 327, 332),
(48, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068624 10.7877882, 106.7068776 10.7877985)', 4326), 2.02, 2.02, 332, 334),
(49, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068776 10.7877985, 106.7068882 10.7878132)', 4326), 2.0, 2.0, 334, 333),
(50, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068882 10.7878132, 106.706893 10.787832)', 4326), 2.16, 2.16, 333, 328),
(51, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706893 10.787832, 106.7068905 10.7878511)', 4326), 2.14, 2.14, 328, 322),
(52, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068905 10.7878511, 106.7068904 10.7878681)', 4326), 1.89, 1.89, 322, 316),
(53, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068904 10.7878681, 106.7068984 10.7878832)', 4326), 1.89, 1.89, 316, 313),
(54, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068984 10.7878832, 106.7069063 10.7878883)', 4326), 1.03, 1.03, 313, 314),
(55, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069063 10.7878883, 106.7069138 10.7878932)', 4326), 0.98, 0.98, 314, 315),
(56, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069138 10.7878932, 106.7069323 10.7878943)', 4326), 2.02, 2.02, 315, 320),
(57, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069323 10.7878943, 106.7069471 10.7878943)', 4326), 1.62, 1.62, 320, 324),
(58, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069471 10.7878943, 106.7069611 10.7878988)', 4326), 1.61, 1.61, 324, 329),
(59, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069611 10.7878988, 106.7069732 10.7879073)', 4326), 1.62, 1.62, 329, 330),
(60, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069732 10.7879073, 106.7069848 10.7879248)', 4326), 2.32, 2.32, 330, 325),
(61, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069848 10.7879248, 106.7069876 10.7879455)', 4326), 2.32, 2.32, 325, 323),
(62, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069876 10.7879455, 106.7069811 10.7879654)', 4326), 2.32, 2.32, 323, 312),
(63, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069811 10.7879654, 106.7069687 10.7879846)', 4326), 2.53, 2.53, 312, 307),
(64, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069687 10.7879846, 106.7069606 10.7880059)', 4326), 2.53, 2.53, 307, 303),
(65, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069606 10.7880059, 106.706957 10.7880295)', 4326), 2.65, 2.65, 303, 301),
(66, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706957 10.7880295, 106.7069586 10.7880533)', 4326), 2.65, 2.65, 301, 300),
(67, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069586 10.7880533, 106.7069569 10.7880695)', 4326), 1.81, 1.81, 300, 296),
(68, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069569 10.7880695, 106.7069499 10.7880843)', 4326), 1.81, 1.81, 296, 295),
(69, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069499 10.7880843, 106.7069338 10.7880985)', 4326), 2.36, 2.36, 295, 292),
(70, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069338 10.7880985, 106.7069196 10.7881046)', 4326), 1.69, 1.69, 292, 290),
(71, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069196 10.7881046, 106.7069009 10.7881054)', 4326), 2.04, 2.04, 290, 282),
(72, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069009 10.7881054, 106.7068835 10.7881019)', 4326), 1.94, 1.94, 282, 276),
(73, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068835 10.7881019, 106.7068673 10.7880945)', 4326), 1.95, 1.95, 276, 273),
(74, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068673 10.7880945, 106.7068533 10.7880836)', 4326), 1.95, 1.95, 273, 272),
(75, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068533 10.7880836, 106.7068362 10.7880761)', 4326), 2.05, 2.05, 272, 270),
(76, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068362 10.7880761, 106.7068177 10.7880731)', 4326), 2.05, 2.05, 270, 262),
(77, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068177 10.7880731, 106.706799 10.7880747)', 4326), 2.05, 2.05, 262, 257),
(78, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706799 10.7880747, 106.7067823 10.7880741)', 4326), 1.83, 1.83, 257, 254),
(79, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067823 10.7880741, 106.7067665 10.7880685)', 4326), 1.83, 1.83, 254, 252),
(80, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067665 10.7880685, 106.7067531 10.7880586)', 4326), 1.83, 1.83, 252, 249),
(81, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067531 10.7880586, 106.7067425 10.7880436)', 4326), 2.03, 2.03, 249, 253),
(82, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067425 10.7880436, 106.7067375 10.7880261)', 4326), 2.02, 2.02, 253, 255),
(83, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067375 10.7880261, 106.7067387 10.7880079)', 4326), 2.03, 2.03, 255, 259),
(84, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067387 10.7880079, 106.706747 10.7879914)', 4326), 2.05, 2.05, 259, 267),
(85, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706747 10.7879914, 106.7067487 10.787973)', 4326), 2.05, 2.05, 267, 275),
(86, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067487 10.787973, 106.7067438 10.7879559)', 4326), 1.98, 1.98, 275, 280),
(87, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067438 10.7879559, 106.7067332 10.7879416)', 4326), 1.97, 1.97, 280, 281),
(88, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067332 10.7879416, 106.7067182 10.7879318)', 4326), 1.97, 1.97, 281, 278),
(89, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067182 10.7879318, 106.7067066 10.787923)', 4326), 1.6, 1.6, 278, 277),
(90, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067066 10.787923, 106.7066979 10.7879114)', 4326), 1.6, 1.6, 277, 279),
(91, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066979 10.7879114, 106.7066927 10.7878979)', 4326), 1.6, 1.6, 279, 283),
(92, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066927 10.7878979, 106.7066917 10.7878809)', 4326), 1.89, 1.89, 283, 289),
(93, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066917 10.7878809, 106.7066964 10.7878645)', 4326), 1.89, 1.89, 289, 293),
(94, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066964 10.7878645, 106.7067061 10.7878505)', 4326), 1.88, 1.88, 293, 294),
(95, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067061 10.7878505, 106.7067626 10.787806)', 4326), 7.91, 7.91, 294, 304),
(96, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063744 10.7879472, 106.7064447 10.7878834)', 4326), 10.45, 10.45, 220, 236),
(97, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074406 10.7859752, 106.7074922 10.7859948)', 4326), 6.04, 6.04, 721, 723),
(98, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074922 10.7859948, 106.7075457 10.7860087)', 4326), 6.04, 6.04, 723, 726),
(99, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075464 10.7860088, 106.7076067 10.7860174)', 4326), 6.65, 6.65, 726, 730),
(100, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076067 10.7860174, 106.7076684 10.7860186)', 4326), 6.74, 6.74, 730, 735),
(101, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076684 10.7860186, 106.7077951 10.785931)', 4326), 16.92, 16.92, 735, 749),
(102, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077951 10.785931, 106.7078065 10.7859239)', 4326), 1.47, 1.47, 749, 753),
(103, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078065 10.7859239, 106.7078197 10.7859212)', 4326), 1.47, 1.47, 753, 756),
(104, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078197 10.7859212, 106.707833 10.7859231)', 4326), 1.47, 1.47, 756, 759),
(105, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707833 10.7859231, 106.7078455 10.78593)', 4326), 1.57, 1.57, 759, 761),
(106, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078455 10.78593, 106.7078545 10.7859409)', 4326), 1.56, 1.56, 761, 760),
(107, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078545 10.7859409, 106.7078588 10.7859544)', 4326), 1.57, 1.57, 760, 758),
(108, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078588 10.7859544, 106.707867 10.7859778)', 4326), 2.75, 2.75, 758, 754),
(109, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707867 10.7859778, 106.7078796 10.7859992)', 4326), 2.75, 2.75, 754, 751),
(110, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078796 10.7859992, 106.7078959 10.7860176)', 4326), 2.71, 2.71, 751, 750),
(111, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078959 10.7860176, 106.7079155 10.7860328)', 4326), 2.73, 2.73, 750, 752),
(112, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079155 10.7860328, 106.7079874 10.7860829)', 4326), 9.63, 9.63, 752, 757),
(113, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061076 10.7881896, 106.7060174 10.7882715)', 4326), 13.42, 13.42, 171, 154),
(114, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068673 10.7880945, 106.7068322 10.7881383)', 4326), 6.2, 6.2, 273, 248),
(115, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068322 10.7881383, 106.7067512 10.7882124)', 4326), 12.09, 12.09, 248, 233),
(116, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067512 10.7882124, 106.7065847 10.7883647)', 4326), 24.85, 24.85, 233, 195),
(117, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065847 10.7883647, 106.706415 10.7885199)', 4326), 25.33, 25.33, 195, 168),
(118, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706415 10.7885199, 106.7063265 10.7886008)', 4326), 13.2, 13.2, 168, 148),
(119, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062019 10.7876227, 106.706363 10.7877956)', 4326), 26.06, 26.06, 239, 238),
(120, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706363 10.7877956, 106.7064447 10.7878834)', 4326), 13.23, 13.23, 238, 236),
(121, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064447 10.7878834, 106.7067512 10.7882124)', 4326), 49.59, 49.59, 236, 233),
(122, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067512 10.7882124, 106.7070316 10.7885092)', 4326), 45.02, 45.02, 233, 230),
(123, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069338 10.7880985, 106.7069634 10.7881443)', 4326), 6.04, 6.04, 292, 291),
(124, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069643 10.7881457, 106.7071595 10.7884182)', 4326), 37.05, 37.05, 291, 260),
(125, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065884 10.7883687, 106.7066065 10.7883572)', 4326), 2.35, 2.35, 194, 201),
(126, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066065 10.7883572, 106.7066276 10.7883524)', 4326), 2.37, 2.37, 201, 206),
(127, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066276 10.7883524, 106.706649 10.788355)', 4326), 2.36, 2.36, 206, 210),
(128, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706649 10.788355, 106.7066683 10.7883646)', 4326), 2.36, 2.36, 210, 212),
(129, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066683 10.7883646, 106.7066831 10.7883801)', 4326), 2.36, 2.36, 212, 211),
(130, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066831 10.7883801, 106.7066915 10.7883997)', 4326), 2.36, 2.36, 211, 209),
(131, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066915 10.7883997, 106.7066927 10.7884209)', 4326), 2.36, 2.36, 209, 205),
(132, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066927 10.7884209, 106.7066864 10.7884412)', 4326), 2.36, 2.36, 205, 199),
(133, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066864 10.7884412, 106.7066733 10.7884582)', 4326), 2.37, 2.37, 199, 193),
(134, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066733 10.7884582, 106.7066552 10.7884698)', 4326), 2.36, 2.36, 193, 190),
(135, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066552 10.7884698, 106.7066341 10.7884746)', 4326), 2.37, 2.37, 190, 186),
(136, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066341 10.7884746, 106.7066127 10.788472)', 4326), 2.36, 2.36, 186, 183),
(137, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066127 10.788472, 106.7065934 10.7884623)', 4326), 2.37, 2.37, 183, 180),
(138, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065934 10.7884623, 106.7065786 10.7884468)', 4326), 2.36, 2.36, 180, 181),
(139, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065786 10.7884468, 106.7065702 10.7884273)', 4326), 2.35, 2.35, 181, 184),
(140, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065702 10.7884273, 106.706569 10.788406)', 4326), 2.37, 2.37, 184, 187),
(141, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706569 10.788406, 106.7065753 10.7883857)', 4326), 2.36, 2.36, 187, 191),
(142, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065753 10.7883857, 106.7065884 10.7883687)', 4326), 2.37, 2.37, 191, 194),
(143, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057599 10.7869778, 106.7058847 10.7869988)', 4326), 13.83, 13.83, 284, 299),
(144, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058847 10.7869988, 106.7059672 10.7870156)', 4326), 9.2, 9.2, 299, 305),
(145, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059672 10.7870156, 106.7060132 10.7870281)', 4326), 5.22, 5.22, 305, 309),
(146, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060132 10.7870281, 106.7060483 10.7870376)', 4326), 3.97, 3.97, 309, 317),
(147, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060483 10.7870376, 106.7061216 10.7870625)', 4326), 8.47, 8.47, 317, 331),
(148, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061216 10.7870625, 106.7061932 10.7870916)', 4326), 8.46, 8.46, 331, 339),
(149, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061932 10.7870916, 106.7062385 10.7871204)', 4326), 5.89, 5.89, 339, 342),
(150, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062385 10.7871204, 106.7062604 10.7871343)', 4326), 2.85, 2.85, 342, 344);
INSERT INTO walkways (id, name, geom, cost, reverse_cost, source, target) VALUES
(151, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062604 10.7871343, 106.7063226 10.7871838)', 4326), 8.74, 8.74, 344, 346),
(152, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063226 10.7871838, 106.7063639 10.7872235)', 4326), 6.31, 6.31, 346, 347),
(153, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063639 10.7872235, 106.706402 10.7872662)', 4326), 6.31, 6.31, 347, 345),
(154, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706402 10.7872662, 106.7064366 10.7873116)', 4326), 6.31, 6.31, 345, 343),
(155, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064366 10.7873116, 106.7064846 10.7873856)', 4326), 9.76, 9.76, 343, 337),
(156, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064846 10.7873856, 106.70657 10.7875173)', 4326), 17.36, 17.36, 337, 326),
(157, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70657 10.7875173, 106.7067626 10.787806)', 4326), 38.38, 38.38, 326, 304),
(158, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7051149 10.7877754, 106.7053183 10.787592)', 4326), 30.16, 30.16, 117, 153),
(159, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7053183 10.787592, 106.7056131 10.7873261)', 4326), 43.72, 43.72, 153, 213),
(160, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056678 10.7879686, 106.7057588 10.7879959)', 4326), 10.39, 10.39, 144, 160),
(161, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057588 10.7879959, 106.7059075 10.7881543)', 4326), 23.96, 23.96, 160, 155),
(162, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059075 10.7881543, 106.7060174 10.7882715)', 4326), 17.72, 17.72, 155, 154),
(163, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060174 10.7882715, 106.706114 10.7883744)', 4326), 15.56, 15.56, 154, 152),
(164, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706114 10.7883744, 106.7062177 10.7884849)', 4326), 16.71, 16.71, 152, 151),
(165, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062177 10.7884849, 106.7063265 10.7886008)', 4326), 17.53, 17.53, 151, 148),
(166, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063265 10.7886008, 106.7063843 10.7886624)', 4326), 9.32, 9.32, 148, 147),
(167, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063843 10.7886624, 106.7064735 10.7888303)', 4326), 21.06, 21.06, 147, 141),
(168, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064735 10.7888303, 106.7063148 10.7887253)', 4326), 20.9, 20.9, 141, 135),
(169, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063148 10.7887253, 106.7062692 10.7886768)', 4326), 7.34, 7.34, 135, 136),
(170, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062692 10.7886768, 106.7060716 10.7884663)', 4326), 31.84, 31.84, 136, 138),
(171, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060716 10.7884663, 106.7059768 10.7883653)', 4326), 15.28, 15.28, 138, 139),
(172, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059768 10.7883653, 106.7058776 10.7882596)', 4326), 15.99, 15.99, 139, 140),
(173, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058776 10.7882596, 106.7056892 10.7880589)', 4326), 30.36, 30.36, 140, 142),
(174, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056892 10.7880589, 106.7056678 10.7879686)', 4326), 10.31, 10.31, 142, 144),
(175, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70657 10.7875173, 106.7066694 10.7875879)', 4326), 13.4, 13.4, 326, 336),
(176, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066694 10.7875879, 106.7067533 10.7876422)', 4326), 10.97, 10.97, 336, 338),
(177, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067533 10.7876422, 106.7067718 10.7876542)', 4326), 2.42, 2.42, 338, 340),
(178, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067718 10.7876542, 106.7069043 10.7877312)', 4326), 16.82, 16.82, 340, 354),
(179, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069043 10.7877312, 106.7070407 10.7878011)', 4326), 16.8, 16.8, 354, 369),
(180, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070407 10.7878011, 106.7070851 10.787825)', 4326), 5.53, 5.53, 369, 374),
(181, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070851 10.787825, 106.7071249 10.7878557)', 4326), 5.53, 5.53, 374, 377),
(182, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071249 10.7878557, 106.7071477 10.7878788)', 4326), 3.58, 3.58, 377, 376),
(183, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071477 10.7878788, 106.7071678 10.7879041)', 4326), 3.57, 3.57, 376, 375),
(184, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071678 10.7879041, 106.7072176 10.7879687)', 4326), 9.01, 9.01, 375, 370),
(185, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072176 10.7879687, 106.7073385 10.7880751)', 4326), 17.73, 17.73, 370, 373),
(186, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073385 10.7880751, 106.7074601 10.7882042)', 4326), 19.56, 19.56, 373, 371),
(187, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061708 10.7879163, 106.706 10.7880741)', 4326), 25.61, 25.61, 204, 173),
(188, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706 10.7880741, 106.7059075 10.7881543)', 4326), 13.48, 13.48, 173, 155),
(189, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077556 10.7856889, 106.7077723 10.785651)', 4326), 4.59, 4.59, 772, 776),
(190, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077723 10.785651, 106.707787 10.7856254)', 4326), 3.27, 3.27, 776, 778),
(191, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707787 10.7856254, 106.7078038 10.785601)', 4326), 3.28, 3.28, 778, 781),
(192, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078038 10.785601, 106.7078087 10.7855954)', 4326), 0.82, 0.82, 781, 785),
(193, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078087 10.7855954, 106.7078427 10.7855565)', 4326), 5.7, 5.7, 785, 794),
(194, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078427 10.7855565, 106.707888 10.7855182)', 4326), 6.53, 6.53, 794, 798),
(195, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707888 10.7855182, 106.7079386 10.785487)', 4326), 6.53, 6.53, 798, 806),
(196, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079386 10.785487, 106.7079994 10.7854967)', 4326), 6.73, 6.73, 806, 811),
(197, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079994 10.7854967, 106.7081392 10.7855189)', 4326), 15.47, 15.47, 811, 814),
(198, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081392 10.7855189, 106.7081498 10.7855206)', 4326), 1.17, 1.17, 814, 815),
(199, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074357 10.7858104, 106.7077556 10.7856889)', 4326), 37.46, 37.46, 734, 772),
(200, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077556 10.7856889, 106.707822 10.7856662)', 4326), 7.68, 7.68, 772, 777),
(201, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707822 10.7856662, 106.7078903 10.7856497)', 4326), 7.68, 7.68, 777, 787),
(202, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078903 10.7856497, 106.7079604 10.7856395)', 4326), 7.74, 7.74, 787, 795),
(203, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079604 10.7856395, 106.7080311 10.7856359)', 4326), 7.73, 7.73, 795, 799),
(204, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080311 10.7856359, 106.708065 10.785638)', 4326), 3.71, 3.71, 799, 801),
(205, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.708065 10.785638, 106.7080983 10.7856446)', 4326), 3.71, 3.71, 801, 805),
(206, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080983 10.7856446, 106.7081304 10.7856557)', 4326), 3.72, 3.72, 805, 808),
(207, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081304 10.7856557, 106.708171 10.7856775)', 4326), 5.05, 5.05, 808, 809),
(208, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.708171 10.7856775, 106.7082068 10.7857064)', 4326), 5.06, 5.06, 809, 810),
(209, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082068 10.7857064, 106.7082786 10.7858243)', 4326), 15.28, 15.28, 810, 804),
(210, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082786 10.7858243, 106.7082878 10.7858523)', 4326), 3.27, 3.27, 804, 802),
(211, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082878 10.7858523, 106.70829 10.7858816)', 4326), 3.27, 3.27, 802, 800),
(212, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70829 10.7858816, 106.7082847 10.7859117)', 4326), 3.4, 3.4, 800, 797),
(213, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082847 10.7859117, 106.7082719 10.7859397)', 4326), 3.41, 3.41, 797, 796),
(214, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082719 10.7859397, 106.7082526 10.7859636)', 4326), 3.39, 3.39, 796, 793),
(215, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059718 10.7877001, 106.7061708 10.7879163)', 4326), 32.41, 32.41, 207, 204),
(216, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061708 10.7879163, 106.7061873 10.7879343)', 4326), 2.69, 2.69, 204, 203),
(217, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061873 10.7879343, 106.706282 10.7878485)', 4326), 14.07, 14.07, 203, 222),
(218, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706282 10.7878485, 106.7063744 10.7879472)', 4326), 14.91, 14.91, 222, 220),
(219, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063744 10.7879472, 106.7064473 10.788025)', 4326), 11.76, 11.76, 220, 217),
(220, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064473 10.788025, 106.706352 10.7881132)', 4326), 14.3, 14.3, 217, 198),
(221, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706352 10.7881132, 106.7063754 10.7881385)', 4326), 3.8, 3.8, 198, 197),
(222, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063754 10.7881385, 106.7065847 10.7883647)', 4326), 33.99, 33.99, 197, 195),
(223, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065847 10.7883647, 106.7065884 10.7883687)', 4326), 0.6, 0.6, 195, 194),
(224, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086289 10.7871474, 106.7083441 10.7871781)', 4326), 31.3, 31.3, 720, 688),
(225, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083441 10.7871781, 106.7080825 10.7872063)', 4326), 28.75, 28.75, 688, 663),
(226, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080825 10.7872063, 106.7079827 10.787217)', 4326), 10.96, 10.96, 663, 654),
(227, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707539 10.7868051, 106.707567 10.7867827)', 4326), 3.94, 3.94, 651, 659),
(228, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707567 10.7867827, 106.7076214 10.7867392)', 4326), 7.66, 7.66, 659, 664),
(229, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076214 10.7867392, 106.7076458 10.7867173)', 4326), 3.61, 3.61, 664, 666),
(230, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076458 10.7867173, 106.7076644 10.7866905)', 4326), 3.61, 3.61, 666, 671),
(231, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076644 10.7866905, 106.7076761 10.7866601)', 4326), 3.61, 3.61, 671, 673),
(232, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076761 10.7866601, 106.7076804 10.7866279)', 4326), 3.61, 3.61, 673, 678),
(233, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076804 10.7866279, 106.70768 10.786601)', 4326), 2.99, 2.99, 678, 680),
(234, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70768 10.786601, 106.7076825 10.7865742)', 4326), 2.99, 2.99, 680, 684),
(235, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076825 10.7865742, 106.7076918 10.7865345)', 4326), 4.53, 4.53, 684, 689),
(236, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076918 10.7865345, 106.7077076 10.7864969)', 4326), 4.52, 4.52, 689, 695),
(237, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077076 10.7864969, 106.7077295 10.7864622)', 4326), 4.54, 4.54, 695, 702),
(238, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077295 10.7864622, 106.7077569 10.7864316)', 4326), 4.53, 4.53, 702, 714),
(239, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077569 10.7864316, 106.7078675 10.7863512)', 4326), 15.03, 15.03, 714, 725),
(240, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078675 10.7863512, 106.707894 10.786332)', 4326), 3.6, 3.6, 725, 728),
(241, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707894 10.786332, 106.7079158 10.7863078)', 4326), 3.59, 3.59, 728, 731),
(242, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079158 10.7863078, 106.7079328 10.7862776)', 4326), 3.84, 3.84, 731, 736),
(243, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079328 10.7862776, 106.7079426 10.7862445)', 4326), 3.83, 3.83, 736, 738),
(244, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079426 10.7862445, 106.7079721 10.7861174)', 4326), 14.5, 14.5, 738, 747),
(245, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079721 10.7861174, 106.7079874 10.7860829)', 4326), 4.18, 4.18, 747, 757),
(246, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079874 10.7860829, 106.7080143 10.7860456)', 4326), 5.08, 5.08, 757, 765),
(247, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080143 10.7860456, 106.7080415 10.7860219)', 4326), 3.97, 3.97, 765, 769),
(248, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080415 10.7860219, 106.7081632 10.785954)', 4326), 15.29, 15.29, 769, 782),
(249, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081632 10.785954, 106.708179 10.7859468)', 4326), 1.9, 1.9, 782, 786),
(250, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.708179 10.7859468, 106.7081961 10.7859434)', 4326), 1.91, 1.91, 786, 789),
(251, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081961 10.7859434, 106.7082135 10.7859442)', 4326), 1.9, 1.9, 789, 790),
(252, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082135 10.7859442, 106.7082346 10.7859509)', 4326), 2.42, 2.42, 790, 791),
(253, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082346 10.7859509, 106.7082526 10.7859636)', 4326), 2.42, 2.42, 791, 793),
(254, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082526 10.7859636, 106.7082658 10.7859811)', 4326), 2.42, 2.42, 793, 792),
(255, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082658 10.7859811, 106.7082901 10.7860361)', 4326), 6.67, 6.67, 792, 788),
(256, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082901 10.7860361, 106.7083074 10.7860937)', 4326), 6.68, 6.68, 788, 784),
(257, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083074 10.7860937, 106.7083136 10.7861284)', 4326), 3.92, 3.92, 784, 780),
(258, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083136 10.7861284, 106.7083164 10.7861442)', 4326), 1.78, 1.78, 780, 779),
(259, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083164 10.7861442, 106.7083393 10.7862351)', 4326), 10.41, 10.41, 779, 774),
(260, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083393 10.7862351, 106.7083672 10.7863246)', 4326), 10.41, 10.41, 774, 771),
(261, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083672 10.7863246, 106.7083999 10.7864125)', 4326), 10.41, 10.41, 771, 766),
(262, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083999 10.7864125, 106.7084352 10.7864935)', 4326), 9.8, 9.8, 766, 763),
(263, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7084352 10.7864935, 106.7084746 10.7865726)', 4326), 9.79, 9.79, 763, 755),
(264, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7084746 10.7865726, 106.708518 10.7866496)', 4326), 9.79, 9.79, 755, 748),
(265, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.708518 10.7866496, 106.70857 10.7867315)', 4326), 10.73, 10.73, 748, 746),
(266, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70857 10.7867315, 106.7086266 10.7868104)', 4326), 10.73, 10.73, 746, 745),
(267, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086266 10.7868104, 106.7086508 10.786839)', 4326), 4.14, 4.14, 745, 744),
(268, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086508 10.786839, 106.7086701 10.7868711)', 4326), 4.15, 4.15, 744, 743),
(269, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086701 10.7868711, 106.7086841 10.7869057)', 4326), 4.14, 4.14, 743, 742),
(270, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086841 10.7869057, 106.7086923 10.7869421)', 4326), 4.15, 4.15, 742, 740),
(271, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086923 10.7869421, 106.7086946 10.7869762)', 4326), 3.8, 3.8, 740, 739),
(272, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086946 10.7869762, 106.7086919 10.7870102)', 4326), 3.79, 3.79, 739, 737),
(273, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086919 10.7870102, 106.7086843 10.7870435)', 4326), 3.79, 3.79, 737, 732),
(274, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086843 10.7870435, 106.7086608 10.7870934)', 4326), 6.11, 6.11, 732, 727),
(275, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086608 10.7870934, 106.7086289 10.7871474)', 4326), 6.94, 6.94, 727, 720),
(276, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086289 10.7871474, 106.708585 10.7872161)', 4326), 9.02, 9.02, 720, 717),
(277, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.708585 10.7872161, 106.7085398 10.7872756)', 4326), 8.26, 8.26, 717, 699),
(278, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7085398 10.7872756, 106.7084906 10.7873319)', 4326), 8.25, 8.25, 699, 687),
(279, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7084906 10.7873319, 106.7084375 10.7873848)', 4326), 8.26, 8.26, 687, 677),
(280, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7084375 10.7873848, 106.7082294 10.7875652)', 4326), 30.31, 30.31, 677, 642),
(281, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079801 10.7877781, 106.707937 10.7878142)', 4326), 6.19, 6.19, 571, 563),
(282, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707937 10.7878142, 106.7078488 10.787888)', 4326), 12.65, 12.65, 563, 548),
(283, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078488 10.787888, 106.7075339 10.7881442)', 4326), 44.66, 44.66, 548, 403),
(284, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075339 10.7881442, 106.7074601 10.7882042)', 4326), 10.46, 10.46, 403, 371),
(285, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074601 10.7882042, 106.7071595 10.7884182)', 4326), 40.55, 40.55, 371, 260),
(286, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071595 10.7884182, 106.7070316 10.7885092)', 4326), 17.25, 17.25, 260, 230),
(287, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070316 10.7885092, 106.7068963 10.7886036)', 4326), 18.13, 18.13, 230, 208),
(288, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068963 10.7886036, 106.7068719 10.7886187)', 4326), 3.15, 3.15, 208, 200),
(289, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068719 10.7886187, 106.7068368 10.7886403)', 4326), 4.52, 4.52, 200, 192),
(290, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068368 10.7886403, 106.7067665 10.7886837)', 4326), 9.07, 9.07, 192, 176),
(291, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067665 10.7886837, 106.7066709 10.7887365)', 4326), 11.98, 11.98, 176, 172),
(292, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066709 10.7887365, 106.7065732 10.7887854)', 4326), 11.98, 11.98, 172, 162),
(293, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065732 10.7887854, 106.7064735 10.7888303)', 4326), 11.98, 11.98, 162, 141),
(294, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074203 10.7868828, 106.7073271 10.7868689)', 4326), 10.3, 10.3, 630, 623),
(295, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073271 10.7868689, 106.7072359 10.7868459)', 4326), 10.28, 10.28, 623, 604),
(296, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072359 10.7868459, 106.7072125 10.7868377)', 4326), 2.71, 2.71, 604, 599),
(297, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072125 10.7868377, 106.7071648 10.7868211)', 4326), 5.53, 5.53, 599, 595),
(298, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071648 10.7868211, 106.7070961 10.7867907)', 4326), 8.23, 8.23, 595, 586),
(299, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070961 10.7867907, 106.7070499 10.7867657)', 4326), 5.76, 5.76, 586, 582),
(300, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070499 10.7867657, 106.70703 10.786755)', 4326), 2.48, 2.48, 582, 580);
INSERT INTO walkways (id, name, geom, cost, reverse_cost, source, target) VALUES
(301, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70703 10.786755, 106.7069812 10.7867178)', 4326), 6.75, 6.75, 580, 576),
(302, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069812 10.7867178, 106.7069357 10.7866766)', 4326), 6.76, 6.76, 576, 575),
(303, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069357 10.7866766, 106.7068939 10.7866319)', 4326), 6.75, 6.75, 575, 577),
(304, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068939 10.7866319, 106.7068712 10.7866028)', 4326), 4.07, 4.07, 577, 579),
(305, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068712 10.7866028, 106.7068528 10.7865792)', 4326), 3.31, 3.31, 579, 581),
(306, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068528 10.7865792, 106.7068331 10.7865522)', 4326), 3.69, 3.69, 581, 583),
(307, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068331 10.7865522, 106.7068168 10.7865232)', 4326), 3.68, 3.68, 583, 585),
(308, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068168 10.7865232, 106.7068045 10.7864938)', 4326), 3.53, 3.53, 585, 587),
(309, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068045 10.7864938, 106.7067957 10.7864632)', 4326), 3.54, 3.54, 587, 594),
(310, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067957 10.7864632, 106.7067743 10.7863762)', 4326), 9.95, 9.95, 594, 612),
(311, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067743 10.7863762, 106.7067714 10.7863605)', 4326), 1.78, 1.78, 612, 616),
(312, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067714 10.7863605, 106.7067583 10.7862881)', 4326), 8.17, 8.17, 616, 624),
(313, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067583 10.7862881, 106.7067558 10.7862672)', 4326), 2.34, 2.34, 624, 626),
(314, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067558 10.7862672, 106.7067477 10.7861992)', 4326), 7.61, 7.61, 626, 632),
(315, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067477 10.7861992, 106.7067418 10.7861636)', 4326), 4.01, 4.01, 632, 635),
(316, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067418 10.7861636, 106.7067402 10.7861274)', 4326), 4.03, 4.03, 635, 637),
(317, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067402 10.7861274, 106.7067432 10.7860914)', 4326), 4.02, 4.02, 637, 643),
(318, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067432 10.7860914, 106.7067532 10.7860468)', 4326), 5.08, 5.08, 643, 647),
(319, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067532 10.7860468, 106.70677 10.7860042)', 4326), 5.08, 5.08, 647, 657),
(320, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70677 10.7860042, 106.7067933 10.7859646)', 4326), 5.09, 5.09, 657, 662),
(321, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067933 10.7859646, 106.7068219 10.7859365)', 4326), 4.42, 4.42, 662, 665),
(322, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068219 10.7859365, 106.7068484 10.7859184)', 4326), 3.52, 3.52, 665, 668),
(323, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068484 10.7859184, 106.706855 10.7859139)', 4326), 0.88, 0.88, 668, 669),
(324, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706855 10.7859139, 106.7068981 10.7858952)', 4326), 5.15, 5.15, 669, 674),
(325, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068981 10.7858952, 106.7069055 10.7858937)', 4326), 0.82, 0.82, 674, 676),
(326, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069055 10.7858937, 106.7069442 10.7858855)', 4326), 4.33, 4.33, 676, 679),
(327, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069442 10.7858855, 106.7069894 10.7858831)', 4326), 4.94, 4.94, 679, 685),
(328, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069894 10.7858831, 106.7070346 10.7858853)', 4326), 4.94, 4.94, 685, 690),
(329, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070346 10.7858853, 106.707051 10.7858878)', 4326), 1.81, 1.81, 690, 692),
(330, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707051 10.7858878, 106.7070793 10.7858921)', 4326), 3.13, 3.13, 692, 693),
(331, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070793 10.7858921, 106.7071272 10.7859048)', 4326), 5.42, 5.42, 693, 698),
(332, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071272 10.7859048, 106.7071734 10.7859227)', 4326), 5.42, 5.42, 698, 700),
(333, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071734 10.7859227, 106.7072172 10.7859457)', 4326), 5.42, 5.42, 700, 705),
(334, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072172 10.7859457, 106.707258 10.7859735)', 4326), 5.42, 5.42, 705, 708),
(335, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707258 10.7859735, 106.7072994 10.7860055)', 4326), 5.75, 5.75, 708, 710),
(336, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072994 10.7860055, 106.7073135 10.7860184)', 4326), 2.1, 2.1, 710, 711),
(337, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073135 10.7860184, 106.707338 10.7860408)', 4326), 3.66, 3.66, 711, 712),
(338, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707338 10.7860408, 106.7073733 10.7860792)', 4326), 5.75, 5.75, 712, 709),
(339, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073733 10.7860792, 106.7074132 10.7861318)', 4326), 7.29, 7.29, 709, 707),
(340, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074132 10.7861318, 106.707447 10.7861882)', 4326), 7.28, 7.28, 707, 701),
(341, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707447 10.7861882, 106.7074746 10.7862478)', 4326), 7.28, 7.28, 701, 697),
(342, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074746 10.7862478, 106.707488 10.7862865)', 4326), 4.55, 4.55, 697, 694),
(343, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707488 10.7862865, 106.7075056 10.7863372)', 4326), 5.95, 5.95, 694, 691),
(344, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075056 10.7863372, 106.7075286 10.786429)', 4326), 10.51, 10.51, 691, 682),
(345, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075286 10.786429, 106.7075432 10.7865207)', 4326), 10.32, 10.32, 682, 675),
(346, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075432 10.7865207, 106.7075497 10.7866134)', 4326), 10.33, 10.33, 675, 667),
(347, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075497 10.7866134, 106.7075484 10.7867095)', 4326), 10.69, 10.69, 667, 661),
(348, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075484 10.7867095, 106.707539 10.7868051)', 4326), 10.68, 10.68, 661, 651),
(349, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062448 10.7874997, 106.7063933 10.7874317)', 4326), 17.9, 17.9, 265, 306),
(350, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063933 10.7874317, 106.7064846 10.7873856)', 4326), 11.21, 11.21, 306, 337),
(351, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064846 10.7873856, 106.7065392 10.7873584)', 4326), 6.69, 6.69, 337, 360),
(352, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065392 10.7873584, 106.7066197 10.7873145)', 4326), 10.06, 10.06, 360, 386),
(353, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066197 10.7873145, 106.7066661 10.7872892)', 4326), 5.8, 5.8, 386, 405),
(354, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066661 10.7872892, 106.7067585 10.7872349)', 4326), 11.76, 11.76, 405, 454),
(355, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067585 10.7872349, 106.7067906 10.7872161)', 4326), 4.08, 4.08, 454, 464),
(356, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067906 10.7872161, 106.7068676 10.7871649)', 4326), 10.16, 10.16, 464, 506),
(357, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068676 10.7871649, 106.706956 10.7871104)', 4326), 11.4, 11.4, 506, 539),
(358, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706956 10.7871104, 106.7070543 10.7870539)', 4326), 12.44, 12.44, 539, 552),
(359, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070543 10.7870539, 106.7071648 10.7869961)', 4326), 13.67, 13.67, 552, 569),
(360, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071648 10.7869961, 106.7072391 10.7869672)', 4326), 8.73, 8.73, 569, 578),
(361, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072391 10.7869672, 106.7073123 10.7869355)', 4326), 8.74, 8.74, 578, 601),
(362, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073123 10.7869355, 106.7073354 10.786925)', 4326), 2.78, 2.78, 601, 614),
(363, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073354 10.786925, 106.7073671 10.7869107)', 4326), 3.81, 3.81, 614, 622),
(364, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073671 10.7869107, 106.7074203 10.7868828)', 4326), 6.59, 6.59, 622, 630),
(365, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074203 10.7868828, 106.707481 10.786846)', 4326), 7.79, 7.79, 630, 640),
(366, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707481 10.786846, 106.707539 10.7868051)', 4326), 7.8, 7.8, 640, 651),
(367, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062448 10.7874997, 106.706251 10.787516)', 4326), 1.93, 1.93, 265, 263),
(368, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706251 10.787516, 106.7062522 10.7875333)', 4326), 1.93, 1.93, 263, 258),
(369, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062522 10.7875333, 106.7062459 10.7875583)', 4326), 2.86, 2.86, 258, 251),
(370, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062459 10.7875583, 106.7062354 10.7875819)', 4326), 2.86, 2.86, 251, 245),
(371, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062354 10.7875819, 106.706221 10.7876034)', 4326), 2.86, 2.86, 245, 242),
(372, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706221 10.7876034, 106.7062019 10.7876227)', 4326), 2.99, 2.99, 242, 239),
(373, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062019 10.7876227, 106.7061728 10.7876429)', 4326), 3.89, 3.89, 239, 234),
(374, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061728 10.7876429, 106.7061435 10.7876545)', 4326), 3.45, 3.45, 234, 229),
(375, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061435 10.7876545, 106.7061183 10.7876583)', 4326), 2.78, 2.78, 229, 227),
(376, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061183 10.7876583, 106.7060929 10.7876561)', 4326), 2.79, 2.79, 227, 224),
(377, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060929 10.7876561, 106.7060684 10.7876479)', 4326), 2.83, 2.83, 224, 219),
(378, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060684 10.7876479, 106.7060567 10.7876422)', 4326), 1.43, 1.43, 219, 216),
(379, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060567 10.7876422, 106.7060466 10.7876341)', 4326), 1.42, 1.42, 216, 215),
(380, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060466 10.7876341, 106.7060376 10.7876198)', 4326), 1.87, 1.87, 215, 218),
(381, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060376 10.7876198, 106.7060327 10.7876037)', 4326), 1.87, 1.87, 218, 221),
(382, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060327 10.7876037, 106.706032 10.7875874)', 4326), 1.81, 1.81, 221, 226),
(383, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706032 10.7875874, 106.7060356 10.7875715)', 4326), 1.81, 1.81, 226, 228),
(384, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060356 10.7875715, 106.7060495 10.7875388)', 4326), 3.94, 3.94, 228, 232),
(385, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060495 10.7875388, 106.7060715 10.7875106)', 4326), 3.95, 3.95, 232, 237),
(386, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060715 10.7875106, 106.7060976 10.7874904)', 4326), 3.63, 3.63, 237, 240),
(387, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060976 10.7874904, 106.7061274 10.7874763)', 4326), 3.61, 3.61, 240, 243),
(388, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061274 10.7874763, 106.7061536 10.7874697)', 4326), 2.95, 2.95, 243, 250),
(389, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061536 10.7874697, 106.7061804 10.7874677)', 4326), 2.94, 2.94, 250, 256),
(390, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061804 10.7874677, 106.7062072 10.7874704)', 4326), 2.94, 2.94, 256, 264),
(391, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062072 10.7874704, 106.7062223 10.7874767)', 4326), 1.79, 1.79, 264, 266),
(392, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062223 10.7874767, 106.7062351 10.7874867)', 4326), 1.79, 1.79, 266, 269),
(393, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062351 10.7874867, 106.7062448 10.7874997)', 4326), 1.79, 1.79, 269, 265),
(394, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055906 10.7868018, 106.7056218 10.7868343)', 4326), 4.96, 4.96, 288, 287),
(395, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056218 10.7868343, 106.7057155 10.7869317)', 4326), 14.9, 14.9, 287, 286),
(396, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057155 10.7869317, 106.7057599 10.7869778)', 4326), 7.06, 7.06, 286, 284),
(397, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057599 10.7869778, 106.7062049 10.7874401)', 4326), 70.75, 70.75, 284, 274),
(398, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062049 10.7874401, 106.7062223 10.7874767)', 4326), 4.49, 4.49, 274, 266),
(399, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.704878 10.7886714, 106.7050816 10.7884902)', 4326), 30.01, 30.01, 26, 39),
(400, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050816 10.7884902, 106.7051601 10.7884204)', 4326), 11.56, 11.56, 39, 54),
(401, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7051601 10.7884204, 106.7053572 10.7882451)', 4326), 29.04, 29.04, 54, 85),
(402, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7053572 10.7882451, 106.7055474 10.7880758)', 4326), 28.04, 28.04, 85, 131),
(403, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055474 10.7880758, 106.7056678 10.7879686)', 4326), 17.75, 17.75, 131, 144),
(404, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.705557 10.7906122, 106.7055455 10.7905459)', 4326), 7.48, 7.48, 1, 2),
(405, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055455 10.7905459, 106.7055269 10.7904341)', 4326), 12.6, 12.6, 2, 3),
(406, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055269 10.7904341, 106.7055018 10.790283)', 4326), 17.02, 17.02, 3, 4),
(407, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055018 10.790283, 106.7054939 10.7902068)', 4326), 8.52, 8.52, 4, 5),
(408, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054939 10.7902068, 106.7054924 10.7901302)', 4326), 8.52, 8.52, 5, 7),
(409, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054924 10.7901302, 106.7054985 10.7900455)', 4326), 9.44, 9.44, 7, 9),
(410, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054985 10.7900455, 106.7055126 10.7899617)', 4326), 9.44, 9.44, 9, 10),
(411, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055126 10.7899617, 106.7055243 10.789915)', 4326), 5.35, 5.35, 10, 11),
(412, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055243 10.789915, 106.70554 10.7898694)', 4326), 5.35, 5.35, 11, 12),
(413, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.70554 10.7898694, 106.7055642 10.7898163)', 4326), 6.47, 6.47, 12, 13),
(414, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055642 10.7898163, 106.7055937 10.789766)', 4326), 6.45, 6.45, 13, 15),
(415, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055937 10.789766, 106.7057198 10.7895907)', 4326), 23.87, 23.87, 15, 21),
(416, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057198 10.7895907, 106.7058474 10.7894286)', 4326), 22.78, 22.78, 21, 27),
(417, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058474 10.7894286, 106.7058778 10.7893932)', 4326), 5.15, 5.15, 27, 29),
(418, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058778 10.7893932, 106.7059324 10.7893296)', 4326), 9.25, 9.25, 29, 37),
(419, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059324 10.7893296, 106.7059716 10.7892839)', 4326), 6.64, 6.64, 37, 43),
(420, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059716 10.7892839, 106.7059819 10.7892719)', 4326), 1.75, 1.75, 43, 48),
(421, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059819 10.7892719, 106.7060542 10.7892069)', 4326), 10.7, 10.7, 48, 58),
(422, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060542 10.7892069, 106.706316 10.7889717)', 4326), 38.75, 38.75, 58, 114),
(423, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706316 10.7889717, 106.7063551 10.7889366)', 4326), 5.78, 5.78, 114, 123),
(424, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063551 10.7889366, 106.7064735 10.7888303)', 4326), 17.53, 17.53, 123, 141),
(425, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7051601 10.7884204, 106.7054697 10.7887487)', 4326), 49.76, 49.76, 54, 52),
(426, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054697 10.7887487, 106.7055535 10.7888376)', 4326), 13.47, 13.47, 52, 51),
(427, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055535 10.7888376, 106.7057778 10.7890753)', 4326), 36.04, 36.04, 51, 47),
(428, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057778 10.7890753, 106.7057319 10.7891164)', 4326), 6.78, 6.78, 47, 41),
(429, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057319 10.7891164, 106.7059324 10.7893296)', 4326), 32.27, 32.27, 41, 37),
(430, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058446 10.7884823, 106.705888 10.7884439)', 4326), 6.38, 6.38, 118, 127),
(431, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.705888 10.7884439, 106.7059768 10.7883653)', 4326), 13.06, 13.06, 127, 139),
(432, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058776 10.7882596, 106.7057908 10.7883369)', 4326), 12.8, 12.8, 140, 129),
(433, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059827 10.7885476, 106.7060716 10.7884663)', 4326), 13.27, 13.27, 126, 138),
(434, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706363 10.7877956, 106.7064804 10.787823)', 4326), 13.18, 13.18, 238, 244),
(435, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064804 10.787823, 106.7065077 10.7878294)', 4326), 3.06, 3.06, 244, 247),
(436, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065077 10.7878294, 106.7066018 10.7878481)', 4326), 10.49, 10.49, 247, 268),
(437, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066018 10.7878481, 106.7066964 10.7878645)', 4326), 10.49, 10.49, 268, 293),
(438, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050469 10.7872996, 106.7050786 10.7873336)', 4326), 5.13, 5.13, 159, 158),
(439, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050786 10.7873336, 106.7053183 10.787592)', 4326), 38.87, 38.87, 158, 153),
(440, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7053183 10.787592, 106.7054625 10.7877474)', 4326), 23.38, 23.38, 153, 149),
(441, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054625 10.7877474, 106.7056678 10.7879686)', 4326), 33.29, 33.29, 149, 144),
(442, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062692 10.7886768, 106.7061764 10.7887595)', 4326), 13.69, 13.69, 136, 124),
(443, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061764 10.7887595, 106.7059827 10.7885476)', 4326), 31.67, 31.67, 124, 126),
(444, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059827 10.7885476, 106.705888 10.7884439)', 4326), 15.49, 15.49, 126, 127),
(445, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.705888 10.7884439, 106.7057908 10.7883369)', 4326), 15.95, 15.95, 127, 129),
(446, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057908 10.7883369, 106.7055474 10.7880758)', 4326), 39.37, 39.37, 129, 131),
(447, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080067 10.7875896, 106.7080049 10.7875874)', 4326), 0.32, 0.32, 609, 610),
(448, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080049 10.7875874, 106.7079704 10.7875428)', 4326), 6.23, 6.23, 610, 615),
(449, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073385 10.7880751, 106.7073545 10.7880358)', 4326), 4.71, 4.71, 373, 387),
(450, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073545 10.7880358, 106.7073774 10.788)', 4326), 4.7, 4.7, 387, 400);
INSERT INTO walkways (id, name, geom, cost, reverse_cost, source, target) VALUES
(451, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073774 10.788, 106.7074065 10.7879685)', 4326), 4.73, 4.73, 400, 427),
(452, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074065 10.7879685, 106.7074409 10.7879427)', 4326), 4.73, 4.73, 427, 440),
(453, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074409 10.7879427, 106.7074794 10.7879234)', 4326), 4.72, 4.72, 440, 455),
(454, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074794 10.7879234, 106.7075209 10.7879111)', 4326), 4.73, 4.73, 455, 472),
(455, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075209 10.7879111, 106.7076137 10.7878806)', 4326), 10.69, 10.69, 472, 514),
(456, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076137 10.7878806, 106.7077039 10.7878432)', 4326), 10.69, 10.69, 514, 540),
(457, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077039 10.7878432, 106.7077881 10.7878008)', 4326), 10.34, 10.34, 540, 549),
(458, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077881 10.7878008, 106.7078298 10.7877786)', 4326), 5.18, 5.18, 549, 557),
(459, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078298 10.7877786, 106.7078689 10.7877523)', 4326), 5.18, 5.18, 557, 561),
(460, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078689 10.7877523, 106.7079102 10.7877174)', 4326), 5.95, 5.95, 561, 570),
(461, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079102 10.7877174, 106.7079469 10.7876779)', 4326), 5.95, 5.95, 570, 574),
(462, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079469 10.7876779, 106.7079786 10.7876343)', 4326), 5.96, 5.96, 574, 590),
(463, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079786 10.7876343, 106.7079801 10.7876316)', 4326), 0.34, 0.34, 590, 592),
(464, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080015 10.7875935, 106.7080049 10.7875874)', 4326), 0.77, 0.77, 605, 610),
(465, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707051 10.7858878, 106.707058 10.7858491)', 4326), 4.37, 4.37, 692, 696),
(466, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707058 10.7858491, 106.7070682 10.7858111)', 4326), 4.37, 4.37, 696, 703),
(467, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070682 10.7858111, 106.7070732 10.7857983)', 4326), 1.52, 1.52, 703, 706),
(468, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070732 10.7857983, 106.7070909 10.7857531)', 4326), 5.39, 5.39, 706, 716),
(469, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070909 10.7857531, 106.707105 10.7857252)', 4326), 3.46, 3.46, 716, 718),
(470, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707105 10.7857252, 106.7071212 10.7856985)', 4326), 3.46, 3.46, 718, 719),
(471, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071212 10.7856985, 106.7071517 10.785658)', 4326), 5.6, 5.6, 719, 724),
(472, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071517 10.785658, 106.7071869 10.7856214)', 4326), 5.6, 5.6, 724, 729),
(473, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071869 10.7856214, 106.7072155 10.7855953)', 4326), 4.27, 4.27, 729, 733),
(474, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707372 10.7854528, 106.7074068 10.7854211)', 4326), 5.18, 5.18, 762, 767),
(475, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074068 10.7854211, 106.7074639 10.7853691)', 4326), 8.5, 8.5, 767, 775),
(476, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074639 10.7853691, 106.7078736 10.7849946)', 4326), 61.13, 61.13, 775, 817),
(477, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064802 10.7863315, 106.7068168 10.7865232)', 4326), 42.5, 42.5, 567, 585),
(478, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067532 10.7860468, 106.7064802 10.7863315)', 4326), 43.49, 43.49, 647, 567),
(479, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064802 10.7863315, 106.7060785 10.7865745)', 4326), 51.53, 51.53, 567, 453),
(480, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060785 10.7865745, 106.7060626 10.7865878)', 4326), 2.28, 2.28, 453, 442),
(481, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060626 10.7865878, 106.7060194 10.7866237)', 4326), 6.18, 6.18, 442, 420),
(482, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060194 10.7866237, 106.7059632 10.786676)', 4326), 8.46, 8.46, 420, 382),
(483, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059632 10.786676, 106.7058919 10.7867512)', 4326), 11.43, 11.43, 382, 349),
(484, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058919 10.7867512, 106.7058264 10.7868314)', 4326), 11.43, 11.43, 349, 311),
(485, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058264 10.7868314, 106.7057155 10.7869317)', 4326), 16.47, 16.47, 311, 286),
(486, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069608 10.7889656, 106.7069696 10.7890633)', 4326), 10.91, 10.91, 175, 169),
(487, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069696 10.7890633, 106.7069731 10.789093)', 4326), 3.32, 3.32, 169, 167),
(488, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069731 10.789093, 106.7069811 10.7891606)', 4326), 7.57, 7.57, 167, 163),
(489, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069811 10.7891606, 106.7069878 10.7892092)', 4326), 5.45, 5.45, 163, 157),
(490, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069878 10.7892092, 106.7069877 10.7892583)', 4326), 5.46, 5.46, 157, 146),
(491, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069877 10.7892583, 106.706981 10.789307)', 4326), 5.46, 5.46, 146, 143),
(492, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706981 10.789307, 106.7069677 10.7893543)', 4326), 5.46, 5.46, 143, 137),
(493, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069677 10.7893543, 106.7069555 10.7893826)', 4326), 3.42, 3.42, 137, 133),
(494, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069555 10.7893826, 106.7069495 10.7893964)', 4326), 1.67, 1.67, 133, 132),
(495, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069495 10.7893964, 106.7069261 10.7894359)', 4326), 5.08, 5.08, 132, 130),
(496, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069261 10.7894359, 106.7068903 10.7894758)', 4326), 5.91, 5.91, 130, 122),
(497, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068903 10.7894758, 106.7068618 10.789521)', 4326), 5.91, 5.91, 122, 113),
(498, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068618 10.789521, 106.7068416 10.7895703)', 4326), 5.91, 5.91, 113, 107),
(499, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068416 10.7895703, 106.7068326 10.7896068)', 4326), 4.18, 4.18, 107, 100),
(500, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068326 10.7896068, 106.7068281 10.7896441)', 4326), 4.18, 4.18, 100, 91),
(501, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068281 10.7896441, 106.7068282 10.7896816)', 4326), 4.17, 4.17, 91, 86),
(502, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068282 10.7896816, 106.7068302 10.789715)', 4326), 3.72, 3.72, 86, 82),
(503, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068302 10.789715, 106.7068279 10.7897483)', 4326), 3.71, 3.71, 82, 75),
(504, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068279 10.7897483, 106.7068215 10.7897811)', 4326), 3.71, 3.71, 75, 69),
(505, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068215 10.7897811, 106.7068092 10.789817)', 4326), 4.21, 4.21, 69, 65),
(506, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068092 10.789817, 106.706792 10.7898509)', 4326), 4.21, 4.21, 65, 63),
(507, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706792 10.7898509, 106.7067717 10.7898793)', 4326), 3.86, 3.86, 63, 61),
(508, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067717 10.7898793, 106.706756 10.7899102)', 4326), 3.84, 3.84, 61, 56),
(509, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706756 10.7899102, 106.706745 10.7899431)', 4326), 3.85, 3.85, 56, 55),
(510, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706745 10.7899431, 106.7067395 10.7899736)', 4326), 3.44, 3.44, 55, 53),
(511, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067395 10.7899736, 106.7067382 10.7900045)', 4326), 3.44, 3.44, 53, 50),
(512, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067382 10.7900045, 106.706741 10.7900354)', 4326), 3.45, 3.45, 50, 45),
(513, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706741 10.7900354, 106.7067634 10.790144)', 4326), 12.32, 12.32, 45, 38),
(514, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068368 10.7886403, 106.7069194 10.7887351)', 4326), 13.88, 13.88, 192, 189),
(515, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069194 10.7887351, 106.7069374 10.7887613)', 4326), 3.51, 3.51, 189, 188),
(516, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069374 10.7887613, 106.7069499 10.7887904)', 4326), 3.51, 3.51, 188, 185),
(517, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069499 10.7887904, 106.7069558 10.7888171)', 4326), 3.04, 3.04, 185, 182),
(518, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069558 10.7888171, 106.7069583 10.7888701)', 4326), 5.9, 5.9, 182, 177),
(519, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069583 10.7888701, 106.7069608 10.7889656)', 4326), 10.62, 10.62, 177, 175),
(520, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058778 10.7893932, 106.7062026 10.7896606)', 4326), 46.29, 46.29, 29, 36),
(521, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062026 10.7896606, 106.7062396 10.7896974)', 4326), 5.75, 5.75, 36, 35),
(522, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062396 10.7896974, 106.7062743 10.7897363)', 4326), 5.75, 5.75, 35, 34),
(523, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062743 10.7897363, 106.706283 10.7897476)', 4326), 1.58, 1.58, 34, 33),
(524, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706283 10.7897476, 106.7063142 10.7897879)', 4326), 5.63, 5.63, 33, 31),
(525, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063142 10.7897879, 106.7063499 10.7898423)', 4326), 7.2, 7.2, 31, 30),
(526, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064909 10.7894412, 106.7064734 10.7894138)', 4326), 3.6, 3.6, 70, 72),
(527, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064734 10.7894138, 106.7064676 10.7894031)', 4326), 1.35, 1.35, 72, 73),
(528, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064676 10.7894031, 106.706458 10.7893852)', 4326), 2.25, 2.25, 73, 74),
(529, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706458 10.7893852, 106.7064448 10.7893557)', 4326), 3.58, 3.58, 74, 79),
(530, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064448 10.7893557, 106.7064339 10.7893253)', 4326), 3.58, 3.58, 79, 83),
(531, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064339 10.7893253, 106.706316 10.7889717)', 4326), 41.37, 41.37, 83, 114),
(532, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065465 10.7893371, 106.7065275 10.7893522)', 4326), 2.67, 2.67, 96, 90),
(533, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065275 10.7893522, 106.7065119 10.7893707)', 4326), 2.67, 2.67, 90, 87),
(534, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065119 10.7893707, 106.7065003 10.7893918)', 4326), 2.67, 2.67, 87, 81),
(535, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065003 10.7893918, 106.7064929 10.789416)', 4326), 2.81, 2.81, 81, 77),
(536, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064929 10.789416, 106.7064909 10.7894412)', 4326), 2.81, 2.81, 77, 70),
(537, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064909 10.7894412, 106.7064914 10.7897798)', 4326), 37.65, 37.65, 70, 46),
(538, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055126 10.7899617, 106.7058291 10.7900275)', 4326), 35.34, 35.34, 10, 14),
(539, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058291 10.7900275, 106.7058916 10.7900156)', 4326), 6.95, 6.95, 14, 16),
(540, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058916 10.7900156, 106.7059534 10.7900008)', 4326), 6.95, 6.95, 16, 17),
(541, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059534 10.7900008, 106.7059898 10.7899898)', 4326), 4.16, 4.16, 17, 18),
(542, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059898 10.7899898, 106.706034 10.7899765)', 4326), 5.05, 5.05, 18, 20),
(543, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706034 10.7899765, 106.7061127 10.7899471)', 4326), 9.2, 9.2, 20, 22),
(544, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061127 10.7899471, 106.7063499 10.7898423)', 4326), 28.41, 28.41, 22, 30),
(545, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063499 10.7898423, 106.7063682 10.7898342)', 4326), 2.2, 2.2, 30, 32),
(546, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063682 10.7898342, 106.7064914 10.7897798)', 4326), 14.75, 14.75, 32, 46),
(547, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064914 10.7897798, 106.7065814 10.789735)', 4326), 11.02, 11.02, 46, 57),
(548, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065814 10.789735, 106.7066043 10.7897189)', 4326), 3.08, 3.08, 57, 60),
(549, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066043 10.7897189, 106.7066237 10.7896989)', 4326), 3.07, 3.07, 60, 62),
(550, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066237 10.7896989, 106.7066391 10.7896757)', 4326), 3.08, 3.08, 62, 64),
(551, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066391 10.7896757, 106.706649 10.7896526)', 4326), 2.79, 2.79, 64, 66),
(552, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706649 10.7896526, 106.7066549 10.7896283)', 4326), 2.78, 2.78, 66, 68),
(553, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066549 10.7896283, 106.7066565 10.7896033)', 4326), 2.79, 2.79, 68, 71),
(554, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066565 10.7896033, 106.7066546 10.7895621)', 4326), 4.59, 4.59, 71, 78),
(555, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066546 10.7895621, 106.7066471 10.7895216)', 4326), 4.58, 4.58, 78, 84),
(556, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066471 10.7895216, 106.7066319 10.7894588)', 4326), 7.17, 7.17, 84, 88),
(557, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066319 10.7894588, 106.7066216 10.7894162)', 4326), 4.87, 4.87, 88, 94),
(558, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066216 10.7894162, 106.7066119 10.7893921)', 4326), 2.88, 2.88, 94, 98),
(559, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066119 10.7893921, 106.7066033 10.7893798)', 4326), 1.66, 1.66, 98, 101),
(560, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066033 10.7893798, 106.7065928 10.7893691)', 4326), 1.65, 1.65, 101, 102),
(561, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065928 10.7893691, 106.7065465 10.7893371)', 4326), 6.18, 6.18, 102, 96),
(562, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065465 10.7893371, 106.7065337 10.7893145)', 4326), 2.88, 2.88, 96, 99),
(563, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065337 10.7893145, 106.7065264 10.7892897)', 4326), 2.87, 2.87, 99, 104),
(564, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065264 10.7892897, 106.7065251 10.7892621)', 4326), 3.07, 3.07, 104, 106),
(565, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065251 10.7892621, 106.7065305 10.789235)', 4326), 3.07, 3.07, 106, 109),
(566, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065305 10.789235, 106.7065794 10.7891211)', 4326), 13.75, 13.75, 109, 128),
(567, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065794 10.7891211, 106.7069499 10.7887904)', 4326), 54.68, 54.68, 128, 185),
(568, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057319 10.7891164, 106.7054898 10.7893332)', 4326), 35.78, 35.78, 41, 23),
(569, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054898 10.7893332, 106.705364 10.7891968)', 4326), 20.46, 20.46, 23, 24),
(570, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.705364 10.7891968, 106.7051849 10.7890028)', 4326), 29.12, 29.12, 24, 25),
(571, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7051849 10.7890028, 106.704878 10.7886714)', 4326), 49.82, 49.82, 25, 26),
(572, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058465 10.7886854, 106.7057093 10.7885349)', 4326), 22.46, 22.46, 89, 92),
(573, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057093 10.7885349, 106.7055802 10.7883933)', 4326), 21.14, 21.14, 92, 93),
(574, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055802 10.7883933, 106.7055688 10.7883755)', 4326), 2.34, 2.34, 93, 97),
(575, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055688 10.7883755, 106.7055636 10.7883551)', 4326), 2.34, 2.34, 97, 103),
(576, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055636 10.7883551, 106.7055651 10.7883342)', 4326), 2.33, 2.33, 103, 105),
(577, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055651 10.7883342, 106.7055732 10.7883147)', 4326), 2.34, 2.34, 105, 108),
(578, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055732 10.7883147, 106.705587 10.7882987)', 4326), 2.33, 2.33, 108, 110),
(579, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.705587 10.7882987, 106.7056044 10.788288)', 4326), 2.24, 2.24, 110, 112),
(580, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056044 10.788288, 106.7056242 10.7882829)', 4326), 2.24, 2.24, 112, 115),
(581, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056242 10.7882829, 106.7056447 10.7882839)', 4326), 2.24, 2.24, 115, 119),
(582, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056447 10.7882839, 106.7056639 10.7882908)', 4326), 2.23, 2.23, 119, 120),
(583, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056639 10.7882908, 106.7056802 10.788303)', 4326), 2.24, 2.24, 120, 121),
(584, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056802 10.788303, 106.7058446 10.7884823)', 4326), 26.83, 26.83, 121, 118),
(585, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058446 10.7884823, 106.7059508 10.7885981)', 4326), 17.33, 17.33, 118, 116),
(586, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7053572 10.7882451, 106.7056623 10.7885769)', 4326), 49.72, 49.72, 85, 80),
(587, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056623 10.7885769, 106.7058847 10.7888187)', 4326), 36.24, 36.24, 80, 76),
(588, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7051849 10.7890028, 106.7054697 10.7887487)', 4326), 42.02, 42.02, 25, 52),
(589, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054697 10.7887487, 106.7056623 10.7885769)', 4326), 28.42, 28.42, 52, 80),
(590, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056623 10.7885769, 106.7057093 10.7885349)', 4326), 6.94, 6.94, 80, 92),
(591, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066632 10.7873828, 106.706712 10.7873864)', 4326), 5.35, 5.35, 380, 391),
(592, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706712 10.7873864, 106.7067343 10.7874213)', 4326), 4.58, 4.58, 391, 388),
(593, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067343 10.7874213, 106.7067429 10.7874288)', 4326), 1.26, 1.26, 388, 389),
(594, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067429 10.7874288, 106.7067541 10.7874315)', 4326), 1.26, 1.26, 389, 390),
(595, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067252 10.7875158, 106.7067457 10.7874783)', 4326), 4.73, 4.73, 366, 378),
(596, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067457 10.7874783, 106.7067512 10.7874645)', 4326), 1.65, 1.65, 378, 381),
(597, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067512 10.7874645, 106.7067543 10.7874481)', 4326), 1.85, 1.85, 381, 384),
(598, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067543 10.7874481, 106.7067541 10.7874315)', 4326), 1.85, 1.85, 384, 390),
(599, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067541 10.7874315, 106.7067665 10.7874282)', 4326), 1.4, 1.4, 390, 396),
(600, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067665 10.7874282, 106.7067754 10.787419)', 4326), 1.41, 1.41, 396, 399);
INSERT INTO walkways (id, name, geom, cost, reverse_cost, source, target) VALUES
(601, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067754 10.787419, 106.7067843 10.7874137)', 4326), 1.14, 1.14, 399, 402),
(602, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067843 10.7874137, 106.7067918 10.787414)', 4326), 0.82, 0.82, 402, 404),
(603, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067918 10.787414, 106.7067983 10.7874177)', 4326), 0.82, 0.82, 404, 406),
(604, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067983 10.7874177, 106.7068094 10.7874223)', 4326), 1.32, 1.32, 406, 408),
(605, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068094 10.7874223, 106.7068215 10.7874218)', 4326), 1.32, 1.32, 408, 416),
(606, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068215 10.7874218, 106.7068315 10.787417)', 4326), 1.22, 1.22, 416, 424),
(607, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068315 10.787417, 106.7068387 10.7874086)', 4326), 1.22, 1.22, 424, 428),
(608, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068387 10.7874086, 106.7068476 10.7873926)', 4326), 2.03, 2.03, 428, 434),
(609, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067252 10.7875158, 106.7067926 10.7876075)', 4326), 12.58, 12.58, 366, 359),
(610, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066197 10.7873145, 106.7066632 10.7873828)', 4326), 8.96, 8.96, 386, 380),
(611, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706712 10.7873864, 106.7067355 10.7873495)', 4326), 4.84, 4.84, 391, 409),
(612, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067355 10.7873495, 106.7067487 10.7873391)', 4326), 1.85, 1.85, 409, 422),
(613, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067487 10.7873391, 106.7067646 10.7873335)', 4326), 1.84, 1.84, 422, 429),
(614, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067646 10.7873335, 106.7067801 10.7873332)', 4326), 1.69, 1.69, 429, 432),
(615, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067801 10.7873332, 106.7067949 10.7873374)', 4326), 1.68, 1.68, 432, 436),
(616, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067949 10.7873374, 106.7068077 10.7873458)', 4326), 1.68, 1.68, 436, 438),
(617, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068077 10.7873458, 106.7068174 10.7873576)', 4326), 1.69, 1.69, 438, 437),
(618, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068174 10.7873576, 106.7068396 10.7873829)', 4326), 3.71, 3.71, 437, 435),
(619, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068396 10.7873829, 106.7068476 10.7873926)', 4326), 1.39, 1.39, 435, 434),
(620, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068476 10.7873926, 106.7068537 10.7874035)', 4326), 1.38, 1.38, 434, 433),
(621, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068537 10.7874035, 106.7068579 10.7874171)', 4326), 1.58, 1.58, 433, 430),
(622, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068579 10.7874171, 106.7068592 10.7874314)', 4326), 1.6, 1.6, 430, 426),
(623, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068592 10.7874314, 106.7068624 10.7874509)', 4326), 2.2, 2.2, 426, 421),
(624, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068624 10.7874509, 106.7068724 10.7874681)', 4326), 2.2, 2.2, 421, 418),
(625, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068724 10.7874681, 106.7068894 10.7874813)', 4326), 2.37, 2.37, 418, 419),
(626, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068894 10.7874813, 106.7069103 10.7874872)', 4326), 2.38, 2.38, 419, 425),
(627, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069103 10.7874872, 106.7069318 10.7874849)', 4326), 2.36, 2.36, 425, 431),
(628, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707288 10.7877627, 106.707319 10.7877355)', 4326), 4.54, 4.54, 452, 463),
(629, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070401 10.7873768, 106.7070508 10.7873892)', 4326), 1.81, 1.81, 493, 491),
(630, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070508 10.7873892, 106.7070581 10.7873909)', 4326), 0.82, 0.82, 491, 494),
(631, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070581 10.7873909, 106.7070642 10.7873951)', 4326), 0.81, 0.81, 494, 496),
(632, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070642 10.7873951, 106.7070679 10.7874003)', 4326), 0.71, 0.71, 496, 495),
(633, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070679 10.7874003, 106.7070697 10.7874063)', 4326), 0.7, 0.7, 495, 492),
(634, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070697 10.7874063, 106.7070783 10.7874221)', 4326), 1.99, 1.99, 492, 488),
(635, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070783 10.7874221, 106.7070912 10.7874346)', 4326), 1.98, 1.98, 488, 489),
(636, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070912 10.7874346, 106.7071041 10.7874447)', 4326), 1.8, 1.8, 489, 490),
(637, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071041 10.7874447, 106.7071078 10.7874511)', 4326), 0.82, 0.82, 490, 487),
(638, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071078 10.7874511, 106.7071081 10.7874623)', 4326), 1.25, 1.25, 487, 483),
(639, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071081 10.7874623, 106.7071122 10.7874745)', 4326), 1.43, 1.43, 483, 482),
(640, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071122 10.7874745, 106.7071198 10.787485)', 4326), 1.43, 1.43, 482, 481),
(641, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069735 10.787266, 106.7070143 10.7872622)', 4326), 4.48, 4.48, 507, 519),
(642, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070143 10.7872622, 106.7070481 10.7872556)', 4326), 3.76, 3.76, 519, 530),
(643, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070481 10.7872556, 106.707063 10.7872539)', 4326), 1.64, 1.64, 530, 533),
(644, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707063 10.7872539, 106.7070776 10.787257)', 4326), 1.63, 1.63, 533, 535),
(645, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070776 10.787257, 106.7070902 10.7872644)', 4326), 1.6, 1.6, 535, 538),
(646, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070902 10.7872644, 106.7070998 10.7872754)', 4326), 1.61, 1.61, 538, 537),
(647, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070998 10.7872754, 106.7071148 10.7872988)', 4326), 3.07, 3.07, 537, 534),
(648, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071148 10.7872988, 106.7071168 10.7873106)', 4326), 1.33, 1.33, 534, 531),
(649, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071168 10.7873106, 106.7071125 10.7873245)', 4326), 1.62, 1.62, 531, 529),
(650, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071029 10.7875002, 106.7071198 10.787485)', 4326), 2.5, 2.5, 473, 481),
(651, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071198 10.787485, 106.7071504 10.7874575)', 4326), 4.53, 4.53, 481, 502),
(652, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071504 10.7874575, 106.7071606 10.7874457)', 4326), 1.72, 1.72, 502, 510),
(653, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071606 10.7874457, 106.7071665 10.7874312)', 4326), 1.74, 1.74, 510, 516),
(654, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071665 10.7874312, 106.7071673 10.7874153)', 4326), 1.77, 1.77, 516, 518),
(655, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071673 10.7874153, 106.7071627 10.7874)', 4326), 1.77, 1.77, 518, 522),
(656, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071627 10.7874, 106.7071534 10.7873871)', 4326), 1.76, 1.76, 522, 523),
(657, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071534 10.7873871, 106.707146 10.7873712)', 4326), 1.94, 1.94, 523, 524),
(658, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707146 10.7873712, 106.7071219 10.787339)', 4326), 4.44, 4.44, 524, 526),
(659, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071219 10.787339, 106.7071165 10.7873307)', 4326), 1.1, 1.1, 526, 528),
(660, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071165 10.7873307, 106.7071125 10.7873245)', 4326), 0.82, 0.82, 528, 529),
(661, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071125 10.7873245, 106.7070984 10.7873232)', 4326), 1.55, 1.55, 529, 525),
(662, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070984 10.7873232, 106.7070853 10.7873284)', 4326), 1.54, 1.54, 525, 520),
(663, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070853 10.7873284, 106.7070772 10.7873372)', 4326), 1.32, 1.32, 520, 517),
(664, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070772 10.7873372, 106.7070733 10.7873485)', 4326), 1.33, 1.33, 517, 515),
(665, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070733 10.7873485, 106.707067 10.7873548)', 4326), 0.98, 0.98, 515, 509),
(666, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707067 10.7873548, 106.7070588 10.7873584)', 4326), 0.98, 0.98, 509, 505),
(667, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070588 10.7873584, 106.7070513 10.7873606)', 4326), 0.85, 0.85, 505, 501),
(668, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070513 10.7873606, 106.7070451 10.7873653)', 4326), 0.86, 0.86, 501, 499),
(669, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070451 10.7873653, 106.7070401 10.7873768)', 4326), 1.39, 1.39, 499, 493),
(670, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070401 10.7873768, 106.7070131 10.787401)', 4326), 3.99, 3.99, 493, 477),
(671, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072036 10.7877994, 106.7072523 10.7877569)', 4326), 7.12, 7.12, 414, 441),
(672, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072523 10.7877569, 106.7072647 10.7877528)', 4326), 1.43, 1.43, 441, 444),
(673, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072647 10.7877528, 106.7072776 10.7877549)', 4326), 1.43, 1.43, 444, 450),
(674, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072776 10.7877549, 106.707288 10.7877627)', 4326), 1.43, 1.43, 450, 452),
(675, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707288 10.7877627, 106.7072932 10.7877731)', 4326), 1.29, 1.29, 452, 447),
(676, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072932 10.7877731, 106.7072933 10.7877846)', 4326), 1.28, 1.28, 447, 443),
(677, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072933 10.7877846, 106.7072885 10.7877951)', 4326), 1.28, 1.28, 443, 439),
(678, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072885 10.7877951, 106.7072405 10.7878383)', 4326), 7.11, 7.11, 439, 412),
(679, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066632 10.7873828, 106.7066491 10.7874388)', 4326), 6.41, 6.41, 380, 367),
(680, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066491 10.7874388, 106.7066435 10.7874484)', 4326), 1.23, 1.23, 367, 363),
(681, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066435 10.7874484, 106.7066408 10.7874592)', 4326), 1.24, 1.24, 363, 358),
(682, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066408 10.7874592, 106.7066416 10.7874732)', 4326), 1.56, 1.56, 358, 353),
(683, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066416 10.7874732, 106.7066471 10.7874862)', 4326), 1.57, 1.57, 353, 351),
(684, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066471 10.7874862, 106.7066763 10.7875162)', 4326), 4.62, 4.62, 351, 350),
(685, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066763 10.7875162, 106.7066869 10.7875201)', 4326), 1.24, 1.24, 350, 352),
(686, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066869 10.7875201, 106.7066981 10.7875218)', 4326), 1.24, 1.24, 352, 355),
(687, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066981 10.7875218, 106.7067121 10.7875206)', 4326), 1.54, 1.54, 355, 362),
(688, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067121 10.7875206, 106.7067252 10.7875158)', 4326), 1.53, 1.53, 362, 366),
(689, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071902 10.7878485, 106.707223 10.7878198)', 4326), 4.8, 4.8, 394, 413),
(690, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071409 10.7877968, 106.7071734 10.7877675)', 4326), 4.82, 4.82, 395, 415),
(691, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070897 10.7877431, 106.7071105 10.78772)', 4326), 3.43, 3.43, 397, 407),
(692, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067926 10.7876075, 106.7068262 10.7876332)', 4326), 4.65, 4.65, 359, 361),
(693, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068262 10.7876332, 106.7068614 10.7876568)', 4326), 4.66, 4.66, 361, 364),
(694, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068614 10.7876568, 106.7069274 10.7876929)', 4326), 8.25, 8.25, 364, 368),
(695, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069274 10.7876929, 106.7069618 10.7877083)', 4326), 4.13, 4.13, 368, 372),
(696, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069618 10.7877083, 106.7069972 10.7877213)', 4326), 4.13, 4.13, 372, 379),
(697, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069972 10.7877213, 106.7070429 10.7877342)', 4326), 5.19, 5.19, 379, 383),
(698, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070429 10.7877342, 106.7070897 10.7877431)', 4326), 5.21, 5.21, 383, 397),
(699, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070897 10.7877431, 106.7071409 10.7877968)', 4326), 8.18, 8.18, 397, 395),
(700, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071409 10.7877968, 106.7071902 10.7878485)', 4326), 7.88, 7.88, 395, 394),
(701, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071902 10.7878485, 106.7072442 10.7879051)', 4326), 8.63, 8.63, 394, 393),
(702, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072442 10.7879051, 106.7072486 10.7879097)', 4326), 0.7, 0.7, 393, 392),
(703, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072486 10.7879097, 106.7072801 10.7878801)', 4326), 4.76, 4.76, 392, 411),
(704, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072801 10.7878801, 106.7072405 10.7878383)', 4326), 6.35, 6.35, 411, 412),
(705, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072405 10.7878383, 106.707223 10.7878198)', 4326), 2.81, 2.81, 412, 413),
(706, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707223 10.7878198, 106.7072036 10.7877994)', 4326), 3.1, 3.1, 413, 414),
(707, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072036 10.7877994, 106.7071734 10.7877675)', 4326), 4.84, 4.84, 414, 415),
(708, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071734 10.7877675, 106.707144 10.7877365)', 4326), 4.71, 4.71, 415, 417),
(709, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707144 10.7877365, 106.7071105 10.78772)', 4326), 4.09, 4.09, 417, 407),
(710, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071105 10.78772, 106.7070857 10.7876924)', 4326), 4.09, 4.09, 407, 410),
(711, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070857 10.7876924, 106.7069137 10.7875004)', 4326), 28.44, 28.44, 410, 423),
(712, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070857 10.7876924, 106.7071936 10.7876002)', 4326), 15.62, 15.62, 410, 467),
(713, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069506 10.7873321, 106.7070131 10.787401)', 4326), 10.26, 10.26, 478, 477),
(714, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070131 10.787401, 106.7070211 10.78741)', 4326), 1.33, 1.33, 477, 476),
(715, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070211 10.78741, 106.7071029 10.7875002)', 4326), 13.43, 13.43, 476, 473),
(716, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071029 10.7875002, 106.7071617 10.787565)', 4326), 9.65, 9.65, 473, 468),
(717, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071617 10.787565, 106.7071936 10.7876002)', 4326), 5.24, 5.24, 468, 467),
(718, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071936 10.7876002, 106.707319 10.7877355)', 4326), 20.35, 20.35, 467, 463),
(719, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707319 10.7877355, 106.707386 10.7878062)', 4326), 10.74, 10.74, 463, 460),
(720, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067533 10.7876422, 106.7067926 10.7876075)', 4326), 5.77, 5.77, 338, 359),
(721, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067926 10.7876075, 106.7069137 10.7875004)', 4326), 17.8, 17.8, 359, 423),
(722, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069137 10.7875004, 106.7069318 10.7874849)', 4326), 2.62, 2.62, 423, 431),
(723, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069318 10.7874849, 106.706965 10.7874566)', 4326), 4.8, 4.8, 431, 445),
(724, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706965 10.7874566, 106.7070211 10.78741)', 4326), 8.02, 8.02, 445, 476),
(725, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068537 10.7874035, 106.7068877 10.7873736)', 4326), 4.98, 4.98, 433, 449),
(726, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068877 10.7873736, 106.7069251 10.7873406)', 4326), 5.49, 5.49, 449, 466),
(727, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069251 10.7873406, 106.7069109 10.7873355)', 4326), 1.65, 1.65, 466, 462),
(728, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069109 10.7873355, 106.7068979 10.7873281)', 4326), 1.64, 1.64, 462, 459),
(729, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068979 10.7873281, 106.7068871 10.7873193)', 4326), 1.53, 1.53, 459, 457),
(730, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068871 10.7873193, 106.7068778 10.787309)', 4326), 1.53, 1.53, 457, 458),
(731, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068778 10.787309, 106.7068733 10.7872998)', 4326), 1.13, 1.13, 458, 461),
(732, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068733 10.7872998, 106.7068708 10.7872899)', 4326), 1.13, 1.13, 461, 465),
(733, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068708 10.7872899, 106.7068712 10.7872732)', 4326), 1.86, 1.86, 465, 471),
(734, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068712 10.7872732, 106.7068772 10.7872576)', 4326), 1.85, 1.85, 471, 479),
(735, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068772 10.7872576, 106.7068882 10.7872448)', 4326), 1.86, 1.86, 479, 484),
(736, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068882 10.7872448, 106.7069026 10.7872345)', 4326), 1.95, 1.95, 484, 497),
(737, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069026 10.7872345, 106.706919 10.787228)', 4326), 1.93, 1.93, 497, 503),
(738, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706919 10.787228, 106.7069381 10.7872286)', 4326), 2.09, 2.09, 503, 508),
(739, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069381 10.7872286, 106.7069552 10.7872369)', 4326), 2.08, 2.08, 508, 513),
(740, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069552 10.7872369, 106.706965 10.7872471)', 4326), 1.56, 1.56, 513, 512),
(741, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706965 10.7872471, 106.706972 10.7872593)', 4326), 1.56, 1.56, 512, 511),
(742, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706972 10.7872593, 106.7069735 10.787266)', 4326), 0.76, 0.76, 511, 507),
(743, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069735 10.787266, 106.7069763 10.7872782)', 4326), 1.39, 1.39, 507, 504),
(744, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069763 10.7872782, 106.706975 10.7872894)', 4326), 1.25, 1.25, 504, 500),
(745, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706975 10.7872894, 106.706974 10.7872975)', 4326), 0.91, 0.91, 500, 498),
(746, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706974 10.7872975, 106.7069665 10.7873151)', 4326), 2.12, 2.12, 498, 486),
(747, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069665 10.7873151, 106.7069542 10.7873301)', 4326), 2.14, 2.14, 486, 480),
(748, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069542 10.7873301, 106.7069506 10.7873321)', 4326), 0.45, 0.45, 480, 478),
(749, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069506 10.7873321, 106.7069406 10.7873378)', 4326), 1.26, 1.26, 478, 474),
(750, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069406 10.7873378, 106.7069251 10.7873406)', 4326), 1.72, 1.72, 474, 466);
INSERT INTO walkways (id, name, geom, cost, reverse_cost, source, target) VALUES
(751, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068174 10.7873576, 106.7068491 10.7873321)', 4326), 4.48, 4.48, 437, 451),
(752, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068491 10.7873321, 106.7068778 10.787309)', 4326), 4.05, 4.05, 451, 458),
(753, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073658 10.7870393, 106.7073985 10.7870389)', 4326), 3.57, 3.57, 589, 597),
(754, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073985 10.7870389, 106.7074307 10.7870452)', 4326), 3.59, 3.59, 597, 602),
(755, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074307 10.7870452, 106.7074556 10.7870553)', 4326), 2.94, 2.94, 602, 606),
(756, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074556 10.7870553, 106.7074784 10.7870695)', 4326), 2.95, 2.95, 606, 611),
(757, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074784 10.7870695, 106.7074984 10.7870873)', 4326), 2.95, 2.95, 611, 613),
(758, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074984 10.7870873, 106.7075349 10.7871302)', 4326), 6.22, 6.22, 613, 608),
(759, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075349 10.7871302, 106.7076246 10.7872354)', 4326), 15.26, 15.26, 608, 603),
(760, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076246 10.7872354, 106.7076169 10.7872713)', 4326), 4.08, 4.08, 603, 593),
(761, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076169 10.7872713, 106.7076399 10.7872985)', 4326), 3.93, 3.93, 593, 591),
(762, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076399 10.7872985, 106.7076606 10.7873031)', 4326), 2.32, 2.32, 591, 596),
(763, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076606 10.7873031, 106.7076818 10.7873018)', 4326), 2.32, 2.32, 596, 598),
(764, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076818 10.7873018, 106.7077014 10.7872948)', 4326), 2.28, 2.28, 598, 607),
(765, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077014 10.7872948, 106.7077183 10.7872827)', 4326), 2.28, 2.28, 607, 618),
(766, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077183 10.7872827, 106.7077255 10.7872768)', 4326), 1.02, 1.02, 618, 619),
(767, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077255 10.7872768, 106.7078068 10.7872105)', 4326), 11.55, 11.55, 619, 634),
(768, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078068 10.7872105, 106.7078823 10.7871489)', 4326), 10.71, 10.71, 634, 648),
(769, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706956 10.7871104, 106.7070877 10.787201)', 4326), 17.56, 17.56, 539, 544),
(770, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070877 10.787201, 106.7071074 10.7872188)', 4326), 2.92, 2.92, 544, 545),
(771, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071074 10.7872188, 106.7071252 10.7872385)', 4326), 2.93, 2.93, 545, 543),
(772, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071252 10.7872385, 106.7071437 10.7872645)', 4326), 3.53, 3.53, 543, 542),
(773, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071437 10.7872645, 106.7071588 10.7872925)', 4326), 3.52, 3.52, 542, 541),
(774, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071588 10.7872925, 106.7072345 10.787423)', 4326), 16.7, 16.7, 541, 532),
(775, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072345 10.787423, 106.7073304 10.7873406)', 4326), 13.92, 13.92, 532, 550),
(776, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073304 10.7873406, 106.7073356 10.7873235)', 4326), 1.98, 1.98, 550, 553),
(777, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073356 10.7873235, 106.7073438 10.7873077)', 4326), 1.97, 1.97, 553, 555),
(778, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073438 10.7873077, 106.7073592 10.7872892)', 4326), 2.66, 2.66, 555, 558),
(779, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073592 10.7872892, 106.7073786 10.787275)', 4326), 2.64, 2.64, 558, 560),
(780, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073786 10.787275, 106.707401 10.7872658)', 4326), 2.65, 2.65, 560, 565),
(781, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707401 10.7872658, 106.707425 10.7872622)', 4326), 2.65, 2.65, 565, 566),
(782, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707425 10.7872622, 106.7073658 10.7870393)', 4326), 25.61, 25.61, 566, 589),
(783, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073658 10.7870393, 106.7073354 10.786925)', 4326), 13.14, 13.14, 589, 614),
(784, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706965 10.7874566, 106.7068877 10.7873736)', 4326), 12.51, 12.51, 445, 449),
(785, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068877 10.7873736, 106.7068491 10.7873321)', 4326), 6.25, 6.25, 449, 451),
(786, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068491 10.7873321, 106.7067585 10.7872349)', 4326), 14.65, 14.65, 451, 454),
(787, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707816 10.7847623, 106.707729 10.7848414)', 4326), 12.95, 12.95, 820, 818),
(788, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707729 10.7848414, 106.7075489 10.7850055)', 4326), 26.83, 26.83, 818, 812),
(789, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075489 10.7850055, 106.7073008 10.7852325)', 4326), 37.03, 37.03, 812, 773),
(790, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066055 10.7858687, 106.7065623 10.7859082)', 4326), 6.44, 6.44, 653, 644),
(791, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065432 10.7859257, 106.7062306 10.7862118)', 4326), 46.67, 46.67, 639, 556),
(792, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706182 10.7862562, 106.7060006 10.7864222)', 4326), 27.09, 27.09, 547, 469),
(793, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059581 10.7864611, 106.7059554 10.7864635)', 4326), 0.39, 0.39, 448, 446),
(794, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057968 10.7866087, 106.7057829 10.7866214)', 4326), 2.07, 2.07, 365, 356),
(795, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057829 10.7866214, 106.7057551 10.7866468)', 4326), 4.15, 4.15, 356, 341),
(796, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057298 10.78667, 106.7056299 10.7867614)', 4326), 14.91, 14.91, 335, 297),
(797, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055838 10.7868035, 106.705553 10.7868315)', 4326), 4.59, 4.59, 285, 261),
(798, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055116 10.786869, 106.7054882 10.7868903)', 4326), 3.48, 3.48, 246, 241),
(799, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054577 10.786918, 106.7054356 10.7869381)', 4326), 3.29, 3.29, 235, 231),
(800, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054017 10.7869688, 106.7053945 10.7869754)', 4326), 1.08, 1.08, 225, 223),
(801, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7053266 10.787037, 106.7052875 10.7870725)', 4326), 5.81, 5.81, 214, 196),
(802, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7052266 10.7871279, 106.7052207 10.7871332)', 4326), 0.87, 0.87, 179, 178),
(803, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050944 10.7872479, 106.7050909 10.7872511)', 4326), 0.53, 0.53, 166, 165),
(804, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050373 10.7872996, 106.7050221 10.7873131)', 4326), 2.24, 2.24, 156, 150),
(805, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075407 10.7849974, 106.7075489 10.7850055)', 4326), 1.27, 1.27, 813, 812),
(806, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057725 10.7866109, 106.7057829 10.7866214)', 4326), 1.63, 1.63, 357, 356),
(807, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055838 10.7868035, 106.7055906 10.7868018)', 4326), 0.76, 0.76, 285, 288),
(808, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050373 10.7872996, 106.7050469 10.7872996)', 4326), 1.05, 1.05, 156, 159),
(809, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055116 10.786869, 106.705553 10.7868315)', 4326), 6.15, 6.15, 246, 261),
(810, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054577 10.786918, 106.7054882 10.7868903)', 4326), 4.54, 4.54, 235, 241),
(811, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054017 10.7869688, 106.7054356 10.7869381)', 4326), 5.03, 5.03, 225, 231),
(812, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056299 10.7867614, 106.7055906 10.7868018)', 4326), 6.21, 6.21, 297, 288),
(813, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057551 10.7866468, 106.7057298 10.78667)', 4326), 3.79, 3.79, 341, 335),
(814, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050909 10.7872511, 106.7050469 10.7872996)', 4326), 7.22, 7.22, 165, 159),
(815, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7053266 10.787037, 106.7053945 10.7869754)', 4326), 10.09, 10.09, 214, 223),
(816, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7052266 10.7871279, 106.7052875 10.7870725)', 4326), 9.07, 9.07, 179, 196),
(817, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059554 10.7864635, 106.7060626 10.7865878)', 4326), 18.1, 18.1, 446, 442),
(818, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060006 10.7864222, 106.7059581 10.7864611)', 4326), 6.35, 6.35, 469, 448),
(819, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062306 10.7862118, 106.706182 10.7862562)', 4326), 7.25, 7.25, 556, 547),
(820, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065623 10.7859082, 106.7065432 10.7859257)', 4326), 2.86, 2.86, 644, 639),
(821, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707729 10.7848414, 106.7078736 10.7849946)', 4326), 23.22, 23.22, 818, 817),
(822, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067466 10.7894321, 106.7066319 10.7894588)', 4326), 12.87, 12.87, 111, 88),
(823, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072322 10.7879162, 106.7072442 10.7879051)', 4326), 1.8, 1.8, 385, 393),
(824, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7087786 10.7867524, 106.7086508 10.786839)', 4326), 16.96, 16.96, 768, 744),
(825, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077461 10.7871386, 106.7078068 10.7872105)', 4326), 10.39, 10.39, 636, 634),
(826, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075403 10.7860499, 106.7075464 10.7860088)', 4326), 4.62, 4.62, 722, 726),
(827, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7049529 10.7879751, 106.7051149 10.7877754)', 4326), 28.4, 28.4, 67, 117),
(828, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068765 10.7862533, 106.7067558 10.7862672)', 4326), 13.28, 13.28, 638, 626),
(829, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706968 10.7893878, 106.7069555 10.7893826)', 4326), 1.48, 1.48, 134, 133),
(830, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063293 10.7897131, 106.706283 10.7897476)', 4326), 6.34, 6.34, 40, 33),
(831, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069324 10.7890976, 106.7069731 10.789093)', 4326), 4.48, 4.48, 164, 167),
(832, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059429 10.7890874, 106.7060542 10.7892069)', 4326), 18.01, 18.01, 59, 58),
(833, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057894 10.790392, 106.7055269 10.7904341)', 4326), 29.05, 29.05, 8, 3),
(834, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059874 10.7899821, 106.7059898 10.7899898)', 4326), 0.9, 0.9, 19, 18),
(835, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074904 10.7871668, 106.7075349 10.7871302)', 4326), 6.34, 6.34, 588, 608),
(836, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075765 10.7881947, 106.7075339 10.7881442)', 4326), 7.3, 7.3, 401, 403),
(837, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080247 10.7879154, 106.707937 10.7878142)', 4326), 14.78, 14.78, 559, 563),
(838, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059916 10.7893005, 106.7059716 10.7892839)', 4326), 2.86, 2.86, 44, 43),
(839, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068688 10.7886139, 106.7068719 10.7886187)', 4326), 0.63, 0.63, 202, 200),
(840, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080523 10.7875285, 106.7079942 10.7875011)', 4326), 7.03, 7.03, 628, 625),
(841, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063256 10.788905, 106.7063551 10.7889366)', 4326), 4.77, 4.77, 125, 123),
(842, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070092 10.7881158, 106.7069634 10.7881443)', 4326), 5.93, 5.93, 298, 291),
(843, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078062 10.7858471, 106.7078197 10.7859212)', 4326), 8.37, 8.37, 764, 756),
(844, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072169 10.7861202, 106.7073135 10.7860184)', 4326), 15.47, 15.47, 683, 711),
(845, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074149 10.7878105, 106.7074124 10.7878002)', 4326), 1.17, 1.17, 470, 475),
(846, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081274 10.7863698, 106.7079328 10.7862776)', 4326), 23.6, 23.6, 741, 736),
(847, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075304 10.7877378, 106.7075384 10.7877718)', 4326), 3.88, 3.88, 527, 521),
(848, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707813 10.7873802, 106.7077255 10.7872768)', 4326), 14.95, 14.95, 617, 619),
(849, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080245 10.787252, 106.7080024 10.7872615)', 4326), 2.63, 2.63, 656, 650),
(850, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7049198 10.7895924, 106.705364 10.7891968)', 4326), 65.48, 65.48, 6, 24),
(851, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083507 10.7872375, 106.7083441 10.7871781)', 4326), 6.64, 6.64, 681, 688),
(852, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062079 10.7884938, 106.7062177 10.7884849)', 4326), 1.46, 1.46, 145, 151),
(853, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068748 10.7879351, 106.7069063 10.7878883)', 4326), 6.24, 6.24, 302, 314),
(854, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076377 10.7874018, 106.7076606 10.7873031)', 4326), 11.26, 11.26, 573, 596),
(855, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080695 10.7870899, 106.7080825 10.7872063)', 4326), 13.01, 13.01, 670, 663),
(856, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7085566 10.7860866, 106.7083136 10.7861284)', 4326), 26.95, 26.95, 807, 780),
(857, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071477 10.7875772, 106.7071617 10.787565)', 4326), 2.05, 2.05, 456, 468),
(858, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078257 10.7869884, 106.7077782 10.7870279)', 4326), 6.8, 6.8, 660, 652),
(859, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080062 10.7867223, 106.7076761 10.7866601)', 4326), 36.71, 36.71, 704, 673),
(860, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072637 10.7872477, 106.7073438 10.7873077)', 4326), 11.01, 11.01, 554, 555),
(861, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076363 10.7869622, 106.707686 10.7869209)', 4326), 7.11, 7.11, 645, 655),
(862, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065001 10.7877418, 106.7064804 10.787823)', 4326), 9.29, 9.29, 271, 244),
(863, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069344 10.7872847, 106.706975 10.7872894)', 4326), 4.46, 4.46, 485, 500),
(864, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072498 10.7867345, 106.7072125 10.7868377)', 4326), 12.18, 12.18, 629, 599),
(865, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069863 10.7868793, 106.7070499 10.7867657)', 4326), 14.41, 14.41, 564, 582),
(866, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075941 10.786251, 106.707488 10.7862865)', 4326), 12.24, 12.24, 715, 694),
(867, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707976 10.7859433, 106.7080415 10.7860219)', 4326), 11.29, 11.29, 770, 769),
(868, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082665 10.7854508, 106.7081498 10.7855206)', 4326), 14.92, 14.92, 816, 815),
(869, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7049359 10.7883321, 106.7050816 10.7884902)', 4326), 23.71, 23.71, 42, 39),
(870, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069709 10.7865279, 106.7068712 10.7866028)', 4326), 13.71, 13.71, 620, 579),
(871, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054875 10.787725, 106.7054625 10.7877474)', 4326), 3.7, 3.7, 161, 149),
(872, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063252 10.7869887, 106.7062385 10.7871204)', 4326), 17.44, 17.44, 398, 342),
(873, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070795 10.7863065, 106.7067714 10.7863605)', 4326), 34.18, 34.18, 658, 616),
(874, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079908 10.7855487, 106.7079994 10.7854967)', 4326), 5.86, 5.86, 803, 811),
(875, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082444 10.7850967, 106.7078736 10.7849946)', 4326), 42.06, 42.06, 821, 817),
(876, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060188 10.7870082, 106.7060132 10.7870281)', 4326), 2.29, 2.29, 318, 309),
(877, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077358 10.7855339, 106.7078087 10.7855954)', 4326), 10.5, 10.5, 783, 785),
(878, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081876 10.7852255, 106.7081392 10.7855189)', 4326), 33.05, 33.05, 819, 814),
(879, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071256 10.7858181, 106.7070732 10.7857983)', 4326), 6.14, 6.14, 713, 706),
(880, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706875 10.785754, 106.7069055 10.7858937)', 4326), 15.88, 15.88, 686, 676),
(881, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7047762 10.7876001, 106.7050221 10.7873131)', 4326), 41.72, 41.72, 95, 150),
(882, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067686 10.7858057, 106.7068484 10.7859184)', 4326), 15.27, 15.27, 672, 668),
(883, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055464 10.7888441, 106.7055535 10.7888376)', 4326), 1.07, 1.07, 49, 51),
(884, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064109 10.7899275, 106.7063682 10.7898342)', 4326), 11.38, 11.38, 28, 32);
SELECT setval(pg_get_serial_sequence('walkways', 'id'), 884);
SELECT setval(pg_get_serial_sequence('walkways_vertices_pgr', 'id'), 821);
COMMIT;

-- Kiểm tra: phải ra 52 khu, 156 bản dịch, 14 cọc phụ, 0 khu cũ, và số đoạn lối đi
SELECT (SELECT count(*) FROM exhibits WHERE is_active AND map_no IS NOT NULL) AS so_khu,
       (SELECT count(*) FROM exhibit_translations WHERE exhibit_id BETWEEN 1 AND 52) AS so_ban_dich,
       (SELECT count(*) FROM exhibit_pins) AS so_coc_phu,
       (SELECT count(*) FROM exhibits WHERE map_no IS NULL) AS so_khu_cu,
       (SELECT count(*) FROM walkways) AS so_doan_loi_di;
