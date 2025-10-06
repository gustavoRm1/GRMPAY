# Script para resolver problema do Apache no XAMPP
Write-Host "🔧 RESOLVENDO PROBLEMA DO APACHE NO XAMPP" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Write-Host "`n🔍 Verificando conflitos de porta..." -ForegroundColor Yellow

# Verificar porta 80
$port80 = netstat -ano | Select-String ":80.*LISTENING"
if ($port80) {
    Write-Host "⚠️ Porta 80 está em uso:" -ForegroundColor Yellow
    Write-Host $port80 -ForegroundColor White
} else {
    Write-Host "✅ Porta 80 está livre" -ForegroundColor Green
}

Write-Host "`n🛠️ SOLUÇÕES DISPONÍVEIS:" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow

Write-Host "`n1️⃣ PARAR IIS (Recomendado):" -ForegroundColor Green
Write-Host "   iisreset /stop" -ForegroundColor Cyan
Write-Host "   Ou via Painel de Controle > Programas > Ativar/Desativar recursos do Windows" -ForegroundColor White

Write-Host "`n2️⃣ ALTERAR PORTA DO XAMPP:" -ForegroundColor Green
Write-Host "   - XAMPP Control Panel > Apache > Config > Apache (httpd.conf)" -ForegroundColor White
Write-Host "   - Altere 'Listen 80' para 'Listen 8080'" -ForegroundColor White
Write-Host "   - Acesse: http://localhost:8080/phpmyadmin" -ForegroundColor Cyan

Write-Host "`n3️⃣ USAR APENAS MYSQL (Para WebBot):" -ForegroundColor Green
Write-Host "   - Inicie apenas MySQL no XAMPP" -ForegroundColor White
Write-Host "   - Apache não é necessário para o WebBot" -ForegroundColor White
Write-Host "   - Use phpMyAdmin via: http://localhost/phpmyadmin" -ForegroundColor Cyan

Write-Host "`n🎯 RECOMENDAÇÃO PARA WEBBOT:" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
Write-Host "Para o WebBot Multi-Tenant, você só precisa do MySQL:" -ForegroundColor White
Write-Host "✅ Inicie apenas MySQL no XAMPP" -ForegroundColor Green
Write-Host "✅ Apache pode ficar parado" -ForegroundColor Green
Write-Host "✅ Acesse phpMyAdmin diretamente" -ForegroundColor Green

Write-Host "`n📋 PASSOS PARA CONTINUAR:" -ForegroundColor Yellow
Write-Host "1. No XAMPP Control Panel:" -ForegroundColor White
Write-Host "   - Clique em 'Start' apenas no MySQL" -ForegroundColor Cyan
Write-Host "   - Deixe Apache parado" -ForegroundColor Cyan
Write-Host "`n2. Acesse phpMyAdmin:" -ForegroundColor White
Write-Host "   - http://localhost/phpmyadmin" -ForegroundColor Cyan
Write-Host "   - (Funciona mesmo com Apache parado)" -ForegroundColor White
Write-Host "`n3. Configure o banco:" -ForegroundColor White
Write-Host "   - Execute o script: .\setup_mysql.ps1" -ForegroundColor Cyan

Write-Host "`n💡 DICA:" -ForegroundColor Yellow
Write-Host "O WebBot usa Node.js + React, não precisa do Apache do XAMPP!" -ForegroundColor White
Write-Host "O Apache só é necessário para PHP, que não usamos." -ForegroundColor White




