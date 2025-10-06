GUIA DE IMPLANTAÇÃO E CORREÇÃO TOTAL - SISTEMA WEB-BOT
DOCUMENTO TÉCNICO DEFINITIVO
Versão: 1.0
Data: 2025-10-05
Objetivo: Resolver permanentemente todos os problemas do sistema Web-Bot e garantir funcionamento 100% estável em produção.

ÍNDICE

DIAGNÓSTICO CONSOLIDADO
CORREÇÕES PERMANENTES
SETUP COMPLETO POR AMBIENTE
VALIDAÇÃO E TESTES
DEPLOY EM PRODUÇÃO
TROUBLESHOOTING
CHECKLIST FINAL


1. DIAGNÓSTICO CONSOLIDADO
1.1 PROBLEMAS CRÍTICOS IDENTIFICADOS
PROBLEMA 1: SERVIDOR NÃO INICIA NA PORTA 3001
Sintomas:

Comando netstat -ano | findstr :3001 não retorna processo
Logs mostram "Server failed to start" ou nenhuma mensagem
pm2 list mostra status "stopped" ou "errored"

Causas Raiz:

Inicialização assíncrona sem tratamento adequado de erros
Middleware JSON com verificação que rejeita requests válidos
Variáveis de ambiente não carregadas corretamente
Dependências não instaladas ou corrompidas

Impacto: Sistema completamente inoperante - frontend não consegue conectar ao backend.
PROBLEMA 2: ENCODING UTF-8 NO WINDOWS
Sintomas:

Caminho exibido como: C:\Users\grcon\OneDrive\?rea de Trabalho\WEB - BOT
Comandos falham com "path not found"
Caracteres especiais (Área, É, Ã) aparecem corrompidos

Causas Raiz:

Windows usando code page 850 ou 1252 por padrão
PowerShell sem encoding UTF-8 configurado
Node.js recebendo paths com encoding incorreto

Impacto: Impossível navegar para diretório do projeto, comandos npm falham.
PROBLEMA 3: CONFLITO DE DIRETÓRIO DE TRABALHO
Sintomas:

Terminal aponta para diretório diferente do esperado
npm install falha com "package.json not found"
Imports relativos quebram no runtime

Causas Raiz:

OneDrive sincronizando arquivos com paths longos/especiais
Espaço no nome do diretório "WEB - BOT" causa parsing incorreto
Workdir não configurado corretamente no PM2/Docker

Impacto: Comandos executam no local errado, módulos não são encontrados.
PROBLEMA 4: DEPENDÊNCIAS E NODE_MODULES
Sintomas:

Erro "Cannot find module 'express'" ou similar
npm install trava ou falha
Versões incompatíveis entre packages

Causas Raiz:

node_modules corrompido por instalações incompletas
Cache npm com entradas inválidas
Lockfile desatualizado ou conflitante

Impacto: Servidor não inicializa, imports falham.
1.2 PROBLEMAS SECUNDÁRIOS

WebSocket não conecta: CORS mal configurado ou servidor não escutando eventos
Gateways não testam: Credenciais não carregadas do .env
Bot Python não comunica: API bridge Flask não iniciada ou porta errada
Logs não aparecem: Diretório logs/ não existe ou sem permissões


2. CORREÇÕES PERMANENTES
2.1 CORREÇÃO: ENCODING UTF-8 (WINDOWS)
Solução Permanente em PowerShell
Adicione ao seu perfil PowerShell ($PROFILE):
powershell# Configurar UTF-8 permanentemente
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
chcp 65001 | Out-Null
$env:PYTHONIOENCODING = "utf-8"
Para aplicar imediatamente sem reiniciar:
powershell. $PROFILE
Verificação
powershellchcp  # Deve retornar 65001
[Console]::OutputEncoding  # Deve retornar UTF8
2.2 CORREÇÃO: CAMINHO LIMPO (MIGRAÇÃO)
Script de Migração Automática
Salve como migrate_project.ps1:
powershellparam(
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
Execução:
powershellpowershell -ExecutionPolicy Bypass -File migrate_project.ps1
2.3 CORREÇÃO: INICIALIZAÇÃO DO SERVIDOR
Arquivo: backend/src/server.js (PATCH COMPLETO)
javascriptimport express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import config from '../config/env.js';
import routes from './routes/index.js';
import { setupWebSocket } from './websocket/handlers.js';
import { initializeServices } from './services/BotDataService.js';
import logger from './utils/logger.js';

const app = express();
const server = createServer(app);

// CORS configurado corretamente
const corsOptions = {
  origin: config.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));

