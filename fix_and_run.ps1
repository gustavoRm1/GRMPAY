# Script para corrigir e executar o sistema Web-Bot
# Executar como Administrador

Write-Host "🚀 Iniciando correção completa do sistema Web-Bot..." -ForegroundColor Green

# 1. Configurar encoding UTF-8
Write-Host "🔧 Configurando encoding UTF-8..." -ForegroundColor Blue
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
chcp 65001 | Out-Null

# 2. Verificar se estamos no diretório correto
$currentPath = Get-Location
Write-Host "📂 Diretório atual: $currentPath" -ForegroundColor Green

# 3. Verificar se o backend existe
if (Test-Path "backend") {
    Write-Host "✅ Diretório backend encontrado" -ForegroundColor Green
} else {
    Write-Host "❌ Diretório backend não encontrado" -ForegroundColor Red
    Write-Host "📋 Conteúdo do diretório atual:" -ForegroundColor Yellow
    Get-ChildItem | Select-Object Name, Mode
    exit 1
}

# 4. Parar processos Node existentes
Write-Host "🛑 Parando processos Node existentes..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# 5. Verificar porta 3001
Write-Host "🔍 Verificando porta 3001..." -ForegroundColor Blue
$portCheck = netstat -ano | findstr :3001
if ($portCheck) {
    Write-Host "⚠️ Porta 3001 em uso:" -ForegroundColor Yellow
    Write-Host $portCheck -ForegroundColor Yellow
} else {
    Write-Host "✅ Porta 3001 disponível" -ForegroundColor Green
}

# 6. Instalar dependências do backend
Write-Host "📦 Instalando dependências do backend..." -ForegroundColor Blue
Set-Location backend
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao instalar dependências" -ForegroundColor Red
    exit 1
}
Set-Location ..

# 7. Criar diretório de logs
Write-Host "📁 Criando diretórios necessários..." -ForegroundColor Blue
New-Item -ItemType Directory -Path "backend\logs" -Force | Out-Null
New-Item -ItemType Directory -Path "logs" -Force | Out-Null

# 8. Criar arquivo .env se não existir
if (-not (Test-Path "backend\.env")) {
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
"@ | Out-File -FilePath "backend\.env" -Encoding UTF8
}

# 9. Testar inicialização do servidor
Write-Host "🧪 Testando inicialização do servidor..." -ForegroundColor Blue
Set-Location backend

# Iniciar servidor em background
$serverProcess = Start-Process -FilePath "node" -ArgumentList "src/server.js" -PassThru -WindowStyle Hidden

# Aguardar inicialização
Start-Sleep -Seconds 5

# Verificar se o processo ainda está rodando
if ($serverProcess.HasExited) {
    Write-Host "❌ Servidor não conseguiu iniciar" -ForegroundColor Red
    Write-Host "📋 Código de saída: $($serverProcess.ExitCode)" -ForegroundColor Yellow
} else {
    Write-Host "✅ Servidor iniciado com sucesso (PID: $($serverProcess.Id))" -ForegroundColor Green
    
    # Testar endpoints
    Write-Host "🔍 Testando endpoints..." -ForegroundColor Blue
    
    try {
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:3001/health" -Method GET -TimeoutSec 10
        Write-Host "✅ Health check: $($healthResponse.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Health check falhou: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    try {
        $testResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/test" -Method GET -TimeoutSec 10
        Write-Host "✅ API test: $($testResponse.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "❌ API test falhou: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    try {
        $gatewaysResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/gateways" -Method GET -TimeoutSec 10
        Write-Host "✅ Gateways endpoint: $($gatewaysResponse.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Gateways endpoint falhou: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Parar servidor de teste
    Stop-Process -Id $serverProcess.Id -Force
    Write-Host "🛑 Servidor de teste parado" -ForegroundColor Yellow
}

Set-Location ..

Write-Host "✅ Correção e teste concluídos!" -ForegroundColor Green
Write-Host "🚀 Para iniciar o servidor:" -ForegroundColor Cyan
Write-Host "   cd backend && npm start" -ForegroundColor White
Write-Host "   ou" -ForegroundColor White
Write-Host "   cd backend && npm run dev" -ForegroundColor White



