# 🌿 HỆ THỐNG DỊCH VỤ DỰA TRÊN VỊ TRÍ (LBS) - HƯỚNG DẪN DU LỊCH TỰ TÚC THẢO CẦM VIÊN SÀI GÒN

> Bản nâng cấp: xem mục 5 và [UPGRADE_GUIDE.md](UPGRADE_GUIDE.md) (đa ngôn ngữ, admin/khách, connection pool).

> **Đề tài**: Hệ thống tìm kiếm định vị, phân tích không gian và dẫn đường thông minh phục vụ khách tham quan tự túc tại Thảo Cầm Viên Sài Gòn.
> **Triển khai thực tế**: [Thảo Cầm Viên LBS Live Demo](https://hdvthaocamvien.streamlit.app/)
> **Kho mã nguồn**: [GitHub Repository](https://github.com/khanh-code/thao-cam-vien-lbs)

---

## 📌 1. TỔNG QUAN DỰ ÁN & NGỮ CẢNH (CONTEXT)
Hệ thống giải quyết bài toán hỗ trợ khách du lịch tham quan tự túc ngoài trời tại Thảo Cầm Viên Sài Gòn:
* **Định vị & Không gian hóa**: Số hóa các phân khu tham quan (chuồng thú, vườn lan, khu vui chơi...) kèm ranh giới thực tế (Polygon) và tâm điểm (Point).
* **Mạng lưới đường đi bộ thực địa**: Tích hợp 1.192 đoạn đường đi bộ từ OpenStreetMap (OSM), lọc bỏ hoàn toàn các đường ngoại vi (sông rạch, mặt đường phố lân cận) bằng ranh giới không gian khép kín `ST_Within`.
* **Thuyết minh đa phương tiện tự động**: Kích hoạt phát âm thanh thuyết minh (Voice Guide) và hình ảnh khi du khách tiến vào bán kính không gian lân cận (Geofencing 50m).
* **Dẫn đường đi bộ tối ưu (pgRouting)**: Tìm đường ngắn nhất uốn lượn theo lối đi bộ thực tế, tuyệt đối không đâm xuyên qua chuồng thú hay các công trình xây dựng.

---

## 🏛️ 2. KIẾN TRÚC HỆ THỐNG & DATA PIPELINE (4 TẦNG)

Hệ thống được thiết kế theo mô hình kiến trúc 4 tầng chuẩn Location-Based Search (LBS):

* **Tầng 1: Client & Ingestion Layer (Thu thập & Tích hợp định vị)**
  * Giao diện tương tác Streamlit kết hợp bản đồ Folium.
  * Nhận tọa độ GPS người dùng theo thời gian thực (mô phỏng qua tương tác click bản đồ).
  * Chức năng Geocoding / Text Search tìm kiếm phân khu theo từ khóa.

* **Tầng 2: Storage & Spatial Indexing Layer (Lưu trữ & Lập chỉ mục không gian)**
  * Cơ sở dữ liệu: Neon Cloud Serverless PostgreSQL 16 + PostGIS 3.4.
  * Bảng POI Master (`exhibits`): Lưu trữ tọa độ tâm (Point) và ranh giới chuồng thú (Polygon).
  * Bảng Topology (`walkways`): 1.192 đoạn đường đi bộ thực tế nội khu Thảo Cầm Viên.
  * Chỉ mục không gian: GiST Index (`idx_walkways_geom`) tối ưu thuật toán tìm kiếm R-Tree.

* **Tầng 3: Spatio-Temporal Search Engine (Truy xuất & Dẫn đường ngữ cảnh)**
  * `ST_DWithin` & `ST_Distance`: Xử lý Geofencing phát hiện và tính khoảng cách tới phân khu trong bán kính 50m.
  * pgRouting (`pgr_dijkstra`): Thuật toán Dijkstra tìm đường đi bộ ngắn nhất trên mạng lưới đường thực tế.

* **Tầng 4: Application & Presentation Layer (Ứng dụng & Trình bày)**
  * Bản đồ nền tương tác Esri World Street Map.
  * Trực quan hóa dữ liệu: Hiển thị lối đi bộ màu xám, ranh giới phân khu đa sắc và lộ trình dẫn đường màu xanh nét đứt.
  * Proximity Notification: Tự động đổi ảnh trực quan và phát Audio thuyết minh khi du khách tiếp cận vị trí.

---

### 📋 Bảng tổng hợp chức năng 4 tầng:

| Tầng kiến trúc | Công nghệ sử dụng | Nhiệm vụ chính |
| :--- | :--- | :--- |
| **1. Client & Ingestion** | Streamlit, Folium | Tiếp nhận GPS người dùng và tìm kiếm phân khu |
| **2. Storage & Indexing** | PostgreSQL, PostGIS, GiST Index | Lưu trữ đối tượng hình học và lập chỉ mục không gian |
| **3. Spatio-Temporal Engine** | `ST_DWithin`, `pgr_dijkstra` | Xử lý Geofencing 50m và tính đường đi ngắn nhất |
| **4. Presentation Layer** | Streamlit UI, HTML5 Audio | Hiển thị bản đồ, ảnh minh họa và phát audio thuyết minh |
---

## 🧩 3. THIẾT KẾ MÃ NGUỒN THEO 4 TÍNH CHẤT MODULE (SOFTWARE DESIGN)

Toàn bộ mã nguồn được tái cấu trúc thành 3 module chuyên biệt nhằm thỏa mãn nghiêm ngặt các tiêu chuẩn kỹ nghệ phần mềm:

1. **Tính đóng gói (Encapsulation)**:
   * `config.py`: Đóng gói toàn bộ cấu hình bí mật (`st.secrets`), chuỗi kết nối và bảng màu chuẩn.
   * `db_services.py`: Đóng gói logic tầng truy vấn cơ sở dữ liệu, che giấu các câu lệnh SQL phức tạp (`ST_DWithin`, `pgr_dijkstra`).
   * `app.py`: Đóng gói logic tầng hiển thị, chỉ gọi hàm dịch vụ mà không can thiệp vào cách truy vấn dữ liệu.

2. **Khả năng tái sử dụng (Reusability)**:
   * Module `db_services.py` là một tập hợp các Service độc lập, có thể dùng lại ngay cho ứng dụng Mobile (React Native / Flutter) hoặc API Backend (FastAPI / Flask) mà không cần chỉnh sửa.

3. **Khả năng mở rộng (Extensibility / Ver 2 không ảnh hưởng Ver 1)**:
   * Khi Thảo Cầm Viên mở rộng thêm các phân khu hoặc tuyến đường mới, dữ liệu chỉ cần cập nhật trong database PostGIS; tầng hiển thị sẽ tự động nhận diện và vẽ lại mà không phải sửa logic mã nguồn.

4. **Khả năng tích hợp (Integrability)**:
   * Cấu trúc module tách bạch giúp hệ thống sẵn sàng cắm thêm các dịch vụ bổ trợ trong tương lai: Module đặt vé tham quan trực tuyến (Payment Gateway), Module gợi ý lộ trình theo sở thích cá nhân, Module thời tiết thời gian thực.

---

## ⚡ 4. TỐI ƯU HÓA HIỆU SUẤT (PHI CHỨC NĂNG & BENCHMARK)

* **Spatial GiST Indexing**: Đánh chỉ mục không gian `GIST(geom)` trên cả bảng `walkways` và `exhibits`, giảm độ phức tạp tìm kiếm láng giềng từ $O(N)$ xuống $O(\log N)$.
* **In-Memory Caching (`@st.cache_data`)**:
  * Các tập dữ liệu tĩnh gồm 1.192 đoạn đường và danh mục phân khu được lưu vào bộ nhớ RAM của server với thời gian sống `ttl=600` (10 phút).
  * Giảm hơn **90%** số lượng kết nối mạng dư thừa lên Neon Cloud Database, triệt tiêu hiện tượng trễ/nháy màn hình khi người dùng tương tác liên tục.
* **Tải phụ tải (Multi-User Simulation)**: Hệ thống duy trì thời gian phản hồi dưới `100ms` cho các truy vấn kiểm tra bán kính và chỉ mất vài mili-giây để tính toán đường đi qua Dijkstra.

---

## 🆕 5. CHỨC NĂNG BỔ SUNG (BẢN NÂNG CẤP)

* **Đa ngôn ngữ Việt / Anh / Trung (中文)**: chọn ngôn ngữ ở đầu thanh bên trái. Giao diện khách, tên phân khu và thuyết minh đổi theo ngôn ngữ (bản dịch có sẵn trong `english_content.json`, `chinese_content.json`; bản admin sửa lưu trong database được ưu tiên). Phân khu chưa có bản dịch sẽ báo và hiển thị tiếng Việt, không phát nhầm audio tiếng Việt.
* **Giọng đọc tự động (gTTS)**: admin chỉ cần sửa nội dung thuyết minh **tiếng Việt** và bấm **💾 Lưu & tạo giọng đọc** → hệ thống đọc đúng đoạn văn đó thành MP3 (tiếng Việt `vi`, Anh `en`, Trung `zh-CN`) và lưu vào cột `exhibit_translations.audio_data` (bytea) trên database, không cần tạo/upload file. Nếu tạo giọng đọc thất bại thì không lưu gì để audio luôn khớp nội dung. Nội dung chưa có audio (vd. bản dịch tiếng Trung có sẵn) được tự đọc khi khách đến gần và lưu trong bộ nhớ đệm của server.
* **Quản lý phân khu** (`zones.py`, chỉ admin): thêm, sửa, xoá khu. Mỗi khu là một **vùng nghe thuyết minh hình tròn** quanh điểm tham quan (geofence), không phải hàng rào chuồng: admin chỉ chạm một điểm trên ảnh vệ tinh, vùng được tạo bằng `ST_Buffer(geography, bán_kính)`. Lý do: GPS điện thoại sai 5–20 m (nhất là dưới tán cây), nên vẽ ranh giới chi tiết không làm tăng độ chính xác. Bán kính gợi ý = min(40 m, nửa khoảng cách tới tâm khu gần nhất, khoảng cách tới mép vùng khu gần nhất) − 2 m nên các vùng không chồng nhau; trước khi lưu vẫn kiểm tra `ST_IsValid`, `ST_Intersects`, `ST_DWithin` (cách lối đi ≤ 40 m). Xoá là ẩn (`is_active = false`) để giữ lịch sử thống kê. Ảnh tải lên được thu nhỏ (≤ 1280 px, JPEG) và lưu trong bảng `exhibit_images`. File `neon_vung_tron.sql` đổi các khu cũ (ô vuông) sang vùng tròn.
* **52 phân khu theo bản đồ chính thức** (`neon_52_phan_khu.sql`, migration 008): mỗi khu có số hiệu `map_no` (1–52) hiện trên **cọc đỏ đánh số** giống bản đồ in "Khám phá Thảo Cầm Viên". Khu có nhiều điểm (nhà vệ sinh 36, nhà ăn 31, quán giải khát 29, khu vui chơi 39, bò sát 6, vượn 20) có thêm cọc phụ trong bảng `exhibit_pins` (chỉ hiển thị, không phát thuyết minh). Tọa độ được tính bằng cách **nắn (georeference) sơ đồ minh hoạ**: 26 điểm khống chế lấy từ bản đồ thật (bờ rạch Thị Nghè, đường Nguyễn Bỉnh Khiêm, Nguyễn Hữu Cảnh) và lối đi OpenStreetMap (ngã ba, bùng binh, hồ), nội suy thin-plate spline từ pixel sơ đồ sang tọa độ thật; cọc sát mép vườn được dời vào trong ≥ 6 m. Kiểm tra chéo bỏ-một-điểm: sai lệch trung vị khoảng 12 m. Admin tinh chỉnh từng khu bằng "Đổi vị trí vùng nghe thuyết minh".
* **Sơ đồ minh hoạ làm nền bản đồ** (`artmap.py`, `so_do_tcv.json`, `static/so_do_tcv.jpg`): khách xem mặc định sơ đồ chính thức (Leaflet `CRS.Simple`), có nút chuyển sang bản đồ thật. Vị trí GPS, tuyến đường và cọc được đổi từ tọa độ thật sang pixel sơ đồ bằng chính phép nắn (giải ngược bằng Newton), nên cọc hiện đúng chỗ số in; chạm lên sơ đồ được đổi ngược ra tọa độ thật. Mọi truy vấn PostGIS/pgRouting vẫn chạy trên tọa độ thật.
* **Tìm theo ý định** (`search.py`): khách gõ tự nhiên ("ăn", "mắc vệ sinh", "cho bé chơi", câu dài, không dấu, sai chính tả, tiếng Anh/Trung). Câu được chuẩn hoá, so với từ điển nhu cầu → các khu đáp ứng, cộng điểm khớp tên/thuyết minh 3 thứ tiếng; gõ có dấu thì so có dấu để phân biệt "hổ"/"hồ", "đền"/"đến". Tiện ích nhiều điểm (nhà vệ sinh, nhà ăn...) xếp theo điểm gần khách nhất và chỉ đường tới đúng điểm đó. Danh sách khu ở thanh bên gom theo nhóm (động vật, chim, bò sát, vườn, di tích, vui chơi, tiện ích).
* **Mạng lối đi liền mạch**: dữ liệu OpenStreetMap trong vườn bị đứt thành nhiều mảnh nên nhiều khu không tìm được đường. `neon_52_phan_khu.sql` thay bằng mạng đã cắt tại giao điểm, nối các mảnh rời (khe ≤ 40 m) và thêm lối nối từ mỗi cọc ra lối đi gần nhất; `pgr_connectedComponents` cho đúng 1 mảnh, từ cổng chính đi tới được cả 52 khu. Bán kính = nửa khoảng cách tới khu gần nhất − 1 m (5–25 m) nên không vùng nào chồng nhau. Bản đồ in ghi nhầm số 48 cạnh nhãn "Di tích Quán Nhan Hương"; dữ liệu dùng đúng số 49.
* **Kiểm duyệt từ ngữ** (`moderation.py`, danh sách `banned_words.json`): trước khi lưu, tên và thuyết minh (cả 3 ngôn ngữ, cả bản máy dịch và bảng thuật ngữ) được kiểm tra phía server; có từ tục tĩu/xúc phạm thì không lưu và báo từ vi phạm (đã che, vd. `v**`). Chống lách luật (viết hoa, lặp chữ `fuuuck`, số thay chữ `sh1t`, chèn dấu `đ.m`, `f*ck`) nhưng không chặn nhầm từ bình thường khi bỏ dấu (`lon`, `buổi`, `đeo`, `du lịch`, `shiitake`...).
* **Không lưu khi nội dung không đổi**: bấm Lưu mà tên và thuyết minh giống hệt bản đang lưu thì không ghi database, không tạo lại giọng đọc, không dịch lại (thao tác lưu idempotent).
* **Tự dịch có kiểm tra** (`translator.py`): admin sửa bản tiếng Việt và bấm Lưu → hệ thống tự dịch sang tiếng Anh và tiếng Trung (Google Dịch qua `deep-translator`) rồi tạo giọng đọc cho cả 3 ngôn ngữ.
  * **Bảng thuật ngữ cố định** (bảng `glossary`, admin sửa được): tên riêng, tên loài, tên khu được thay bằng mã giữ chỗ trước khi đưa cho máy dịch, dịch xong mới thay bằng bản dịch chuẩn (vd. *báo hoa mai → leopards / 花豹*, *Thảo Cầm Viên → 西贡动植物园（Thảo Cầm Viên）*), nên máy dịch không thể tự chế tên.
  * **Dịch ngược để kiểm tra**: bản Anh/Trung được dịch ngược về tiếng Việt và so với câu gốc → điểm độ khớp (✅ ≥ 75%, ⚠️ 50–75%, ❌ < 50%). Người chỉ biết tiếng Việt vẫn duyệt được bằng cách đọc câu dịch ngược; bản dịch làm mất thuật ngữ bị đánh dấu bắt buộc xem lại.
* **Phân quyền Admin / Khách**: khách dùng ngay không cần đăng nhập. Admin đăng nhập trong mục *Quản trị* để biên tập tên, thuyết minh và đường dẫn audio của từng phân khu theo từng ngôn ngữ (bảng `exhibit_translations`).
  * Tài khoản admin lưu trong bảng `admin_users`, **mặc định `admin` / `123456`**. Khi còn dùng mật khẩu mặc định, app hiện cảnh báo nhắc đổi.
  * Nút **🔑 Đổi mật khẩu**: nhập mật khẩu hiện tại + mật khẩu mới (≥ 6 ký tự, nhập lại 2 lần). Mật khẩu lưu dạng hash PBKDF2-SHA256 có salt, phiên admin hết hạn sau 1 giờ, quyền được kiểm tra lại ở tầng dịch vụ (`require_admin`).
* **Tài khoản khách tạm & lưu vết lộ trình** (`tracking.py`):
  * Khách quét **mã QR** ở cổng → web tự tạo tài khoản tạm (UUID) và gắn vào URL `?v=...`, tải lại trang vẫn giữ tài khoản. Admin tạo/tải mã QR trong mục *📱 Mã QR vào web*.
  * Mỗi lần khách đổi vị trí → lưu 1 điểm `geometry(Point)` vào `visitor_tracks`. Lộ trình đã đi được vẽ lên bản đồ (màu cam) và tính quãng đường bằng `ST_Length(ST_MakeLine(...)::geography)`.
  * **Ưu tiên phân khu chưa ghé**: khi đứng gần 2 phân khu có khoảng cách chênh nhau ≤ 5 m (`tie_metres`), truy vấn xếp hạng dùng window function `MIN(distance) OVER ()` + `EXISTS` trên `exhibit_visits` để phát thuyết minh phân khu khách **chưa** nghe trước. Phân khu đã ghé hiện dấu ✔ màu xám trên bản đồ. Nếu cả hai khu đều chưa ghé, ưu tiên khu nằm **bên phải hướng khách đang đi**: hướng đi tính bằng `ST_Azimuth` từ điểm lưu vết trước đó tới vị trí hiện tại, khu bên phải có `sin(góc tới khu − hướng đi) > 0` (chưa có hướng đi thì lấy bên phải bản đồ, tức phía đông).
  * **Thống kê**: admin xem số khách đã ghé từng phân khu theo ngày (mỗi khách tính 1 lần / phân khu / ngày), số tài khoản khách mới và số điểm lưu vết.
  * **Tự reset**: tài khoản khách chỉ có hiệu lực trong chu kỳ `reset_period = "day"` (mỗi ngày) hoặc `"week"` (mỗi thứ Hai), theo giờ Việt Nam. Hết chu kỳ, mã cũ tự hết hạn và khách được cấp tài khoản mới; số liệu thống kê các ngày trước vẫn được giữ.
* **Nhiều người dùng đồng thời**: `ThreadedConnectionPool` (mặc định 10 kết nối, dùng luân phiên) + semaphore chống quá tải; kết nối luôn được trả lại kể cả khi truy vấn lỗi. `query_nearby` cache 5 giây, `get_shortest_path` cache 60 giây theo tọa độ, có giới hạn số mục.
* **Chỉ mục không gian cho geofencing**: `migrations/001_multilingual.sql` tạo index GiST biểu thức `COALESCE(geom_poly::geography, geom::geography)` khớp đúng điều kiện `ST_DWithin` trong `query_nearby`, để truy vấn bán kính dùng được chỉ mục.
* **Bảo mật cấu hình**: không còn mật khẩu viết cứng trong mã nguồn; mọi thông tin kết nối đọc từ `.streamlit/secrets.toml` (đã đưa vào `.gitignore`) hoặc biến môi trường.
* **Kiểm thử tự động**: `tests/test_upgrade.py` (pytest) kiểm tra hash mật khẩu, khách không được lưu nội dung, đường dẫn audio không hợp lệ, pool nhiều luồng, tách session và giao diện hai ngôn ngữ.

---

## 🛠️ 6. HƯỚNG DẪN CÀI ĐẶT VÀ KHỞI CHẠY CỤC BỘ

### Yêu cầu tiên quyết
* Python 3.10+
* Cơ sở dữ liệu PostgreSQL đã kích hoạt extension `postgis` và `pgrouting`.

### Các bước cài đặt
1. **Clone repository**:
   ```bash
   git clone https://github.com/khanh-code/thao-cam-vien-lbs.git
   cd thao-cam-vien-lbs
   ```
2. **Cài đặt thư viện phụ thuộc**:
   ```bash
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. **Cấu hình kết nối**: chép `.streamlit/secrets.toml.example` thành `.streamlit/secrets.toml` và điền thông tin thật:
   ```toml
   [postgres]
   dbname = "neondb"
   user = "neondb_owner"
   password = "YOUR_PASSWORD"
   host = "your-host.neon.tech"
   port = 5432

   [visitor]
   reset_period = "day"   # hoặc "week"
   ```
4. **Chạy migration** (tạo bảng bản dịch, index, tài khoản admin mặc định, các bảng khách tạm và cột giọng đọc; chạy lại nhiều lần vẫn an toàn). Trên Neon có thể dán file `neon_setup.sql` vào SQL Editor thay cho lệnh này:
   ```bash
   python run_migrations.py
   ```
5. **Khởi chạy ứng dụng**:
   ```bash
   streamlit run app.py
   ```
6. **Kiểm thử**:
   ```bash
   python -m pytest tests -q
   ```

> Sau bước 4, đăng nhập admin bằng `admin` / `123456` rồi bấm **🔑 Đổi mật khẩu**.
>
> Test đụng database (`tests/test_visitors.py`) chỉ chạy khi đặt `TCV_TEST_DB=1` và trỏ tới database **thử nghiệm**, không chạy trên database thật.
