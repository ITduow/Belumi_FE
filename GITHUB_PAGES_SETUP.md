# BELUMI - GitHub Pages: Privacy Policy Hosting Guide

## Mục đích
File này hướng dẫn cách host trang Privacy Policy lên GitHub Pages miễn phí
để lấy link URL dán vào Google Play Console (bắt buộc).

## Bước thực hiện

### Cách 1: Host trực tiếp từ repo Belumi_FE (khuyên dùng)

1. Đảm bảo file `privacy_policy.html` đã có trong thư mục gốc của `Belumi_FE`.

2. Push file lên GitHub:
   ```bash
   git add privacy_policy.html
   git commit -m "chore: add privacy policy page"
   git push origin main
   ```

3. Vào GitHub repo → **Settings** → **Pages** (sidebar)

4. Trong mục **Source**: chọn `Deploy from a branch`

5. Chọn branch: `main`, folder: `/ (root)`

6. Nhấn **Save**

7. Sau vài phút, GitHub Pages sẽ live tại:
   ```
   https://[YOUR-USERNAME].github.io/[REPO-NAME]/privacy_policy.html
   ```

8. Dán URL đó vào Google Play Console → Store Listing → Privacy Policy URL.

---

### Cách 2: Tạo repo riêng cho Privacy Policy

1. Tạo repo mới: `belumi-privacy`
2. Upload `privacy_policy.html` vào repo đó
3. Đặt tên file là `index.html` (hoặc giữ `privacy_policy.html`)
4. Bật GitHub Pages từ repo đó
5. URL sẽ là: `https://[USERNAME].github.io/belumi-privacy/`

---

## Lưu ý

- URL phải **công khai** và **truy cập được** từ mọi thiết bị
- Không cần custom domain
- GitHub Pages hoàn toàn miễn phí
- Trang phải thực sự có nội dung (không phải placeholder)

## Kiểm tra trước khi dán vào Play Console

- [ ] URL mở được trên điện thoại
- [ ] Trang hiển thị đầy đủ nội dung (không bị 404)
- [ ] Nội dung phù hợp với dữ liệu thực tế app thu thập
