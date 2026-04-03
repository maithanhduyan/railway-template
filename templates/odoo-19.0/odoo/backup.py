import subprocess
import os
from datetime import datetime
import schedule
import time
import configparser

# Load cấu hình từ file backup.conf
config = configparser.ConfigParser()
config.read('backup.conf')

ODOO_DB = config['odoo']['db']
BACKUP_FORMAT = config['backup']['format']
CONTAINER_NAME = config.get('docker', 'container', fallback='odoo-19')
ODOO_CONF = config.get('docker', 'odoo_conf', fallback='/etc/odoo/odoo.conf')

BACKUP_DIR = "./backup"
os.makedirs(BACKUP_DIR, exist_ok=True)

def backup():
    date_time = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    filename = f"{ODOO_DB}_{date_time}.zip"
    container_path = f"/tmp/{filename}"
    local_path = f"{BACKUP_DIR}/{filename}"

    # Tạo backup bằng Odoo CLI trong Docker container
    script = (
        "import odoo; "
        f"odoo.tools.config.parse_config(['-c', '{ODOO_CONF}']); "
        "odoo.tools.config['list_db'] = True; "
        "import odoo.service.db as db; "
        f"f = open('{container_path}', 'wb'); "
        f"db.dump_db('{ODOO_DB}', f, '{BACKUP_FORMAT}'); "
        "f.close(); "
        "print('OK')"
    )

    try:
        # Bước 1: Tạo backup trong container
        result = subprocess.run(
            ["docker", "exec", CONTAINER_NAME, "python3", "-c", script],
            capture_output=True, text=True, timeout=600
        )
        if result.returncode != 0:
            print(f"[{date_time}] Backup failed: {result.stderr.strip()}")
            return

        # Bước 2: Copy file từ container ra host
        result = subprocess.run(
            ["docker", "cp", f"{CONTAINER_NAME}:{container_path}", local_path],
            capture_output=True, text=True, timeout=120
        )
        if result.returncode != 0:
            print(f"[{date_time}] Copy failed: {result.stderr.strip()}")
            return

        # Bước 3: Xóa file tạm trong container
        subprocess.run(
            ["docker", "exec", CONTAINER_NAME, "rm", "-f", container_path],
            capture_output=True, timeout=10
        )

        size_mb = os.path.getsize(local_path) / 1024 / 1024
        print(f"[{date_time}] Backup successful: {filename} ({size_mb:.1f} MB)")

    except subprocess.TimeoutExpired:
        print(f"[{date_time}] Backup timed out!")
    except Exception as e:
        print(f"[{date_time}] Backup error: {e}")

schedule.every().sunday.at("00:00").do(backup)

# test
# backup()

if __name__ == "__main__":
    print(datetime.now(), "Running Odoo backup ...")
    # Tạo công việc chạy backup mỗi tuần vào Chủ nhật lúc 0 giờ
    # schedule.every().sunday.at("00:00").do(backup)
    #backup()

    # Loop : Vòng lặp chạy tác vụ
    while True:
        schedule.run_pending()
        time.sleep(5)
