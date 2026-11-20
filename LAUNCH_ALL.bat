@echo off
title SchedSolicit - Full System Master Launcher
echo ========================================================
echo        SchedSolicit - Launching Complete System
echo ========================================================
echo.
echo [1/3] Starting FastAPI Backend on http://localhost:8000 ...
start "SchedSolicit Backend API" cmd /k "cd /d ""%~dp0backend"" && set PYTHONPATH=. && "".venv\Scripts\python.exe"" -m uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload"

echo [2/3] Starting Viewer Portal PWA on http://localhost:3000 ...
start "SchedSolicit Viewer Portal" cmd /k "cd /d ""%~dp0viewer_portal"" && ""C:\Program Files\nodejs\node.exe"" ""C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js"" run dev"

echo Waiting 3 seconds for servers to initialize...
timeout /t 3 /nobreak >nul

echo [3/3] Opening SchedSolicit Viewer Portal in your browser...
start http://localhost:3000

echo.
echo ========================================================
echo All servers are running!
echo Backend Docs:   http://localhost:8000/docs
echo Viewer Portal:  http://localhost:3000
echo.
echo To launch the Flutter Owner App desktop UI, double-click:
echo   launch_owner_app_windows.bat
echo or for Chrome web UI:
echo   launch_owner_app_chrome.bat
echo ========================================================
pause