// Security headers
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}));

// Body parsers - SEM verificação JSON que causa rejeição
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check ANTES de qualquer middleware
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: config.NODE_ENV
  });
});

// Logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

// API routes
app.use('/api', routes);

// Error handler global
app.use((err, req, res, next) => {
  logger.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal server error',
    ...(config.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// WebSocket setup
const io = new Server(server, {
  cors: corsOptions,
  pingTimeout: 60000,
  pingInterval: 25000
});

setupWebSocket(io);

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, closing server...');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, closing server...');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

// INICIALIZAÇÃO ROBUSTA
const startServer = async () => {
  try {
    // 1. Inicializar serviços
    logger.info('Initializing services...');
    await initializeServices();
    
    // 2. Obter porta e host com fallbacks
    const port = parseInt(process.env.PORT || config.PORT || '3001', 10);
    const host = process.env.HOST || config.HOST || '0.0.0.0';
    
    // 3. Verificar se porta está disponível
    const portInUse = await new Promise((resolve) => {
      const testServer = createServer();
      testServer.once('error', (err) => {
        if (err.code === 'EADDRINUSE') resolve(true);
        else resolve(false);
      });
      testServer.once('listening', () => {
        testServer.close();
        resolve(false);
      });
      testServer.listen(port, host);
    });
    
    if (portInUse) {
      logger.error(`Port ${port} is already in use`);
      logger.info('Run: netstat -ano | findstr :' + port + ' (Windows) or lsof -i :' + port + ' (Linux)');
      process.exit(1);
    }
    
    // 4. Iniciar servidor
    server.listen(port, host, () => {
      logger.info('='.repeat(60));
      logger.info('SERVER STARTED SUCCESSFULLY');
      logger.info('='.repeat(60));
      logger.info(`Environment: ${config.NODE_ENV}`);
      logger.info(`Server URL: http://${host}:${port}`);
      logger.info(`API URL: http://${host}:${port}/api`);
      logger.info(`WebSocket: ws://${host}:${port}`);
      logger.info(`Health Check: http://${host}:${port}/health`);
      logger.info(`JWT Secret: ${config.JWT_SECRET ? 'Configured' : 'NOT CONFIGURED - CRITICAL!'}`);
      logger.info('='.repeat(60));
    });
    
  } catch (error) {
    logger.error('CRITICAL: Server initialization failed');
    logger.error('Error:', error);
    logger.error('Stack:', error.stack);
    process.exit(1);
  }
};

// Handle uncaught errors
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Start
startServer();
2.4 CORREÇÃO: LOGGER UTILITY
Arquivo: backend/src/utils/logger.js (NOVO)
javascriptimport winston from 'winston';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Criar diretório de logs se não existir
const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.printf(({ timestamp, level, message, stack }) => {
      return `[${timestamp}] ${level.toUpperCase()}: ${message}${stack ? '\n' + stack : ''}`;
    })
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(({ timestamp, level, message }) => {
          return `[${timestamp}] ${level}: ${message}`;
        })
      )
    }),
    new winston.transports.File({ 
      filename: path.join(logsDir, 'error.log'), 
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),
    new winston.transports.File({ 
      filename: path.join(logsDir, 'combined.log'),
      maxsize: 10485760,
      maxFiles: 5
    })
  ]
});

export default logger;
2.5 CORREÇÃO: PM2 CONFIGURATION
Arquivo: backend/ecosystem.config.js (COMPLETO)
javascriptmodule.exports = {
  apps: [{
    name: 'web-bot-backend',
    script: './src/server.js',
    cwd: __dirname,
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    ignore_watch: ['node_modules', 'logs', '*.log'],
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development',
      PORT: 3001,
      HOST: 'localhost'
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3001,
      HOST: '0.0.0.0'
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_file: './logs/pm2-combined.log',
    time: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 1000,
    kill_timeout: 5000,
    listen_timeout: 10000,
    node_args: '--max-old-space-size=1024'
  }]
};

3. SETUP COMPLETO POR AMBIENTE
3.1 WINDOWS (RECOMENDADO: DOCKER)
Opção A: Docker (MAIS ESTÁVEL)
Pré-requisitos:

Docker Desktop instalado e rodando
WSL2 habilitado

Dockerfile.backend:
dockerfileFROM node:18-alpine

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    NODE_ENV=production

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

COPY backend/package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

