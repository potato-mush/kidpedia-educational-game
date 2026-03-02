@echo off
echo =========================================
echo   Kidpedia Admin System Startup
echo =========================================
echo.

REM Check if Node.js is installed
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js version:
node --version
echo.

REM Navigate to backend directory
echo [1/4] Setting up Backend...
cd backend

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing backend dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install backend dependencies
        pause
        exit /b 1
    )
)

REM Check if .env exists
if not exist ".env" (
    echo Creating .env file from template...
    copy .env.example .env
    echo Please edit backend\.env with your settings if needed
)

echo.
echo [2/4] Starting Backend API server...
start "Kidpedia Backend API" cmd /k "npm run dev"

REM Wait for backend to start
timeout /t 5 /nobreak

REM Navigate to admin-panel directory
cd ..\admin-panel

echo.
echo [3/4] Setting up Admin Panel...

REM Check if node_modules exists
if not exist "node_modules" (
    echo Installing admin panel dependencies...
    call npm install
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install admin panel dependencies
        pause
        exit /b 1
    )
)

echo.
echo [4/4] Starting Admin Panel...
start "Kidpedia Admin Panel" cmd /k "npm run dev"

echo.
echo =========================================
echo   Startup Complete!
echo =========================================
echo.
echo Backend API: http://localhost:8080
echo Admin Panel: http://localhost:3000
echo.
echo Login credentials:
echo Username: admin
echo Password: admin
echo.
echo Press any key to return to the main directory...
pause >nul

cd ..
