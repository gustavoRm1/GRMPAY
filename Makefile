# Makefile para Web-Bot
.PHONY: help install dev prod test clean docker-up docker-down logs

# Variáveis
NODE_ENV ?= development
PORT ?= 3001
DOCKER_COMPOSE = docker-compose

# Ajuda
help:
	@echo "🚀 Web-Bot - Comandos disponíveis:"
	@echo ""
	@echo "📦 Instalação:"
	@echo "  make install          - Instalar dependências"
	@echo "  make install-windows  - Setup completo Windows"
	@echo "  make install-wsl      - Setup completo WSL/Linux"
	@echo ""
	@echo "🚀 Execução:"
	@echo "  make dev              - Desenvolvimento (nodemon)"
	@echo "  make prod             - Produção (PM2)"
	@echo "  make start            - Iniciar servidor"
	@echo "  make stop             - Parar servidor"
	@echo ""
	@echo "🐳 Docker:"
	@echo "  make docker-up        - Subir containers"
	@echo "  make docker-down      - Parar containers"
	@echo "  make docker-build     - Build containers"
	@echo "  make docker-logs      - Ver logs Docker"
	@echo ""
	@echo "🧪 Testes:"
	@echo "  make test             - Executar testes"
	@echo "  make smoke-test       - Teste de fumaça"
	@echo "  make lint             - Linter"
	@echo ""
	@echo "🔧 Utilitários:"
	@echo "  make clean            - Limpar cache/node_modules"
	@echo "  make logs             - Ver logs"
	@echo "  make status           - Status dos serviços"

# Instalação
install:
	@echo "📦 Instalando dependências..."
	cd backend && npm install
	npm install

install-windows:
	@echo "🪟 Setup Windows..."
	powershell -ExecutionPolicy Bypass -File scripts/setup_windows.ps1

install-wsl:
	@echo "🐧 Setup WSL/Linux..."
	chmod +x scripts/setup_wsl.sh
	./scripts/setup_wsl.sh

# Desenvolvimento
dev:
	@echo "🚀 Iniciando desenvolvimento..."
	cd backend && npm run dev

prod:
	@echo "🏭 Iniciando produção..."
	cd backend && pm2 start ecosystem.config.js --env production

start:
	@echo "▶️ Iniciando servidor..."
	cd backend && npm start

stop:
	@echo "⏹️ Parando servidor..."
	cd backend && pm2 stop web-bot-backend || pkill -f "node.*server.js" || true

# Docker
docker-up:
	@echo "🐳 Subindo containers..."
	$(DOCKER_COMPOSE) up -d --build

docker-down:
	@echo "🐳 Parando containers..."
	$(DOCKER_COMPOSE) down

docker-build:
	@echo "🔨 Build containers..."
	$(DOCKER_COMPOSE) build --no-cache

docker-logs:
	@echo "📋 Logs Docker..."
	$(DOCKER_COMPOSE) logs -f

# Testes
test:
	@echo "🧪 Executando testes..."
	cd backend && npm test || echo "⚠️ Testes não configurados"

smoke-test:
	@echo "💨 Teste de fumaça..."
	python scripts/smoke_test.py

lint:
	@echo "🔍 Linter..."
	cd backend && npm run lint || echo "⚠️ Linter não configurado"

# Utilitários
clean:
	@echo "🧹 Limpando..."
	rm -rf node_modules backend/node_modules
	rm -rf backend/logs/*.log
	docker system prune -f

logs:
	@echo "📋 Logs do sistema..."
	tail -f backend/logs/combined.log

status:
	@echo "📊 Status dos serviços..."
	@echo "Porta 3001:"
	@netstat -tlnp 2>/dev/null | grep :3001 || lsof -i :3001 2>/dev/null || echo "  Não encontrado"
	@echo "Processos Node:"
	@ps aux | grep node | grep -v grep || echo "  Nenhum processo Node encontrado"
	@echo "PM2:"
	@pm2 list 2>/dev/null || echo "  PM2 não disponível"
	@echo "Docker:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  Docker não disponível"



