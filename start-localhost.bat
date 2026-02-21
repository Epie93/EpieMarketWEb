@echo off
chcp 65001 >nul
title EpieMarket - Serveur Local
color 0A

cd /d "%~dp0"

echo.
echo ========================================
echo   EpieMarket - Demarrage Local Host
echo ========================================
echo.

echo [1/4] Verification cle privee Stripe...
cd backend
node check-key.js >nul 2>&1
set KEYOK=%errorlevel%
cd ..
if %KEYOK% neq 0 (
    echo.
    echo CLE PRIVEE NON ACCEPTEE
    echo Verifie backend\.env - STRIPE_SECRET_KEY=sk_...
    echo.
    pause
    exit /b 1
)
echo.
echo CLE PRIVEE ACCEPTEE
echo.

echo [2/4] Demarrage backend Stripe port 3001...
start "EpieMarket Backend Stripe" cmd /k "cd /d %~dp0backend && node server.js"
echo Backend lance
echo.

echo [3/4] Attente 8 secondes...
timeout /t 8 /nobreak >nul
echo.

echo [4/4] Demarrage site web...
echo.
echo Site:  http://localhost:8000
echo Stripe: http://localhost:3001
echo.
echo Ctrl+C pour arreter. Fermer fenetre Backend pour arreter Stripe.
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0server.ps1"

pause
