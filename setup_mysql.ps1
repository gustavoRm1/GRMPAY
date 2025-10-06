# Script de Configuração do MySQL para WebBot Multi-Tenant
Write-Host "🗄️ CONFIGURAÇÃO DO MYSQL PARA WEBBOT MULTI-TENANT" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verificar se MySQL está instalado
Write-Host "`n🔍 Verificando instalação do MySQL..." -ForegroundColor Yellow
$mysqlService = Get-Service -Name "*mysql*" -ErrorAction SilentlyContinue

if ($mysqlService) {
    Write-Host "✅ MySQL encontrado: $($mysqlService.Name)" -ForegroundColor Green
    
    # Verificar status
    if ($mysqlService.Status -eq "Running") {
        Write-Host "✅ MySQL já está rodando" -ForegroundColor Green
    } else {
        Write-Host "⚠️ MySQL não está rodando. Tentando iniciar..." -ForegroundColor Yellow
        try {
            Start-Service -Name $mysqlService.Name
            Write-Host "✅ MySQL iniciado com sucesso" -ForegroundColor Green
        } catch {
            Write-Host "❌ Erro ao iniciar MySQL: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "💡 Tente iniciar manualmente pelo Painel de Controle > Serviços" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ MySQL não encontrado!" -ForegroundColor Red
    Write-Host "`n📥 OPÇÕES DE INSTALAÇÃO:" -ForegroundColor Yellow
    Write-Host "1. MySQL Community Server (Oficial):" -ForegroundColor White
    Write-Host "   https://dev.mysql.com/downloads/installer/" -ForegroundColor Cyan
    Write-Host "`n2. XAMPP (Mais simples para desenvolvimento):" -ForegroundColor White
    Write-Host "   https://www.apachefriends.org/pt_br/index.html" -ForegroundColor Cyan
    Write-Host "`n💡 Recomendo XAMPP para desenvolvimento - inclui MySQL + phpMyAdmin" -ForegroundColor Green
    exit 1
}

# Verificar se MySQL está acessível
Write-Host "`n🔍 Testando conectividade com MySQL..." -ForegroundColor Yellow
try {
    # Tentar conectar com mysql command line se disponível
    $mysqlTest = mysql --version 2>$null
    if ($mysqlTest) {
        Write-Host "✅ MySQL CLI disponível" -ForegroundColor Green
    } else {
        Write-Host "⚠️ MySQL CLI não encontrado (normal se instalado via XAMPP)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ MySQL CLI não encontrado (normal se instalado via XAMPP)" -ForegroundColor Yellow
}

# Verificar porta 3306
Write-Host "`n🔍 Verificando porta 3306..." -ForegroundColor Yellow
$portCheck = netstat -an | Select-String ":3306"
if ($portCheck) {
    Write-Host "✅ Porta 3306 está em uso (MySQL rodando)" -ForegroundColor Green
} else {
    Write-Host "⚠️ Porta 3306 não está em uso" -ForegroundColor Yellow
    Write-Host "💡 Verifique se o MySQL está rodando corretamente" -ForegroundColor Yellow
}

# Configurar banco de dados
Write-Host "`n🗄️ Configurando banco de dados..." -ForegroundColor Yellow

# Verificar se o arquivo schema.sql existe
$schemaPath = "backend\database\schema.sql"
if (Test-Path $schemaPath) {
    Write-Host "✅ Schema encontrado: $schemaPath" -ForegroundColor Green
    
    Write-Host "`n📋 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
    Write-Host "1. Acesse o MySQL (Workbench, phpMyAdmin ou linha de comando)" -ForegroundColor White
    Write-Host "2. Execute o arquivo: $schemaPath" -ForegroundColor White
    Write-Host "3. Ou execute o script de setup:" -ForegroundColor White
    Write-Host "   cd backend" -ForegroundColor Cyan
    Write-Host "   node setup_database.js" -ForegroundColor Cyan
} else {
    Write-Host "⚠️ Schema não encontrado em: $schemaPath" -ForegroundColor Yellow
}

# Verificar configuração do backend
Write-Host "`n🔍 Verificando configuração do backend..." -ForegroundColor Yellow
$envPath = "backend\.env"
if (Test-Path $envPath) {
    Write-Host "✅ Arquivo .env encontrado" -ForegroundColor Green
} else {
    Write-Host "⚠️ Arquivo .env não encontrado" -ForegroundColor Yellow
    Write-Host "💡 Copie env.example para .env e configure as credenciais do MySQL" -ForegroundColor Yellow
}

# Instruções finais
Write-Host "`n🎯 CONFIGURAÇÃO DO BANCO DE DADOS:" -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host "1. Configure as credenciais no backend/.env:" -ForegroundColor White
Write-Host "   DB_HOST=localhost" -ForegroundColor Cyan
Write-Host "   DB_PORT=3306" -ForegroundColor Cyan
Write-Host "   DB_USER=root" -ForegroundColor Cyan
Write-Host "   DB_PASSWORD=sua_senha_aqui" -ForegroundColor Cyan
Write-Host "   DB_NAME=web_bot_multi_tenant" -ForegroundColor Cyan

Write-Host "`n2. Execute o schema SQL:" -ForegroundColor White
Write-Host "   - Via phpMyAdmin (se XAMPP)" -ForegroundColor Cyan
Write-Host "   - Via MySQL Workbench" -ForegroundColor Cyan
Write-Host "   - Via linha de comando: mysql -u root -p < backend/database/schema.sql" -ForegroundColor Cyan

Write-Host "`n3. Teste a conexão:" -ForegroundColor White
Write-Host "   cd backend" -ForegroundColor Cyan
Write-Host "   node test_database.js" -ForegroundColor Cyan

Write-Host "`n4. Inicie o sistema:" -ForegroundColor White
Write-Host "   Terminal 1: cd backend && npm run dev" -ForegroundColor Cyan
Write-Host "   Terminal 2: npm run dev" -ForegroundColor Cyan

Write-Host "`n🎉 MySQL configurado! Agora você pode usar o sistema completo!" -ForegroundColor Green




