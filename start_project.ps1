# Script simples para iniciar o projeto Web-Bot
Write-Host "🚀 Iniciando projeto Web-Bot..." -ForegroundColor Green

# Configurar encoding UTF-8
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Verificar se estamos no diretório correto
$currentPath = Get-Location
Write-Host "📂 Diretório atual: $currentPath" -ForegroundColor Green

# Verificar se o backend existe
if (Test-Path "backend") {
    Write-Host "✅ Diretório backend encontrado" -ForegroundColor Green
} else {
    Write-Host "❌ Diretório backend não encontrado" -ForegroundColor Red
    Write-Host "📋 Conteúdo do diretório atual:" -ForegroundColor Yellow
    Get-ChildItem | Select-Object Name, Mode
    exit 1
}

# Parar processos Node existentes
Write-Host "🛑 Parando processos Node existentes..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# Verificar porta 3001
Write-Host "🔍 Verificando porta 3001..." -ForegroundColor Blue
$portCheck = netstat -ano | findstr :3001
if ($portCheck) {
    Write-Host "⚠️ Porta 3001 em uso:" -ForegroundColor Yellow
    Write-Host $portCheck -ForegroundColor Yellow
} else {
    Write-Host "✅ Porta 3001 disponível" -ForegroundColor Green
}

# Instalar dependências do backend
Write-Host "📦 Instalando dependências do backend..." -ForegroundColor Blue
Set-Location backend
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências" -ForegroundColor Red
    exit 1
}

# Criar diretório de logs
Write-Host "📁 Criando diretórios necessários..." -ForegroundColor Blue
New-Item -ItemType Directory -Path "logs" -Force | Out-Null

# Criar arquivo .env se não existir
if (-not (Test-Path ".env")) {
    Write-Host "📝 Criando arquivo .env..." -ForegroundColor Blue
    @"
NODE_ENV=development
PORT=3001
HOST=localhost
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
ADMIN_USER_ID=1
CORS_ORIGIN=http://localhost:5173
WS_CORS_ORIGIN=http://localhost:5173
"@ | Out-File -FilePath ".env" -Encoding UTF8
}

Write-Host "✅ Configuração concluída!" -ForegroundColor Green
Write-Host "🚀 Iniciando servidor..." -ForegroundColor Cyan

# Iniciar servidor
npm start
