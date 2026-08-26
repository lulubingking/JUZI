"""M0 数据库基线冒烟验证：连接 MySQL，核对 21 张表齐全。
用法: python scripts/verify_db.py
"""
import os
import sys

import pymysql

EXPECTED_TABLES = [
    "admin_users", "roles", "permissions", "role_permissions",
    "product_series", "products", "product_variants", "product_images",
    "product_specs", "product_highlights", "purchase_channels",
    "cases", "banners", "news", "pages", "faqs", "service_policies",
    "messages", "site_configs", "operation_logs", "visit_stats",
]


def main() -> int:
    host = os.getenv("DB_HOST", "127.0.0.1")
    port = int(os.getenv("DB_PORT", "3306"))
    user = os.getenv("DB_USER", "orange")
    password = os.getenv("DB_PASSWORD", "orange")
    db = os.getenv("DB_NAME", "juzi_phone")

    try:
        conn = pymysql.connect(host=host, port=port, user=user, password=password, database=db, charset="utf8mb4")
    except Exception as e:  # noqa: BLE001
        print(f"[FAIL] 无法连接 MySQL: {e}")
        return 1

    with conn.cursor() as cur:
        cur.execute("SELECT VERSION()")
        version = cur.fetchone()[0]
        cur.execute("SHOW TABLES")
        tables = {row[0] for row in cur.fetchall()}

    conn.close()
    print(f"[OK] MySQL 连接成功，版本 {version}，库 {db}")

    missing = [t for t in EXPECTED_TABLES if t not in tables]
    extra = sorted(tables - set(EXPECTED_TABLES))
    if missing:
        print(f"[FAIL] 缺少表 {len(missing)} 张: {missing}")
        return 1
    if extra:
        print(f"[WARN] 存在预期外表 {len(extra)} 张: {extra}")
    print(f"[OK] 21 张业务表全部存在")
    return 0


if __name__ == "__main__":
    sys.exit(main())
