#!/usr/bin/env python3
"""
Belumi Render Server Warm-up Script
=====================================
Mục đích: Giữ cho Render server luôn thức (active) tránh bị ngủ đông (cold start)
          trong suốt thời gian Google kiểm duyệt ứng dụng.

Render Free tier sẽ tự động ngủ đông sau 15 phút không có traffic.
Khi kiểm duyệt viên Google mở app, nếu server đang ngủ thì sẽ mất ~50 giây
để khởi động lại — có thể khiến Google REJECT app vì "kết nối quá chậm".

Cách sử dụng:
    python warm_up_render.py

Lịch trình gợi ý:
    Chạy script này LIÊN TỤC trong suốt 14 ngày Closed Testing.
    Có thể dùng Task Scheduler (Windows) hoặc cron (Linux/Mac).
"""

import urllib.request
import urllib.error
import time
import datetime

BASE_URL = "https://belumi-be.onrender.com"
HEALTH_ENDPOINT = f"{BASE_URL}/api/news"
PING_INTERVAL_SECONDS = 600  # Ping mỗi 10 phút (600 giây)

def ping():
    """Gửi request đến API để giữ ấm server."""
    try:
        req = urllib.request.Request(
            HEALTH_ENDPOINT,
            headers={"User-Agent": "Belumi-WarmUp/1.0"}
        )
        with urllib.request.urlopen(req, timeout=30) as response:
            status = response.getcode()
            now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"[{now}] ✅ Render ACTIVE — HTTP {status}")
            return True
    except urllib.error.HTTPError as e:
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{now}] ⚠️  HTTP Error {e.code} — Server alive but endpoint issue")
        return True  # Server is alive even if 404
    except Exception as e:
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{now}] ❌ FAILED — {type(e).__name__}: {e}")
        return False

def main():
    print("=" * 55)
    print("  BELUMI RENDER WARM-UP SERVICE")
    print(f"  Target: {BASE_URL}")
    print(f"  Interval: every {PING_INTERVAL_SECONDS // 60} minutes")
    print("=" * 55)
    print("Press Ctrl+C to stop.\n")

    while True:
        ping()
        time.sleep(PING_INTERVAL_SECONDS)

if __name__ == "__main__":
    main()
