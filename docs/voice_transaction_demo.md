# AI Voice Transaction Demo

Tính năng này chỉ phục vụ demo/thuyết trình, không productionize.

## Cấu Hình

- Vào `Profile > Tính năng thử nghiệm`.
- Bật `AI nhận diện giọng nói`.
- Nhập endpoint Render, ví dụ:

```text
https://smart-expense-m8nm.onrender.com
```

- Nhập demo token nếu backend Render có cấu hình `DEMO_TOKEN`.
- OpenAI API key chỉ nằm trên Render backend. Flutter không chứa `OPENAI_API_KEY`.

Endpoint có thể nhập dạng base URL hoặc full path `/voice-transaction-demo`; Flutter normalize để tránh double path.

## Wakeup Render

Render free có thể sleep. Trước khi demo, bấm `Đánh thức API demo` trong cùng section. App gọi:

```text
GET {endpoint}/health
```

Nếu thành công, app báo:

```text
Service AI demo đang hoạt động.
```

## Quick Voice Entry

Khi user ghi âm xong trong luồng nhập nhanh bằng giọng nói:

- App giữ audio attachment hiện tại.
- Nếu AI đang bật và endpoint đã cấu hình, app tự upload audio lên backend demo.
- Backend trả transcript và transaction draft.
- Flutter tự điền title, amount, income/expense, category, note và date nếu response có date rõ ràng.
- Nếu `transactionDate` null hoặc parse lỗi, Flutter giữ nguyên ngày hiện tại trong form.
- Giao dịch từ AI luôn `pending = true`.
- App không auto-save; user phải kiểm tra và bấm lưu.

Khi form đã có audio, nút `AI đọc ghi âm` nằm bên phải hàng `Chờ đối soát`. Nút này cho phép user gọi lại AI thủ công sau khi ghi âm hoặc khi muốn thử lại.

## Transaction Editor Và Pending Review

Trong màn sửa giao dịch thường hoặc màn đối soát pending:

- Nếu form có audio và AI đang bật, nút `AI đọc ghi âm` nằm bên phải hàng `Chờ đối soát`.
- Nút này upload audio hiện có rồi autofill editor để user kiểm tra nhanh hơn.
- Save/Delete vẫn là action riêng của editor.
- App không tự confirm pending transaction.

## Error Handling

Nếu API lỗi, app hiển thị:

```text
Đã có lỗi khi AI nhận diện ghi âm. Bạn hãy tiếp tục lưu giao dịch và đối soát lại sau khi rảnh.
```

Audio, note và dữ liệu user đã nhập không bị xoá. User vẫn có thể lưu transaction pending để đối soát sau.

Nếu thiếu config endpoint, app hiển thị:

```text
Bạn cần cấu hình endpoint AI trong Profile trước.
```

## Timeout Và Debug Log

API client timeout sau 10 giây cho cả:

- `GET /health`
- `POST /voice-transaction-demo`

Console log dùng prefix:

```text
[AI Voice Demo]
```

Log có metadata để debug như endpoint normalized, HTTP status, content type, filename, byte length, warning count và field nào được apply. App không log demo token và không log raw audio bytes.

## Audio

Seed audio demo dùng `assets/seed/audio/voice_note.m4a`, cùng nội dung với `voice_demo_api/samples/01.m4a`.

Recorder ưu tiên các format backend support:

- M4A/MP4
- WebM
- WAV

Nếu platform chỉ hỗ trợ format khác, app vẫn cố lưu voice note; API demo có thể fail và app sẽ giữ flow cũ.

## Category Mapping

Backend demo trả stable default category IDs khớp với app:

- `default_expense_food` -> `Ăn uống`
- `default_expense_shopping` -> `Mua sắm`
- `default_expense_transport` -> `Di chuyển`
- `default_expense_bills` -> `Hoá đơn`
- `system_khac_expense` -> `Khác`
- `default_income_salary` -> `Lương`
- `system_khac_income` -> `Khác`

Flutter vẫn resolve lại theo local categories: `categoryId`, rồi `categoryKey`, rồi `categoryName`, cuối cùng fallback `Khác` theo thu/chi.

## Demo Checklist

1. Bật AI trong Profile > Tính năng thử nghiệm.
2. Nhập endpoint Render và demo token.
3. Bấm `Đánh thức API demo`.
4. Ghi âm trong quick voice entry.
5. Đợi AI autofill form, kiểm tra lại title/amount/category/note/date.
6. Bấm lưu thủ công.
7. Mở pending review nếu cần, bấm `AI đọc ghi âm` cạnh `Chờ đối soát` để parse lại audio hiện có.
8. Confirm thủ công sau khi kiểm tra.
