@echo off
REM Lokaal bekijken: bouwt de site en start een server op http://localhost:8080
cd /d %~dp0
python tools\sync_css.py && python tools\build.py project dist && python tools\check.py dist
echo Open http://localhost:8080 in de browser (Ctrl+C om te stoppen)
cd dist && python -m http.server 8080
