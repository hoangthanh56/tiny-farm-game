# Quy tắc làm việc nhóm

## Công cụ chung

- Dùng Godot **4.5.1 Standard** làm phiên bản thống nhất ban đầu. Khi nâng cấp, cả nhóm thống nhất phiên bản và kiểm tra lại dự án.
- Viết bằng GDScript, dùng tab để thụt dòng, `snake_case` cho hàm/biến/tệp, `PascalCase` cho tên lớp.
- Không đưa `.godot/`, bản build, dữ liệu lưu cá nhân, mật khẩu hoặc token vào Git. Giữ các tệp `.gd.uid` và `.svg.import` để Godot duy trì tham chiếu tài nguyên.
- Đồ họa/âm thanh bên ngoài phải có nguồn và giấy phép trong `assets/CREDITS.md` trước khi sử dụng.

## Quy trình một công việc

1. Tạo issue nêu mục tiêu, người phụ trách và điều kiện hoàn thành. Gắn với một trong 8 giai đoạn ở README.
2. Cập nhật `main` rồi tạo nhánh `feat/ten-tinh-nang`, `fix/ten-loi` hoặc `docs/ten-tai-lieu`.
3. Làm một việc có phạm vi rõ ràng. Thông báo trước khi cùng sửa scene hoặc script với người khác.
4. Chạy game bằng F6/F5 và kiểm thử logic trước khi gửi pull request.
5. PR ghi hành vi thay đổi, cách kiểm tra, ảnh chụp nếu sửa giao diện và lỗi còn biết.
6. Có ít nhất một thành viên khác review trước khi merge vào `main`. Với dự án cá nhân, tự đọc diff và chạy checklist thay cho review chéo.
7. Không force-push vào `main`. Giải quyết xung đột `.tscn` cùng người phụ trách scene, sau đó mở lại bằng Godot để kiểm tra.

## Phân chia trách nhiệm gợi ý

| Mảng | Tệp chính | Trách nhiệm |
| --- | --- | --- |
| Luật chơi và dữ liệu | `scripts/farm_state.gd` | Trồng trọt, kinh tế, đổi ngày, lưu/tải |
| Nhân vật và bản đồ | `scripts/player.gd`, `scripts/world.gd` | Di chuyển, camera, va chạm, tương tác |
| Giao diện và âm thanh | `scripts/main.gd`, `scripts/sound.gd` | Menu, túi đồ, cửa hàng, phản hồi |
| Kiểm thử và phát hành | `tests/`, `docs/`, `export_presets.cfg` | Test, ghi lỗi, cân bằng và đóng gói |

Đây là phân công mã nguồn cho game một người chơi; chưa có chế độ multiplayer.

## Điều kiện hoàn thành

- Tính năng chơi được từ menu chính và không tạo lỗi trong Debugger.
- Không làm mất tiến trình hoặc làm tiền/túi đồ âm.
- Thêm kiểm thử nếu thay đổi luật chơi, lưu game hoặc xử lý lỗi.
- Cập nhật README khi đổi thao tác, giá bán hoặc cách chạy.
- Chạy `godot --headless --path . --script res://tests/test_farm.gd` thành công.

## Tham gia repository GitHub

Repository: [hoangthanh56/tiny-farm-game](https://github.com/hoangthanh56/tiny-farm-game). Thư mục được chuẩn bị sẵn `.gitignore` và `.gitattributes`.

1. Chủ repo mời các thành viên qua mục Collaborators.
2. Clone mã nguồn:

   ```sh
   git clone https://github.com/hoangthanh56/tiny-farm-game.git
   cd tiny-farm-game
   ```

3. Import `project.godot`, chạy game rồi nhận issue.

Vòng làm việc tiếp theo:

```sh
git switch main
git pull --ff-only
git switch -c feat/ten-tinh-nang
```
