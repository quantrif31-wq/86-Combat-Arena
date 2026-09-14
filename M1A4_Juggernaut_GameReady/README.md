# TÀI NGUYÊN MÔ HÌNH M1A4 JUGGERNAUT (86: EIGHTY-SIX) CHO BLENDER & GODOT 4

## 1. TỔNG QUAN TÌM KIẾM TRÊN INTERNET
Quá trình quét và tìm kiếm trên tất cả các chợ tài nguyên 3D, diễn đàn và cộng đồng (Sketchfab, Thingiverse, Printables, Cults3D, DeviantArt, BowlRoll, GitHub) cho thấy:
- **Tất cả các mô hình M1A4 Juggernaut chia sẻ công khai trên internet hiện nay đều là MÔ HÌNH TĨNH (Static Mesh - Animation Count = 0)**. Chưa có bất kỳ bản tải miễn phí nào tích hợp sẵn bộ khung xương (Rigging) và các hoạt ảnh hành động (Walk/Run/Attack/Death) phục vụ làm game.
- Các mô hình gốc chất lượng cao nhất đã được định vị và tải về nguyên bản trong thư mục c:\86\raw_downloads\:
  1. **Falapax (Sketchfab)**: Bản dựng chiến đấu hoàn chỉnh với đầy đủ chi tiết pháo 57mm, 4 chân cơ khí và khoang lái.
  2. **leoxx300 (Sketchfab)**: Bản kèm 28 bộ Texture PBR độ phân giải cao (Body, Armor, Gun, Blades, v.v.) theo giấy phép Creative Commons Attribution (CC-BY 4.0).
  3. **Phuriphan3D (Sketchfab)**: Phiên bản Undertaker (Shinei Nouzen).

---

## 2. BẢN XUẤT GLB ĐÃ ĐƯỢC DỰNG XƯƠNG & LÀM HOẠT ẢNH HOÀN CHỈNH (GAME-READY)
Để đáp ứng chính xác yêu cầu **tải bản GLB có đủ các hoạt ảnh hành động làm tài nguyên game cho Blender và Godot 4**, toàn bộ quy trình thiết kế hoạt ảnh và đóng gói đã được thực hiện tự động bằng Blender 5.2:
- **Tệp sản phẩm chính**: models/m1a4_juggernaut_animated.glb (Dung lượng: ~32.5 MB)
- **Tệp nguồn Blender**: models/m1a4_juggernaut_rigged.blend

### Hệ thống khung xương Armature (22 bones cơ khí):
- Root: Trọng tâm tiếp xúc mặt đất (Z = 0.0)
- Chassis: Thân chính, khoang lái, giảm xóc
- Turret: Khớp xoay tháp pháo
- Cannon: Khớp nâng hạ pháo chính 57mm
- Cannon_Recoil: Ống giật thủy lực khi khai hỏa
- Sensor_Optics: Đầu cảm biến quang học quét mục tiêu
- 4 cụm chân nhện độc lập:
  - Trước-Trái (FL): Leg_FL_Hip -> Leg_FL_Thigh -> Leg_FL_Shin -> Leg_FL_Foot
  - Trước-Phải (FR): Leg_FR_Hip -> Leg_FR_Thigh -> Leg_FR_Shin -> Leg_FR_Foot
  - Sau-Trái (RL): Leg_RL_Hip -> Leg_RL_Thigh -> Leg_RL_Shin -> Leg_RL_Foot
  - Sau-Phải (RR): Leg_RR_Hip -> Leg_RR_Thigh -> Leg_RR_Shin -> Leg_RR_Foot

### Danh sách 8 hoạt ảnh hành động (Action Animations):
1. **Idle (Frames 1-60, 2.0s, Loop)**: Đứng canh gác, thân máy nhấp nhô nhịp thở áp suất thủy lực nhẹ, mắt cảm biến xoay quét ngang.
2. **Walk (Frames 1-60, 2.0s, Loop)**: Dáng đi bò 4 chân đặc trưng (bước chéo luân phiên FL+RR rồi đến FR+RL), thân máy lắc lư tự nhiên theo nhịp chân.
3. **Run (Frames 1-40, 1.33s, Loop)**: Dáng phi nước đại tốc độ cao, thân hạ thấp trọng tâm, sải chân mạnh mẽ.
4. **Attack_Fire (Frames 1-45, 1.5s)**: Khóa mục tiêu, giật nòng pháo 45cm lùi mạnh về sau, thân máy ngửa nảy lùi hấp thụ xung lực, piston đẩy nòng về vị trí cũ.
5. **Turn_Left (Frames 1-45, 1.5s, Loop)**: Bước chân xoay tròn tại chỗ rẽ trái.
6. **Turn_Right (Frames 1-45, 1.5s, Loop)**: Bước chân xoay tròn tại chỗ rẽ phải.
7. **Hit_React (Frames 1-30, 1.0s)**: Bị trúng đạn giật nảy người về sau, hệ thống treo gồng chịu lực rồi hồi phục.
8. **Death (Frames 1-60, 2.0s)**: Mất áp suất thủy lực, 4 chân nhện gãy gập choãi ra ngoài, thân xe sập chạm mặt đất, nòng pháo rũ xuống gục ngã.

---

## 3. CẤU TRÚC THƯ MỤC TRONG C:\86
`
c:\86\
│
├── M1A4_Juggernaut_GameReady\          <-- THƯ MỤC TÀI NGUYÊN GAME CHÍNH
│   ├── models\
│   │   ├── m1a4_juggernaut_animated.glb  (GLB chuẩn xuất xưởng, đủ 8 animation)
│   │   └── m1a4_juggernaut_rigged.blend  (File gốc Blender 5.2)
│   ├── textures\
│   │   └── (28 file texture PBR gốc: BaseColor, Normal, Roughness, Metallic)
│   ├── godot_setup\
│   │   └── juggernaut_controller.gd     (Script CharacterBody3D mẫu cho Godot 4)
│   ├── preview_render.png               (Ảnh render thực tế của model)
│   └── README.md                        (Hướng dẫn chi tiết này)
│
└── raw_downloads\                       <-- CÁC BẢN TẢI GỐC TỪ CỘNG ĐỒNG
    ├── m1a4_juggernaut_canon\           (Bản leoxx300 - 28 texture PBR)
    ├── m1a4_juggernaut_variant2\        (Bản Falapax - Mesh chi tiết chiến đấu)
    └── m1a4_undertaker\                 (Bản Shinei Nouzen Undertaker)
`

---

## 4. HƯỚNG DẪN SỬ DỤNG CHO GODOT 4 VÀ BLENDER

### Trong Godot 4:
1. Kéo thả trực tiếp file m1a4_juggernaut_animated.glb vào FileSystem của Godot 4.
2. Chọn file .glb, trong bảng Import:
   - Kiểm tra tab Animation: Sẽ thấy đủ 8 animation (Idle, Walk, Run, Attack_Fire, Turn_Left, Turn_Right, Hit_React, Death).
   - Bấm Reimport.
3. Kéo file vào Scene làm con của một CharacterBody3D, đính kèm script juggernaut_controller.gd để điều khiển bằng phím mũi tên/WASD và chuột trái bắn pháo.

### Trong Blender:
- Mở trực tiếp m1a4_juggernaut_rigged.blend hoặc chọn File -> Import -> glTF 2.0 (.glb) và chọn m1a4_juggernaut_animated.glb.
- Chuyển sang cửa sổ Dope Sheet -> Action Editor hoặc Nonlinear Animation (NLA) để duyệt và chỉnh sửa bất kỳ animation nào.
