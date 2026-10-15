import os
# Kiểm thử chạy trên database thử với dữ liệu mẫu riêng: không tự nạp 52 phân khu đè lên.
os.environ.setdefault('APP_AUTO_DATA_SYNC', '0')
# Dữ liệu mẫu của test có 2 khu cách nhau ~65 m (bài toán "cách đều 2 khu") nên dùng bán kính 50 m;
# app thật dùng 10 m (tracking.NARRATION_RADIUS_M) cho sơ đồ 52 khu sát nhau.
os.environ.setdefault('VISITOR_NARRATION_RADIUS', '50')
