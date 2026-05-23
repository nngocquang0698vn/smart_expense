# User Flow

## Mục lục
- [Tạo/sửa/xoá transaction](#tạosửaxoá-transaction)
- [Xem danh sách transaction](#xem-danh-sách-transaction)
- [Lọc transaction](#lọc-transaction)
- [Báo cáo](#báo-cáo)
- [Đối soát](#đối-soát)
- [Attachment](#attachment)
- [PWA/mobile](#pwamobile)

## Tạo/sửa/xoá transaction
- Mục tiêu: ghi nhận giao dịch thu/chi.
- Actor: người dùng cá nhân.
- Precondition: app đã onboarding, có category mặc định.
- Main steps:
  1. Bấm FAB hoặc mục thêm nhanh.
  2. Chọn nhập nhanh, ghi âm, hoặc hoá đơn.
  3. Nhập tiêu đề, loại thu/chi, số tiền, category, ngày, note/audio/images.
  4. Chọn `Chờ đối soát` nếu muốn xử lý sau.
  5. Lưu.
- Expected result: transaction được lưu vào Sembast; dashboard/pending/report reload qua `repo.changes`.
- Edge cases: thiếu amount/category với giao dịch không pending sẽ báo lỗi; nếu đang đóng sheet có dữ liệu dirty thì hiện dialog xác nhận bỏ thay đổi.

Xoá transaction có trong editor khi sửa giao dịch non-embedded; embedded pending dùng footer action `PendingEditorActionBar`.

## Xem danh sách transaction
- Dashboard hiển thị pending preview và history.
- Desktop dashboard chia pending/history thành hai cột.
- Mobile dashboard dùng `CustomScrollView` và sliver.
- History phân trang với `AppPageSizes.historyPage = 20`.

## Lọc transaction
- Dashboard và Pending dùng `DateFilterSelection` qua `showDateFilterSheet`.
- Pending có thêm filter attachment: tất cả, có ảnh, có ghi âm, có ảnh/ghi âm, không có tệp.
- Expected result: controller reload hoặc lọc lại danh sách hiện có, selection pending được reconcile về transaction còn hợp lệ.

## Báo cáo
- Mục tiêu: xem tổng thu, tổng chi, chênh lệch và breakdown theo category.
- Actor: người dùng.
- Precondition: có giao dịch confirmed trong kỳ.
- Main steps:
  1. Vào tab Báo cáo.
  2. Chọn kỳ: tuần/tháng/quý/năm/tuỳ chọn.
  3. Chọn Chi tiêu hoặc Thu nhập.
  4. Xem pie chart và danh sách category.
  5. Chọn category để xem detail.
- Desktop: master-detail, detail nằm bên phải.
- Mobile: detail thay nội dung màn hình và back sẽ quay về report master.
- Expected result: detail list lấy qua `categoryReportDetailProvider`.
- Edge cases: không có slice thì hiển thị empty state; category không tìm thấy bị bỏ khỏi report slices.

## Đối soát
- Mục tiêu: xử lý giao dịch `pending == true`.
- Actor: người dùng.
- Precondition: có pending transaction.
- Main steps desktop:
  1. Vào tab Đối soát.
  2. Chọn date/filter attachment nếu cần.
  3. Chọn transaction ở left panel.
  4. Edit ở right panel.
  5. Bấm Lưu/Xoá hoặc dùng Xác nhận nhanh nếu transaction đủ thông tin.
  6. Dùng `Trước`/`Sau` để chuyển transaction.
- Main steps mobile:
  1. Vào list pending.
  2. Tap transaction để mở edit full-width.
  3. Back để về list.
- Expected result: save/update phát `repo.changes`; pending controller reload và giữ/reconcile selected transaction.
- Edge cases: nếu form dirty khi chuyển transaction/back thì hỏi bỏ thay đổi; filter không có kết quả hiển thị empty.
- Skip: **Chưa xác định từ codebase**. Không thấy action skip riêng; hiện chỉ có `Trước` và `Sau`.

## Attachment
### Ghi chú
- Note nhập trong `TransactionNoteInput`, controller được truyền từ form parent.
- Expected result: note lưu vào `LedgerTransaction.note`.

### Ảnh
- Người dùng chụp/chọn ảnh từ `TransactionImageAttachments`.
- Gallery hỗ trợ chọn nhiều ảnh, nhưng giới hạn còn lại được enforce trước khi render.
- Tối đa 5 ảnh/transaction.
- Thumbnail đọc bytes lazy theo tile; preview full ảnh chỉ mở khi user tap thumbnail.
- Edge cases: ảnh thiếu/hỏng hiển thị lỗi ảnh.

### Audio
- Người dùng ghi âm trong `TransactionNoteInput` hoặc quick entry voice.
- Audio recorder state quản lý bằng `voiceRecorderControllerProvider` theo session id.
- Audio player lazy-load khi bấm play.
- Edge cases: thiếu quyền micro, audio missing hoặc không đọc được sẽ báo lỗi.

## PWA/mobile
- Web có PWA install prompt/guide qua `PwaInstallActions`.
- Onboarding có thể hiển thị PWA hint/page nếu đủ điều kiện.
- Profile có entry cài app trên Web.
- Android dùng quyền camera/micro, keyboard resize theo `windowSoftInputMode="adjustResize"`.
- Chưa xác định từ codebase: chính sách backup/restore dữ liệu khi người dùng đổi thiết bị.
