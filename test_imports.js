/**
 * Script para testar imports e identificar problemas
 */

console.log('🔍 Testando imports do backend...\n');

// Testar imports básicos
try {
  console.log('📦 Testando import do config...');
  const { config } = await import('./backend/config/env.js');
  console.log('✅ Config importado com sucesso');
  console.log('   - NODE_ENV:', config.NODE_ENV);
  console.log('   - PORT:', config.PORT);
} catch (error) {
  console.log('❌ Erro ao importar config:', error.message);
}

// Testar import do database
try {
  console.log('\n📦 Testando import do database...');
  await import('./backend/src/config/database.js');
  console.log('✅ Database importado com sucesso');
} catch (error) {
  console.log('❌ Erro ao importar database:', error.message);
}

// Testar import dos modelos
try {
  console.log('\n📦 Testando import dos modelos...');
  const { User } = await import('./backend/src/models/User.js');
  const { UserGateway } = await import('./backend/src/models/UserGateway.js');
  const { Transaction } = await import('./backend/src/models/Transaction.js');
  console.log('✅ Modelos importados com sucesso');
} catch (error) {
  console.log('❌ Erro ao importar modelos:', error.message);
}

// Testar import dos serviços
try {
  console.log('\n📦 Testando import dos serviços...');
  const { MultiTenantPixService, multiTenantPixService } = await import('./backend/src/services/MultiTenantPixService.js');
  const { gatewayService } = await import('./backend/src/services/GatewayService.js');
  console.log('✅ Serviços importados com sucesso');
  console.log('   - MultiTenantPixService:', typeof MultiTenantPixService);
  console.log('   - multiTenantPixService:', typeof multiTenantPixService);
  console.log('   - gatewayService:', typeof gatewayService);
} catch (error) {
  console.log('❌ Erro ao importar serviços:', error.message);
}

// Testar import do server
try {
  console.log('\n📦 Testando import do server...');
  await import('./backend/src/server.js');
  console.log('✅ Server importado com sucesso');
} catch (error) {
  console.log('❌ Erro ao importar server:', error.message);
}

console.log('\n🎉 Teste de imports concluído!');




