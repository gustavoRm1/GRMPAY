# Sistema Multi-Bot Telegram

## 📁 Arquivos Essenciais

### 🚀 Scripts de Controle
- **`INICIAR.bat`** - Inicia todo o sistema (Frontend, Backend, Bot)
- **`PARAR.bat`** - Para todos os serviços
- **`DIAGNOSTICO.bat`** - Diagnostica problemas do sistema

## 🎯 Como Usar

### 1. Iniciar o Sistema
```
Duplo clique em: INICIAR.bat
```
- Instala dependências automaticamente
- Inicia todos os serviços
- Abre 3 janelas (Frontend, Backend, Bot)

### 2. Acessar o Dashboard
```
URL: http://localhost:5173
Login: admin
Senha: admin123
```

### 3. Parar o Sistema
```
Duplo clique em: PARAR.bat
```

### 4. Diagnosticar Problemas
```
Duplo clique em: DIAGNOSTICO.bat
```

## 🌐 URLs dos Serviços

- **Frontend:** http://localhost:5173
- **Backend API:** http://localhost:3001
- **Bot API:** http://localhost:5000

## 📊 Recursos do Sistema

- ✅ Dashboard em tempo real
- ✅ Controle de bots Telegram
- ✅ Gestão de usuários
- ✅ Monitoramento de pagamentos
- ✅ Estatísticas detalhadas
- ✅ WebSocket para atualizações live

## 🔧 Solução de Problemas

Se algo não funcionar:

1. Execute `DIAGNOSTICO.bat`
2. Verifique se as portas 3001, 5000, 5173 estão livres
3. Execute `PARAR.bat` e depois `INICIAR.bat`
4. Verifique se Node.js e Python estão instalados

## 📝 Logs

- Logs do sistema: `sistema.log`
- Logs do backend: Console da janela "Backend API"
- Logs do bot: Console da janela "Bot Python API"




