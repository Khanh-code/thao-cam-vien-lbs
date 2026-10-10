# Bổ sung trên bản app hiện tại

Giữ bản đồ Esri, dữ liệu database gốc, ảnh, nút trước/sau, audio tiếng Việt và tự phát audio. Chỉ bổ sung pool/cache cho nhiều phiên, Việt/Anh và admin/khách. Không dùng dữ liệu hoặc tọa độ mẫu.

## Triển khai trên app Streamlit đang chạy

Cập nhật mã trong GitHub đang liên kết với app. Giữ nguyên mục [postgres] trong Secrets của app đang hoạt động; không chép thông tin mẫu từ máy local lên Cloud. Python 3.12+ và requirements.txt mới. File .streamlit/secrets.toml chứa thông tin thật không được commit.

Khách sử dụng bản đồ ngay cả khi chưa chạy migration đa ngôn ngữ. Nội dung Anh và sáu MP3 tiếng Anh đi kèm trong english_content.json và audio/en/. Tên phân khu phải khớp tên gốc; phân khu chưa có bản dịch sẽ thông báo và hiện tiếng Việt. Ảnh dùng chung hai ngôn ngữ. MP3 Anh được tổng hợp từ bản dịch của nội dung gốc; cần nghe và kiểm duyệt trước khi sử dụng chính thức.

## Admin và khách

Khách không cần đăng nhập, được tìm kiếm, chọn phân khu, xem ảnh, nghe thuyết minh và tìm đường. Admin đăng nhập ở thanh bên trái để biên tập tên, thuyết minh và đường dẫn audio từng ngôn ngữ. Quyền lưu được kiểm tra tại hàm dịch vụ; phiên admin hết hạn sau một giờ.

Chạy python run_migrations.py (hoặc migrations/001_multilingual.sql) trên database gốc để tạo bảng biên tập. Không chạy import_osm.py để nâng cấp vì script đó nạp lại mạng đường. Có thể chạy 002 để nhập các bản dịch khởi đầu; không ghi đè nội dung admin đã lưu.

Migration 003 tạo bảng admin_users với tài khoản mặc định admin / 123456. Đăng nhập rồi bấm "🔑 Đổi mật khẩu" để đổi; mật khẩu mới được lưu (dạng hash) vào database.

Migration 003 cũng tạo các bảng khách tạm: visitors (tài khoản theo chu kỳ ngày/tuần), visitor_tracks (lưu vết vị trí) và exhibit_visits (phân khu đã được thuyết minh, dùng để ưu tiên khu chưa ghé và thống kê theo ngày).

Audio biên tập có đường dẫn vi/ten-file.mp3 hoặc en/ten-file.mp3 và phải được triển khai vào audio trước khi lưu. Audio Việt gốc vẫn được giữ khi admin chỉ sửa văn bản. Khi sửa nội dung Anh cần cập nhật audio cho khớp, không phát bản ghi cũ cho văn bản mới.

## Nhiều người cùng lúc

Mỗi trình duyệt có tọa độ, ngôn ngữ, ảnh, điểm đến và quyền riêng trong session_state. Pool PostgreSQL thread-safe giới hạn mặc định 10 kết nối dùng luân phiên giữa các yêu cầu; cache có TTL và giới hạn mục cho các truy vấn theo vị trí. Kết nối được trả về khi thành công hoặc lỗi. Pool 10 không phải giới hạn 10 khách.

Khả năng chịu tải thực tế phụ thuộc CPU, RAM và database. Chưa đo tải trên Cloud, không cam kết số người đồng thời. Tổng pool của các replica phải nằm trong giới hạn DB; nhiều replica cần sticky sessions. Triển khai public cần HTTPS và rate limit hoặc SSO cho admin, vì giới hạn thử đăng nhập hiện tại theo session.

## Chạy trên máy này

Mở thư mục dự án trong VS Code, vào Terminal → Run Task… và chạy lần lượt: 1. Cài đặt môi trường, 2. Chạy migration database, 3. Chạy app. Hoặc chạy START_APP.ps1. Thông tin kết nối thật nằm trong .streamlit/secrets.toml (không commit).

Kiểm tra: python -m pytest tests -q. Các test dùng database giả; có kiểm tra giữ ảnh/audio Việt–Anh, tách session, phân quyền và pool nhiều thread. Cần kiểm tra database thật và tải triển khai trước khi đưa vào sử dụng.
