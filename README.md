# 🌱 Tiny Farm — Nông trại nhỏ với Godot

Game nông trại 2D một người chơi, xây dựng bằng **Godot 4.5 + GDScript**. Bạn điều khiển nhân vật đi quanh nông trại, cuốc đất, gieo hạt, tưới cây, ngủ qua ngày rồi thu hoạch và bán nông sản.

**Hiện trạng:** Đã có prototype chạy trong Godot với các chức năng chính của giai đoạn 2–6, hình ảnh/animation và hiệu ứng âm thanh cơ bản. Repository: [hoangthanh56/tiny-farm-game](https://github.com/hoangthanh56/tiny-farm-game). Chưa có bản phát hành `.exe`; giai đoạn 7–8 cần tiếp tục hoàn thiện hình ảnh, chơi thử và cân bằng.

## Mở và chơi

Clone mã nguồn bằng GitHub CLI hoặc Git:

```sh
gh repo clone hoangthanh56/tiny-farm-game
# Hoặc:
git clone https://github.com/hoangthanh56/tiny-farm-game.git
```

1. Cài **Godot 4.5.1 Standard** hoặc bản 4.x mới hơn tương thích; không cần bản .NET.
2. Mở Godot Project Manager → **Import** → chọn `project.godot` trong thư mục này.
3. Mở dự án, chờ import tài nguyên rồi nhấn **F5** để chạy.
4. Trong menu, chọn **Bắt đầu nông trại mới**, hoặc **Tải game đã lưu** nếu đã chơi trước đó.

Không cần Node.js, trình duyệt, plugin hay tải thêm bộ asset. Bản thử nghiệm web cũ nằm trong [`legacy-web/`](legacy-web/README.md) để tham khảo; bản lưu của hai phiên bản độc lập.

## Lộ trình 8 giai đoạn

| Giai đoạn | Nội dung | Kết quả và hiện trạng |
| --- | --- | --- |
| 1 | Học Godot, tạo GitHub và quy tắc làm việc nhóm | Có project, repository GitHub, cấu trúc mã, `.gitignore` và [quy tắc nhóm](CONTRIBUTING.md). Thành viên cần học scene/node/signal và được mời vào repo. |
| 2 | Nhân vật di chuyển, camera và bản đồ | Đã có WASD/mũi tên, camera theo nhân vật, giới hạn bản đồ và va chạm với nhà, tiệm, cây, ao. |
| 3 | Cuốc đất, gieo hạt và tưới nước | Đã có 40 ô ruộng, 4 công cụ, chọn hạt và giới hạn khoảng cách tương tác. |
| 4 | Cây phát triển, thu hoạch và đổi ngày | Đã có tăng trưởng theo ngày được tưới, ngủ tại nhà, cây chín và thu hoạch. |
| 5 | Túi đồ, cửa hàng, mua bán và tiền | Đã có hạt giống/nông sản, cửa hàng theo vị trí, mua hạt, bán nông sản và kiểm tra số xu. |
| 6 | Lưu game, tải game và menu | Đã có menu đầu game/tạm dừng, lưu tự động, lưu/tải thủ công, kiểm tra dữ liệu và bản sao lưu. |
| 7 | Thêm hình ảnh, âm thanh, animation | Đã có hình vẽ 2D, bước chân, thao tác công cụ, cây đung đưa và hiệu ứng âm thanh; còn thay sprite và bổ sung nhạc nền. |
| 8 | Chơi thử, sửa lỗi, cân bằng và tạo bản phát hành | Có kiểm thử tự động, preset Windows và [checklist phát hành](docs/RELEASE_CHECKLIST.md). Chưa xuất hoặc đăng bản phát hành. |

Mỗi giai đoạn có thể là một tuần hoặc một sprint tùy lịch của nhóm. Hoàn thành tiêu chí chơi được và review trước khi chuyển giai đoạn.

## Điều khiển

| Phím / thao tác | Chức năng |
| --- | --- |
| WASD hoặc mũi tên | Di chuyển nhân vật |
| 1 / 2 / 3 / 4 | Chọn cuốc / gieo hạt / tưới nước / thu hoạch |
| Q hoặc nút tên hạt ở thanh dưới | Chuyển loại hạt giống, đồng thời chọn gieo hạt |
| E hoặc Space | Dùng công cụ lên ô phía trước; mở cửa hàng hoặc ngủ khi đứng gần cửa tương ứng |
| Chuột trái vào ô ruộng | Dùng công cụ lên ô được bấm nếu ở gần nhân vật |
| I | Mở/đóng túi đồ |
| B | Mở/đóng cửa hàng khi đứng gần cửa tiệm |
| N | Hỏi xác nhận ngủ khi đứng gần cửa nhà |
| Esc | Mở menu hoặc đóng bảng đang xem |
| F5 / F9 trong cửa sổ game | Lưu / tải slot hiện tại |

Lưu ý: F5 ở **editor Godot** chạy dự án; F5 khi **cửa sổ game có focus** lưu tiến trình.

## Vụ mùa đầu tiên

Bạn có **80 xu, 6 hạt cà rốt và 3 hạt lúa mì**. Ruộng ở giữa bản đồ, nhà ở phía tây bắc và tiệm hạt giống ở phía đông bắc.

1. Đi tới ruộng, chọn **1 · Cuốc đất**, bấm một ô gần nhân vật.
2. Chọn **2 · Gieo hạt** để gieo cà rốt. Dùng **Q** nếu muốn đổi giống.
3. Chọn **3 · Tưới nước** và bấm ô đã gieo.
4. Về cửa nhà, nhấn **E**, xác nhận ngủ để sang ngày 2.
5. Tưới lại cà rốt rồi ngủ thêm một đêm. Ngày 3, cây đã chín.
6. Chọn **4 · Thu hoạch**, thu cây vào túi.
7. Đi tới tiệm, nhấn **E**, chọn bán nông sản và mua hạt cho vụ tiếp theo.

**Cây chỉ lớn sau một đêm đã được tưới.** Quên tưới sẽ làm cây ngừng lớn trong ngày đó, không làm chết cây. Mỗi sáng đất khô trở lại. Cây chín có thể chờ thu hoạch; sau thu hoạch, ô đất vẫn được cuốc sẵn.

| Cây | Số đêm được tưới để chín | Giá hạt | Giá bán | Lãi mỗi cây |
| --- | --- | --- | --- | --- |
| Cà rốt | 2 | 5 xu | 14 xu | 9 xu |
| Lúa mì | 3 | 8 xu | 24 xu | 16 xu |
| Cà chua | 4 | 14 xu | 44 xu | 30 xu |
| Bí ngô | 5 | 22 xu | 72 xu | 50 xu |

Đây là giá cân bằng ban đầu; nhóm có thể chỉnh trong `CROPS` ở `scripts/farm_state.gd` sau khi chơi thử. Không có năng lượng, cây chết hay giới hạn thời gian trong prototype.

## Lưu và tải

- Tự lưu sau thao tác làm vườn thành công, mua bán, ngủ, bắt đầu mới, khi thoát và mỗi 20 giây đang chơi.
- Lưu thủ công bằng F5 hoặc menu; tải bằng F9 hoặc **Tải game đã lưu**.
- Dữ liệu: ngày, tiền, hạt giống, nông sản, trạng thái từng ô ruộng, số cây đã thu hoạch và vị trí nhân vật.
- Slot: `user://farm_save.json`. Godot quản lý thư mục `user://`; trên Windows bản cài thông thường là `%APPDATA%/Godot/app_userdata/Tiny Farm/`.
- File `.bak` giữ lần lưu trước. Nếu slot chính hỏng, thoát game rồi sao chép `.bak` thành `farm_save.json` để phục hồi thủ công.
- Tải file không hợp lệ sẽ báo lỗi và giữ trạng thái đang chơi. Bắt đầu mới yêu cầu xác nhận nếu đã có tiến trình.
- Đóng game không làm trôi ngày; cây lớn theo thao tác ngủ, không theo thời gian thực.

## Cấu trúc dự án

```text
project.godot              Cấu hình và điểm mở dự án
scenes/main.tscn           Scene chính
scripts/
  main.gd                 Giao diện, input và kết nối các hệ thống
  player.gd               Nhân vật, camera, va chạm và animation
  world.gd                Bản đồ, ô ruộng và hình ảnh cây trồng
  farm_state.gd           Luật trồng trọt, kinh tế và dữ liệu lưu
  sound.gd                Hiệu ứng âm thanh tổng hợp
assets/                   Icon và ghi nhận tài nguyên
tests/test_farm.gd         Kiểm thử luật chơi và tích hợp màn chơi
docs/RELEASE_CHECKLIST.md  Checklist chơi thử và phát hành
export_presets.cfg        Preset xuất Windows x86_64
CONTRIBUTING.md            GitHub, nhánh, review và phân chia công việc
legacy-web/               Bản thử nghiệm web trước đây
```

Scene chính hiện dựng các node con và UI bằng GDScript. Khi nhóm mở rộng dự án, có thể tách nhân vật, cửa hàng, menu và ô ruộng thành scene riêng để chỉnh trực quan trong editor.

## Kiểm thử và tạo bản phát hành

Nếu executable Godot có tên `godot` và nằm trong PATH:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_farm.gd
```

Bộ kiểm thử bao gồm vòng trồng trọt cho cả 4 giống, cây thiếu nước, chống trồng đè/thu hoạch lặp, mua bán, dữ liệu lưu hỏng, sao lưu, di chuyển, tương tác từ xa và mở/đóng menu. Xem [checklist](docs/RELEASE_CHECKLIST.md) để chơi thử thủ công và xuất `TinyFarm.exe` bằng preset **Windows Desktop**.

## Tài liệu học

- [Godot: game 2D đầu tiên](https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html)
- [Di chuyển 2D với CharacterBody2D](https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html)
- [Đọc và ghi tệp với FileAccess](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html)
- [Xuất dự án và cài export templates](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)

## Giấy phép

Chưa chọn giấy phép cho dự án. Nguồn hình ảnh và âm thanh hiện có được ghi trong [`assets/CREDITS.md`](assets/CREDITS.md); cần thống nhất giấy phép trước khi phát hành công khai.
