#!/usr/bin/env python3

import html
import os
import socket
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.error import URLError
from urllib.request import urlopen


PORT = 8080
TIMEOUT = 2

SERVICES = [
    ("WordPress (PHP-FPM)", "wordpress", 9000, "tcp"),
    ("MariaDB", "mariadb", 3306, "tcp"),
    ("Redis", "redis", 6379, "redis"),
    ("Adminer (PHP-FPM)", "adminer", 9000, "tcp"),
    ("FTP", "ftp", 21, "tcp"),
    ("Static Website", "website", 8080, "http"),
    ("NGINX (HTTPS)", "nginx", 443, "https"),
]


def check_tcp(host, port):
    try:
        with socket.create_connection((host, port), timeout=TIMEOUT):
            return True, "TCP connection successful"
    except OSError as error:
        return False, str(error)


def check_redis(host, port):
    try:
        with socket.create_connection((host, port), timeout=TIMEOUT) as connection:
            connection.settimeout(TIMEOUT)
            connection.sendall(b"*1\r\n$4\r\nPING\r\n")
            response = connection.recv(128)
            if response.startswith(b"+PONG"):
                return True, "Redis returned PONG"
            return False, "Unexpected Redis response"
    except OSError as error:
        return False, str(error)


def check_http(url):
    try:
        with urlopen(url, timeout=TIMEOUT) as response:
            if 200 <= response.status < 400:
                return True, f"HTTP {response.status}"
            return False, f"HTTP {response.status}"
    except (OSError, URLError) as error:
        return False, str(error)


def check_service(name, host, port, kind):
    if kind == "redis":
        return check_redis(host, port)
    if kind == "http":
        return check_http(f"http://{host}:{port}/")
    if kind == "https":
        try:
            with socket.create_connection((host, port), timeout=TIMEOUT):
                return True, "HTTPS port is accepting connections"
        except OSError as error:
            return False, str(error)
    return check_tcp(host, port)


def build_page():
    results = []

    for name, host, port, kind in SERVICES:
        ok, details = check_service(name, host, port, kind)
        status = "UP" if ok else "DOWN"
        results.append((name, status, details))

    all_up = all(status == "UP" for _, status, _ in results)
    overall = "All checks passed" if all_up else "One or more checks failed"
    overall_class = "up" if all_up else "down"

    rows = ""
    for name, status, details in results:
        rows += (
            "<tr>"
            f"<td>{html.escape(name)}</td>"
            f'<td class="{status.lower()}">{status}</td>'
            f"<td>{html.escape(details)}</td>"
            "</tr>"
        )

    checked_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="15">
<title>Inception - Service Status</title>
<style>
body {{ font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto;
       padding: 0 20px; background: #f4f6f8; color: #222; }}
h1 {{ margin-bottom: 8px; }}
.subtitle {{ color: #555; }}
.summary {{ padding: 14px; border-radius: 6px; margin: 24px 0; }}
.summary.up {{ background: #d8f3dc; color: #1b4332; }}
.summary.down {{ background: #ffe0e0; color: #842029; }}
table {{ width: 100%; border-collapse: collapse; background: white; }}
th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }}
th {{ background: #263238; color: white; }}
.up {{ color: #18743b; font-weight: bold; }}
.down {{ color: #b42318; font-weight: bold; }}
footer {{ margin-top: 20px; color: #666; font-size: 0.9em; }}
</style>
</head>
<body>
<h1>Inception Service Status</h1>
<p class="subtitle">Infrastructure health checks</p>
<div class="summary {overall_class}">{overall}</div>
<table>
<thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead>
<tbody>{rows}</tbody>
</table>
<footer>Last checked: {checked_at} · Page refreshes every 15 seconds.</footer>
</body>
</html>"""


class StatusHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ("/", "/status", "/status/"):
            self.send_error(404, "Not Found")
            return

        page = build_page().encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(page)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(page)

    def log_message(self, format_string, *args):
        print("%s - %s" % (self.address_string(), format_string % args))


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), StatusHandler)
    print(f"Status service listening on port {PORT}", flush=True)
    server.serve_forever()
