import json
import psycopg2


# 1. Điền thông tin kết nối Neon của bạn
DB_CONFIG = {
    "dbname": "neondb",
    "user": "neondb_owner",
    "password": "npg_rIDqWC4QXUd8",
    "host": "ep-fancy-dust-b3d0chpg-pooler.c-4.ap-southeast-1.aws.neon.tech",
    "port": "5432",
    "sslmode": "require"
}

# 2. Đọc file GeoJSON tải từ overpass-turbo
with open("export.geojson", "r", encoding="utf-8") as f:
    data = json.load(f)

conn = psycopg2.connect(**DB_CONFIG)
cur = conn.cursor()

# Tạo lại bảng walkways
cur.execute("""
    DROP TABLE IF EXISTS walkways_vertices_pgr CASCADE;
    TRUNCATE TABLE walkways RESTART IDENTITY CASCADE;
""")

print("Đang nạp các đoạn đường từ OpenStreetMap...")

insert_query = """
    INSERT INTO walkways (name, geom, cost, reverse_cost)
    VALUES (%s, ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326), 
            ST_Length(ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326)::geography),
            ST_Length(ST_SetSRID(ST_GeomFromGeoJSON(%s), 4326)::geography));
"""

count = 0
for feature in data.get('features', []):
    geom = feature.get('geometry')
    if not geom or geom.get('type') != 'LineString':
        continue
    
    props = feature.get('properties', {})
    name = props.get('name') or props.get('highway') or 'Lối đi bộ nội khu'
    
    coords = geom.get('coordinates', [])
    # Tách các đường cong phức tạp thành từng cặp đỉnh liền kề để làm cạnh đồ thị
    for i in range(len(coords) - 1):
        segment = {
            "type": "LineString",
            "coordinates": [coords[i], coords[i+1]]
        }
        seg_json = json.dumps(segment)
        cur.execute(insert_query, (name, seg_json, seg_json, seg_json))
        count += 1

conn.commit()
print(f"Đã nạp thành công {count} đoạn đường vào bảng walkways!")