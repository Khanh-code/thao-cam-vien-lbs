"""Chạy các file SQL trong thư mục migrations/ theo thứ tự tên (001, 002, ...).

Dùng cùng cấu hình kết nối với app (.streamlit/secrets.toml hoặc biến môi trường),
nên không cần cài psql. Các migration đều viết dạng IF NOT EXISTS / ON CONFLICT DO NOTHING
nên chạy lại nhiều lần vẫn an toàn và KHÔNG đụng tới bảng walkways.
"""
from pathlib import Path
import psycopg2
from config import DB_CONFIG

def main():
    files = sorted((Path(__file__).resolve().parent / "migrations").glob("*.sql"))
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = True  # mỗi file tự có BEGIN/COMMIT
    try:
        with conn.cursor() as cur:
            for f in files:
                print(f"-> {f.name}")
                cur.execute(f.read_text(encoding="utf-8"))
        print("Hoàn tất migration.")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
