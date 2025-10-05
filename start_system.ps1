# Sistema Multi-Bot Telegram - PowerShell Script
# ================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   SISTEMA MULTI-BOT TELEGRAM - PRODUÇÃO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Iniciando sistema completo..." -ForegroundColor Green
Write-Host ""

# Navegar para o diretório do script
Set-Location $PSScriptRoot

# Parar serviços anteriores
Write-Host "🛑 Parando serviços anteriores..." -ForegroundColor Yellow
if (Test-Path "stop_system.bat") {
    & "stop_system.bat" 2>$null
}
Start-Sleep -Seconds 2

# Verificar Node.js
Write-Host "🔍 Verificando Node.js..." -ForegroundColor Cyan
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Node.js encontrado: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js não encontrado"
    }
} catch {
    Write-Host "❌ ERRO: Node.js não encontrado!" -ForegroundColor Red
    Write-Host "💡 Instale Node.js primeiro: https://nodejs.org" -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Verificar Python
Write-Host "🔍 Verificando Python..." -ForegroundColor Cyan
try {
    $pythonVersion = python --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Python encontrado: $pythonVersion" -ForegroundColor Green
    } else {
        throw "Python não encontrado"
    }
} catch {
    Write-Host "❌ ERRO: Python não encontrado!" -ForegroundColor Red
    Write-Host "💡 Instale Python primeiro: https://python.org" -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit 1
}

Write-Host ""
Write-Host "📦 Instalando dependências..." -ForegroundColor Cyan
Write-Host ""

# Backend Node.js
Write-Host "[1/4] 🔧 Backend Node.js..." -ForegroundColor Cyan
if (Test-Path "backend") {
    Set-Location "backend"
    if (-not (Test-Path "node_modules")) {
        Write-Host "📥 Instalando dependências do backend..." -ForegroundColor Yellow
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ ERRO: Falha ao instalar dependências do backend!" -ForegroundColor Red
            Read-Host "Pressione Enter para sair"
            exit 1
        }
        Write-Host "✅ Backend instalado" -ForegroundColor Green
    } else {
        Write-Host "✅ Backend já instalado" -ForegroundColor Green
    }
    Set-Location ".."
} else {
    Write-Host "❌ ERRO: Pasta backend não encontrada!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Frontend React
Write-Host "[2/4] 🎨 Frontend React..." -ForegroundColor Cyan
if (-not (Test-Path "node_modules")) {
    Write-Host "📥 Instalando dependências do frontend..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ERRO: Falha ao instalar dependências do frontend!" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    Write-Host "✅ Frontend instalado" -ForegroundColor Green
} else {
    Write-Host "✅ Frontend já instalado" -ForegroundColor Green
}

# Verificar socket.io-client
Write-Host "🔍 Verificando socket.io-client..." -ForegroundColor Cyan
if (-not (Test-Path "node_modules\socket.io-client")) {
    Write-Host "⚠️ Instalando socket.io-client..." -ForegroundColor Yellow
    npm install socket.io-client@^4.7.5 --save
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ERRO: Falha ao instalar socket.io-client!" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    Write-Host "✅ socket.io-client instalado" -ForegroundColor Green
} else {
    Write-Host "✅ socket.io-client verificado" -ForegroundColor Green
}

# Bot Python API
Write-Host "[3/4] 🐍 Bot Python - API..." -ForegroundColor Cyan
if (Test-Path "Grmpay - SEM WEB") {
    Set-Location "Grmpay - SEM WEB"
    if (-not (Test-Path "requirements_api.txt")) {
        Write-Host "❌ ERRO: requirements_api.txt não encontrado!" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    if (-not (Test-Path "__pycache__")) {
        Write-Host "📥 Instalando dependências da API do bot..." -ForegroundColor Yellow
        pip install -r requirements_api.txt
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ ERRO: Falha ao instalar dependências da API do bot!" -ForegroundColor Red
            Read-Host "Pressione Enter para sair"
            exit 1
        }
        Write-Host "✅ Bot API instalado" -ForegroundColor Green
    } else {
        Write-Host "✅ Bot API já instalado" -ForegroundColor Green
    }
    Set-Location ".."
} else {
    Write-Host "❌ ERRO: Pasta 'Grmpay - SEM WEB' não encontrada!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Bot Python Principal
Write-Host "[4/4] 🐍 Bot Python - Principal..." -ForegroundColor Cyan
Set-Location "Grmpay - SEM WEB"
if (-not (Test-Path "requirements.txt")) {
    Write-Host "❌ ERRO: requirements.txt não encontrado!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
if (-not (Test-Path "__pycache__")) {
    Write-Host "📥 Instalando dependências do bot principal..." -ForegroundColor Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ERRO: Falha ao instalar dependências do bot principal!" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    Write-Host "✅ Bot Principal instalado" -ForegroundColor Green
} else {
    Write-Host "✅ Bot Principal já instalado" -ForegroundColor Green
}

Set-Location ".."
Write-Host ""
Write-Host "✅ Todas as dependências instaladas com sucesso!" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   INICIANDO SERVIÇOS..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Iniciar Bot API
Write-Host "🤖 Iniciando Bot API (Python - porta 5000)..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k", "cd /d `"$PSScriptRoot\Grmpay - SEM WEB`" && echo 🤖 Bot API iniciando... && python bot_api.py" -WindowStyle Normal

Write-Host "⏳ Aguardando Bot API inicializar..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Iniciar Backend
Write-Host "⚙️ Iniciando Backend (Node.js - porta 3001)..." -ForegroundColor Cyan
Set-Location "backend"
Start-Process cmd -ArgumentList "/k", "echo ⚙️ Backend iniciando... && npm run dev" -WindowStyle Normal

Write-Host "⏳ Aguardando Backend inicializar..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Iniciar Frontend
Set-Location ".."
Write-Host "🌐 Iniciando Frontend (React - porta 5173)..." -ForegroundColor Cyan

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   SISTEMA INICIADO COM SUCESSO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Serviços disponíveis:" -ForegroundColor Cyan
Write-Host "   🌐 Frontend: http://localhost:5173" -ForegroundColor White
Write-Host "   ⚙️ Backend API: http://localhost:3001" -ForegroundColor White
Write-Host "   🤖 Bot API: http://localhost:5000" -ForegroundColor White
Write-Host ""
Write-Host "🔐 Credenciais de login:" -ForegroundColor Cyan
Write-Host "   👤 Usuário: admin" -ForegroundColor White
Write-Host "   🔑 Senha: admin123" -ForegroundColor White
Write-Host ""
Write-Host "💡 Para parar o sistema: execute stop_system.bat" -ForegroundColor Yellow
Write-Host ""

Start-Process cmd -ArgumentList "/k", "echo 🌐 Frontend iniciando... && npm run dev" -WindowStyle Normal

Write-Host "✅ Sistema iniciado com sucesso!" -ForegroundColor Green
Write-Host "📊 Acesse: http://localhost:5173" -ForegroundColor Cyan
Write-Host ""
Read-Host "⏳ Pressione Enter para fechar esta janela"

