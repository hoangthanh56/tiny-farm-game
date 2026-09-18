# Kiểm thử và phát hành

## Kiểm thử tự động

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_farm.gd
```

Nếu chương trình Godot chưa có trong PATH, thay `godot` bằng đường dẫn tới executable. Trong PowerShell, dùng `& "C:\duong-dan\Godot_v4.5.1-stable_win64_console.exe"` trước các tham số.

Bộ test dùng các tệp `user://tiny_farm_automated_test.json` và `user://tiny_farm_ui_test.json`, dọn chúng sau khi chạy; không ghi vào slot `farm_save.json` của người chơi.

## Chơi thử thủ công trước bản phát hành

- [ ] Bắt đầu game mới từ menu, di chuyển bằng WASD và mũi tên.
- [ ] Camera đi theo nhân vật; không xuyên nhà, cửa hàng, thân cây hoặc ao.
- [ ] Không thao tác được ô đất ở xa; ô được chọn có viền rõ ràng.
- [ ] Cuốc, gieo, tưới, ngủ hai lần có tưới giữa hai đêm và thu hoạch cà rốt.
- [ ] Cây không được tưới không lớn; cây chín không biến mất khi sang ngày.
- [ ] Bán nông sản tại cửa hàng; tiền và túi đồ cập nhật đúng.
- [ ] Thử mua khi hết tiền, gieo khi hết hạt, gieo đè cây và thu hoạch quá sớm.
- [ ] Lưu, thoát hoàn toàn, mở lại và tải đúng ngày, vị trí, cây, tiền, túi đồ.
- [ ] F5 lưu, F9 tải; file hỏng phải báo lỗi và giữ trạng thái hiện tại.
- [ ] Esc mở/đóng menu; túi đồ/cửa hàng chặn di chuyển; hủy ngủ không đổi ngày.
- [ ] Kiểm tra bật/tắt âm thanh, animation đi bộ, thao tác và cây đung đưa.
- [ ] Chơi ít nhất 10 ngày, ghi nhận lợi nhuận và số thao tác; điều chỉnh `CROPS` nếu cần.
- [ ] Kiểm tra chữ tiếng Việt và bố cục ở 1152×720, 1280×720 và 1920×1080.

## Xuất bản Windows

1. Trong Godot, mở **Editor → Manage Export Templates**, cài template trùng phiên bản editor.
2. Mở **Project → Export**, chọn preset **Windows Desktop** có sẵn.
3. Tạo thư mục `builds/windows/` nếu chưa có.
4. Chọn **Export Project**, bỏ chọn **Export With Debug**, lưu `builds/windows/TinyFarm.exe`.
5. Chạy bản `.exe` trên máy Windows khác, thực hiện lại vòng trồng trọt và lưu/tải. Máy chơi không cần cài Godot.
6. Đính kèm hướng dẫn phím, số phiên bản, ghi chú thay đổi và giấy phép tài nguyên trong gói ZIP.
7. Chỉ tạo tag `v0.1.0` và GitHub Release sau khi checklist đạt và nhóm thống nhất phát hành.

Có thể xuất qua dòng lệnh sau khi cài template:

```sh
godot --headless --path . --export-release "Windows Desktop" builds/windows/TinyFarm.exe
```

Preset có sẵn không đồng nghĩa với bản phát hành đã được tạo. Hiện chưa có executable được xuất hoặc GitHub Release được đăng.

## Phạm vi hiện tại

- Game một người chơi, một slot lưu và một bản sao `.bak` của lần lưu trước.
- Cây lớn bằng thao tác ngủ; thời gian ngoài đời không làm đổi ngày.
- Đồ họa được vẽ bằng primitive Godot, chưa phải bộ sprite pixel art hoàn chỉnh.
- Có âm thanh hiệu ứng tổng hợp; chưa có nhạc nền, chăn nuôi, nhiệm vụ hoặc multiplayer.
- Cấu hình xuất hiện tại dành cho Windows x86_64; nền tảng khác cần thêm preset và kiểm thử.
