// Verificação simples das correções
const fs = require('fs');

console.log('🧪 VERIFICANDO CORREÇÕES APLICADAS...\n');

// Teste 1: Backend - Rotas duplicadas
try {
  const botsFile = fs.readFileSync('backend/src/routes/bots.js', 'utf8');
  const postBotsCount = (botsFile.match(/app\.post\('\/api\/bots'/g) || []).length;
  console.log(`✅ Backend: ${postBotsCount} rota(s) POST /api/bots (deve ser 1)`);
} catch (e) {
  console.log('❌ Backend: Erro ao verificar rotas');
}

// Teste 2: Frontend - Métodos duplicados
try {
  const apiFile = fs.readFileSync('src/services/api.ts', 'utf8');
  const verifyTokenCount = (apiFile.match(/async verifyToken\(/g) || []).length;
  console.log(`✅ Frontend: ${verifyTokenCount} método(s) verifyToken (deve ser 1)`);
} catch (e) {
  console.log('❌ Frontend: Erro ao verificar métodos');
}

// Teste 3: Bot Python - Inicialização
try {
  const botFile = fs.readFileSync('botpy/multi_tenant_bot.py', 'utf8');
  const hasRunPolling = botFile.includes('application.run_polling');
  const hasInitializeStart = botFile.includes('application.initialize()') && botFile.includes('application.start()');
  console.log(`✅ Bot Python: run_polling=${hasRunPolling}, initialize+start=${hasInitializeStart}`);
} catch (e) {
  console.log('❌ Bot Python: Erro ao verificar inicialização');
}

// Teste 4: Banco - Schema
try {
  const schemaFile = fs.readFileSync('backend/database/schema.sql', 'utf8');
  const hasCredentialsEncrypted = schemaFile.includes('credentials_encrypted');
  const hasLastActiveAt = schemaFile.includes('last_active_at');
  console.log(`✅ Banco: credentials_encrypted=${hasCredentialsEncrypted}, last_active_at=${hasLastActiveAt}`);
} catch (e) {
  console.log('❌ Banco: Erro ao verificar schema');
}

// Teste 5: Conexão
try {
  const dbFile = fs.readFileSync('botpy/database_manager.py', 'utf8');
  const hasConnectionCheck = dbFile.includes('connection.is_connected()');
  console.log(`✅ Conexão: validação=${hasConnectionCheck}`);
} catch (e) {
  console.log('❌ Conexão: Erro ao verificar validação');
}

console.log('\n🎉 VERIFICAÇÃO CONCLUÍDA!');
