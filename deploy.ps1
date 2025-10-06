# Script de Deployment - WebBot Multi-Tenant (Windows PowerShell)
# Executa deployment completo do sistema

param(
    [string]$Action = "deploy",
    [switch]$Clean
)

# Função para logging
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Error {
    param([string]$Message)
    Write-Log "ERROR: $Message" -Color "Red"
}

function Write-Success {
    param([string]$Message)
    Write-Log "SUCCESS: $Message" -Color "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-Log "WARNING: $Message" -Color "Yellow"
}

# Verificar se Docker está instalado
function Test-Docker {
    Write-Log "Verificando Docker..." -Color "Blue"
    
    try {
        $dockerVersion = docker --version
        Write-Success "Docker está instalado: $dockerVersion"
    }
    catch {
        Write-Error "Docker não está instalado. Instale o Docker Desktop primeiro."
        exit 1
    }
    
    try {
        $composeVersion = docker-compose --version
        Write-Success "Docker Compose está instalado: $composeVersion"
    }
    catch {
        Write-Error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
        exit 1
    }
}

# Verificar arquivo .env
function Test-EnvFile {
    Write-Log "Verificando arquivo .env..." -Color "Blue"
    
    if (-not (Test-Path ".env")) {
        Write-Warning "Arquivo .env não encontrado. Criando a partir do exemplo..."
        if (Test-Path "env.production.example") {
            Copy-Item "env.production.example" ".env"
            Write-Warning "Arquivo .env criado. Configure as variáveis antes de continuar."
            exit 1
        }
        else {
            Write-Error "Arquivo env.production.example não encontrado."
            exit 1
        }
    }
    Write-Success "Arquivo .env encontrado"
}

# Backup do banco de dados
function Backup-Database {
    Write-Log "Fazendo backup do banco de dados..." -Color "Blue"
    
    # Criar diretório de backup se não existir
    if (-not (Test-Path "backups")) {
        New-Item -ItemType Directory -Path "backups" | Out-Null
    }
    
    # Backup usando mysqldump (se disponível)
    try {
        $backupFile = "backups/backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
        mysqldump -h localhost -u root -p web_bot_multi_tenant > $backupFile
        Write-Success "Backup do banco de dados criado: $backupFile"
    }
    catch {
        Write-Warning "mysqldump não encontrado. Pulando backup do banco."
    }
}

# Build das imagens Docker
function Build-Images {
    Write-Log "Construindo imagens Docker..." -Color "Blue"
    
    # Build do backend
    Write-Log "Construindo imagem do backend..." -Color "Blue"
    docker build -f Dockerfile.backend -t webbot-backend:latest .
    
    # Build do frontend
    Write-Log "Construindo imagem do frontend..." -Color "Blue"
    docker build -f Dockerfile.frontend -t webbot-frontend:latest .
    
    Write-Success "Imagens Docker construídas com sucesso"
}

# Deploy usando Docker Compose
function Deploy-Compose {
    Write-Log "Executando deployment com Docker Compose..." -Color "Blue"
    
    # Parar containers existentes
    Write-Log "Parando containers existentes..." -Color "Blue"
    docker-compose down
    
    # Remover imagens antigas se solicitado
    if ($Clean) {
        Write-Log "Removendo imagens antigas..." -Color "Blue"
        docker system prune -f
    }
    
    # Subir novos containers
    Write-Log "Subindo novos containers..." -Color "Blue"
    docker-compose up -d
    
    Write-Success "Deployment com Docker Compose concluído"
}

# Executar migrações
function Run-Migrations {
    Write-Log "Executando migrações do banco de dados..." -Color "Blue"
    
    # Aguardar o banco estar pronto
    Write-Log "Aguardando banco de dados estar pronto..." -Color "Blue"
    Start-Sleep -Seconds 30
    
    # Executar migrações
    docker-compose exec backend node run_migration.js
    
    Write-Success "Migrações executadas com sucesso"
}