COPY backend/src ./src
COPY backend/config ./config

RUN mkdir -p logs && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD ["node", "src/server.js"]
docker-compose.yml:
yamlversion: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    container_name: web-bot-backend
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - PORT=3001
      - HOST=0.0.0.0
      - CORS_ORIGIN=http://localhost:5173
      - WS_CORS_ORIGIN=http://localhost:5173
    env_file:
      - backend/.env
    volumes:
      - ./Grmpay - SEM WEB:/app/data:ro
      - backend-logs:/app/logs
    networks:
      - web-bot-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  backend-logs:

networks:
  web-bot-network:
    driver: bridge
Comandos:
powershell# Build e start
docker-compose up --build -d

# Verificar logs
docker-compose logs -f backend

# Status
docker-compose ps

# Parar
docker-compose down
Opção B: Nativo (com PM2)
Setup completo:
powershell# 1. Migrar projeto
.\migrate_project.ps1

# 2. Navegar
cd C:\projects\web-bot

# 3. Instalar dependências
cd backend
npm install

# 4. Criar diretórios
New-Item -ItemType Directory -Path logs -Force

# 5. Instalar PM2 globalmente
npm install -g pm2
npm install -g pm2-windows-startup
pm2-startup install

# 6. Configurar PM2 log rotate
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7

# 7. Iniciar com PM2
pm2 start ecosystem.config.js --env production
pm2 save

# 8. Verificar
pm2 list
pm2 logs
3.2 LINUX / WSL
Setup script (setup_linux.sh):
bash#!/bin/bash
set -e

echo "=== SETUP WEB-BOT LINUX/WSL ==="

# 1. Configurar locale UTF-8
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
sudo locale-gen C.UTF-8
sudo update-locale LANG=C.UTF-8

# 2. Instalar Node.js 18 se não existir
if ! command -v node &> /dev/null; then
    echo "Instalando Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# 3. Verificar versões
node --version
npm --version

# 4. Criar diretório do projeto
PROJECT_DIR="/home/$USER/web-bot"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 5. Copiar arquivos (assumindo que já estão no diretório)
echo "Instalando dependências..."
cd backend
npm install

# 6. Criar diretórios necessários
mkdir -p logs
chmod 755 logs

# 7. Instalar PM2
sudo npm install -g pm2

# 8. Configurar PM2
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7

# 9. Criar .env se não existir
if [ ! -f ".env" ]; then
    cat > .env << EOF
NODE_ENV=production
PORT=3001
HOST=0.0.0.0
JWT_SECRET=$(uuidgen)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
ADMIN_USER_ID=1
CORS_ORIGIN=http://localhost:5173
WS_CORS_ORIGIN=http://localhost:5173
EOF
fi

# 10. Iniciar servidor
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup

echo "=== SETUP CONCLUÍDO ==="
echo "Comandos úteis:"
echo "  pm2 list       - Ver processos"
echo "  pm2 logs       - Ver logs"
echo "  pm2 restart all - Reiniciar"
echo "  pm2 stop all   - Parar"
Execução:
bashchmod +x setup_linux.sh
./setup_linux.sh
3.3 MAKEFILE (UNIVERSAL)
Arquivo: Makefile (na raiz do projeto)
makefile.PHONY: help install clean dev prod docker-up docker-down logs test smoke-test

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

4. VALIDAÇÃO E TESTES
4.1 SMOKE TEST PYTHON
Arquivo: smoke_test.py (raiz do projeto)
python#!/usr/bin/env python3
"""
Smoke Test - Web-Bot
Valida endpoints principais do backend
"""

import requests
import json
import sys
import time
from typing import Dict, List, Tuple

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

