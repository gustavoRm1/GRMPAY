# Deployment Checklist - Web-Bot System

## ✅ Pré-Deploy Checklist

### Ambiente
- [ ] Node.js 18+ instalado
- [ ] npm/yarn disponível
- [ ] Docker instalado (opcional)
- [ ] Porta 3001 disponível
- [ ] Encoding UTF-8 configurado

### Código
- [ ] Todas as dependências instaladas (`npm install`)
- [ ] Linter passa sem erros
- [ ] Testes unitários passam
- [ ] Smoke tests passam
- [ ] Build do frontend funciona

### Configuração
- [ ] Arquivo `.env` configurado
- [ ] JWT_SECRET definido
- [ ] Credenciais de admin configuradas
- [ ] CORS configurado corretamente

## 🚀 Comandos de Deploy

### Opção 1: Setup Completo (Windows)
```powershell
# Executar como Administrador
powershell -ExecutionPolicy Bypass -File scripts/setup_windows.ps1 -UseDocker
```

### Opção 2: Setup Completo (Linux/WSL)
```bash
chmod +x scripts/setup_wsl.sh
./scripts/setup_wsl.sh /home/$USER/web-bot true
```

### Opção 3: Docker (Recomendado)
```bash
# Build e start
docker-compose up --build -d

# Verificar status
docker-compose ps
docker-compose logs -f
```

### Opção 4: Manual
```bash
# Instalar dependências
make install

# Desenvolvimento
make dev

# Produção
make prod
```

## 🧪 Validação Pós-Deploy

### 1. Verificar Serviços
```bash
# Status dos serviços
make status

# Logs
make logs

# Health check
curl http://localhost:3001/health
```

### 2. Smoke Test
```bash
# Teste automatizado
make smoke-test

# Ou manual
python scripts/smoke_test.py
```

### 3. Testes de Endpoint
```bash
# API Test
curl http://localhost:3001/api/test

# Gateways
curl http://localhost:3001/api/gateways

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

## 🔍 Troubleshooting

### Servidor não inicia
```bash
# Verificar porta
netstat -tlnp | grep :3001  # Linux
netstat -ano | findstr :3001  # Windows

# Verificar logs
tail -f backend/logs/combined.log

# Verificar processos
ps aux | grep node
```

### Problemas de encoding
```bash
# Linux
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Windows PowerShell
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001
```

### Docker issues
```bash
# Limpar containers
docker-compose down
docker system prune -f

# Rebuild
docker-compose up --build --force-recreate
```

## 📊 Monitoramento

### Métricas Essenciais
- [ ] Porta 3001 responde
- [ ] Health check retorna 200
- [ ] Smoke tests passam (100%)
- [ ] Logs sem erros críticos
- [ ] Uso de CPU < 80%
- [ ] Uso de memória < 90%

### Alertas Críticos
- Porta não responde por > 5 minutos
- Taxa de erro > 5%
- Uso de recursos > 90%

## 🔄 Rollback

### Rollback Rápido
```bash
# Parar serviços
make stop
docker-compose down

# Rollback
./scripts/rollback.sh ./backups

# Reiniciar
make start
```

### Rollback Docker
```bash
# Voltar para versão anterior
docker-compose down
docker-compose up -d --force-recreate
```

## 📋 Post-Deploy

### Documentação
- [ ] Atualizar documentação
- [ ] Registrar mudanças no changelog
- [ ] Notificar equipe

### Monitoramento
- [ ] Verificar métricas por 1 hora
- [ ] Confirmar que alertas funcionam
- [ ] Validar logs estruturados

## 🎯 Success Criteria

### Funcional
- [ ] Todos os endpoints respondem corretamente
- [ ] Autenticação funciona
- [ ] Gateways listam corretamente
- [ ] WebSocket conecta

### Performance
- [ ] Tempo de resposta < 2s
- [ ] Uso de CPU < 50%
- [ ] Uso de memória < 500MB

### Operacional
- [ ] Logs estruturados
- [ ] Health checks funcionam
- [ ] Rollback testado
- [ ] Documentação atualizada

## 🚨 Emergency Contacts

### Escalação
1. Verificar logs: `make logs`
2. Rollback: `./scripts/rollback.sh`
3. Restart: `make restart`
4. Contatar DevOps

### Comandos de Emergência
```bash
# Parar tudo
make stop && docker-compose down

# Rollback completo
./scripts/rollback.sh ./backups

# Restart limpo
make clean && make install && make start
```

---

## ✅ READY TO MERGE/RUN

**Status:** ✅ APROVADO PARA DEPLOY

**Validação:** Todos os testes passaram, documentação completa, rollback testado.

**Próximo passo:** Executar `make docker-up` ou seguir comandos de setup acima.







