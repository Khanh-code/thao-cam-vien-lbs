# 🌿 HỆ THỐNG DỊCH VỤ DỰA TRÊN VỊ TRÍ (LBS) - HƯỚNG DẪN DU LỊCH TỰ TÚC THẢO CẦM VIÊN SÀI GÒN

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

Hệ thống được thiết kế theo mô hình kiến trúc 4 tầng chuyên biệt cho dịch vụ định vị (LBS):
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. CLIENT & INGESTION LAYER (Thu thập & Tích hợp định vị)                   │
│    • Streamlit UI + Folium Map                                              │
│    • Mô phỏng GPS thời gian thực (Lat/Lng qua click bản đồ)                 │
│    • Text Search / Geocoding tìm kiếm phân khu theo từ khóa                 │
└──────────────────────────────────────┬──────────────────────────────────────┘
│ (Truy vấn GPS / Toạ độ)
▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. STORAGE & SPATIAL INDEXING LAYER (Lưu trữ & Lập chỉ mục không gian)      │
│    • Cơ sở dữ liệu: Neon Cloud Serverless PostgreSQL 16 + PostGIS 3.4       │
│    • POI Master DB (exhibits): Chứa toạ độ Point & Polygon ranh giới      │
│    • Walkway Topology (walkways): 1.192 đoạn đường đi bộ thực địa OSM     │
│    • Chỉ mục không gian: GiST Index (idx_walkways_geom) tối ưu R-Tree     │
└──────────────────────────────────────┬──────────────────────────────────────┘
│ (Candidates & Spatial Queries)
▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. SPATIO-TEMPORAL SEARCH ENGINE (Truy xuất & Dẫn đường ngữ cảnh)           │
│    • ST_DWithin & ST_Distance: Lọc và xếp hạng POI trong bán kính 50m       │
│    • pgRouting (pgr_dijkstra): Tìm lộ trình đi bộ ngắn nhất né vật cản    │
└──────────────────────────────────────┬──────────────────────────────────────┘
│ (Enriched POI & Polyline)
▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. APPLICATION & PRESENTATION LAYER (Ứng dụng & Trình bày)                  │
│    • Hiển thị lớp bản đồ nền Esri World Street Map                          │
│    • Render trực quan: Lối đi bộ xám, vùng ranh giới màu, lộ trình nét đứt │
│    • Proximity Notification: Tự động đổi ảnh và phát thuyết minh âm thanh   │
└─────────────────────────────────────────────────────────────────────────────┘
### 📋 Chi tiết chức năng từng tầng:

| Tầng kiến trúc | Thành phần công nghệ | Chức năng chính |
| :--- | :--- | :--- |
| **1. Client & Ingestion** | Streamlit, Folium, Session State | Thu nhận toạ độ mô phỏng của du khách, xử lý tìm kiếm theo tên và tương tác trực quan trên bản đồ. |
| **2. Storage & Spatial Index** | PostgreSQL, PostGIS, GiST Index | Lưu trữ các đối tượng không gian thực tế (Point, Polygon, LineString), đánh chỉ mục để truy vấn tức thì. |
| **3. Spatio-Temporal Engine** | `ST_DWithin`, `pgr_dijkstra` | Xử lý logic không gian: phát hiện chuồng thú khi đến gần (50m) và tính đường đi bộ qua 1.192 cạnh đồ thị. |
| **4. Application & Presentation** | Web UI, HTML5 Audio, Dynamic Image | Phản hồi kết quả cho du khách: vẽ đường đi, hiển thị hình ảnh xoay vòng và tự động phát thuyết minh âm thanh. |
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

## 🛠️ 5. HƯỚNG DẪN CÀI ĐẶT VÀ KHỞI CHẠY CỤC BỘ

### Yêu cầu tiên quyết
* Python 3.10+
* Cơ sở dữ liệu PostgreSQL đã kích hoạt extension `postgis` và `pgrouting`.

### Các bước cài đặt
1. **Clone repository**:
   ```bash
   git clone [https://github.com/khanh-code/thao-cam-vien-lbs.git](https://github.com/khanh-code/thao-cam-vien-lbs.git)
   cd thao-cam-vien-lbs
Cài đặt thư viện phụ thuộc:

Bash
pip install -r requirements.txt
Cấu hình thông tin kết nối:
Tạo file .streamlit/secrets.toml với nội dung:

Ini, TOML
[postgres]
dbname = "neondb"
user = "neondb_owner"
password = "YOUR_PASSWORD"
host = "your-host.neon.tech"
port = 5432
Khởi chạy ứng dụng:

Bash
streamlit run app.py