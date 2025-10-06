.PHONY: help install clean dev prod docker-up docker-down logs test smoke-test

help:
	@echo "=== WEB-BOT - COMANDOS DISPONÍVEIS ==="
	@echo ""
	@echo "Setup:"
	@echo "  make install          - Instalar dependências"
	@echo "  make clean            - Limpar cache e logs"
	@echo ""
	@echo "Desenvolvimento:"
	@echo "  make dev              - Iniciar em modo desenvolvimento"
	@echo ""
	@echo "Produção:"
	@echo "  make prod             - Iniciar com PM2 (produção)"
	@echo "  make logs             - Ver logs PM2"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-up        - Subir containers"
	@echo "  make docker-down      - Parar containers"
	@echo "  make docker-logs      - Ver logs Docker"
	@echo ""
	@echo "Testes:"
	@echo "  make test             - Executar todos os testes"
	@echo "  make smoke-test       - Smoke test rápido"

install:
	@echo "Instalando dependências..."
	cd backend && npm install
	@echo "Criando diretórios..."
	mkdir -p backend/logs
	@echo "Instalação concluída!"

clean:
	@echo "Limpando cache e logs..."
	rm -rf backend/node_modules
	rm -rf backend/logs/*
	npm cache clean --force
	@echo "Limpeza concluída!"

dev:
	@echo "Iniciando servidor em modo desenvolvimento..."
	cd backend && npm run dev

prod:
	@echo "Iniciando servidor em produção com PM2..."
	cd backend && pm2 start ecosystem.config.js --env production
	@echo "Servidor iniciado! Use 'make logs' para ver logs."

logs:
	cd backend && pm2 logs

docker-up:
	@echo "Subindo containers Docker..."
	docker-compose up -d --build
	@echo "Containers iniciados! Use 'make docker-logs' para ver logs."

docker-down:
	@echo "Parando containers Docker..."
	docker-compose down
	@echo "Containers parados!"

docker-logs:
	docker-compose logs -f backend

test:
	@echo "Executando testes..."
	cd backend && npm test

smoke-test:
	@echo "Executando smoke test..."
	python3 smoke_test.py || python smoke_test.py