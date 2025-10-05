# Sistema Multi-Bot Telegram - Versão de Produção

## 🚀 Visão Geral

Sistema completo de gestão de múltiplos bots Telegram com dashboard web em tempo real, integração com gateways de pagamento e sistema de downsells automatizado.

## 🏗️ Arquitetura

### Frontend (React + TypeScript)
- **Porta**: 5173
- **Tecnologias**: React 18, TypeScript, Vite, Tailwind CSS, shadcn/ui
- **Funcionalidades**: Dashboard em tempo real, autenticação, gestão de bots, monitoramento de pagamentos

### Backend (Node.js + Express + Socket.io)
- **Porta**: 3001
- **Tecnologias**: Node.js, Express, Socket.io, JWT
- **Funcionalidades**: API REST, WebSocket para tempo real, autenticação, integração com bot Python

### Bot Python (API REST)
- **Porta**: 5000
- **Tecnologias**: Python 3.12, Flask, python-telegram-bot
- **Funcionalidades**: API REST para controle dos bots, integração com dados JSON

### Bot Principal (Python)
- **Tecnologias**: Python 3.12, python-telegram-bot, asyncio
- **Funcionalidades**: Gestão de 2 bots ativos, sistema de downsells, gateways de pagamento

## 📋 Pré-requisitos

### Software Necessário
- **Node.js** 18+ (com npm)
- **Python** 3.12+
- **Git** (opcional)

### Dependências Python
```bash
# Instalar dependências do bot principal
cd "Grmpay - SEM WEB"
pip install -r requirements.txt

# Instalar dependências da API
pip install -r requirements_api.txt
```

### Dependências Node.js
```bash
# Backend
cd backend
npm install

# Frontend
cd frontend
npm install
```

## 🚀 Inicialização

### Método Automático (Recomendado)
```bash
# Execute o script de inicialização
start_system.bat
```

### Método Manual

#### 1. Iniciar API do Bot
```bash
cd "Grmpay - SEM WEB"
python bot_api.py
```

#### 2. Iniciar Backend Node.js
```bash
cd backend
npm run dev
```

#### 3. Iniciar Frontend React
```bash
cd frontend
npm run dev
```

## 🔐 Autenticação

### Credenciais Padrão
- **Usuário**: `admin`
- **Senha**: `admin123`

### Configuração de Segurança
- JWT com expiração de 24h
- Rate limiting configurado
- CORS configurado para desenvolvimento

## 📊 Funcionalidades

### Dashboard Principal
- ✅ Visão geral em tempo real
- ✅ Estatísticas de usuários e pagamentos
- ✅ Status dos bots (ativo/inativo)
- ✅ Eventos recentes
- ✅ Status dos gateways de pagamento

### Gestão de Bots
- ✅ Lista de bots ativos (2 bots)
- ✅ Iniciar/parar/reiniciar bots
- ✅ Adicionar novos bots
- ✅ Monitoramento de logs
- ✅ Status de uptime

### Sistema de Pagamentos
- ✅ Integração com PushynPay e SyncPay
- ✅ Monitoramento de pagamentos pendentes
- ✅ Confirmação/cancelamento manual
- ✅ Regeneração de emails de pagamento
- ✅ Estatísticas de conversão

### Analytics
- ✅ Métricas de usuários únicos
- ✅ Taxa de conversão
- ✅ Análise de downsells
- ✅ Valor médio do ticket
- ✅ Usuários recentes

### Sistema de Downsells
- ✅ 26 sequências configuradas
- ✅ Timers automáticos
- ✅ Order bumps
- ✅ Configuração flexível de preços

## 🔧 Configuração

### Variáveis de Ambiente (Backend)
```env
NODE_ENV=production
PORT=3001
HOST=localhost
JWT_SECRET=seu_jwt_secret_muito_seguro_aqui_2024
BOT_API_URL=http://localhost:5000
BOT_DATA_FILE_PATH=../Grmpay - SEM WEB/bot_dashboard_data.json
ADMIN_USER_ID=7676333385
ADMIN_USERNAME=admin
CORS_ORIGIN=http://localhost:5173
```

### Tokens dos Bots
Os tokens estão hardcoded no arquivo `bot_api.py`. Em produção, considere:
- Usar variáveis de ambiente
- Implementar rotação de tokens
- Adicionar criptografia

## 📡 WebSocket Events

### Eventos de Dados
- `data_updated` - Atualização completa de dados
- `stats_updated` - Atualização de estatísticas
- `events_updated` - Novos eventos
- `users_updated` - Atualização de usuários
- `payments_updated` - Atualização de pagamentos
- `bot_status_updated` - Status dos bots

