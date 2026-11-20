@echo off
title SchedSolicit - Owner App (Chrome)
cd /d "%~dp0flutter_app"
echo ========================================================
echo   Launching SchedSolicit Owner App (Google Chrome)
echo ========================================================
echo.
"C:\Users\kingk\flutter\bin\flutter.bat" run -d chrome --web-port=4000
pause
