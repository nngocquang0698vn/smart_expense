# User Flow

## Onboarding

1. User mở app lần đầu.
2. Xem các trang giới thiệu.
3. Nhập tên hoặc bỏ qua tới trang nhập tên.
4. App lưu `userName` và `onboarded`.
5. Vào `MainShell`.

## Main shell

App có 4 tab:

- Trang chủ.
- Đối soát.
- Báo cáo.
- Cá nhân.

Tab được giữ state bằng `IndexedStack`.

## Tạo giao dịch

1. User bấm FAB.
2. Chọn nhập tay, ghi âm hoặc ảnh hoá đơn.
3. Nhập số tiền, danh mục, ngày, ghi chú, audio hoặc ảnh nếu có.
4. Chọn trạng thái chờ đối soát khi muốn xử lý sau.
5. Lưu.

Voice/receipt quick mode có thể khởi tạo transaction ở trạng thái pending để người dùng hoàn thiện sau. Tuy nhiên attachment không tự làm transaction pending; cờ `pending` vẫn là source of truth.

## Sửa và xoá giao dịch

- Từ history/report/pending, user mở editor.
- Editor dùng form chung với quick entry.
- Save update transaction qua repository.
- Delete hỏi xác nhận trước khi xoá.
- Nếu form dirty khi đóng/chuyển item, app hỏi xác nhận bỏ thay đổi.

## Đối soát giao dịch

Mục tiêu: xử lý transaction đang `pending == true`.

Desktop:

1. Vào tab Đối soát.
2. Chọn filter thời gian hoặc attachment nếu cần.
3. Chọn transaction bên trái.
4. Xem/sửa chi tiết bên phải.
5. Bấm Lưu giao dịch, Xoá, hoặc Xác nhận nhanh khi đủ thông tin.
6. Dùng Trước/Sau để chuyển item.

Mobile:

1. Vào list pending.
2. Tap transaction để mở detail full-width.
3. Back về list.

Empty state:

```text
Xong rồi! Các giao dịch cần đối soát đã được xử lý.
```

## Reminder notification

Trong Profile, user bật **Nhắc đối soát giao dịch**:

- Nếu chưa có quyền notification, app request khi user bật.
- Nếu mode Cuối ngày, app check theo giờ đã chọn.
- Nếu mode Theo khoảng thời gian, app check ở các mốc trong khung giờ đã chọn.
- App chỉ gửi khi còn pending transaction tại thời điểm notification sắp gửi.

Khi tap notification:

- App chuyển sang tab Đối soát nếu platform/browser hỗ trợ.
- App hiện thông báo nhỏ rằng đã chuyển tới màn hình đối soát.

## Profile

Profile có:

- Tên người dùng.
- Giao diện.
- Nhắc đối soát giao dịch.
- Danh mục.
- Entry Đối soát.
- Xác nhận nhanh.
- Thêm giao dịch nhanh.
- Cài PWA trên Web.
- Demo đối soát.
- Dữ liệu mẫu.
- Tính năng thử nghiệm: AI nhận diện giọng nói, cấu hình endpoint/token, đánh thức API demo.

## AI Voice Transaction Demo

1. User vào Profile > Tính năng thử nghiệm.
2. Bật `AI nhận diện giọng nói`.
3. Nhập endpoint Render và demo token nếu backend yêu cầu.
4. Trước khi demo, bấm `Đánh thức API demo` để gọi `/health`.
5. Khi quick voice entry dừng ghi âm, app tự upload audio và autofill form.
6. Khi form đang có audio, nút `AI đọc ghi âm` nằm bên phải hàng `Chờ đối soát` để user gọi lại AI thủ công.
7. Trong pending review, editor dùng cùng vị trí nút AI cạnh `Chờ đối soát`; Save/Delete vẫn nằm ở action bar dưới form.
8. User luôn review trước khi lưu hoặc confirm; app không auto-save/auto-confirm.

Nếu API lỗi, app hiển thị thông báo thân thiện và giữ nguyên audio, note, dữ liệu user đã nhập.

## Demo đối soát

Section **Demo đối soát**:

- Tạo giao dịch demo cần đối soát.
- Gửi thông báo sau 20 giây.
- Xoá tất cả dữ liệu.

Nếu chưa có transaction pending, action gửi notification demo sẽ nhắc user tạo dữ liệu demo trước. Nếu pending được xử lý hết trước khi hết 20 giây, demo notification sẽ không gửi nữa.

## Dữ liệu mẫu

Section **Dữ liệu mẫu** nạp bộ dữ liệu Johny:

- Xoá transaction hiện tại.
- Set tên người dùng Johny.
- Tạo nhiều transaction thu/chi để demo dashboard/report/pending.

## Báo cáo

1. Vào tab Báo cáo.
2. Chọn kỳ: tuần, tháng, quý, năm, tuỳ chọn.
3. Chọn Chi tiêu hoặc Thu nhập.
4. Xem pie chart và breakdown category.
5. Chọn category để xem detail.

Report chỉ tính transaction `pending == false`.

## Attachment

- Ảnh: chụp/chọn ảnh, giới hạn tối đa 5 ảnh.
- Audio: ghi âm và phát lại sau user gesture.
- Nếu audio/image lỗi hoặc thiếu file, UI fallback thay vì crash.