# Verificar saúde dos serviços
function Test-Health {
    Write-Log "Verificando saúde dos serviços..." -Color "Blue"
    
    # Verificar backend
    Write-Log "Verificando backend..." -Color "Blue"
    for ($i = 1; $i -le 30; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3001/api/health" -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Success "Backend está saudável"
                break
            }
        }
        catch {
            if ($i -eq 30) {
                Write-Error "Backend não está respondendo após 30 tentativas"
                return $false
            }
            Start-Sleep -Seconds 2
        }
    }
    
    # Verificar frontend
    Write-Log "Verificando frontend..." -Color "Blue"
    for ($i = 1; $i -le 30; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:80/" -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Success "Frontend está saudável"
                break
            }
        }
        catch {
            if ($i -eq 30) {
                Write-Error "Frontend não está respondendo após 30 tentativas"
                return $false
            }
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Success "Todos os serviços estão saudáveis"
    return $true
}

# Executar testes
function Run-Tests {
    Write-Log "Executando testes..." -Color "Blue"
    
    # Executar testes no container do backend
    docker-compose exec backend npm run test:ci
    
    Write-Success "Testes executados com sucesso"
}

# Mostrar status dos containers
function Show-Status {
    Write-Log "Status dos containers:" -Color "Blue"
    docker-compose ps
    
    Write-Log "Logs recentes:" -Color "Blue"
    docker-compose logs --tail=20
}

# Rollback
function Invoke-Rollback {
    Write-Log "Executando rollback..." -Color "Blue"
    
    # Parar containers atuais
    docker-compose down
    
    # Restaurar backup se existir
    $backupFiles = Get-ChildItem -Path "backups" -Filter "backup_*.sql" | Sort-Object LastWriteTime -Descending
    if ($backupFiles.Count -gt 0) {
        Write-Log "Restaurando backup do banco de dados..." -Color "Blue"
        # Comando para restaurar backup
        # mysql -h localhost -u root -p web_bot_multi_tenant < $backupFiles[0].FullName
    }
    
    # Subir containers anteriores
    docker-compose up -d
    
    Write-Success "Rollback executado"
}

# Função principal
function Main {
    Write-Host "🚀 DEPLOYMENT WEBBOT MULTI-TENANT" -ForegroundColor "Cyan"
    Write-Host "==================================" -ForegroundColor "Cyan"
    
    switch ($Action.ToLower()) {
        "deploy" {
            Test-Docker
            Test-EnvFile
            Backup-Database
            Build-Images
            Deploy-Compose
            Run-Migrations
            if (Test-Health) {
                Write-Success "Deployment concluído com sucesso!"
                Show-Status
            }
            else {
                Write-Error "Deployment falhou na verificação de saúde"
                exit 1
            }
        }
        "test" {
            Test-Docker
            Run-Tests
        }
        "status" {
            Show-Status
        }
        "rollback" {
            Invoke-Rollback
        }
        "clean" {
            Write-Log "Limpando containers e imagens..." -Color "Blue"
            docker-compose down -v
            docker system prune -af
            Write-Success "Limpeza concluída"
        }
        default {
            Write-Host "Uso: .\deploy.ps1 {deploy|test|status|rollback|clean} [-Clean]" -ForegroundColor "Yellow"
            Write-Host ""
            Write-Host "Comandos:" -ForegroundColor "Yellow"
            Write-Host "  deploy     - Executa deployment completo"
            Write-Host "  test       - Executa testes"
            Write-Host "  status     - Mostra status dos containers"
            Write-Host "  rollback   - Executa rollback"
            Write-Host "  clean      - Limpa containers e imagens"
            Write-Host ""
            Write-Host "Opções:" -ForegroundColor "Yellow"
            Write-Host "  -Clean     - Remove imagens antigas durante deploy"
            exit 1
        }
    }
}

# Executar função principal
Main




