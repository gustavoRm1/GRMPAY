# Script para corrigir problemas do backend
Write-Host "🔧 Corrigindo problemas do backend..." -ForegroundColor Cyan

# 1. Criar arquivo .env
Write-Host "📝 Criando arquivo .env..." -ForegroundColor Yellow
$envContent = @"
# Configurações do Servidor
NODE_ENV=development
PORT=3001
HOST=localhost

# JWT Secret (ALTERE EM PRODUÇÃO!)
JWT_SECRET=syncpay_web_bot_jwt_secret_fixed_2024_development_only

# Bot API Configuration
BOT_API_URL=http://localhost:5000
BOT_DATA_FILE_PATH=../botpy/bot_dashboard_data.json

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=web_bot_multi_tenant

# Admin Configuration
ADMIN_USER_ID=7676333385
ADMIN_USERNAME=admin
ADMIN_EMAIL=admin@webbot.com
ADMIN_PASSWORD=admin123

# Encryption
ENCRYPTION_KEY=12345678901234567890123456789012

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS
CORS_ORIGIN=http://localhost:5173
WS_CORS_ORIGIN=http://localhost:5173

# Gateways
SYNCPAY_BASE_URL=https://api.syncpayments.com.br
SYNCPAY_CLIENT_ID=your_client_id_here
SYNCPAY_CLIENT_SECRET=your_client_secret_here

PUSHINPAY_BASE_URL=https://api.pushinpay.com.br
PUSHINPAY_PUBLIC_KEY=your_public_key_here
PUSHINPAY_SECRET_KEY=your_secret_key_here

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090
"@

$envContent | Out-File -FilePath "backend\.env" -Encoding UTF8
Write-Host "✅ Arquivo .env criado" -ForegroundColor Green

# 2. Verificar se MySQL está rodando
Write-Host "🗄️ Verificando MySQL..." -ForegroundColor Yellow
$mysqlService = Get-Service -Name "*mysql*" -ErrorAction SilentlyContinue
if ($mysqlService) {
    if ($mysqlService.Status -eq "Running") {
        Write-Host "✅ MySQL está rodando" -ForegroundColor Green
    } else {
        Write-Host "⚠️ MySQL não está rodando. Tentando iniciar..." -ForegroundColor Yellow
        Start-Service -Name $mysqlService.Name
        Write-Host "✅ MySQL iniciado" -ForegroundColor Green
    }
} else {
    Write-Host "❌ MySQL não encontrado. Instale o MySQL primeiro." -ForegroundColor Red
}

# 3. Instalar dependências se necessário
Write-Host "📦 Verificando dependências..." -ForegroundColor Yellow
if (-not (Test-Path "backend\node_modules")) {
    Write-Host "📥 Instalando dependências do backend..." -ForegroundColor Yellow
    Set-Location "backend"
    npm install
    Set-Location ".."
    Write-Host "✅ Dependências instaladas" -ForegroundColor Green
} else {
    Write-Host "✅ Dependências já instaladas" -ForegroundColor Green
}

# 4. Testar se o servidor inicia
Write-Host "🚀 Testando inicialização do backend..." -ForegroundColor Yellow
Set-Location "backend"

# Tentar iniciar o servidor em background
$job = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    npm run dev
}

# Aguardar um pouco e verificar se está funcionando
Start-Sleep -Seconds 5

# Verificar se a porta 3001 está em uso
$portCheck = netstat -an | Select-String ":3001"
if ($portCheck) {
    Write-Host "✅ Backend está rodando na porta 3001" -ForegroundColor Green
    Write-Host "🌐 Acesse: http://localhost:3001/api/health" -ForegroundColor Cyan
} else {
    Write-Host "❌ Backend não está respondendo" -ForegroundColor Red
    Write-Host "📋 Logs do job:" -ForegroundColor Yellow
    Receive-Job -Job $job
}

# Parar o job
Stop-Job -Job $job
Remove-Job -Job $job

Set-Location ".."

Write-Host "🎉 Correções aplicadas!" -ForegroundColor Green
Write-Host "📋 Para iniciar o backend:" -ForegroundColor Cyan
Write-Host "   cd backend" -ForegroundColor White
Write-Host "   npm run dev" -ForegroundColor White




