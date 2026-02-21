@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title EpieMarket - Push vers GitHub

REM Se placer dans le dossier du script (obligatoire pour tout ajouter)
cd /d "%~dp0"

echo.
echo ========================================
echo   EpieMarket - Push vers GitHub
echo ========================================
echo.

REM Verifier que git est installe
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERREUR] Git n'est pas installe ou pas dans le PATH.
    pause
    exit /b 1
)

REM Verifier si GitHub CLI est connecte - si oui, pas besoin de token
set USE_GH=0
where gh >nul 2>nul
if %errorlevel% equ 0 (
    gh auth status >nul 2>nul
    if %errorlevel% equ 0 set USE_GH=1
)

if %USE_GH%==1 (
    echo [OK] GitHub CLI connecte - pas besoin de token.
    gh auth setup-git >nul 2>nul
    echo.
) else (
    REM Demander les identifiants
    echo [CONFIG] Entre tes identifiants GitHub:
    echo.
    set /p GIT_USER="Username GitHub (ex: Epie93): "
    set /p GIT_EMAIL="Email (ex: ton@email.com): "
    set /p GIT_TOKEN="Token GitHub (ne partage jamais ton token): "
    echo.

    if "!GIT_USER!"=="" (
        echo [ERREUR] Username requis.
        pause
        exit /b 1
    )
    if "!GIT_EMAIL!"=="" (
        echo [ERREUR] Email requis.
        pause
        exit /b 1
    )
    if "!GIT_TOKEN!"=="" (
        echo [ERREUR] Token requis.
        pause
        exit /b 1
    )

    REM Configurer Git pour ce commit
    git config user.name "!GIT_USER!"
    git config user.email "!GIT_EMAIL!"
    echo [OK] Identite configuree.
    echo.
)

REM Verifier qu'on est dans un repo git
if not exist ".git" (
    echo [INFO] Initialisation du depot Git...
    git init
    echo.
)

REM Verifier le remote origin
git remote get-url origin >nul 2>nul
if %errorlevel% neq 0 (
    git remote add origin https://github.com/Epie93/EpieMarketWEb.git
    echo [OK] Remote origin ajoute.
    echo.
)

REM Ajouter TOUS les fichiers et dossiers (nouveaux, modifies, supprimes)
git add -A
echo [OK] Tous les fichiers ajoutes
git status --short
echo.

REM Demander le message de commit
set /p MSG="Message de commit (ou Enter pour 'Deploy EpieMarket'): "
if "%MSG%"=="" set MSG=Deploy EpieMarket

REM Commit (si des changements existent)
git commit -m "%MSG%"
if %errorlevel% neq 0 (
    echo [INFO] Rien a committer - working tree clean. On pousse les commits existants...
    echo.
)

REM Push
git branch -M main 2>nul
echo [INFO] Push en cours...

if %USE_GH%==1 (
    REM GitHub CLI connecte - push simple
    git push -u origin main
    if %errorlevel% neq 0 (
        echo.
        git push -u origin master
    )
) else (
    REM Supprimer anciens identifiants puis enregistrer le nouveau token
    (
    echo protocol=https
    echo host=github.com
    ) | git credential reject 2>nul
    (
    echo protocol=https
    echo host=github.com
    echo username=!GIT_USER!
    echo password=!GIT_TOKEN!
    echo.
    ) | git credential approve 2>nul
    git push -u origin main
    if %errorlevel% neq 0 (
        git push -u origin master
    )
)
set PUSH_OK=%errorlevel%

if %PUSH_OK% neq 0 (
    echo.
    echo [ERREUR] Push echoue. Verifie le message d'erreur ci-dessus.
    echo.
    echo Si "repository not found": le repo https://github.com/Epie93/EpieMarketWEb existe-t-il ?
    echo Si "authentication failed": relance "gh auth login" dans PowerShell.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Push reussi !
echo ========================================
echo.
echo Prochaines etapes pour deploy sur Render:
echo   1. Va sur https://dashboard.render.com
echo   2. New ^> Web Service
echo   3. Connecte ton repo GitHub (EpieMarket)
echo   4. Render detectera render.yaml automatiquement
echo   5. Ajoute STRIPE_SECRET_KEY dans Environment
echo.
pause
