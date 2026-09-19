import streamlit as st

# Cấu hình kết nối cơ sở dữ liệu PostgreSQL / Neon
if "postgres" in st.secrets:
    DB_CONFIG = {
        "dbname": st.secrets["postgres"]["dbname"],
        "user": st.secrets["postgres"]["user"],
        "password": st.secrets["postgres"]["password"],
        "host": st.secrets["postgres"]["host"],
        "port": str(st.secrets["postgres"]["port"]),
        "sslmode": "require"
    }
else:
    DB_CONFIG = {
        "dbname": "postgis_36_sample",
        "user": "postgres",
        "password": "YOUR_LOCAL_PASSWORD",
        "host": "localhost",
        "port": "5432"
    }

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