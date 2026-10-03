#!/usr/bin/env python3
"""Serves frontend/build/web locally with single-page-app fallback (for testing the release build).
Usage: python3 scripts/serve_web.py [port]   (default 3000)"""
import http.server
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "frontend", "build", "web")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 3000


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def do_GET(self):
        path = self.translate_path(self.path.split("?")[0])
        if not os.path.exists(path):
            self.path = "/index.html"
        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


http.server.ThreadingHTTPServer(("", PORT), Handler).serve_forever()