class SmokeTest:
    def __init__(self, base_url: str = "http://localhost:3001"):
        self.base_url = base_url
        self.results: List[Dict] = []
        self.token: str = None
        
    def log(self, message: str, color: str = Colors.BLUE):
        timestamp = time.strftime("%H:%M:%S")
        print(f"[{timestamp}] {color}{message}{Colors.END}")
        
    def test_endpoint(
        self, 
        method: str, 
        endpoint: str, 
        expected_status: int = 200, 
        data: Dict = None,
        headers: Dict = None
    ) -> Tuple[bool, Dict]:
        """Testa um endpoint específico"""
        url = f"{self.base_url}{endpoint}"
        
        try:
            start_time = time.time()
            
            if method.upper() == "GET":
                response = requests.get(url, headers=headers, timeout=10)
            elif method.upper() == "POST":
                response = requests.post(url, json=data, headers=headers, timeout=10)
            else:
                return False, {"error": f"Método {method} não suportado"}
            
            elapsed = time.time() - start_time
            success = response.status_code == expected_status
            
            result = {
                "method": method,
                "endpoint": endpoint,
                "status_code": response.status_code,
                "expected_status": expected_status,
                "success": success,
                "response_time": elapsed
            }
            
            try:
                result["response_data"] = response.json()
            except:
                result["response_data"] = response.text[:100]
            
            self.results.append(result)
            
            if success:
                self.log(f"✅ {method} {endpoint} - {response.status_code} ({elapsed:.3f}s)", Colors.GREEN)
            else:
                self.log(f"❌ {method} {endpoint} - {response.status_code} (esperado: {expected_status})", Colors.RED)
            
            return success, result
            
        except requests.exceptions.ConnectionError:
            self.log(f"❌ Conexão recusada: {url}", Colors.RED)
            return False, {"error": "Connection refused"}
        except requests.exceptions.Timeout:
            self.log(f"❌ Timeout: {url}", Colors.RED)
            return False, {"error": "Timeout"}
        except Exception as e:
            self.log(f"❌ Erro: {str(e)}", Colors.RED)
            return False, {"error": str(e)}
    
    def test_health(self) -> bool:
        """Testa health check"""
        self.log("🔍 Testando health check...", Colors.BLUE)
        return self.test_endpoint("GET", "/health")[0]
    
    def test_api_test(self) -> bool:
        """Testa endpoint de teste"""
        self.log("🔍 Testando API test endpoint...", Colors.BLUE)
        return self.test_endpoint("GET", "/api/test")[0]
    
    def test_gateways(self) -> bool:
        """Testa listagem de gateways"""
        self.log("🔍 Testando gateways...", Colors.BLUE)
        return self.test_endpoint("GET", "/api/gateways")[0]
    
    def test_login(self) -> bool:
        """Testa autenticação"""
        self.log("🔍 Testando login...", Colors.BLUE)
        success, result = self.test_endpoint(
            "POST", 
            "/api/auth/login",
            200,
            {"username": "admin", "password": "admin123"}
        )
        
        if success and "response_data" in result:
            self.token = result["response_data"].get("token")
            if self.token:
                self.log(f"✅ Token obtido: {self.token[:20]}...", Colors.GREEN)
        
        return success
    
    def test_verify_token(self) -> bool:
        """Testa verificação de token"""
        if not self.token:
            self.log("⚠️  Pulando teste de token (login falhou)", Colors.YELLOW)
            return False
        
        self.log("🔍 Testando verificação de token...", Colors.BLUE)
        headers = {"Authorization": f"Bearer {self.token}"}
        return self.test_endpoint("GET", "/api/auth/verify", 200, headers=headers)[0]
    
    def run_all(self) -> Dict:
        """Executa todos os testes"""
        self.log("=" * 60, Colors.BLUE)
        self.log("SMOKE TEST - WEB-BOT BACKEND", Colors.BLUE)
        self.log("=" * 60, Colors.BLUE)
        self.log(f"Base URL: {self.base_url}", Colors.BLUE)
        self.log("", Colors.BLUE)
        
        tests = [
            ("Health Check", self.test_health),
            ("API Test", self.test_api_test),
            ("Gateways", self.test_gateways),
            ("Login", self.test_login),
            ("Verify Token", self.test_verify_token)
        ]
        
        passed = 0
        total = len(tests)
        
        for name, test_func in tests:
            try:
                if test_func():
                    passed += 1Tentar novamenteClaude ainda não tem a capacidade de executar o código que gera.AContinuarEditarGUIA DE IMPLANTAÇÃO E CORREÇÃO TOTAL - SISTEMA WEB-BOT (CONTINUAÇÃO)
python            except Exception as e:
                self.log(f"❌ Erro no teste {name}: {str(e)}", Colors.RED)
        
        self.log("", Colors.BLUE)
        self.log("=" * 60, Colors.BLUE)
        self.log("RESUMO DOS TESTES", Colors.BLUE)
        self.log("=" * 60, Colors.BLUE)
        self.log(f"Total: {total}", Colors.BLUE)
        self.log(f"Passou: {passed}", Colors.GREEN)
        self.log(f"Falhou: {total - passed}", Colors.RED if total - passed > 0 else Colors.GREEN)
        self.log(f"Taxa de sucesso: {(passed/total)*100:.1f}%", Colors.GREEN if passed == total else Colors.YELLOW)
        self.log("=" * 60, Colors.BLUE)
        
        return {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "success_rate": (passed / total) * 100,
            "results": self.results
        }

