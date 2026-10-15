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
(1, ST_SetSRID(ST_MakePoint(106.7043297, 10.7893114), 4326)),
(2, ST_SetSRID(ST_MakePoint(106.7036671, 10.7886336), 4326)),
(3, ST_SetSRID(ST_MakePoint(106.7057395, 10.7908424), 4326)),
(4, ST_SetSRID(ST_MakePoint(106.7055836, 10.7904908), 4326)),
(5, ST_SetSRID(ST_MakePoint(106.7049198, 10.7895924), 4326)),
(6, ST_SetSRID(ST_MakePoint(106.7057894, 10.790392), 4326)),
(7, ST_SetSRID(ST_MakePoint(106.7052669, 10.7896518), 4326)),
(8, ST_SetSRID(ST_MakePoint(106.7056357, 10.7900624), 4326)),
(9, ST_SetSRID(ST_MakePoint(106.7056403, 10.7900437), 4326)),
(10, ST_SetSRID(ST_MakePoint(106.705673, 10.7899185), 4326)),
(11, ST_SetSRID(ST_MakePoint(106.7059874, 10.7899821), 4326)),
(12, ST_SetSRID(ST_MakePoint(106.7057924, 10.7896285), 4326)),
(13, ST_SetSRID(ST_MakePoint(106.7064109, 10.7899275), 4326)),
(14, ST_SetSRID(ST_MakePoint(106.7050809, 10.7884611), 4326)),
(15, ST_SetSRID(ST_MakePoint(106.7049359, 10.7883321), 4326)),
(16, ST_SetSRID(ST_MakePoint(106.7055506, 10.7888398), 4326)),
(17, ST_SetSRID(ST_MakePoint(106.7051389, 10.7884027), 4326)),
(18, ST_SetSRID(ST_MakePoint(106.7063293, 10.7897131), 4326)),
(19, ST_SetSRID(ST_MakePoint(106.7059745, 10.7892869), 4326)),
(20, ST_SetSRID(ST_MakePoint(106.7059916, 10.7893005), 4326)),
(21, ST_SetSRID(ST_MakePoint(106.7059429, 10.7890874), 4326)),
(22, ST_SetSRID(ST_MakePoint(106.7060653, 10.7891771), 4326)),
(23, ST_SetSRID(ST_MakePoint(106.7052737, 10.7882701), 4326)),
(24, ST_SetSRID(ST_MakePoint(106.7049529, 10.7879751), 4326)),
(25, ST_SetSRID(ST_MakePoint(106.706117, 10.7891187), 4326)),
(26, ST_SetSRID(ST_MakePoint(106.7064648, 10.7894045), 4326)),
(27, ST_SetSRID(ST_MakePoint(106.7047762, 10.7876001), 4326)),
(28, ST_SetSRID(ST_MakePoint(106.7047522, 10.7875851), 4326)),
(29, ST_SetSRID(ST_MakePoint(106.7063365, 10.7889184), 4326)),
(30, ST_SetSRID(ST_MakePoint(106.7063256, 10.788905), 4326)),
(31, ST_SetSRID(ST_MakePoint(106.7067466, 10.7894321), 4326)),
(32, ST_SetSRID(ST_MakePoint(106.7063602, 10.7889004), 4326)),
(33, ST_SetSRID(ST_MakePoint(106.7064842, 10.78881), 4326)),
(34, ST_SetSRID(ST_MakePoint(106.7062079, 10.7884938), 4326)),
(35, ST_SetSRID(ST_MakePoint(106.7056692, 10.787905), 4326)),
(36, ST_SetSRID(ST_MakePoint(106.7054875, 10.787725), 4326)),
(37, ST_SetSRID(ST_MakePoint(106.706968, 10.7893878), 4326)),
(38, ST_SetSRID(ST_MakePoint(106.7065932, 10.7887339), 4326)),
(39, ST_SetSRID(ST_MakePoint(106.7069324, 10.7890976), 4326)),
(40, ST_SetSRID(ST_MakePoint(106.7067463, 10.7886408), 4326)),
(41, ST_SetSRID(ST_MakePoint(106.7068688, 10.7886139), 4326)),
(42, ST_SetSRID(ST_MakePoint(106.7068517, 10.788584), 4326)),
(43, ST_SetSRID(ST_MakePoint(106.7070124, 10.7884399), 4326)),
(44, ST_SetSRID(ST_MakePoint(106.7068413, 10.7882502), 4326)),
(45, ST_SetSRID(ST_MakePoint(106.7066829, 10.7880849), 4326)),
(46, ST_SetSRID(ST_MakePoint(106.7064119, 10.7878108), 4326)),
(47, ST_SetSRID(ST_MakePoint(106.7061269, 10.7875161), 4326)),
(48, ST_SetSRID(ST_MakePoint(106.7058105, 10.7871782), 4326)),
(49, ST_SetSRID(ST_MakePoint(106.7055399, 10.7868576), 4326)),
(50, ST_SetSRID(ST_MakePoint(106.7055564, 10.7867695), 4326)),
(51, ST_SetSRID(ST_MakePoint(106.7065001, 10.7877418), 4326)),
(52, ST_SetSRID(ST_MakePoint(106.7070092, 10.7881158), 4326)),
(53, ST_SetSRID(ST_MakePoint(106.7060188, 10.7870082), 4326)),
(54, ST_SetSRID(ST_MakePoint(106.7068748, 10.7879351), 4326)),
(55, ST_SetSRID(ST_MakePoint(106.7065099, 10.7873363), 4326)),
(56, ST_SetSRID(ST_MakePoint(106.7063252, 10.7869887), 4326)),
(57, ST_SetSRID(ST_MakePoint(106.7072322, 10.7879162), 4326)),
(58, ST_SetSRID(ST_MakePoint(106.7074547, 10.7881988), 4326)),
(59, ST_SetSRID(ST_MakePoint(106.7075765, 10.7881947), 4326)),
(60, ST_SetSRID(ST_MakePoint(106.7075377, 10.7881191), 4326)),
(61, ST_SetSRID(ST_MakePoint(106.7071477, 10.7875772), 4326)),
(62, ST_SetSRID(ST_MakePoint(106.7069344, 10.7872847), 4326)),
(63, ST_SetSRID(ST_MakePoint(106.7068547, 10.7871699), 4326)),
(64, ST_SetSRID(ST_MakePoint(106.7068605, 10.7871664), 4326)),
(65, ST_SetSRID(ST_MakePoint(106.7075785, 10.7880918), 4326)),
(66, ST_SetSRID(ST_MakePoint(106.7074149, 10.7878105), 4326)),
(67, ST_SetSRID(ST_MakePoint(106.7076946, 10.7880149), 4326)),
(68, ST_SetSRID(ST_MakePoint(106.7075304, 10.7877378), 4326)),
(69, ST_SetSRID(ST_MakePoint(106.7070774, 10.7870587), 4326)),
(70, ST_SetSRID(ST_MakePoint(106.7077835, 10.7879668), 4326)),
(71, ST_SetSRID(ST_MakePoint(106.7072637, 10.7872477), 4326)),
(72, ST_SetSRID(ST_MakePoint(106.7069863, 10.7868793), 4326)),
(73, ST_SetSRID(ST_MakePoint(106.7076596, 10.7877443), 4326)),
(74, ST_SetSRID(ST_MakePoint(106.707137, 10.7870381), 4326)),
(75, ST_SetSRID(ST_MakePoint(106.7076377, 10.7874018), 4326)),
(76, ST_SetSRID(ST_MakePoint(106.7074904, 10.7871668), 4326)),
(77, ST_SetSRID(ST_MakePoint(106.7069709, 10.7865279), 4326)),
(78, ST_SetSRID(ST_MakePoint(106.7080247, 10.7879154), 4326)),
(79, ST_SetSRID(ST_MakePoint(106.7079718, 10.7878391), 4326)),
(80, ST_SetSRID(ST_MakePoint(106.7073478, 10.7869488), 4326)),
(81, ST_SetSRID(ST_MakePoint(106.7073534, 10.7869465), 4326)),
(82, ST_SetSRID(ST_MakePoint(106.7079755, 10.7878165), 4326)),
(83, ST_SetSRID(ST_MakePoint(106.707813, 10.7873802), 4326)),
(84, ST_SetSRID(ST_MakePoint(106.7072498, 10.7867345), 4326)),
(85, ST_SetSRID(ST_MakePoint(106.7068765, 10.7862533), 4326)),
(86, ST_SetSRID(ST_MakePoint(106.7070607, 10.7864434), 4326)),
(87, ST_SetSRID(ST_MakePoint(106.7070083, 10.7863791), 4326)),
(88, ST_SetSRID(ST_MakePoint(106.7081428, 10.7875579), 4326)),
(89, ST_SetSRID(ST_MakePoint(106.7072698, 10.7866573), 4326)),
(90, ST_SetSRID(ST_MakePoint(106.7080523, 10.7875285), 4326)),
(91, ST_SetSRID(ST_MakePoint(106.706921, 10.7862543), 4326)),
(92, ST_SetSRID(ST_MakePoint(106.7077461, 10.7871386), 4326)),
(93, ST_SetSRID(ST_MakePoint(106.7076363, 10.7869622), 4326)),
(94, ST_SetSRID(ST_MakePoint(106.7075529, 10.7868638), 4326)),
(95, ST_SetSRID(ST_MakePoint(106.707563, 10.7868594), 4326)),
(96, ST_SetSRID(ST_MakePoint(106.7070795, 10.7863065), 4326)),
(97, ST_SetSRID(ST_MakePoint(106.708273, 10.7875524), 4326)),
(98, ST_SetSRID(ST_MakePoint(106.7076014, 10.7868247), 4326)),
(99, ST_SetSRID(ST_MakePoint(106.7080245, 10.787252), 4326)),
(100, ST_SetSRID(ST_MakePoint(106.7075914, 10.7867728), 4326)),
(101, ST_SetSRID(ST_MakePoint(106.7078257, 10.7869884), 4326)),
(102, ST_SetSRID(ST_MakePoint(106.7067997, 10.7859194), 4326)),
(103, ST_SetSRID(ST_MakePoint(106.7067635, 10.7858129), 4326)),
(104, ST_SetSRID(ST_MakePoint(106.7067573, 10.7857982), 4326)),
(105, ST_SetSRID(ST_MakePoint(106.7076869, 10.7868177), 4326)),
(106, ST_SetSRID(ST_MakePoint(106.7067686, 10.7858057), 4326)),
(107, ST_SetSRID(ST_MakePoint(106.7077641, 10.7867592), 4326)),
(108, ST_SetSRID(ST_MakePoint(106.7080695, 10.7870899), 4326)),
(109, ST_SetSRID(ST_MakePoint(106.7072169, 10.7861202), 4326)),
(110, ST_SetSRID(ST_MakePoint(106.706875, 10.785754), 4326)),
(111, ST_SetSRID(ST_MakePoint(106.7068445, 10.7857564), 4326)),
(112, ST_SetSRID(ST_MakePoint(106.707053, 10.785919), 4326)),
(113, ST_SetSRID(ST_MakePoint(106.707459, 10.7863067), 4326)),
(114, ST_SetSRID(ST_MakePoint(106.7084888, 10.7873679), 4326)),
(115, ST_SetSRID(ST_MakePoint(106.7083507, 10.7872375), 4326)),
(116, ST_SetSRID(ST_MakePoint(106.7073636, 10.7861704), 4326)),
(117, ST_SetSRID(ST_MakePoint(106.7072781, 10.7860805), 4326)),
(118, ST_SetSRID(ST_MakePoint(106.7077925, 10.7865525), 4326)),
(119, ST_SetSRID(ST_MakePoint(106.7071256, 10.7858181), 4326)),
(120, ST_SetSRID(ST_MakePoint(106.7075941, 10.786251), 4326)),
(121, ST_SetSRID(ST_MakePoint(106.7080062, 10.7867223), 4326)),
(122, ST_SetSRID(ST_MakePoint(106.7075403, 10.7860499), 4326)),
(123, ST_SetSRID(ST_MakePoint(106.7079529, 10.7862262), 4326)),
(124, ST_SetSRID(ST_MakePoint(106.7081274, 10.7863698), 4326)),
(125, ST_SetSRID(ST_MakePoint(106.7074041, 10.7854182), 4326)),
(126, ST_SetSRID(ST_MakePoint(106.7073946, 10.7853602), 4326)),
(127, ST_SetSRID(ST_MakePoint(106.7086119, 10.7869261), 4326)),
(128, ST_SetSRID(ST_MakePoint(106.7078062, 10.7858471), 4326)),
(129, ST_SetSRID(ST_MakePoint(106.7080827, 10.7860694), 4326)),
(130, ST_SetSRID(ST_MakePoint(106.7083921, 10.7863616), 4326)),
(131, ST_SetSRID(ST_MakePoint(106.7081008, 10.7860534), 4326)),
(132, ST_SetSRID(ST_MakePoint(106.707976, 10.7859433), 4326)),
(133, ST_SetSRID(ST_MakePoint(106.7077358, 10.7855339), 4326)),
(134, ST_SetSRID(ST_MakePoint(106.7075493, 10.7852465), 4326)),
(135, ST_SetSRID(ST_MakePoint(106.7087786, 10.7867524), 4326)),
(136, ST_SetSRID(ST_MakePoint(106.7082534, 10.7859454), 4326)),
(137, ST_SetSRID(ST_MakePoint(106.7085566, 10.7860866), 4326)),
(138, ST_SetSRID(ST_MakePoint(106.7079908, 10.7855487), 4326)),
(139, ST_SetSRID(ST_MakePoint(106.7078168, 10.7851146), 4326)),
(140, ST_SetSRID(ST_MakePoint(106.7079015, 10.7850713), 4326)),
(141, ST_SetSRID(ST_MakePoint(106.7081876, 10.7852255), 4326)),
(142, ST_SetSRID(ST_MakePoint(106.7082665, 10.7854508), 4326)),
(143, ST_SetSRID(ST_MakePoint(106.7082444, 10.7850967), 4326));
INSERT INTO walkways (id, name, geom, cost, reverse_cost, source, target) VALUES
(1, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057395 10.7908424, 106.7056955 10.7907783, 106.7056509 10.7907343, 106.7056194 10.7906798, 106.7056015 10.7906207, 106.7055903 10.7905571, 106.7055836 10.7904908)', 4326), 43.72, 43.72, 3, 4),
(2, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055836 10.7904908, 106.7055808 10.7904353, 106.7055799 10.790379, 106.7055807 10.7903222, 106.7055928 10.790257, 106.7056061 10.7901919, 106.7056205 10.7901269, 106.7056357 10.7900623)', 4326), 48.02, 48.02, 4, 8),
(3, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056357 10.7900623, 106.7056403 10.7900437)', 4326), 2.12, 2.12, 8, 9),
(4, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056403 10.7900437, 106.7056563 10.7899808, 106.705673 10.7899185)', 4326), 14.3, 14.3, 9, 10),
(5, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.705673 10.7899185, 106.7057022 10.789844, 106.7057319 10.7897708, 106.705762 10.7896989, 106.7057924 10.7896285)', 4326), 34.62, 34.62, 10, 12),
(6, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057924 10.7896285, 106.7058234 10.7895592, 106.7058545 10.7894916, 106.7058857 10.7894261, 106.7059167 10.789363, 106.7059459 10.7893239, 106.7059746 10.7892869)', 4326), 42.88, 42.88, 12, 19),
(7, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059746 10.7892869, 106.7060047 10.7892492, 106.706035 10.7892126, 106.7060653 10.7891771)', 4326), 15.68, 15.68, 19, 22),
(8, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060653 10.7891771, 106.7060911 10.7891476, 106.706117 10.7891187)', 4326), 8.58, 8.58, 22, 25),
(9, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706117 10.7891187, 106.7061497 10.7890831, 106.7061824 10.7890484, 106.7062151 10.7890145, 106.7062556 10.7889816, 106.7062961 10.7889496, 106.7063365 10.7889184)', 4326), 32.75, 32.75, 25, 29),
(10, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063365 10.7889184, 106.7063602 10.7889004)', 4326), 3.27, 3.27, 29, 32),
(11, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063602 10.7889004, 106.7064017 10.7888696, 106.706443 10.7888394, 106.7064842 10.78881)', 4326), 16.85, 16.85, 32, 33),
(12, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064842 10.78881, 106.7065207 10.7887842, 106.7065571 10.7887589, 106.7065932 10.7887339)', 4326), 14.59, 14.59, 33, 38),
(13, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065932 10.7887339, 106.7066306 10.7887084, 106.7066676 10.7886833, 106.7067071 10.7886619, 106.7067463 10.7886408)', 4326), 19.68, 19.68, 38, 40),
(14, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067463 10.7886408, 106.7067819 10.7886217, 106.706817 10.7886027, 106.7068517 10.788584)', 4326), 13.13, 13.13, 40, 42),
(15, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068517 10.788584, 106.7068894 10.7885634, 106.7069263 10.7885429, 106.7069711 10.7885262, 106.7070145 10.7885093, 106.7070559 10.7884921, 106.7070954 10.7884745, 106.7071331 10.7884572, 106.7071695 10.7884402, 106.7072009 10.7884153, 106.7072312 10.7883914, 106.7072603 10.7883685, 106.7072883 10.7883467, 106.7073155 10.7883258, 106.7073419 10.7883058, 106.7073676 10.7882864, 106.7073897 10.7882643, 106.7074116 10.7882424, 106.7074332 10.7882207, 106.7074547 10.7881988)', 4326), 79.39, 79.39, 42, 58),
(16, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074547 10.7881988, 106.7074773 10.7881757, 106.7074999 10.7881525, 106.7075225 10.7881293, 106.7075377 10.7881191)', 4326), 12.69, 12.69, 58, 60),
(17, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075377 10.7881191, 106.7075581 10.7881055, 106.7075785 10.7880918)', 4326), 5.39, 5.39, 60, 65),
(18, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075785 10.7880918, 106.7076017 10.7880763, 106.7076249 10.7880608, 106.7076481 10.7880454, 106.7076714 10.7880301, 106.7076946 10.7880148)', 4326), 15.29, 15.29, 65, 67),
(19, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076946 10.7880148, 106.7077032 10.7880092, 106.70773 10.7879947, 106.7077568 10.7879805, 106.7077835 10.7879668)', 4326), 11.08, 11.08, 67, 70),
(20, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077835 10.7879668, 106.7078105 10.7879532, 106.7078371 10.7879401, 106.7078631 10.7879276, 106.7078881 10.7879154, 106.7079105 10.7879025, 106.7079309 10.7878892, 106.7079488 10.7878749, 106.7079628 10.7878585, 106.7079718 10.7878391)', 4326), 25.53, 25.53, 70, 79),
(21, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079718 10.7878391, 106.7079755 10.7878165)', 4326), 2.53, 2.53, 79, 82),
(22, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079755 10.7878165, 106.7079757 10.7878039, 106.7079755 10.787791, 106.7079755 10.7877684, 106.7079755 10.7877454, 106.7079755 10.7877224, 106.7081428 10.7875579)', 4326), 36.2, 36.2, 82, 88),
(23, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081428 10.7875579, 106.7081694 10.7875588, 106.7081956 10.7875596, 106.7082214 10.7875604, 106.7082467 10.7875612, 106.7082729 10.7875524)', 4326), 14.39, 14.39, 88, 97),
(24, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082729 10.7875524, 106.7082955 10.7875407, 106.7083178 10.787527, 106.7083397 10.787512, 106.7083622 10.7874931, 106.7083842 10.7874735, 106.7084056 10.7874532, 106.7084266 10.7874325, 106.7084474 10.7874113, 106.708468 10.7873898, 106.7084888 10.7873679)', 4326), 31.39, 31.39, 97, 114),
(25, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7084888 10.7873679, 106.7085036 10.7873522, 106.7085187 10.7873363, 106.7085357 10.7873119, 106.7085535 10.7872871, 106.7085722 10.7872622, 106.7085921 10.7872371, 106.7086135 10.7872123, 106.7086291 10.7871788, 106.7086485 10.7871498, 106.7086715 10.7871251, 106.7086967 10.7871009, 106.7087235 10.7870752, 106.7087227 10.787063, 106.7087206 10.7870524, 106.7087166 10.7870426, 106.7087101 10.7870325, 106.7087005 10.7870206, 106.708684 10.7870085, 106.7086639 10.7869905, 106.7086398 10.7869637, 106.7086119 10.7869261)', 4326), 62.6, 62.6, 114, 127),
(26, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7086119 10.7869261, 106.7085813 10.7868784, 106.7085483 10.7868208, 106.708514 10.7867559, 106.7084797 10.786687, 106.7084547 10.7866041, 106.708431 10.7865201, 106.7084097 10.7864383, 106.7083921 10.7863616)', 4326), 67.4, 67.4, 127, 130),
(27, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083921 10.7863616, 106.7083794 10.7862954, 106.7083708 10.7862363, 106.7083661 10.7861845, 106.7083629 10.7861341, 106.7083635 10.786092, 106.7083667 10.786057, 106.7083716 10.7860276, 106.7083772 10.7860028, 106.7083676 10.7859925, 106.7083558 10.7859824, 106.7083414 10.7859717, 106.7083244 10.7859603, 106.7083056 10.7859479, 106.7082791 10.785947, 106.7082534 10.7859454)', 4326), 55.69, 55.69, 130, 136),
(28, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7043297 10.7893114, 106.7043734 10.7892575, 106.7044179 10.7892036, 106.7044627 10.7891501, 106.7045075 10.7890971, 106.7045521 10.7890447, 106.7045965 10.788993, 106.7046407 10.7889419, 106.7046847 10.7888914, 106.7047284 10.7888416, 106.704772 10.7887923, 106.7048155 10.7887437, 106.704859 10.7886956, 106.7049027 10.7886479, 106.7049466 10.7886007, 106.7049909 10.7885538, 106.7050357 10.7885073, 106.7050809 10.7884611)', 4326), 124.89, 124.89, 1, 14),
(29, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7050809 10.7884611, 106.7051099 10.7884318, 106.7051389 10.7884027)', 4326), 9.05, 9.05, 14, 17),
(30, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7051389 10.7884027, 106.7051854 10.7883565, 106.7052295 10.788313, 106.7052737 10.7882701)', 4326), 20.79, 20.79, 17, 23),
(31, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7052737 10.7882701, 106.7053187 10.788227, 106.7053637 10.7881844, 106.7054085 10.7881424, 106.7054531 10.7881011, 106.7054974 10.7880604, 106.7055412 10.7880204, 106.7055845 10.7879812, 106.7056271 10.7879427, 106.7056692 10.787905)', 4326), 59.17, 59.17, 23, 35),
(32, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7056692 10.787905, 106.7057104 10.7878681, 106.705751 10.787832, 106.705791 10.7877966, 106.7058303 10.7877619, 106.7058691 10.7877278, 106.7059075 10.7876944, 106.7059454 10.7876615, 106.7059831 10.7876292, 106.7060204 10.7875973, 106.706056 10.7875699, 106.7060914 10.7875429, 106.7061269 10.7875161)', 4326), 66.01, 66.01, 35, 47),
(33, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061269 10.7875161, 106.7061701 10.787498, 106.7062131 10.7874803, 106.706256 10.7874632, 106.7062934 10.7874436, 106.7063304 10.7874246, 106.7063671 10.787406, 106.7064034 10.7873879, 106.7064393 10.7873702, 106.7064748 10.787353, 106.7065099 10.7873363)', 4326), 46.39, 46.39, 47, 55),
(34, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065099 10.7873363, 106.7065392 10.7873224, 106.7065776 10.7873045, 106.7066153 10.787287, 106.7066525 10.7872699, 106.7066891 10.7872532, 106.7067251 10.787237, 106.7067605 10.7872211, 106.7067952 10.7872055, 106.7068252 10.7871876, 106.7068547 10.7871699)', 4326), 41.99, 41.99, 55, 63),
(35, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068547 10.7871699, 106.7068605 10.7871664)', 4326), 0.74, 0.74, 63, 64),
(36, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068605 10.7871664, 106.7068897 10.7871488, 106.7069183 10.7871315, 106.7069464 10.7871144, 106.7069738 10.7870976, 106.7070008 10.7870811, 106.7070266 10.7870735, 106.7070521 10.787066, 106.7070774 10.7870587)', 4326), 26.74, 26.74, 64, 69),
(37, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070774 10.7870587, 106.7070954 10.7870535, 106.7071132 10.7870484, 106.707137 10.7870381)', 4326), 6.92, 6.92, 69, 74),
(38, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707137 10.7870381, 106.7071641 10.7870264, 106.7071909 10.7870149, 106.7072174 10.7870036, 106.7072438 10.7869924, 106.70727 10.7869813, 106.707296 10.7869703, 106.707322 10.7869595, 106.7073478 10.7869488)', 4326), 25.08, 25.08, 74, 80),
(39, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073478 10.7869488, 106.7073534 10.7869465)', 4326), 0.66, 0.66, 80, 81),
(40, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073534 10.7869465, 106.7073771 10.7869366, 106.7074009 10.7869269, 106.7074264 10.7869164, 106.7074518 10.7869059, 106.7074772 10.7868955, 106.7075026 10.786885, 106.7075278 10.7868745, 106.7075529 10.7868638)', 4326), 23.66, 23.66, 81, 94),
(41, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075529 10.7868638, 106.707563 10.7868594)', 4326), 1.21, 1.21, 94, 95),
(42, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707563 10.7868594, 106.7075859 10.7868492, 106.7076109 10.7868419, 106.7076357 10.7868344, 106.7076605 10.7868267, 106.7076853 10.7868188, 106.7076869 10.7868177)', 4326), 14.34, 14.34, 95, 105),
(43, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076869 10.7868177, 106.7077059 10.7868036, 106.7077251 10.7867893, 106.7077445 10.7867745, 106.7077641 10.7867592)', 4326), 10.64, 10.64, 105, 107),
(44, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077641 10.7867592, 106.7077672 10.7867252, 106.7077705 10.7866902, 106.7077742 10.7866541, 106.7077783 10.7866171, 106.707783 10.786579, 106.7077925 10.7865525)', 4326), 23.14, 23.14, 107, 118),
(45, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077925 10.7865525, 106.707806 10.7865159, 106.7078204 10.7864782, 106.7078358 10.7864393, 106.7078523 10.7863995, 106.70787 10.7863589, 106.7078891 10.7863178, 106.7079095 10.7862876, 106.7079308 10.786257, 106.7079529 10.7862262)', 4326), 40.33, 40.33, 118, 123),
(46, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079529 10.7862262, 106.7079828 10.7861863, 106.7080143 10.7861466, 106.7080476 10.7861075, 106.7080827 10.7860694)', 4326), 22.42, 22.42, 123, 129),
(47, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080827 10.7860694, 106.7081008 10.7860534)', 4326), 2.65, 2.65, 129, 131),
(48, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081008 10.7860534, 106.7081355 10.7860243, 106.7081721 10.7859963, 106.7082109 10.7859698, 106.7082534 10.7859454)', 4326), 20.57, 20.57, 131, 136),
(49, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070124 10.7884399, 106.7069852 10.7884085, 106.7069574 10.788377, 106.706929 10.7883453, 106.7069002 10.7883136, 106.7068709 10.7882819, 106.7068413 10.7882502)', 4326), 28.11, 28.11, 43, 44),
(50, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068413 10.7882502, 106.7068101 10.788217, 106.7067786 10.7881839, 106.7067468 10.7881508, 106.7067149 10.7881178, 106.7066829 10.7880849)', 4326), 25.18, 25.18, 44, 45),
(51, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7066829 10.7880849, 106.7066488 10.78805, 106.7066146 10.7880152, 106.7065803 10.7879805, 106.706546 10.7879458, 106.7065124 10.7879119, 106.7064788 10.7878781, 106.7064453 10.7878444, 106.7064119 10.7878108)', 4326), 42.39, 42.39, 45, 46),
(52, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064119 10.7878108, 106.7063792 10.7877778, 106.7063467 10.787745, 106.7063144 10.7877122, 106.7062823 10.7876795, 106.7062504 10.7876469, 106.7062188 10.7876143, 106.7061876 10.7875817, 106.7061569 10.787549, 106.7061269 10.7875161)', 4326), 45.09, 45.09, 46, 47),
(53, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7061269 10.7875161, 106.7060976 10.7874833, 106.7060685 10.7874507, 106.7060397 10.7874183, 106.7060111 10.7873862, 106.7059825 10.7873545, 106.705954 10.7873233, 106.7059255 10.7872927, 106.705897 10.7872628, 106.7058683 10.7872337, 106.7058395 10.7872055, 106.7058105 10.7871782)', 4326), 50.94, 50.94, 47, 48),
(54, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7058105 10.7871782, 106.7057871 10.7871568, 106.7057637 10.787136, 106.7057404 10.7871155, 106.7057114 10.7870903, 106.7056829 10.7870653, 106.7056552 10.7870401, 106.7056284 10.7870144, 106.705603 10.7869878, 106.7055794 10.7869598, 106.7055586 10.7869296, 106.7055428 10.786896, 106.7055399 10.7868576)', 4326), 47.39, 47.39, 48, 49),
(55, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055399 10.7868576, 106.7055575 10.786808, 106.7055564 10.7867695)', 4326), 10.07, 10.07, 49, 50),
(56, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7051389 10.7884027, 106.7051705 10.7884316, 106.705201 10.7884612, 106.705231 10.7884914, 106.7052606 10.788522, 106.70529 10.788553, 106.7053193 10.7885842, 106.7053484 10.7886156, 106.7053774 10.7886472, 106.7054064 10.788679, 106.7054354 10.7887109, 106.7054642 10.788743, 106.7054931 10.7887752, 106.7055219 10.7888075, 106.7055506 10.7888398)', 4326), 66.08, 66.08, 17, 16),
(57, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055506 10.7888398, 106.7055798 10.7888728, 106.7056089 10.7889059, 106.705638 10.788939, 106.7056672 10.7889722, 106.7056964 10.7890053, 106.7057257 10.7890384, 106.7057551 10.7890714, 106.7057062 10.7891222, 106.7056571 10.789175, 106.7056079 10.7892296, 106.7055585 10.789286, 106.7055092 10.789344, 106.7054601 10.7894034, 106.7054111 10.7894641, 106.7053625 10.7895259, 106.7053144 10.7895885, 106.7052669 10.7896518)', 4326), 117.54, 117.54, 16, 7),
(58, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7052669 10.7896518, 106.7052869 10.7896944, 106.7053071 10.7897373, 106.7053276 10.7897805, 106.7053484 10.7898241, 106.7053697 10.789868, 106.7053916 10.789912, 106.7054361 10.7899147, 106.7054815 10.7899168, 106.7055279 10.7899181, 106.7055752 10.7899189, 106.7056236 10.789919, 106.705673 10.7899185)', 4326), 62.63, 62.63, 7, 10),
(59, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075914 10.7867728, 106.7075592 10.7867702, 106.7075268 10.7867674, 106.7074939 10.7867642, 106.7074609 10.7867608, 106.7074278 10.7867572, 106.7073949 10.7867535, 106.7073636 10.7867296, 106.7073322 10.7867055, 106.707301 10.7866814, 106.7072698 10.7866573)', 4326), 38.92, 38.92, 100, 89),
(60, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072698 10.7866573, 106.7072389 10.7866331, 106.7072081 10.7866089, 106.7071776 10.7865846, 106.7071482 10.7865493, 106.7071189 10.786514, 106.7070897 10.7864787, 106.7070607 10.7864434)', 4326), 33.07, 33.07, 89, 86),
(61, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070607 10.7864434, 106.7070343 10.7864112, 106.7070083 10.7863791)', 4326), 9.13, 9.13, 86, 87),
(62, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070083 10.7863791, 106.7069862 10.7863514, 106.7069645 10.7863238, 106.7069433 10.7862965, 106.7069322 10.7862753, 106.706921 10.7862543)', 4326), 16.84, 16.84, 87, 91),
(63, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706921 10.7862543, 106.7069025 10.7862194, 106.7068843 10.7861849, 106.7068664 10.7861509, 106.7068491 10.7861173, 106.7068326 10.7860843, 106.7068172 10.786052, 106.70681 10.7860243, 106.7068035 10.7859971, 106.7067985 10.7859705, 106.7067966 10.7859446, 106.7067997 10.7859194)', 4326), 40.01, 40.01, 91, 102),
(64, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067997 10.7859194, 106.7068193 10.7859111, 106.7068445 10.7859023, 106.7068744 10.7858929, 106.7069084 10.7858827, 106.706946 10.785872, 106.70698 10.7858872, 106.7070158 10.7859029, 106.707053 10.785919)', 4326), 29.65, 29.65, 102, 112),
(65, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707053 10.785919, 106.7070912 10.785935, 106.7071303 10.785951, 106.70717 10.7859669, 106.7071961 10.7859946, 106.7072229 10.7860228, 106.7072503 10.7860515, 106.7072781 10.7860806)', 4326), 31.1, 31.1, 112, 117),
(66, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072781 10.7860806, 106.7073064 10.7861101, 106.7073349 10.7861401, 106.7073636 10.7861705)', 4326), 13.65, 13.65, 117, 116),
(67, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073636 10.7861705, 106.7073918 10.7862005, 106.7074138 10.7862356, 106.7074363 10.786271, 106.707459 10.7863067)', 4326), 18.38, 18.38, 116, 113),
(68, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707459 10.7863067, 106.7074831 10.7863443, 106.7075074 10.7863822, 106.707532 10.7864203, 106.7075566 10.7864586, 106.7075814 10.7864971, 106.7075906 10.7865391, 106.7076004 10.7865809, 106.7076106 10.7866222, 106.7076209 10.786663, 106.7076313 10.7867033, 106.7076178 10.786727, 106.7076046 10.7867501, 106.7075914 10.7867728)', 4326), 57.23, 57.23, 113, 100),
(69, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075914 10.7867728, 106.7075966 10.7867989, 106.7076014 10.7868247)', 4326), 5.84, 5.84, 100, 98),
(70, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7036671 10.7886336, 106.7036874 10.7886097, 106.7036884 10.7885978, 106.7037031 10.7885759, 106.7037659 10.7885203, 106.7038226 10.7884741, 106.7038485 10.7884487, 106.7039175 10.7883786, 106.703969 10.7883308, 106.7040204 10.788283, 106.7040718 10.7882353, 106.704123 10.7881879, 106.7041681 10.7881466, 106.7042106 10.7881074, 106.7042536 10.7880672, 106.7042997 10.7880222, 106.7043476 10.7879747, 106.7043966 10.7879258, 106.7044464 10.7878762, 106.7044968 10.7878263, 106.7045477 10.7877763, 106.7045989 10.7877267, 106.7046501 10.7876779, 106.7047013 10.7876304, 106.7047522 10.7875851)', 4326), 166.36, 166.36, 2, 28),
(71, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7047522 10.7875851, 106.704764 10.787575, 106.7048135 10.787533, 106.7048624 10.787493, 106.7049107 10.7874542, 106.7049583 10.7874161, 106.7050049 10.7873785, 106.7050505 10.7873409, 106.7050946 10.7873029, 106.7051366 10.7872641, 106.7051749 10.7872235, 106.7052061 10.7871798, 106.7052411 10.7871323, 106.7052931 10.7870783, 106.7053494 10.7870251, 106.7053985 10.7869807, 106.7054274 10.7869562, 106.70547 10.7869295, 106.7055125 10.7868984, 106.7055399 10.7868576)', 4326), 118.49, 118.49, 28, 49),
(72, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7055399 10.7868576, 106.7055559 10.7868033, 106.7056194 10.7867823, 106.7056743 10.7867568, 106.7057222 10.7867279, 106.7057673 10.7866984, 106.7058104 10.786669, 106.7058519 10.78664, 106.7058922 10.7866114, 106.7059313 10.7865835, 106.7059694 10.7865561, 106.7060065 10.7865294, 106.7060427 10.7865032, 106.706078 10.7864777, 106.7061125 10.7864526, 106.7061461 10.7864282, 106.7061791 10.7864042, 106.7062112 10.7863806, 106.706243 10.7863571, 106.7062739 10.7863341, 106.7063042 10.7863114, 106.7063337 10.786289, 106.7063626 10.786267, 106.7063906 10.7862453, 106.706418 10.7862239, 106.7064446 10.7862028, 106.7064705 10.7861819, 106.7064956 10.7861612, 106.70652 10.7861408, 106.7065435 10.7861207, 106.7065663 10.7861007, 106.7065882 10.786081, 106.7066092 10.7860615, 106.7066293 10.7860422, 106.7066484 10.7860231, 106.7066665 10.7860043, 106.7066835 10.7859857, 106.7066993 10.7859674, 106.7067136 10.7859495, 106.7067267 10.7859307, 106.7067374 10.7859125, 106.7067443 10.7858952, 106.7067468 10.785879, 106.7067472 10.7858635, 106.706747 10.7858487, 106.7067473 10.7858346, 106.7067489 10.7858213, 106.7067522 10.7858089, 106.7067573 10.7857982)', 4326), 182.94, 182.94, 49, 104),
(73, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067573 10.7857982, 106.7067632 10.7857909, 106.7067702 10.7857862, 106.7067801 10.7857822, 106.7067943 10.7857772, 106.7068148 10.7857696, 106.7068445 10.7857564)', 4326), 10.73, 10.73, 104, 111),
(74, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068445 10.7857564, 106.7068928 10.7857269, 106.7069731 10.7856608, 106.7070036 10.785623, 106.7070141 10.7856012, 106.7070262 10.7855881, 106.7070598 10.7855849, 106.7071368 10.7855998, 106.707182 10.7855997, 106.7073767 10.7854477, 106.7073766 10.7854181, 106.7073766 10.7853895, 106.7073946 10.7853602)', 4326), 82.18, 82.18, 111, 126),
(75, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7073946 10.7853602, 106.7074191 10.7853346, 106.7074482 10.7853108, 106.7074802 10.7852884, 106.7075142 10.7852671, 106.7075493 10.7852465)', 4326), 21.18, 21.18, 126, 134),
(76, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075493 10.7852465, 106.70759 10.7852237, 106.7076309 10.7852013, 106.7076716 10.7851792, 106.7077085 10.7851633, 106.7077452 10.7851474, 106.7077813 10.7851312, 106.7078168 10.7851146)', 4326), 32.72, 32.72, 134, 139),
(77, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078168 10.7851146, 106.7078457 10.7851005, 106.7078739 10.7850861, 106.7079015 10.7850713)', 4326), 10.43, 10.43, 139, 140),
(78, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067997 10.7859194, 106.7067888 10.7858949, 106.7067805 10.7858718, 106.7067741 10.7858503, 106.7067688 10.7858305, 106.7067635 10.7858129)', 4326), 12.44, 12.44, 102, 103),
(79, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067635 10.7858129, 106.7067573 10.7857982)', 4326), 1.76, 1.76, 103, 104),
(80, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067466 10.7894321, 106.7067247 10.7894039, 106.7067027 10.7893744, 106.7066806 10.7893437, 106.7066582 10.789312, 106.7066356 10.7892793, 106.7066126 10.7892459, 106.7065893 10.789212, 106.7065656 10.7891776, 106.7065415 10.7891429, 106.7065169 10.7891081, 106.7064919 10.7890732, 106.7064664 10.7890383, 106.7064405 10.7890035, 106.7064142 10.7889689, 106.7063874 10.7889345, 106.7063602 10.7889004)', 4326), 72.42, 72.42, 31, 32),
(81, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072322 10.7879162, 106.707259 10.7879477, 106.7072854 10.7879791, 106.7073112 10.7880104, 106.7073366 10.7880417, 106.7073614 10.788073, 106.7073856 10.7881044, 106.7074092 10.7881357, 106.7074323 10.7881672, 106.7074547 10.7881988)', 4326), 39.62, 39.62, 57, 58),
(82, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7087786 10.7867524, 106.7087387 10.7868208, 106.7086966 10.7868666, 106.708654 10.7869003, 106.7086119 10.7869261)', 4326), 26.96, 26.96, 135, 127),
(83, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077461 10.7871386, 106.7077233 10.7871058, 106.7077002 10.7870725, 106.7076767 10.7870388, 106.7076528 10.7870046, 106.7076285 10.78697, 106.7076038 10.786935, 106.7075786 10.7868996, 106.7075529 10.7868638)', 4326), 37.01, 37.01, 92, 94),
(84, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075403 10.7860499, 106.7075023 10.7860751, 106.7074655 10.7860999, 106.70743 10.786124, 106.707396 10.7861476, 106.7073636 10.7861705)', 4326), 23.48, 23.48, 122, 116),
(85, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7049529 10.7879751, 106.7049803 10.7880016, 106.7050079 10.7880281, 106.7050357 10.7880548, 106.7050638 10.7880816, 106.7050923 10.7881084, 106.7051214 10.7881352, 106.7051511 10.788162, 106.7051814 10.7881888, 106.7052121 10.7882157, 106.705243 10.7882428, 106.7052737 10.7882701)', 4326), 47.91, 47.91, 24, 23),
(86, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068765 10.7862533, 106.7068907 10.7862535, 106.7069055 10.7862538, 106.706921 10.7862543)', 4326), 4.87, 4.87, 85, 91),
(87, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706968 10.7893878, 106.7069526 10.7893571, 106.7069369 10.7893244, 106.7069209 10.7892899, 106.7069043 10.7892541, 106.7068872 10.7892171, 106.7068694 10.7891795, 106.706851 10.7891414, 106.7068317 10.7891032, 106.7068117 10.789065, 106.7067909 10.789027, 106.7067692 10.7889893, 106.7067467 10.7889519, 106.7067232 10.7889148, 106.7066989 10.788878, 106.7066738 10.7888416, 106.7066477 10.7888055, 106.7066209 10.7887696, 106.7065932 10.7887339)', 4326), 83.35, 83.35, 37, 38),
(88, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063293 10.7897131, 106.7062832 10.7897064, 106.7062363 10.7896992, 106.7061886 10.7896917, 106.7061403 10.789684, 106.7060912 10.7896761, 106.7060417 10.7896682, 106.7059919 10.7896601, 106.7059419 10.7896521, 106.7058919 10.7896441, 106.7058421 10.7896362, 106.7057924 10.7896285)', 4326), 59.45, 59.45, 18, 12),
(89, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069324 10.7890976, 106.70692 10.7890537, 106.7069069 10.78901, 106.7068929 10.7889668, 106.7068781 10.7889242, 106.7068623 10.7888823, 106.7068455 10.7888409, 106.7068278 10.7888001, 106.706809 10.7887598, 106.7067892 10.7887199, 106.7067682 10.7886803, 106.7067463 10.7886408)', 4326), 54.61, 54.61, 39, 40),
(90, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059429 10.7890874, 106.7059737 10.7891091, 106.7060044 10.7891312, 106.7060349 10.7891538, 106.7060653 10.7891771)', 4326), 16.66, 16.66, 21, 22),
(91, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076596 10.7877443, 106.7076802 10.7877826, 106.7077011 10.7878207, 106.707722 10.7878583, 106.7077429 10.7878953, 106.7077634 10.7879315, 106.7077835 10.7879668)', 4326), 28.09, 28.09, 73, 70),
(92, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7057894 10.790392, 106.7057207 10.790425, 106.7056515 10.7904585, 106.7055836 10.7904908)', 4326), 25.02, 25.02, 6, 4),
(93, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059874 10.7899821, 106.7059303 10.7899921, 106.7058723 10.7900026, 106.7058138 10.7900133, 106.7057554 10.7900239, 106.7056974 10.7900341, 106.7056403 10.7900437)', 4326), 38.56, 38.56, 11, 9),
(94, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074904 10.7871668, 106.7074675 10.7871309, 106.7074443 10.7870949, 106.7074208 10.7870587, 106.7073968 10.7870222, 106.7073725 10.7869856, 106.7073478 10.7869488)', 4326), 28.71, 28.71, 76, 80),
(95, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064648 10.7894045, 106.7064313 10.7893775, 106.7063975 10.7893497, 106.7063633 10.7893215, 106.7063288 10.7892927, 106.706294 10.7892637, 106.706259 10.7892344, 106.7062237 10.7892052, 106.7061883 10.789176, 106.7061527 10.7891471, 106.706117 10.7891187)', 4326), 49.45, 49.45, 26, 25),
(96, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075765 10.7881947, 106.7075574 10.7881568, 106.7075377 10.7881191)', 4326), 9.37, 9.37, 59, 60),
(97, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080247 10.7879154, 106.7080068 10.7878918, 106.7079886 10.7878659, 106.7079718 10.7878391)', 4326), 10.24, 10.24, 78, 79),
(98, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7059916 10.7893005, 106.7059746 10.7892869)', 4326), 2.39, 2.39, 20, 19),
(99, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068688 10.7886139, 106.7068517 10.788584)', 4326), 3.8, 3.8, 41, 42),
(100, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080523 10.7875285, 106.7080709 10.7875456, 106.7080886 10.7875563, 106.7081065 10.7875569, 106.7081245 10.7875575, 106.7081428 10.7875579)', 4326), 10.98, 10.98, 90, 88),
(101, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063256 10.788905, 106.7063365 10.7889184)', 4326), 1.9, 1.9, 30, 29),
(102, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070092 10.7881158, 106.7069778 10.7881418, 106.7069453 10.7881683, 106.7069118 10.7881952, 106.7068771 10.7882225, 106.7068413 10.7882502)', 4326), 23.62, 23.62, 52, 44),
(103, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078062 10.7858471, 106.707832 10.7858743, 106.7078582 10.7859007, 106.7078848 10.7859262, 106.7079117 10.7859505, 106.707939 10.7859737, 106.7079667 10.7859954, 106.7079949 10.7860158, 106.7080235 10.7860349, 106.7080527 10.7860527, 106.7080827 10.7860694)', 4326), 39.16, 39.16, 128, 129),
(104, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072169 10.7861202, 106.7072466 10.7861007, 106.7072781 10.7860806)', 4326), 8.0, 8.0, 109, 117),
(105, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074149 10.7878105, 106.7074366 10.7878459, 106.7074579 10.7878812, 106.707479 10.7879164, 106.7074997 10.7879516, 106.70752 10.7879867, 106.70754 10.7880217, 106.7075595 10.7880568, 106.7075785 10.7880918)', 4326), 35.89, 35.89, 66, 65),
(106, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081274 10.7863698, 106.708098 10.7863436, 106.7080688 10.7863187, 106.7080396 10.7862948, 106.7080106 10.7862716, 106.7079816 10.7862488, 106.7079529 10.7862262)', 4326), 24.83, 24.83, 124, 123),
(107, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075304 10.7877378, 106.7075512 10.787773, 106.707572 10.7878081, 106.7075928 10.7878431, 106.7076135 10.7878779, 106.7076342 10.7879126, 106.7076546 10.787947, 106.7076748 10.7879811, 106.7076946 10.7880148)', 4326), 35.5, 35.5, 68, 67),
(108, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707813 10.7873802, 106.7078325 10.7874156, 106.7078511 10.787452, 106.7078685 10.7874887, 106.7078848 10.7875255, 106.7078996 10.7875622, 106.7079127 10.7875985, 106.7079239 10.7876346, 106.7079332 10.7876706, 106.707941 10.7877069, 106.707949 10.7877436, 106.7079598 10.7877802, 106.7079755 10.7878165)', 4326), 51.64, 51.64, 83, 82),
(109, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080245 10.787252, 106.7080519 10.7872805, 106.7080794 10.7873086, 106.7081067 10.787336, 106.7081336 10.7873625, 106.7081597 10.787388, 106.7081846 10.7874128, 106.7082078 10.7874374, 106.7082284 10.7874631, 106.7082459 10.7874909, 106.7082602 10.7875213, 106.7082729 10.7875524)', 4326), 43.34, 43.34, 99, 97),
(110, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7049198 10.7895924, 106.7049632 10.7896002, 106.7050064 10.7896081, 106.7050494 10.7896159, 106.7050925 10.7896236, 106.7051357 10.7896311, 106.7051791 10.7896383, 106.7052228 10.7896453, 106.7052669 10.7896518)', 4326), 38.52, 38.52, 5, 7),
(111, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7083507 10.7872375, 106.7083747 10.7872571, 106.7083981 10.787277, 106.7084212 10.7872978, 106.7084439 10.7873197, 106.7084664 10.7873431, 106.7084888 10.7873679)', 4326), 20.91, 20.91, 115, 114),
(112, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7062079 10.7884938, 106.7062367 10.7885246, 106.7062653 10.7885556, 106.7062938 10.7885868, 106.706322 10.7886181, 106.7063499 10.7886496, 106.7063775 10.7886812, 106.7064048 10.7887131, 106.7064317 10.7887452, 106.7064582 10.7887775, 106.7064842 10.78881)', 4326), 46.22, 46.22, 34, 33),
(113, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7068748 10.7879351, 106.7068446 10.7879592, 106.7068137 10.7879836, 106.7067821 10.7880084, 106.7067498 10.7880336, 106.7067167 10.7880591, 106.7066829 10.7880849)', 4326), 26.73, 26.73, 54, 45),
(114, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076377 10.7874018, 106.7076168 10.7873637, 106.7075952 10.7873258, 106.707573 10.7872883, 106.7075504 10.7872508, 106.7075272 10.7872134, 106.7075036 10.7871759, 106.7074795 10.7871382, 106.7074551 10.7871003, 106.7074303 10.7870622, 106.7074051 10.7870238, 106.7073794 10.7869853, 106.7073534 10.7869465)', 4326), 59.19, 59.19, 75, 81),
(115, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080695 10.7870899, 106.7080405 10.7870605, 106.708011 10.78703, 106.7079812 10.7869984, 106.707951 10.7869659, 106.7079206 10.7869327, 106.7078898 10.7868988, 106.7078588 10.7868643, 106.7078275 10.7868295, 106.707796 10.7867945, 106.7077641 10.7867592)', 4326), 49.53, 49.53, 108, 107),
(116, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7085566 10.7860866, 106.7085193 10.7861442, 106.7084866 10.786205, 106.7084551 10.7862626, 106.7084238 10.786315, 106.7083921 10.7863616)', 4326), 35.36, 35.36, 137, 130),
(117, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071477 10.7875772, 106.7071217 10.78754, 106.7070956 10.7875027, 106.7070694 10.7874654, 106.7070432 10.787428, 106.7070169 10.7873907, 106.7069907 10.7873533, 106.7069645 10.7873159, 106.7069383 10.7872785, 106.7069122 10.7872411, 106.7068863 10.7872037, 106.7068605 10.7871664)', 4326), 55.22, 55.22, 61, 64),
(118, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7078257 10.7869884, 106.7077988 10.7869554, 106.7077714 10.7869217, 106.7077437 10.7868875, 106.7077155 10.7868528, 106.7076869 10.7868177)', 4326), 24.22, 24.22, 101, 105),
(119, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7080062 10.7867223, 106.7079702 10.7866925, 106.7079345 10.7866633, 106.7078989 10.7866349, 106.7078634 10.786607, 106.707828 10.7865795, 106.7077925 10.7865525)', 4326), 29.98, 29.98, 121, 118),
(120, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072637 10.7872477, 106.7072429 10.7872129, 106.7072219 10.787178, 106.7072008 10.7871431, 106.7071796 10.7871081, 106.7071583 10.7870732, 106.707137 10.7870381)', 4326), 27.0, 27.0, 71, 74),
(121, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7076363 10.7869622, 106.7076123 10.7869283, 106.7075879 10.7868941, 106.707563 10.7868594)', 4326), 13.91, 13.91, 93, 95),
(122, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7065001 10.7877418, 106.706471 10.7877645, 106.7064416 10.7877875, 106.7064119 10.7878108)', 4326), 12.3, 12.3, 51, 46),
(123, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069344 10.7872847, 106.7069077 10.7872464, 106.7068811 10.7872081, 106.7068547 10.7871699)', 4326), 15.4, 15.4, 62, 63),
(124, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7072498 10.7867345, 106.7072569 10.7867088, 106.7072636 10.7866831, 106.7072698 10.7866573)', 4326), 8.81, 8.81, 84, 89),
(125, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069863 10.7868793, 106.7070043 10.7869152, 106.7070225 10.7869511, 106.7070407 10.7869869, 106.707059 10.7870228, 106.7070774 10.7870587)', 4326), 22.2, 22.2, 72, 69),
(126, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7075941 10.786251, 106.7075594 10.786266, 106.7075252 10.7862802, 106.7074918 10.7862938, 106.707459 10.7863067)', 4326), 16.01, 16.01, 120, 113),
(127, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.707976 10.7859433, 106.7079998 10.7859679, 106.7080241 10.7859911, 106.7080489 10.7860129, 106.7080744 10.7860336, 106.7081008 10.7860534)', 4326), 18.32, 18.32, 132, 131),
(128, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082665 10.7854508, 106.7082809 10.7855117, 106.7082992 10.7855644, 106.7083179 10.7856119, 106.7083352 10.7856553, 106.7083495 10.7856954, 106.7083596 10.7857326, 106.7083642 10.7857674, 106.7083623 10.7857998, 106.7083532 10.7858304, 106.7083366 10.7858593, 106.7083132 10.7858875, 106.7082847 10.7859158, 106.7082534 10.7859454)', 4326), 60.69, 60.69, 142, 136),
(129, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7049359 10.7883321, 106.7049638 10.7883579, 106.7049927 10.7883835, 106.7050221 10.7884091, 106.7050516 10.7884349, 106.7050809 10.7884611)', 4326), 21.33, 21.33, 15, 14),
(130, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7069709 10.7865279, 106.7069865 10.7865136, 106.7070017 10.7864995, 106.7070167 10.7864854, 106.7070314 10.7864714, 106.707046 10.7864574, 106.7070607 10.7864434)', 4326), 13.55, 13.55, 77, 86),
(131, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7054875 10.787725, 106.7055179 10.7877539, 106.705548 10.7877835, 106.7055781 10.7878134, 106.7056083 10.7878437, 106.7056386 10.7878742, 106.7056692 10.787905)', 4326), 28.12, 28.12, 36, 35),
(132, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7063252 10.7869887, 106.7063434 10.7870265, 106.7063623 10.7870645, 106.7063819 10.7871028, 106.706402 10.7871414, 106.7064226 10.7871801, 106.7064437 10.787219, 106.7064653 10.787258, 106.7064874 10.7872971, 106.7065099 10.7873363)', 4326), 43.43, 43.43, 56, 55),
(133, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7070795 10.7863065, 106.7070641 10.7863212, 106.7070494 10.7863358, 106.7070353 10.7863503, 106.7070217 10.7863647, 106.7070083 10.7863791)', 4326), 11.19, 11.19, 96, 87),
(134, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7079908 10.7855487, 106.7079813 10.7855094, 106.7079711 10.7854704, 106.7079598 10.7854321, 106.7079475 10.7853947, 106.7079341 10.7853583, 106.7079198 10.785323, 106.707905 10.7852891, 106.7078899 10.7852566, 106.7078748 10.7852255, 106.7078599 10.7851958, 106.7078452 10.7851675, 106.7078308 10.7851405, 106.7078168 10.7851146)', 4326), 51.83, 51.83, 138, 139),
(135, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7082444 10.7850967, 106.7082638 10.7850947, 106.7082823 10.7850998, 106.7082868 10.7851047, 106.7082758 10.7851076, 106.7082554 10.7851092, 106.7082298 10.7851098, 106.7082014 10.7851095, 106.7081714 10.7851084, 106.7081402 10.7851065, 106.7081079 10.7851038, 106.7080748 10.7851003, 106.7080409 10.785096, 106.7080064 10.7850908, 106.7079716 10.7850849, 106.7079366 10.7850784, 106.7079015 10.7850713)', 4326), 47.47, 47.47, 143, 140),
(136, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7060188 10.7870082, 106.7059777 10.7870404, 106.7059359 10.787074, 106.7058939 10.7871083, 106.705852 10.7871431, 106.7058105 10.7871782)', 4326), 29.53, 29.53, 53, 48),
(137, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7077358 10.7855339, 106.7077149 10.7855014, 106.7076931 10.7854691, 106.7076711 10.7854373, 106.7076496 10.7854062, 106.7076289 10.785376, 106.7076095 10.7853469, 106.7075918 10.7853192, 106.7075759 10.7852932, 106.7075618 10.7852689, 106.7075493 10.7852465)', 4326), 37.78, 37.78, 133, 134),
(138, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7081876 10.7852255, 106.7081615 10.7852077, 106.7081346 10.7851908, 106.7081068 10.7851747, 106.7080782 10.7851591, 106.7080491 10.7851439, 106.7080197 10.7851291, 106.7079901 10.7851145, 106.7079604 10.7851, 106.7079308 10.7850856, 106.7079015 10.7850713)', 4326), 35.67, 35.67, 141, 140),
(139, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7071256 10.7858181, 106.7071051 10.785844, 106.7070861 10.7858693, 106.7070687 10.7858942, 106.707053 10.785919)', 4326), 13.7, 13.7, 119, 112),
(140, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.706875 10.785754, 106.7068579 10.7857567, 106.7068445 10.7857564)', 4326), 3.36, 3.36, 110, 111),
(141, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7074041 10.7854182, 106.7074012 10.7853967, 106.7073981 10.7853774, 106.7073946 10.7853602)', 4326), 6.5, 6.5, 125, 126),
(142, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7047762 10.7876001, 106.7047522 10.7875851)', 4326), 3.1, 3.1, 27, 28),
(143, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7067686 10.7858057, 106.7067635 10.7858129)', 4326), 0.97, 0.97, 106, 103),
(144, 'Lối đi bộ', ST_GeomFromText('LINESTRING(106.7064109 10.7899275, 106.7063626 10.7899371, 106.7063136 10.7899458, 106.7062636 10.7899541, 106.7062123 10.7899623, 106.7061597 10.7899706, 106.7061056 10.7899791, 106.7060501 10.789988, 106.7059931 10.7899975, 106.7059345 10.790008, 106.7058748 10.790019, 106.7058146 10.7900303, 106.7057543 10.7900415, 106.7056946 10.7900523, 106.7056357 10.7900623)', 4326), 86.08, 86.08, 13, 8);
SELECT setval(pg_get_serial_sequence('walkways', 'id'), 144);
SELECT setval(pg_get_serial_sequence('walkways_vertices_pgr', 'id'), 143);
COMMIT;

-- Kiểm tra: phải ra 52 khu, 156 bản dịch, 14 cọc phụ, 0 khu cũ, và số đoạn lối đi
SELECT (SELECT count(*) FROM exhibits WHERE is_active AND map_no IS NOT NULL) AS so_khu,
       (SELECT count(*) FROM exhibit_translations WHERE exhibit_id BETWEEN 1 AND 52) AS so_ban_dich,
       (SELECT count(*) FROM exhibit_pins) AS so_coc_phu,
       (SELECT count(*) FROM exhibits WHERE map_no IS NULL) AS so_khu_cu,
       (SELECT count(*) FROM walkways) AS so_doan_loi_di;
