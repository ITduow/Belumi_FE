## 🎯 Mục đích

PR này gộp toàn bộ cấu hình phát hành Google Play Store từ nhánh `v1` vào nhánh `main`.

---

## 📋 Những thay đổi trong PR này

### Android Release Configuration
- **`build.gradle.kts`**: Đổi package name sang `com.belumi.app`, cấu hình tự động ký bằng `key.properties`, bật R8 minification và resource shrinking
- **`AndroidManifest.xml`**: App label đổi thành `Belumi`, thêm `INTERNET` permission rõ ràng
- **`proguard-rules.pro`** *(file mới)*: Luật ProGuard giữ nguyên Flutter/Firebase/Google classes tránh crash bản Release
- **`.gitignore`**: Thêm rule bảo mật chặn `*.jks`, `key.properties`, `android/build/` khỏi Git

### Version & Metadata
- **`pubspec.yaml`**: Version bump `1.0.0+1 → 1.0.1+2`, cập nhật description

### Tài liệu kỹ thuật & Tiếp thị *(file mới)*
- `FIREBASE_SHA_SETUP.md` — SHA-1 và SHA-256 fingerprints + hướng dẫn Firebase Console
- `PLAY_STORE_LISTING.md` — Toàn bộ nội dung Store Listing, Data Safety, tài khoản test
- `GITHUB_PAGES_SETUP.md` + `privacy_policy.html` — Trang Privacy Policy
- `warm_up_render.py` — Script giữ ấm Render server (stdlib only, ping mỗi 10 phút)
- `MANUAL_ACTIONS_REQUIRED.md` — Hướng dẫn chi tiết tất cả các bước thủ công cần thiết

---

## ⚠️ Conflict cần xử lý thủ công

**File bị conflict:** `lib/core/config/app_config.dart`

Khi merge, Git sẽ báo conflict tại file này. Hãy chọn:
- ✅ **Giữ lại version của `v1`** (link Render Production): `defaultValue: 'https://belumi-be.onrender.com/api'`
- ❌ **Bỏ version của `main`**: `defaultValue: 'http://localhost:5151/api'`

---

## ✅ Checklist trước khi merge

- [ ] `android/app/google-services.json` đã tồn tại trong thư mục
- [ ] Backend `https://belumi-be.onrender.com/api/news` trả về HTTP 200
- [ ] `flutter build appbundle --release` hoàn thành thành công
- [ ] Xử lý conflict tại `app_config.dart` (giữ link Render)

---

## 🔒 Files KHÔNG được commit (đã gitignore)

- `android/key.properties` — chứa mật khẩu keystore
- `android/app/upload-keystore.jks` — file chữ ký số
- `android/app/google-services.json` — file cấu hình Firebase (mỗi máy tải riêng)
