import os
from gtts import gTTS

os.makedirs("audio", exist_ok=True)

data = {
    "thu_an_thit.mp3": "Khu thú ăn thịt. Nơi nuôi dưỡng và bảo tồn các loài động vật săn mồi dũng mãnh như sư tử, hổ trắng Bengal, hổ Đông Dương và các loài báo hoa mai.",
    "chuong_voi.mp3": "Khu chuồng voi. Vị trí sinh sống rộng rãi của các chú voi, nằm gần khu vực gia đình hươu cao cổ sát bờ sông.",
    "linh_truong.mp3": "Khu vực linh trưởng và thú nhỏ. Nơi sinh sống tự nhiên của các loài khỉ, vượn và nhiều loài thú nhỏ hoạt bát.",
    "bo_sat.mp3": "Khu bò sát. Nơi trưng bày các loài trăn, rắn, cá sấu và rùa nhiệt đới quý hiếm.",
    "vuon_lan.mp3": "Vườn lan và xương rồng. Nằm ở phía bên trái sân khấu chính, là điểm chụp ảnh nổi tiếng với không gian xanh mát.",
    "vui_choi.mp3": "Khu vui chơi giải trí. Nơi tập trung các trò chơi cảm giác mạnh và khu vực vận động ngoài trời dành cho thiếu nhi."
}

for filename, text in data.items():
    tts = gTTS(text=text, lang='vi', slow=False)
    tts.save(os.path.join("audio", filename))
    print(f"Đã tạo: {filename}")