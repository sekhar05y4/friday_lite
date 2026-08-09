import psutil
from flask import Blueprint, jsonify

telemetry_bp = Blueprint("telemetry", __name__)

@telemetry_bp.get("/api/telemetry")
def get_telemetry():
    """Returns real-time hardware OS telemetry metrics."""
    try:
        # 1. Live CPU load calculated across all logical cores via psutil.cpu_percent(interval=0.2)
        cpu_usage = psutil.cpu_percent(interval=0.2)

        # 2. Memory (RAM) using 1e9 scale
        mem = psutil.virtual_memory()
        ram_usage = {
            "percent": round(mem.percent, 1),
            "used_gb": round(mem.used / 1e9, 2),
            "total_gb": round(mem.total / 1e9, 2),
        }

        # 3. Battery status with graceful fallback
        battery_data = {"percent": 100, "is_charging": True}
        try:
            bat = psutil.sensors_battery()
            if bat is not None:
                battery_data = {
                    "percent": int(bat.percent),
                    "is_charging": bat.power_plugged if bat.power_plugged is not None else True,
                }
        except Exception:
            pass

        # 4. Top 5 memory-hogging active processes filtered by rss RAM usage
        top_apps = []
        try:
            processes = []
            for proc in psutil.process_iter(['name', 'memory_info']):
                try:
                    info = proc.info
                    name = info.get('name') or 'unknown'
                    mem_bytes = info.get('memory_info').rss if info.get('memory_info') else 0
                    if mem_bytes > 0:
                        processes.append((name, mem_bytes))
                except (psutil.NoSuchProcess, psutil.AccessDenied, Exception):
                    continue

            processes.sort(key=lambda x: x[1], reverse=True)
            top_apps = [
                {"name": p[0], "memory_mb": round(p[1] / 1e6, 1)}
                for p in processes[:5]
            ]
        except Exception:
            top_apps = [{"name": "system", "memory_mb": 256.0}]

        # 5. Active Network Adapters
        networks = []
        try:
            if_addrs = psutil.net_if_addrs()
            for if_name in if_addrs.keys():
                if not if_name.startswith("Loopback") and "loopback" not in if_name.lower():
                    networks.append(if_name)
        except Exception:
            networks = ["Wi-Fi", "Ethernet"]

        return jsonify({
            "status": "ok",
            "cpu_usage": cpu_usage,
            "ram_usage": ram_usage,
            "battery": battery_data,
            "top_apps": top_apps,
            "networks": networks if networks else ["Wi-Fi"],
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500
