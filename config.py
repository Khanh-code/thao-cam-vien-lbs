import os
import streamlit as st

def setting(section, key, default=None):
    env = os.getenv(f"{section}_{key}".upper())
    if env is not None:
        return env
    try:
        return st.secrets.get(section, {}).get(key, default)
    except Exception:
        # Chưa có .streamlit/secrets.toml -> dùng giá trị mặc định
        return default

DB_CONFIG = {
    "dbname": setting("postgres", "dbname", "postgis_36_sample"),
    "user": setting("postgres", "user", "postgres"),
    "password": setting("postgres", "password", ""),
    "host": setting("postgres", "host", "localhost"),
    "port": setting("postgres", "port", "5432"),
    # "prefer": dùng SSL nếu server hỗ trợ (Neon), vẫn chạy được với PostgreSQL local không bật SSL
    "sslmode": setting("postgres", "sslmode", "prefer"),
    "connect_timeout": 10,
    # KHÔNG dùng "options" ở đây: Neon pooler (PgBouncer) từ chối tham số khởi động này.
    # Giới hạn thời gian truy vấn được đặt bằng SET LOCAL trong db_services.database_cursor().
}
POOL_SIZE = int(setting("postgres", "pool_size", 10))
if not 1 <= POOL_SIZE <= 100:
    raise ValueError("postgres.pool_size must be between 1 and 100")
# Bảng màu đại diện cho từng phân khu
COLOR_PALETTE = {
    'Khu Thú Ăn Thịt': '#e74c3c',
    'Khu Chuồng Voi': '#8e44ad',
    'Khu Vực Linh Trưởng & Thú Nhỏ': '#e67e22',
    'Khu Bò Sát': '#27ae60',
    'Vườn Lan & Xương Rồng': '#2ecc71',
    'Khu Vui Chơi Giải Trí (Đu Quay)': '#3498db',
    'Khu Vui Chơi Giải Trí': '#3498db'
}

# Danh sách hình ảnh minh họa cho các phân khu
EXHIBIT_IMAGES = {
    1: ["1.jpg", "9.jpg", "10.jpg"],
    2: ["2.jpg", "11.jpg"],
    3: ["3.jpg", "4.jpg", "5.jpg"],
    4: ["6.jpg", "7.jpg", "8.jpg"],
    5: ["12.jpg", "13.jpg"],
    6: ["14.jpg", "15.jpg", "16.jpg", "17.jpg"]
}