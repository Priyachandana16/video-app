@echo off
title My Invitation - Stop All Services
echo ========================================================
echo         STOPPING ALL MY INVITATION SERVICES            
echo ========================================================
echo.

echo Stopping services on ports 5000, 8085, 3001...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :5000 ^| findstr LISTENING') do (
    taskkill /F /PID %%a 2>nul
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8085 ^| findstr LISTENING') do (
    taskkill /F /PID %%a 2>nul
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3001 ^| findstr LISTENING') do (
    taskkill /F /PID %%a 2>nul
)

echo All services stopped cleanly.
echo.
pause
