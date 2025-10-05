@echo off
chcp 65001 >nul
title Sistema Multi-Bot - Iniciar

echo.
echo ========================================
echo   SISTEMA MULTI-BOT - INICIANDO
echo   Dashboard + Gateways + Webhooks
echo ========================================
echo.

echo [1/5] Parando processos anteriores...
taskkill /IM node.exe /F >nul 2>&1
taskkill /IM python.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/5] Iniciando Bot Python...
cd /d "%~dp0"
cd "Grmpay - SEM WEB"
start "Bot Python" cmd /k "python bot.py"
cd /d "%~dp0"
timeout /t 5 /nobreak >nul

echo [3/5] Iniciando Backend...
cd backend
start "Backend" cmd /k "npm run dev"
cd /d "%~dp0"
timeout /t 5 /nobreak >nul

echo [4/5] Iniciando Frontend...
start "Frontend" cmd /k "npm run dev"
timeout /t 8 /nobreak >nul

echo [5/5] Abrindo Dashboard...
start "" http://localhost:5173

echo.
echo ========================================
echo   SISTEMA INICIADO COM SUCESSO
echo ========================================
echo.

echo [INFO] Dashboard: http://localhost:5173
echo [INFO] Login: admin / admin123
echo [INFO] Gateways: PushinPay e SyncPay
echo [INFO] Para parar: Execute PARAR.bat
echo.

pause




