/**
 * Script para verificar status do sistema
 */

console.log('🔍 Verificando status do sistema WebBot Multi-Tenant...\n');

// Verificar se o arquivo api.ts foi corrigido
const fs = require('fs');
const path = require('path');

try {
  const apiPath = path.join(__dirname, 'src', 'services', 'api.ts');
  const apiContent = fs.readFileSync(apiPath, 'utf8');
  
  // Verificar se ainda há propriedades órfãs
  if (apiContent.includes('first_seen: string;') || apiContent.includes('last_seen: string;')) {
    console.log('❌ Ainda há propriedades órfãs no api.ts');
  } else {
    console.log('✅ Arquivo api.ts corrigido - sem propriedades órfãs');
  }
  
  // Verificar estrutura das interfaces
  const interfaceMatches = apiContent.match(/export interface \w+/g);
  if (interfaceMatches) {
    console.log(`✅ ${interfaceMatches.length} interfaces encontradas`);
    console.log('   Interfaces:', interfaceMatches.map(i => i.replace('export interface ', '')).join(', '));
  }
  
} catch (error) {
  console.log('❌ Erro ao verificar api.ts:', error.message);
}

console.log('\n🎉 Verificação concluída!');
console.log('\n📋 Para testar o sistema:');
console.log('1. Backend: cd backend && npm run dev');
console.log('2. Frontend: npm run dev');
console.log('3. Acessar: http://localhost:5173');




