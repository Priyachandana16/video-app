@echo off
title My Invitation - Starting All Services
echo ========================================================
echo        MY INVITATION - 1-CLICK LOCALHOST RUNNER        
echo ========================================================
echo.

echo [1/3] Starting Backend API Server (Port 5000)...
start "My Invitation - Backend API (5000)" cmd /k "node backend\server.js"

echo [2/3] Starting Flutter Web Client (Port 8085)...
start "My Invitation - Flutter Web App (8085)" cmd /k "node serve_web.js"

echo [3/3] Starting Admin Studio (Port 3001)...
start "My Invitation - Admin Studio (3001)" cmd /k "cd admin-dashboard && npx next dev --turbo -p 3001"

echo.
echo All 3 servers are launching in the background!
echo Waiting for services to initialize...
timeout /t 4 /nobreak >nul

echo.
echo Opening browser...
start http://localhost:8085
start http://localhost:3001

echo.
echo ========================================================
echo  Flutter Web App  : http://localhost:8085
echo  Admin Studio     : http://localhost:3001
echo  Backend API      : http://localhost:5000
echo ========================================================
echo.
echo Keep the 3 command windows open while testing.
echo Run stop_all.bat whenever you want to shut them down.
echo.
pause

