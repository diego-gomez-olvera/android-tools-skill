#!/usr/bin/env python3
"""
serve-trace.py — minimal HTTP server with CORS headers for Perfetto UI.

Usage:
    python3 skill-scripts/serve-trace.py <port> <directory>

Called by open-trace.sh; not intended for direct use.
"""
import http.server
import sys
import os


class CORSHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        super().end_headers()

    def log_message(self, fmt, *args):
        pass  # suppress per-request noise


port = int(sys.argv[1]) if len(sys.argv) > 1 else 9001
directory = sys.argv[2] if len(sys.argv) > 2 else "."

os.chdir(directory)
http.server.test(HandlerClass=CORSHandler, port=port, bind="127.0.0.1")
