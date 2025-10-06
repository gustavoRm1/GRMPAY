param(
    [string]$SourcePath = "C:\Users\grcon\OneDrive\Área de Trabalho\WEB - BOT",
    [string]$DestPath = "C:\projects\web-bot"
)

$ErrorActionPreference = "Stop"

Write-Host "=== MIGRACAO WEB-BOT ===" -ForegroundColor Cyan

# 1. Parar processos existentes
Write-Host "[1/7] Parando processos Node..." -ForegroundColor Yellow
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# 2. Verificar origem
if (-not (Test-Path $SourcePath)) {
    Write-Host "ERRO: Caminho de origem nao encontrado: $SourcePath" -ForegroundColor Red
    exit 1
}

# 3. Criar destino
Write-Host "[2/7] Criando diretorio de destino..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $DestPath -Force | Out-Null

# 4. Copiar arquivos (excluindo node_modules, .git, logs)
Write-Host "[3/7] Copiando arquivos..." -ForegroundColor Yellow
robocopy $SourcePath $DestPath /E /XD node_modules .git /XF *.log /NFL /NDL /NJH /NJS /R:3 /W:1

# 5. Configurar encoding
Write-Host "[4/7] Configurando UTF-8..." -ForegroundColor Yellow
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# 6. Navegar para novo local
Set-Location $DestPath
Write-Host "[5/7] Novo diretorio: $(Get-Location)" -ForegroundColor Green

# 7. Criar .env se nao existir
if (-not (Test-Path "backend\.env")) {
    Write-Host "[6/7] Criando .env..." -ForegroundColor Yellow
    @"
NODE_ENV=development
PORT=3001
HOST=localhost
JWT_SECRET=$(New-Guid)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
ADMIN_USER_ID=1
CORS_ORIGIN=http://localhost:5173
WS_CORS_ORIGIN=http://localhost:5173
"@ | Out-File -FilePath "backend\.env" -Encoding UTF8
}

# 8. Instalar dependencias
Write-Host "[7/7] Instalando dependencias..." -ForegroundColor Yellow
Set-Location backend
npm install --no-audit --no-fund
Set-Location ..

Write-Host "=== MIGRACAO CONCLUIDA ===" -ForegroundColor Green
Write-Host "Novo caminho: $DestPath" -ForegroundColor Cyan
Write-Host "Proximo passo: cd $DestPath && make dev" -ForegroundColor Cyan



