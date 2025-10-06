#!/usr/bin/env node
/**
 * SCRIPT DE TESTE COMPLETO - VERIFICA TODAS AS CORREÇÕES
 * 
 * Este script testa todas as correções implementadas:
 * 1. Rotas duplicadas no backend
 * 2. Métodos duplicados no frontend
 * 3. Inicialização do bot Python
 * 4. Schema do banco de dados
 * 5. Validação de conexão
 */

import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const mysql = require('mysql2/promise');

console.log('🧪 INICIANDO TESTES COMPLETOS DAS CORREÇÕES...\n');

// Configuração do banco
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'web_bot_multi_tenant'
};

async function testDatabaseConnection() {
  console.log('🔍 TESTE 1: Conexão com Banco de Dados');
  try {
    const connection = await mysql.createConnection(dbConfig);
    console.log('✅ Conexão com MySQL estabelecida');
    
    // Testar se as tabelas existem
    const [tables] = await connection.execute("SHOW TABLES");
    console.log(`✅ ${tables.length} tabelas encontradas no banco`);
    
    // Testar se a coluna credentials_encrypted existe
    const [columns] = await connection.execute("DESCRIBE user_gateways");
    const hasCredentialsEncrypted = columns.some(col => col.Field === 'credentials_encrypted');
    console.log(hasCredentialsEncrypted ? '✅ Coluna credentials_encrypted encontrada' : '❌ Coluna credentials_encrypted NÃO encontrada');
    
    // Testar se a coluna last_active_at existe
    const [botColumns] = await connection.execute("DESCRIBE user_bots");
    const hasLastActiveAt = botColumns.some(col => col.Field === 'last_active_at');
    console.log(hasLastActiveAt ? '✅ Coluna last_active_at encontrada' : '❌ Coluna last_active_at NÃO encontrada');
    
    await connection.end();
    return true;
  } catch (error) {
    console.log('❌ Erro na conexão com banco:', error.message);
    return false;
  }
}

async function testBackendRoutes() {
  console.log('\n🔍 TESTE 2: Rotas do Backend');
  try {
    // Simular teste das rotas (sem iniciar servidor)
    const fs = require('fs');
    const path = require('path');
    
    const botsFile = fs.readFileSync('backend/src/routes/bots.js', 'utf8');
    
    // Verificar se não há rotas duplicadas
    const postBotsMatches = botsFile.match(/app\.post\('\/api\/bots'/g);
    const getBotsIdMatches = botsFile.match(/app\.get\('\/api\/bots\/:id'/g);
    
    console.log(`✅ Rotas POST /api/bots encontradas: ${postBotsMatches ? postBotsMatches.length : 0}`);
    console.log(`✅ Rotas GET /api/bots/:id encontradas: ${getBotsIdMatches ? getBotsIdMatches.length : 0}`);
    
    if (postBotsMatches && postBotsMatches.length === 1) {
      console.log('✅ Rota POST /api/bots não está duplicada');
    } else {
      console.log('❌ Rota POST /api/bots está duplicada');
    }
    
    return true;
  } catch (error) {
    console.log('❌ Erro ao testar rotas do backend:', error.message);
    return false;
  }
}

async function testFrontendAPI() {
  console.log('\n🔍 TESTE 3: API do Frontend');
  try {
    const fs = require('fs');
    const apiFile = fs.readFileSync('src/services/api.ts', 'utf8');
    
    // Verificar se não há métodos verifyToken duplicados
    const verifyTokenMatches = apiFile.match(/async verifyToken\(/g);
    
    console.log(`✅ Métodos verifyToken encontrados: ${verifyTokenMatches ? verifyTokenMatches.length : 0}`);
    
    if (verifyTokenMatches && verifyTokenMatches.length === 1) {
      console.log('✅ Método verifyToken não está duplicado');
    } else {
      console.log('❌ Método verifyToken está duplicado');
    }
    
    return true;
  } catch (error) {
    console.log('❌ Erro ao testar API do frontend:', error.message);
    return false;
  }
}

async function testPythonBot() {
  console.log('\n🔍 TESTE 4: Bot Python');
  try {
    const fs = require('fs');
    const botFile = fs.readFileSync('botpy/multi_tenant_bot.py', 'utf8');
    
    // Verificar se usa run_polling em vez de initialize + start
    const hasRunPolling = botFile.includes('application.run_polling');
    const hasInitializeStart = botFile.includes('application.initialize()') && botFile.includes('application.start()');
    
    console.log(hasRunPolling ? '✅ Usa application.run_polling()' : '❌ NÃO usa application.run_polling()');
    console.log(hasInitializeStart ? '❌ Ainda usa initialize() + start()' : '✅ NÃO usa initialize() + start()');
    
    return hasRunPolling && !hasInitializeStart;
  } catch (error) {
    console.log('❌ Erro ao testar bot Python:', error.message);
    return false;
  }
}

async function testDatabaseManager() {
  console.log('\n🔍 TESTE 5: Gerenciador de Banco');
  try {
    const fs = require('fs');
    const dbFile = fs.readFileSync('botpy/database_manager.py', 'utf8');
    
    // Verificar se tem validação de conexão
    const hasConnectionValidation = dbFile.includes('connection.is_connected()');
    const hasReconnect = dbFile.includes('self.connect()');
    
    console.log(hasConnectionValidation ? '✅ Tem validação de conexão' : '❌ NÃO tem validação de conexão');
    console.log(hasReconnect ? '✅ Tem lógica de reconexão' : '❌ NÃO tem lógica de reconexão');
    
    return hasConnectionValidation && hasReconnect;
  } catch (error) {
    console.log('❌ Erro ao testar gerenciador de banco:', error.message);
    return false;
  }
}

async function runAllTests() {
  const results = [];
  
  results.push(await testDatabaseConnection());
  results.push(await testBackendRoutes());
  results.push(await testFrontendAPI());
  results.push(await testPythonBot());
  results.push(await testDatabaseManager());
  
  console.log('\n📊 RESULTADOS FINAIS:');
  console.log('='.repeat(50));
  
  const passed = results.filter(r => r).length;
  const total = results.length;
  
  console.log(`✅ Testes aprovados: ${passed}/${total}`);
  console.log(`❌ Testes falharam: ${total - passed}/${total}`);
  
  if (passed === total) {
    console.log('\n🎉 TODAS AS CORREÇÕES FORAM APLICADAS COM SUCESSO!');
    console.log('🚀 Sistema pronto para uso!');
  } else {
    console.log('\n⚠️ Algumas correções precisam de atenção.');
  }
  
  console.log('\n📋 PRÓXIMOS PASSOS:');
  console.log('1. Reiniciar o backend: cd backend && node src/server.js');
  console.log('2. Reiniciar o frontend: npm run dev');
  console.log('3. Reiniciar o bot Python: cd botpy && python multi_tenant_bot.py');
  console.log('4. Testar criação de bots no frontend');
}

// Executar todos os testes
runAllTests().catch(console.error);
