# 🔴 MANUAL ACTIONS REQUIRED — Belumi Play Store Release

Tài liệu này liệt kê toàn bộ các bước **PHẢI THỰC HIỆN THỦ CÔNG** (không thể tự động hóa bằng code)
để hoàn tất việc phát hành Belumi lên Google Play Store.

---

## ⚡ CRITICAL — Thực hiện NGAY (Chặn build nếu bỏ qua)

### 🔴 STEP C1: Tải `google-services.json` từ Firebase Console

**Tại sao:** File này hoàn toàn vắng mặt trong dự án. Gradle sẽ thất bại 100% khi build nếu thiếu file này.

**Các bước:**
1. Truy cập: https://console.firebase.google.com/
2. Chọn project **Belumi** (`belumi-1712f`)
3. Click biểu tượng **⚙️ Project Settings** (bánh răng cưa)
4. Tab **General** → kéo xuống phần **Your apps**
5. Chọn ứng dụng Android (`com.belumi.app`)
6. Click nút **Add fingerprint** → Dán **SHA-1:**
   ```
   07:CD:76:22:A8:95:58:3E:85:71:EC:97:B8:B1:30:D1:08:CC:84:AA
   ```
7. Click **Add fingerprint** lần nữa → Dán **SHA-256:**
   ```
   F5:0E:13:39:BD:41:0D:15:D0:37:17:14:40:7D:1F:E9:B3:34:0E:C5:51:8F:48:B6:6E:7F:6A:16:F4:3D:4A:95
   ```
8. Click **Download google-services.json**
9. Đặt file vào: `Belumi_FE/android/app/google-services.json`

**Xác minh:** Mở file `google-services.json` vừa tải về, tìm dòng `"package_name"` phải có giá trị là `"com.belumi.app"`.

---

### 🔴 STEP C2: Deploy Backend lên Render

**Tại sao:** Server `belumi-be.onrender.com` hiện đang trả về 404. Google Reviewer sẽ REJECT app nếu server không phản hồi.

**Dockerfile đã được tạo và push lên GitHub.** BE Owner cần làm:

1. Truy cập https://dashboard.render.com/
2. Click **New +** → **PostgreSQL**
   - Name: `belumi-db`
   - Region: `Singapore`
   - Click **Create Database** → Đợi trạng thái **Available**
   - Copy **Internal Database URL** (dùng ở bước sau)

3. Click **New +** → **Web Service**
   - Connect GitHub repo: `ITduow/Belumi_BE`
   - **Language: Docker** (Render tự nhận diện `Dockerfile`)
   - **Root Directory:** `Belumi_BE` *(nếu repo chứa cả FE và BE)*
   - *(Nếu repo BE riêng biệt thì bỏ trống Root Directory)*
   - Branch: `main`
   - Instance Type: **Free**

4. Click **Advanced** → Thêm các biến môi trường:

| Key | Value |
|-----|-------|
| `ConnectionStrings__DefaultConnection` | *(Internal DB URL từ bước tạo Postgres trên)* |
| `JwtSettings__SecretKey` | *(lấy từ file `.env` của BE Owner)* |
| `JwtSettings__Issuer` | `Belumi_App` |
| `JwtSettings__Audience` | `Belumi_App_Users` |
| `SMTP__Host` | `smtp.gmail.com` |
| `SMTP__Port` | `587` |
| `SMTP__User` | `loner9h@gmail.com` |
| `SMTP__Pass` | *(Gmail App Password — lấy từ file `.env` của BE Owner)* |
| `SMTP__From` | `Belumi@gmail.com` |
| `SMTP__DisplayName` | `Belumi App` |
| `Gemini__ApiKey` | *(Gemini API Key — lấy từ file `.env` — **ROTATE NGAY nếu đã bị lộ**)* |
| `FIREBASE_CREDENTIALS` | *(Copy toàn bộ nội dung JSON từ file `.env` dòng cuối)* |

5. Click **Create Web Service** → Đợi build (5-8 phút)
6. Kiểm tra: Truy cập `https://belumi-be.onrender.com/api/news` → Phải trả về JSON

---

## 🟡 HIGH — Thực hiện trước khi gửi duyệt Google

### STEP H1: Backup Keystore (FE Owner)

```
File: Belumi_FE/android/app/upload-keystore.jks
Password: *(xem trong file key.properties — KHÔNG ĐỂ LỘ password này)*
```

**Backup lên tối thiểu 2 nơi:**
- [ ] Google Drive cá nhân (private folder)
- [ ] USB drive vật lý

⚠️ **CẢNH BÁO:** Mất file này = vĩnh viễn không thể update app trên Play Store.

### STEP H2: Thiết kế Store Assets (Leader Owner)

| Asset | Kích thước | Format |
|-------|-----------|--------|
| App Icon | 512 × 512 px | PNG 32-bit, không có bo góc |
| Feature Graphic | 1024 × 500 px | PNG hoặc JPG |
| Screenshots | Tối thiểu 2 ảnh | PNG hoặc JPG |

Nội dung Store Listing đã soạn sẵn trong: `PLAY_STORE_LISTING.md`

### STEP H3: Tạo link Privacy Policy (Leader Owner)

File `privacy_policy.html` đã được tạo sẵn trong dự án. Upload lên:
- **GitHub Pages:** Xem hướng dẫn trong `GITHUB_PAGES_SETUP.md`
- **Hoặc Google Sites:** sites.google.com (miễn phí, nhanh hơn)

---

## 🟢 LOW — Thực hiện khi sẵn sàng gửi duyệt

### STEP L1: Chạy bản Release Local (FE Owner)

```bash
# Bước 1: Dọn dẹp cache
flutter clean
flutter pub get

# Bước 2: Kiểm thử Release trên thiết bị thật (cắm USB)
flutter run --release

# Bước 3: Build App Bundle chính thức
flutter build appbundle --release
```

File output: `build/app/outputs/bundle/release/app-release.aab`

### STEP L2: Upload lên Play Console (Leader Owner)

1. https://play.google.com/console → Create App
2. Internal Testing → Upload `app-release.aab`
3. Điền Store Listing từ `PLAY_STORE_LISTING.md`
4. Data Safety → Khai báo theo nội dung trong file trên
5. Content Rating, Target Audience, App Access → Điền đầy đủ
6. Closed Testing → Thêm 20 email testers
7. Warm-up Render: Chạy `python warm_up_render.py` trước khi submit
8. Submit → Staged Rollout 5%

---

## ✅ CHECKLIST CUỐI CÙNG TRƯỚC KHI SUBMIT

- [ ] `android/app/google-services.json` đã tồn tại với `package_name: com.belumi.app`
- [ ] SHA-1 và SHA-256 đã được thêm vào Firebase Console
- [ ] Backend tại `https://belumi-be.onrender.com/api/news` trả về HTTP 200
- [ ] `flutter build appbundle --release` hoàn thành không lỗi
- [ ] App chạy thành công trên thiết bị thật bản Release
- [ ] Keystore đã backup ít nhất 2 nơi
- [ ] Privacy Policy URL đang hoạt động (không phải localhost)
- [ ] Store Assets (icon + feature graphic + screenshots) đã sẵn sàng
- [ ] Render warm-up script đang chạy
