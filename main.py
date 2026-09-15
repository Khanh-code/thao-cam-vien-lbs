from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI(title="Museum LBS API", version="1.0")

# Cho phép Frontend gọi API từ bất kỳ nguồn nào (tránh lỗi CORS khi test)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cấu hình kết nối cơ sở dữ liệu PostgreSQL của bạn
DB_CONFIG = {
    "dbname": "postgis_36_sample",
    "user": "postgres",
    "password": "YOUR_PASSWORD",  # <-- THAY MẬT KHẨU CỦA BẠN VÀO ĐÂY
    "host": "localhost",
    "port": "5432"
}

def get_db_connection():
    """Hàm hỗ trợ kết nối database và trả về dữ liệu dạng dictionary"""
    conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
    return conn

@app.get("/")
def home():
    return {"message": "Museum LBS Backend is running!"}

@app.get("/api/nearby")
def get_nearby_exhibits(lat: float, lng: float, radius: float = 50.0):
    """
    API nhận tọa độ (lat, lng) của người dùng và bán kính (mét),
    trả về danh sách hiện vật lân cận nhờ truy vấn không gian PostGIS.
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Câu lệnh truy vấn không gian cốt lõi cho môn Truy vấn dữ liệu:
        # 1. ST_MakePoint(lng, lat): Tạo đối tượng hình học từ tọa độ GPS. (Lưu ý: Kinh độ đứng trước, Vĩ độ đứng sau)
        # 2. ST_DWithin: Lọc nhanh các điểm nằm trong bán kính (tận dụng chỉ mục GIST / R-Tree).
        # 3. ST_Distance: Tính khoảng cách chính xác theo mét (kiểu geography).
        query = """
            SELECT 
                id, 
                name, 
                description, 
                audio_file,
                ST_Distance(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography) AS distance_meters
            FROM exhibits
            WHERE ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography, %s)
            ORDER BY distance_meters ASC;
        """
        
        # Truyền tham số: Lng, Lat được lặp lại cho cả điều kiện khoảng cách và điều kiện bán kính
        cur.execute(query, (lng, lat, lng, lat, radius))
        results = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return {
            "status": "success",
            "user_location": {"lat": lat, "lng": lng},
            "radius_meters": radius,
            "count": len(results),
            "data": results
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))