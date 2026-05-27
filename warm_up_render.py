#!/usr/bin/env python3
"""
Belumi - Render API Warm-up Script
===================================
Chạy script này trước khi Google reviewer đăng nhập vào app
để đảm bảo Render server không bị "ngủ đông" (cold start).

Usage:
    python warm_up_render.py

Requirements:
    pip install requests
"""

import requests
import time
import sys

BASE_URL = "https://belumi-be.onrender.com"

WARMUP_ENDPOINTS = [
    "/api/news",
    "/api/products",
    "/api/subscription/plans",
]

def warm_up():
    print("🔥 Belumi Render Warm-up Script")
    print("=" * 40)
    print(f"Target: {BASE_URL}")
    print()

    success_count = 0

    for endpoint in WARMUP_ENDPOINTS:
        url = BASE_URL + endpoint
        try:
            print(f"📡 Pinging {endpoint}...", end=" ", flush=True)
            start = time.time()
            response = requests.get(url, timeout=90)
            elapsed = round((time.time() - start) * 1000)

            if response.status_code < 500:
                print(f"✅ {response.status_code} ({elapsed}ms)")
                success_count += 1
            else:
                print(f"⚠️  {response.status_code} ({elapsed}ms)")

        except requests.exceptions.Timeout:
            print("⏱️  Timeout (>90s) - server đang khởi động, thử lại...")
        except requests.exceptions.ConnectionError as e:
            print(f"❌ Connection error: {e}")
        except Exception as e:
            print(f"❌ Error: {e}")

        time.sleep(2)

    print()
    print(f"{'=' * 40}")
    print(f"✅ Warm-up hoàn thành: {success_count}/{len(WARMUP_ENDPOINTS)} endpoints phản hồi")

    if success_count > 0:
        print("🚀 Render server đã sẵn sàng! Google reviewer có thể đăng nhập.")
    else:
        print("⚠️  Server chưa phản hồi. Chờ 60s và thử lại...")

if __name__ == "__main__":
    warm_up()
