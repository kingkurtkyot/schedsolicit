@echo off
title SchedSolicit - FastAPI Backend Server
cd /d "%~dp0backend"
echo ========================================================
echo   Starting SchedSolicit FastAPI Backend (Port 8000)
echo ========================================================
echo.
echo API Docs: http://localhost:8000/docs
echo Health:   http://localhost:8000/health
echo.
"%~dp0backend\.venv\Scripts\python.exe" -m uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
pause