def main():
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:3001"
    
    tester = SmokeTest(base_url)
    summary = tester.run_all()
    
    # Exit code baseado no resultado
    if summary["success_rate"] >= 80:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
Execução:
bash# Linux/WSL
python3 smoke_test.py

# Windows
python smoke_test.py

# Teste personalizado
python smoke_test.py http://localhost:3001
4.2 TESTES JEST (BACKEND)
Arquivo: backend/tests/smoke.test.js
javascriptimport { describe, it, expect, beforeAll } from '@jest/globals';
import axios from 'axios';

const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3001';
const TIMEOUT = 10000;

describe('Smoke Tests - Web-Bot Backend', () => {
  let authToken = null;

  beforeAll(() => {
    jest.setTimeout(TIMEOUT);
  });

  describe('Health Check', () => {
    it('should return 200 and status ok', async () => {
      const response = await axios.get(`${BASE_URL}/health`);
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('status', 'ok');
      expect(response.data).toHaveProperty('timestamp');
    });
  });

  describe('API Test', () => {
    it('should return success', async () => {
      const response = await axios.get(`${BASE_URL}/api/test`);
      expect(response.status).toBe(200);
      expect(response.data.success).toBe(true);
    });
  });

  describe('Authentication', () => {
    it('should login with valid credentials', async () => {
      const response = await axios.post(`${BASE_URL}/api/auth/login`, {
        username: 'admin',
        password: 'admin123'
      });
      
      expect(response.status).toBe(200);
      expect(response.data.success).toBe(true);
      expect(response.data).toHaveProperty('token');
      expect(response.data).toHaveProperty('user');
      
      authToken = response.data.token;
    });

    it('should reject invalid credentials', async () => {
      try {
        await axios.post(`${BASE_URL}/api/auth/login`, {
          username: 'invalid',
          password: 'wrong'
        });
        fail('Should have thrown error');
      } catch (error) {
        expect(error.response.status).toBe(401);
      }
    });

    it('should verify valid token', async () => {
      const response = await axios.get(`${BASE_URL}/api/auth/verify`, {
        headers: { Authorization: `Bearer ${authToken}` }
      });
      
      expect(response.status).toBe(200);
      expect(response.data.valid).toBe(true);
    });
  });

  describe('Gateways', () => {
    it('should list payment gateways', async () => {
      const response = await axios.get(`${BASE_URL}/api/gateways`);
      expect(response.status).toBe(200);
      expect(response.data.success).toBe(true);
      expect(Array.isArray(response.data.data.gateways)).toBe(true);
    });
  });
});
Executar testes:
bashcd backend
npm test
4.3 VALIDAÇÃO MANUAL DE ENDPOINTS
Script de validação (validate_endpoints.sh):
bash#!/bin/bash

BASE_URL="${1:-http://localhost:3001}"

echo "=== VALIDAÇÃO DE ENDPOINTS ==="
echo "Base URL: $BASE_URL"
echo ""

# Health Check
echo "1. Health Check:"
curl -s "$BASE_URL/health" | jq '.' || echo "FALHOU"
echo ""

# API Test
echo "2. API Test:"
curl -s "$BASE_URL/api/test" | jq '.' || echo "FALHOU"
echo ""

# Gateways
echo "3. Gateways:"
curl -s "$BASE_URL/api/gateways" | jq '.' || echo "FALHOU"
echo ""

# Login
echo "4. Login:"
TOKEN=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  echo "Token obtido: ${TOKEN:0:20}..."
  echo ""
  
  # Verify Token
  echo "5. Verify Token:"
  curl -s "$BASE_URL/api/auth/verify" \
    -H "Authorization: Bearer $TOKEN" | jq '.' || echo "FALHOU"
else
  echo "FALHOU - Token não obtido"
fi

echo ""
echo "=== VALIDAÇÃO CONCLUÍDA ==="
Executar:
bashchmod +x validate_endpoints.sh
./validate_endpoints.sh
4.4 CHECKLIST DE VALIDAÇÃO
Copie e cole no terminal para validar tudo:
bash# CHECKLIST DE VALIDAÇÃO - WEB-BOT

echo "=== INICIANDO VALIDAÇÃO COMPLETA ==="

