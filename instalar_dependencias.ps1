# Script PowerShell para instalar dependências do Sistema Multi-Bot
# =================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   INSTALANDO DEPENDÊNCIAS - SISTEMA MULTI-BOT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navegar para o diretório do script
Set-Location $PSScriptRoot

Write-Host "📦 Instalando dependências do Frontend..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERRO: Falha ao instalar dependências do frontend!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host "✅ Frontend instalado com sucesso!" -ForegroundColor Green
Write-Host ""

Write-Host "📦 Instalando dependências do Backend..." -ForegroundColor Yellow
Set-Location "backend"
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERRO: Falha ao instalar dependências do backend!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host "✅ Backend instalado com sucesso!" -ForegroundColor Green
Set-Location ".."
Write-Host ""

Write-Host "📦 Instalando dependências do Bot Python..." -ForegroundColor Yellow
Set-Location "Grmpay - SEM WEB"
pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERRO: Falha ao instalar dependências do bot principal!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

pip install -r requirements_api.txt
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERRO: Falha ao instalar dependências da API do bot!" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}
Write-Host "✅ Bot Python instalado com sucesso!" -ForegroundColor Green
Set-Location ".."
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "   TODAS AS DEPENDÊNCIAS INSTALADAS!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Agora você pode executar:" -ForegroundColor Cyan
Write-Host "   start_system.bat" -ForegroundColor White
Write-Host ""
Read-Host "Pressione Enter para sair"

