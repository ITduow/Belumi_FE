# BELUMI - Hướng dẫn Cấu hình Firebase SHA cho Google Sign-In (Release)

## SHA Fingerprints từ Keystore (upload-keystore.jks)

```
SHA-1:   07:CD:76:22:A8:95:58:3E:85:71:EC:97:B8:B1:30:D1:08:CC:84:AA
SHA-256: F5:0E:13:39:BD:41:0D:15:D0:37:17:14:40:7D:1F:E9:B3:34:0E:C5:51:8F:48:B6:6E:7F:6A:16:F4:3D:4A:95
```

## Bước thực hiện

1. Truy cập Firebase Console: https://console.firebase.google.com/
2. Chọn project **Belumi** (`belumi-1712f`)
3. Vào **Project Settings** (biểu tượng răng cưa)
4. Chọn tab **General**
5. Kéo xuống phần **Your apps** → chọn ứng dụng Android
6. Nhấn **Add fingerprint**
7. Dán **SHA-1** vào và lưu
8. Nhấn **Add fingerprint** lần nữa
9. Dán **SHA-256** vào và lưu
10. Tải lại file `google-services.json` mới và thay thế file cũ trong `android/app/`

## Tại sao cần làm điều này?

Khi debug, Flutter ký app bằng debug keystore (khác với release keystore).
Firebase lưu danh sách SHA hợp lệ để phê duyệt Google Sign-In requests.
Nếu SHA của release keystore không được khai báo → Google Sign-In **sẽ bị lỗi 100%** dù debug chạy bình thường.

## Xác minh sau khi thêm SHA

Để kiểm tra SHA đã thêm đúng chưa:
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload -storepass belumi2026
```

## Ghi chú bảo mật

- File `upload-keystore.jks` đã được tạo tại: `android/app/upload-keystore.jks`
- File đã được gitignore (không đẩy lên git)
- **BACKUP NGAY:** Copy file này ra Google Drive riêng tư và/hoặc USB
- Mật khẩu: `belumi2026` (lưu trữ an toàn, không chia sẻ qua chat)