# 1. Verificar porta 3001
echo "1. Verificando porta 3001..."
if netstat -ano 2>/dev/null | grep -q ":3001" || ss -tlnp 2>/dev/null | grep -q ":3001"; then
  echo "✅ Porta 3001 em uso"
else
  echo "❌ Porta 3001 não está em uso"
fi

# 2. Verificar processo Node
echo "2. Verificando processo Node..."
if pgrep -f "node.*server.js" > /dev/null; then
  echo "✅ Processo Node rodando"
else
  echo "❌ Processo Node não encontrado"
fi

# 3. Verificar encoding
echo "3. Verificando encoding..."
if locale | grep -q "UTF-8"; then
  echo "✅ Encoding UTF-8 configurado"
else
  echo "⚠️  Encoding não é UTF-8"
fi

# 4. Verificar dependências
echo "4. Verificando node_modules..."
if [ -d "backend/node_modules" ]; then
  echo "✅ node_modules existe"
else
  echo "❌ node_modules não encontrado"
fi

# 5. Verificar .env
echo "5. Verificando .env..."
if [ -f "backend/.env" ]; then
  echo "✅ .env existe"
else
  echo "❌ .env não encontrado"
fi

# 6. Verificar logs
echo "6. Verificando diretório de logs..."
if [ -d "backend/logs" ]; then
  echo "✅ Diretório logs existe"
else
  echo "⚠️  Diretório logs não existe"
fi

# 7. Test health endpoint
echo "7. Testando health endpoint..."
if curl -s -f http://localhost:3001/health > /dev/null 2>&1; then
  echo "✅ Health endpoint responde"
else
  echo "❌ Health endpoint não responde"
fi

# 8. Test API endpoint
echo "8. Testando API endpoint..."
if curl -s -f http://localhost:3001/api/test > /dev/null 2>&1; then
  echo "✅ API endpoint responde"
else
  echo "❌ API endpoint não responde"
fi

echo ""
echo "=== VALIDAÇÃO CONCLUÍDA ==="

5. DEPLOY EM PRODUÇÃO
5.1 PREPARAÇÃO PRÉ-DEPLOY
Checklist pré-deploy:
bash# 1. Limpar ambiente
make clean

# 2. Reinstalar dependências
make install

# 3. Executar testes
make smoke-test

# 4. Verificar variáveis de ambiente
cat backend/.env | grep -v "PASSWORD\|SECRET"

# 5. Verificar versões
node --version  # Deve ser >= 18
npm --version   # Deve ser >= 9

# 6. Verificar espaço em disco
df -h

# 7. Verificar memória
free -h
5.2 DEPLOY COM DOCKER (RECOMENDADO)
Processo completo:
bash# 1. Build das imagens
docker-compose build --no-cache

# 2. Verificar imagens
docker images | grep web-bot

# 3. Iniciar em modo detached
docker-compose up -d

# 4. Verificar status
docker-compose ps

# 5. Verificar logs
docker-compose logs -f backend

# 6. Verificar health
curl http://localhost:3001/health

# 7. Executar smoke test
python3 smoke_test.py
Monitoramento contínuo:
bash# Logs em tempo real
docker-compose logs -f

# Status dos containers
watch -n 5 docker-compose ps

# Uso de recursos
docker stats

# Health checks
watch -n 10 'curl -s http://localhost:3001/health | jq .'
5.3 DEPLOY COM PM2
Processo completo:
bash# 1. Navegar para backend
cd backend

# 2. Instalar dependências
npm ci --only=production

# 3. Parar processos anteriores
pm2 stop all
pm2 delete all

# 4. Iniciar nova instância
pm2 start ecosystem.config.js --env production

# 5. Salvar configuração
pm2 save

# 6. Configurar auto-start
pm2 startup

# 7. Verificar status
pm2 list
pm2 logs --lines 50

# 8. Monitorar
pm2 monit
5.4 NGINX REVERSE PROXY (OPCIONAL)
Configuração Nginx:
nginx# /etc/nginx/sites-available/web-bot

upstream backend {
    server localhost:3001;
    keepalive 64;
}

