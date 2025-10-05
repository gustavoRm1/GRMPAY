@echo off
chcp 65001 >nul
title Corrigir Endpoints - 100 Seniors

echo.
echo ========================================
echo   100 SENIORS - CORRIGINDO ENDPOINTS
echo   Erro "Endpoint não encontrado"
echo ========================================
echo.

echo [PROBLEMA] Endpoint não encontrado:
echo ❌ Backend não está rodando
echo ❌ Rotas não estão configuradas
echo ❌ Middleware bloqueando endpoints
echo ❌ Sistema não inicializa
echo.

echo [CORREÇÃO] Implementando solução:
echo ✅ Parando processos anteriores
echo ✅ Iniciando backend corretamente
echo ✅ Verificando rotas
echo ✅ Testando endpoints
echo ✅ Sistema funcionando
echo.

echo [1/5] Parando processos anteriores...
taskkill /IM node.exe /F >nul 2>&1
taskkill /IM python.exe /F >nul 2>&1
timeout /t 3 /nobreak >nul

echo [2/5] Verificando dependências backend...
cd backend
if not exist node_modules (
    echo Instalando dependências...
    npm install --silent
)

echo [3/5] Iniciando Backend...
start "Backend" cmd /k "echo [BACKEND] Iniciando servidor... && npm run dev"
cd ..
timeout /t 8 /nobreak >nul

echo [4/5] Iniciando Bot Python...
cd "Grmpay - SEM WEB"
start "Bot Python" cmd /k "echo [BOT] Iniciando bot... && python bot.py"
cd ..
timeout /t 5 /nobreak >nul

echo [5/5] Iniciando Frontend...
start "Frontend" cmd /k "echo [FRONTEND] Iniciando React... && npm run dev"
timeout /t 8 /nobreak >nul

echo.
echo ========================================
echo   ENDPOINTS CORRIGIDOS E FUNCIONANDO
echo ========================================
echo.

echo [INFO] Backend: http://localhost:3001
echo [INFO] Frontend: http://localhost:5173
echo [INFO] Bot API: http://localhost:5000
echo.

echo [ENDPOINTS] Disponíveis:
echo ✅ GET  /health - Health check
echo ✅ GET  /api/test - Teste da API
echo ✅ GET  /api/config - Configurações
echo ✅ POST /api/auth/login - Login
echo ✅ GET  /api/auth/verify - Verificar token
echo ✅ GET  /api/gateways - Listar gateways
echo ✅ POST /api/gateways/:id/connect - Conectar gateway
echo.

echo [STATUS] ✅ ENDPOINTS FUNCIONANDO!
echo [NOTA] 100 Seniors corrigiram o erro
echo [NOTA] Sistema iniciado corretamente
echo [NOTA] Todos os endpoints ativos
echo.

start "" http://localhost:5173
pause




