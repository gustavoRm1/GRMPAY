#!/bin/bash

# Script de Deployment - WebBot Multi-Tenant
# Executa deployment completo do sistema

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar se Docker está instalado
check_docker() {
    log "Verificando Docker..."
    if ! command -v docker &> /dev/null; then
        error "Docker não está instalado. Instale o Docker primeiro."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose não está instalado. Instale o Docker Compose primeiro."
        exit 1
    fi
    
    success "Docker e Docker Compose estão instalados"
}

# Verificar arquivo .env
check_env() {
    log "Verificando arquivo .env..."
    if [ ! -f ".env" ]; then
        warning "Arquivo .env não encontrado. Criando a partir do exemplo..."
        if [ -f "env.production.example" ]; then
            cp env.production.example .env
            warning "Arquivo .env criado. Configure as variáveis antes de continuar."
            exit 1
        else
            error "Arquivo env.production.example não encontrado."
            exit 1
        fi
    fi
    success "Arquivo .env encontrado"
}

# Backup do banco de dados
backup_database() {
    log "Fazendo backup do banco de dados..."
    
    # Criar diretório de backup se não existir
    mkdir -p backups
    
    # Backup usando mysqldump
    if command -v mysqldump &> /dev/null; then
        mysqldump -h localhost -u root -p web_bot_multi_tenant > backups/backup_$(date +%Y%m%d_%H%M%S).sql
        success "Backup do banco de dados criado"
    else
        warning "mysqldump não encontrado. Pulando backup do banco."
    fi
}

# Build das imagens Docker
build_images() {
    log "Construindo imagens Docker..."
    
    # Build do backend
    log "Construindo imagem do backend..."
    docker build -f Dockerfile.backend -t webbot-backend:latest .
    
    # Build do frontend
    log "Construindo imagem do frontend..."
    docker build -f Dockerfile.frontend -t webbot-frontend:latest .
    
    success "Imagens Docker construídas com sucesso"
}

# Deploy usando Docker Compose
deploy_compose() {
    log "Executando deployment com Docker Compose..."
    
    # Parar containers existentes
    log "Parando containers existentes..."
    docker-compose down
    
    # Remover imagens antigas (opcional)
    if [ "$1" = "--clean" ]; then
        log "Removendo imagens antigas..."
        docker system prune -f
    fi
    
    # Subir novos containers
    log "Subindo novos containers..."
    docker-compose up -d
    
    success "Deployment com Docker Compose concluído"
}

# Executar migrações
run_migrations() {
    log "Executando migrações do banco de dados..."
    
    # Aguardar o banco estar pronto
    log "Aguardando banco de dados estar pronto..."
    sleep 30
    
    # Executar migrações
    docker-compose exec backend node run_migration.js
    
    success "Migrações executadas com sucesso"
}

# Verificar saúde dos serviços
health_check() {
    log "Verificando saúde dos serviços..."
    
    # Verificar backend
    log "Verificando backend..."
    for i in {1..30}; do
        if curl -f http://localhost:3001/api/health &> /dev/null; then
            success "Backend está saudável"
            break
        fi
        if [ $i -eq 30 ]; then
            error "Backend não está respondendo após 30 tentativas"
            return 1
        fi
        sleep 2
    done
    
    # Verificar frontend
    log "Verificando frontend..."
    for i in {1..30}; do
        if curl -f http://localhost:80/ &> /dev/null; then
            success "Frontend está saudável"
            break
        fi
        if [ $i -eq 30 ]; then
            error "Frontend não está respondendo após 30 tentativas"
            return 1
        fi
        sleep 2
    done
    
    success "Todos os serviços estão saudáveis"
}

# Executar testes
run_tests() {
    log "Executando testes..."
    
    # Executar testes no container do backend
    docker-compose exec backend npm run test:ci
    
    success "Testes executados com sucesso"
}

# Mostrar status dos containers
show_status() {
    log "Status dos containers:"
    docker-compose ps
    
    log "Logs recentes:"
    docker-compose logs --tail=20
}

# Rollback
rollback() {
    log "Executando rollback..."
    
    # Parar containers atuais
    docker-compose down
    
    # Restaurar backup se existir
    if [ -f "backups/backup_$(date +%Y%m%d)_*.sql" ]; then
        log "Restaurando backup do banco de dados..."
        # Comando para restaurar backup
        # mysql -h localhost -u root -p web_bot_multi_tenant < backups/backup_*.sql
    fi
    
    # Subir containers anteriores
    docker-compose up -d
    
    success "Rollback executado"
}

# Função principal
main() {
    echo "🚀 DEPLOYMENT WEBBOT MULTI-TENANT"
    echo "=================================="
    
    case "${1:-deploy}" in
        "deploy")
            check_docker
            check_env
            backup_database
            build_images
            deploy_compose "$2"
            run_migrations
            health_check
            success "Deployment concluído com sucesso!"
            show_status
            ;;
        "test")
            check_docker
            run_tests
            ;;
        "status")
            show_status
            ;;
        "rollback")
            rollback
            ;;
        "clean")
            log "Limpando containers e imagens..."
            docker-compose down -v
            docker system prune -af
            success "Limpeza concluída"
            ;;
        *)
            echo "Uso: $0 {deploy|test|status|rollback|clean}"
            echo ""
            echo "Comandos:"
            echo "  deploy     - Executa deployment completo"
            echo "  test       - Executa testes"
            echo "  status     - Mostra status dos containers"
            echo "  rollback   - Executa rollback"
            echo "  clean      - Limpa containers e imagens"
            echo ""
            echo "Opções:"
            echo "  --clean    - Remove imagens antigas durante deploy"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"




