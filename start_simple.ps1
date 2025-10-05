# Script simples para iniciar o projeto
Write-Host "Iniciando projeto Web-Bot..." -ForegroundColor Green

# Configurar encoding
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Verificar diretório atual
$currentPath = Get-Location
Write-Host "Diretorio atual: $currentPath" -ForegroundColor Green

# Verificar se backend existe
if (Test-Path "backend") {
    Write-Host "Backend encontrado" -ForegroundColor Green
} else {
    Write-Host "Backend nao encontrado" -ForegroundColor Red
    Get-ChildItem | Select-Object Name
    exit 1
}

# Parar processos Node
Write-Host "Parando processos Node..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# Verificar porta 3001
Write-Host "Verificando porta 3001..." -ForegroundColor Blue
netstat -ano | findstr :3001

# Ir para backend
Set-Location backend

# Instalar dependências
Write-Host "Instalando dependencias..." -ForegroundColor Blue
npm install

# Criar diretório logs
New-Item -ItemType Directory -Path "logs" -Force | Out-Null

# Criar .env
if (-not (Test-Path ".env")) {
    Write-Host "Criando arquivo .env..." -ForegroundColor Blue
    "NODE_ENV=development`nPORT=3001`nHOST=localhost`nJWT_SECRET=your-secret-key`nADMIN_USERNAME=admin`nADMIN_PASSWORD=admin123" | Out-File -FilePath ".env" -Encoding UTF8
}

Write-Host "Configuracao concluida!" -ForegroundColor Green
Write-Host "Iniciando servidor..." -ForegroundColor Cyan

# Iniciar servidor
npm start
