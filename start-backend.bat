@echo off
echo ========================================
echo Starting Backend Server for Push Notifications
echo ========================================
echo.

cd backend

echo Checking if node_modules exists...
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
    echo.
)

echo Starting server on port 3000...
echo Backend will be accessible at:
echo   - Localhost: http://localhost:3000
echo   - Android Emulator: http://10.0.2.2:3000
echo.
echo Press Ctrl+C to stop the server
echo.

call npm run dev
