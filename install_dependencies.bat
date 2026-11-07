@echo off
title My Invitation - One-Time Dependency Installer
echo ========================================================
echo     MY INVITATION - AUTOMATIC DEPENDENCY INSTALLER      
echo ========================================================
echo.

echo Checking Node.js installation...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH!
    echo Please install Node.js from https://nodejs.org/ (LTS recommended)
    pause
    exit /b 1
)
node -v

echo Checking Python installation...
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH!
    echo Please install Python 3.10+ from https://python.org/ and check 'Add to PATH'
    pause
    exit /b 1
)
python --version

echo.
echo ========================================================
echo [1/3] Installing Backend Node.js modules...
echo ========================================================
cd backend
call npm install
cd ..

echo.
echo ========================================================
echo [2/3] Installing Admin Studio Next.js modules...
echo ========================================================
cd admin-dashboard
call npm install
cd ..

echo.
echo ========================================================
echo [3/3] Installing Python Rendering Engine dependencies...
echo ========================================================
python -m pip install Pillow

echo.
echo ========================================================
echo           SUCCESS! ALL DEPENDENCIES INSTALLED           
echo ========================================================
echo.
echo You are now ready to run the app.
echo Simply double-click 'start_all.bat' to launch everything!
echo.
pause

