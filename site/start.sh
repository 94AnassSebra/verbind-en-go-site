#!/usr/bin/env bash
# Lokaal bekijken: bouwt de site en start een server op http://localhost:8080
cd "$(dirname "$0")"
python3 tools/sync_css.py && python3 tools/build.py project dist && python3 tools/check.py dist
echo "Open http://localhost:8080 in de browser (Ctrl+C om te stoppen)"
cd dist && python3 -m http.server 8080