### Eventos de Bots
- `bot_started` - Bot iniciado
- `bot_stopped` - Bot parado
- `bot_restarted` - Bot reiniciado
- `bot_added` - Novo bot adicionado

### Eventos de Pagamentos
- `payment_confirmed` - Pagamento confirmado
- `payment_cancelled` - Pagamento cancelado
- `payment_email_regenerated` - Email regenerado

## 🔄 Fluxo de Dados

1. **Bot Python** → Atualiza `bot_dashboard_data.json`
2. **API Bot** → Expõe dados via REST
3. **Backend Node.js** → Consome API e serve WebSocket
4. **Frontend React** → Consome API e WebSocket
5. **Dashboard** → Exibe dados em tempo real

## 🛠️ Desenvolvimento

### Estrutura de Pastas
```
├── backend/                 # Backend Node.js
│   ├── src/
│   │   ├── routes/         # Rotas da API
│   │   ├── services/       # Serviços
│   │   ├── websocket/      # Handlers WebSocket
│   │   └── middleware/     # Middlewares
│   └── config/
├── frontend/               # Frontend React
│   ├── src/
│   │   ├── components/     # Componentes React
│   │   ├── hooks/          # Hooks personalizados
│   │   ├── services/       # Serviços de API
│   │   └── pages/          # Páginas
│   └── public/
├── Grmpay - SEM WEB/       # Bot Python
│   ├── bot.py             # Bot principal
│   ├── bot_api.py         # API REST
│   ├── shared_data.py     # Gerenciamento de dados
│   └── bot_dashboard_data.json
└── start_system.bat       # Script de inicialização
```

### Scripts Disponíveis

#### Backend
```bash
npm run dev    # Desenvolvimento
npm start      # Produção
```

#### Frontend
```bash
npm run dev    # Desenvolvimento
npm run build  # Build para produção
npm run preview # Preview do build
```

#### Bot API
```bash
python bot_api.py  # Iniciar API
```

## 🔍 Monitoramento

### Logs
- **Bot**: `bot.log` e `events.log`
- **Backend**: Console do Node.js
- **Frontend**: Console do navegador

### Health Checks
- **Backend**: `http://localhost:3001/health`
- **Bot API**: `http://localhost:5000/api/health`

### Métricas
- Usuários únicos em tempo real
- Taxa de conversão
- Status dos gateways
- Uptime dos bots

## 🚨 Troubleshooting

### Problemas Comuns

#### Bot não conecta
1. Verificar tokens válidos
2. Verificar conexão com internet
3. Verificar logs em `bot.log`

#### WebSocket não conecta
1. Verificar se backend está rodando na porta 3001
2. Verificar CORS configurado
3. Verificar firewall

#### API não responde
1. Verificar se bot_api.py está rodando na porta 5000
2. Verificar arquivo `bot_dashboard_data.json`
3. Verificar logs do Python

### Logs Importantes
```bash
# Logs do bot principal
tail -f "Grmpay - SEM WEB/bot.log"

# Logs de eventos
tail -f "Grmpay - SEM WEB/events.log"

# Logs do backend
# (visível no console do Node.js)
```

## 📈 Performance

### Otimizações Implementadas
- ✅ WebSocket para dados em tempo real
- ✅ Paginação em listas grandes
- ✅ Rate limiting na API
- ✅ Cache de dados no frontend
- ✅ Lazy loading de componentes

### Limites Recomendados
- Máximo 100 eventos exibidos
- Paginação de 20 usuários por página
- Rate limit de 100 requests/15min

## 🔒 Segurança

### Implementado
- ✅ JWT para autenticação
- ✅ Rate limiting
- ✅ CORS configurado
- ✅ Validação de entrada
- ✅ Sanitização de dados

### Recomendações para Produção
- [ ] HTTPS obrigatório
- [ ] Secrets em variáveis de ambiente
- [ ] Logs de auditoria
- [ ] Backup automático dos dados
- [ ] Monitoramento de segurança

## 📞 Suporte

### Contatos
- **Desenvolvedor**: Sistema Multi-Bot
- **Documentação**: Este README
- **Issues**: Logs de erro nos arquivos `.log`

### Informações do Sistema
- **Versão**: 1.0.0 (Produção)
- **Última Atualização**: 2024
- **Ambiente**: Desenvolvimento/Produção

---

**⚠️ IMPORTANTE**: Este é um sistema de produção. Certifique-se de que todas as dependências estão instaladas e os serviços estão rodando antes de usar o dashboard.
