@echo off
cd /d "%~dp0"
title EpieMarket Backend Stripe
echo Demarrage du backend Stripe...
echo.
npm install 2>nul
node server.js
echo.
echo Backend arrete. Appuyez sur une touche pour fermer.
pause >nul