server {
    listen 80;
    server_name seu-dominio.com;
    
    # Logs
    access_log /var/log/nginx/web-bot-access.log;
    error_log /var/log/nginx/web-bot-error.log;
    
    # API Backend
    location /api {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # WebSocket
    location /socket.io {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Health Check
    location /health {
        proxy_pass http://backend;
        access_log off;
    }
}
Ativar configuração:
bash# Link simbólico
sudo ln -s /etc/nginx/sites-available/web-bot /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx

6. TROUBLESHOOTING
6.1 SERVIDOR NÃO INICIA
Diagnóstico:
bash# Verificar porta
netstat -ano | findstr :3001  # Windows
lsof -i :3001                  # Linux

# Verificar processo
ps aux | grep node

# Verificar logs
cat backend/logs/error.log
pm2 logs --err --lines 100
docker-compose logs backend
Soluções:
bash# Matar processo na porta
# Windows
netstat -ano | findstr :3001
taskkill /PID <PID> /F

# Linux
lsof -ti:3001 | xargs kill -9

# Limpar PM2
pm2 kill
pm2 flush

# Reinstalar dependências
cd backend
rm -rf node_modules package-lock.json
npm install

# Reiniciar servidor
pm2 restart all
6.2 ERRO DE ENCODING
Diagnóstico:
powershell# Windows PowerShell
chcp
[Console]::OutputEncoding
$PSDefaultParameterValues
Solução permanente:
powershell# Adicionar ao $PROFILE
if (!(Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}

Add-Content $PROFILE @"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
`$PSDefaultParameterValues['*:Encoding'] = 'utf8'
chcp 65001 | Out-Null
"@

# Recarregar perfil
. $PROFILE
6.3 WEBSOCKET NÃO CONECTA
Diagnóstico:
javascript// No navegador (Console)
const socket = io('http://localhost:3001', {
  transports: ['websocket', 'polling']
});

socket.on('connect', () => console.log('Connected'));
socket.on('connect_error', (err) => console.error('Error:', err));
Soluções:
javascript// backend/src/server.js - Verificar configuração CORS do Socket.IO
const io = new Server(server, {
  cors: {
    origin: process.env.WS_CORS_ORIGIN || "http://localhost:5173",
    methods: ["GET", "POST"],
    credentials: true
  },
  pingTimeout: 60000,
  pingInterval: 25000,
  transports: ['websocket', 'polling']
});
6.4 GATEWAYS NÃO CONECTAM
Diagnóstico:
bash# Verificar .env
cat backend/.env | grep GATEWAY

# Testar manualmente
curl -X POST https://api.pushinpay.com.br/api/pix/cashIn \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"value": 100}'
Soluções:

Verificar credenciais no .env
Testar conectividade com APIs externas
Verificar logs de erro específicos
Validar formato das requisições

6.5 LOGS E MONITORAMENTO
Coletar todos os logs:
bash# Script de coleta
mkdir -p logs_debug
cp backend/logs/* logs_debug/ 2>/dev/null
pm2 logs > logs_debug/pm2.log 2>&1
docker-compose logs > logs_debug/docker.log 2>&1
systemctl status nginx > logs_debug/nginx.log 2>&1
tar -czf logs_debug_$(date +%Y%m%d_%H%M%S).tar.gz logs_debug/
Análise de logs:
bash# Erros mais comuns
grep -i "error" backend/logs/*.log | head -20

# Avisos
grep -i "warn" backend/logs/*.log | head -20

# Conexões
grep -i "connect" backend/logs/*.log | tail -50

# Requisições com erro
grep -E "40[0-9]|50[0-9]" backend/logs/*.log

7. CHECKLIST FINAL - PRONTO PARA PRODUÇÃO
7.1 INFRAESTRUTURA
[ ] Node.js 18+ instalado
[ ] npm 9+ instalado
[ ] PM2 instalado globalmente (ou Docker)
[ ] Portas 3001, 5173, 5000 disponíveis
[ ] Encoding UTF-8 configurado
[ ] Diretório sem caracteres especiais no caminho
[ ] 2GB+ RAM disponível
[ ] 10GB+ espaço em disco
7.2 CONFIGURAÇÃO
[ ] Arquivo .env criado e configurado
[ ] JWT_SECRET gerado (não usar padrão)
[ ] ADMIN_PASSWORD alterado
[ ] CORS_ORIGIN configurado corretamente
[ ] Credenciais de gateways válidas
[ ] Logs directory criado com permissões
[ ] ecosystem.config.js configurado
[ ] docker-compose.yml configurado (se usar Docker)
7.3 BACKEND
[ ] Dependências instaladas (npm install)
[ ] node_modules sem erros
[ ] server.js inicia sem erros
[ ] Porta 3001 escutando
[ ] Health check responde 200
[ ] /api/test responde com success: true
[ ] /api/gateways lista gateways
[ ] Autenticação funciona (login + verify)
[ ] WebSocket aceita conexões
[ ] Logs sendo gerados corretamente
7.4 BOT PYTHON
[ ] Python 3.8+ instalado
[ ] requirements.txt instalado (pip install -r)
[ ] bot.py inicia sem erros
[ ] bot_api.py (Flask) rodando na porta 5000
[ ] Telegram bot responde a /start
[ ] Integração com gateways funciona
[ ] bot_dashboard_data.json sendo atualizado
[ ] Downsells configurados
7.5 FRONTEND
[ ] npm install executado
[ ] Vite dev server inicia (porta 5173)
[ ] Build de produção funciona (npm run build)
[ ] Conexão com backend estabelecida
[ ] Login funciona
[ ] Dashboard carrega dados
[ ] WebSocket conecta e atualiza em tempo real
[ ] Gestão de bots funcional
[ ] Gateways configuráveis
7.6 INTEGRAÇÃO
[ ] Bot Python -> Backend: comunicação OK
[ ] Backend -> Frontend: API OK
[ ] Backend -> Frontend: WebSocket OK
[ ] Gateways PIX: PushinPay conecta
[ ] Gateways PIX: SyncPay conecta
[ ] Fluxo completo: pagamento -> entrega funciona
[ ] Downsells sendo enviados automaticamente
[ ] Logs centralizados e legíveis
7.7 TESTES
[ ] smoke_test.py passa 100%
[ ] npm test passa todos os testes
[ ] Validação manual de endpoints OK
[ ] Teste de carga básico OK (opcional)
[ ] Teste de reconexão WebSocket OK
[ ] Teste de failover de gateways OK
7.8 MONITORAMENTO
[ ] PM2 ou Docker configurado para auto-restart
[ ] Logs rotacionados (pm2-logrotate ou Docker)
[ ] Health checks configurados
[ ] Alertas de erro configurados (opcional)
[ ] Backup automático configurado (opcional)
[ ] Monitoramento de recursos (CPU, RAM)
7.9 SEGURANÇA
[ ] Senhas padrão alteradas
[ ] JWT_SECRET forte e único
[ ] CORS configurado restritivamente
[ ] Helmet.js ativo
[ ] Rate limiting implementado (opcional)
[ ] HTTPS configurado (produção)
[ ] Firewall configurado (portas necessárias apenas)
[ ] Logs sensíveis mascarados
7.10 DOCUMENTAÇÃO
[ ] README atualizado
[ ] .env.example criado
[ ] Comandos de deploy documentados
[ ] Troubleshooting documentado
[ ] Contatos de suporte definidos

COMANDOS QUICK START
Windows (Docker - RECOMENDADO)
powershell# 1. Migrar projeto
.\migrate_project.ps1

# 2. Navegar
cd C:\projects\web-bot

# 3. Iniciar
docker-compose up -d

# 4. Validar
python smoke_test.py

# 5. Ver logs
docker-compose logs -f
Windows (PM2)
powershell# 1. Migrar projeto
.\migrate_project.ps1

# 2. Navegar
cd C:\projects\web-bot\backend

# 3. Instalar
npm install

# 4. Iniciar
pm2 start ecosystem.config.js --env production

# 5. Validar
cd ..
python smoke_test.py
Linux/WSL
bash# 1. Setup
chmod +x setup_linux.sh
./setup_linux.sh

# 2. Validar
make smoke-test

# 3. Iniciar produção
make prod

# 4. Monitorar
make logs

SUPORTE E CONTATOS
Logs para análise:
bash# Gerar pacote completo de logs
tar -czf logs_$(date +%Y%m%d_%H%M%S).tar.gz \
  backend/logs/ \
  sistema.log \
  *.log
Informações do sistema:
bash# Windows
systeminfo > system_info.txt
node --version >> system_info.txt
npm --version >> system_info.txt

# Linux
uname -a > system_info.txt
node --version >> system_info.txt
npm --version >> system_info.txt
free -h >> system_info.txt
df -h >> system_info.txt

FIM DO GUIA
Este documento contém todas as informações necessárias para:

Diagnosticar problemas
Corrigir erros permanentemente
Configurar ambiente corretamente
Validar funcionamento
Deploy em produção
Troubleshooting completo

Se todos os checklists estiverem marcados, o sistema está 100% funcional e pronto para produção.Tentar novamenteClaude ainda não tem a capacidade de executar o código que gera.O Claude pode cometer erros. Confira sempre as respostas. Sonnet 4.5