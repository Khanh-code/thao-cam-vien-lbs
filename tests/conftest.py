import os
# Kiểm thử chạy trên database thử với dữ liệu mẫu riêng: không tự nạp 52 phân khu đè lên.
os.environ.setdefault('APP_AUTO_DATA_SYNC', '0')
