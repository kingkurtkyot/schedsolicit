@echo off
title SchedSolicit - Viewer Portal PWA
cd /d "%~dp0viewer_portal"
echo ========================================================
echo   Starting SchedSolicit Viewer Portal (Port 3000)
echo ========================================================
echo.
start http://localhost:3000
"C:\Program Files\nodejs\node.exe" "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js" run dev
pause
