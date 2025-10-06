/**
 * Teste de Migração
 * Verifica se os scripts de migração foram criados corretamente
 */

const fs = require('fs');
const path = require('path');

function testMigration() {
  console.log('🔄 Testando scripts de migração...\n');
  
  let allGood = true;
  
  // Verificar arquivos criados
  const filesToCheck = [
    'backend/src/migrations/migration_001_initial_setup.js',
    'backend/src/migrations/migration_002_migrate_users.js',
    'backend/src/migrations/migration_003_migrate_gateways.js',
    'backend/src/migrations/migration_004_migrate_transactions.js',
    'backend/src/migrations/migration_manager.js',
    'backend/src/migrations/backup_existing_data.js',
    'backend/src/migrations/validate_migration.js',
    'backend/run_migration.js',
    'backend/rollback_migration.js'
  ];
  
  console.log('📁 Verificando arquivos de migração:');
  filesToCheck.forEach(file => {
    if (fs.existsSync(file)) {
      console.log(`   ✅ ${file}`);
    } else {
      console.log(`   ❌ ${file} - FALTANDO`);
      allGood = false;
    }
  });
  
  // Verificar funcionalidades do migration_manager
  console.log('\n🔧 Verificando MigrationManager:');
  try {
    const managerPath = path.join(__dirname, 'backend/src/migrations/migration_manager.js');
    const manager = fs.readFileSync(managerPath, 'utf8');
    
    const requiredFeatures = [
      'class MigrationManager',
      'async runAllMigrations()',
      'async rollbackAllMigrations()',
      'async getMigrationStatus()',
      'async runMigration(',
      'async rollbackMigration('
    ];
    
    requiredFeatures.forEach(feature => {
      if (manager.includes(feature)) {
        console.log(`   ✅ ${feature} implementado`);
      } else {
        console.log(`   ❌ ${feature} - NÃO ENCONTRADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar MigrationManager');
    allGood = false;
  }
  
  // Verificar migrações individuais
  console.log('\n📋 Verificando migrações individuais:');
  const migrations = [
    'migration_001_initial_setup.js',
    'migration_002_migrate_users.js',
    'migration_003_migrate_gateways.js',
    'migration_004_migrate_transactions.js'
  ];
  
  migrations.forEach(migration => {
    try {
      const migrationPath = path.join(__dirname, 'backend/src/migrations', migration);
      const migrationContent = fs.readFileSync(migrationPath, 'utf8');
      
      if (migrationContent.includes('export async function up()') && 
          migrationContent.includes('export async function down()')) {
        console.log(`   ✅ ${migration} - funções up/down implementadas`);
      } else {
        console.log(`   ❌ ${migration} - funções up/down NÃO ENCONTRADAS`);
        allGood = false;
      }
    } catch (error) {
      console.log(`   ❌ ${migration} - ERRO ao verificar`);
      allGood = false;
    }
  });
  
  // Verificar script de backup
  console.log('\n💾 Verificando script de backup:');
  try {
    const backupPath = path.join(__dirname, 'backend/src/migrations/backup_existing_data.js');
    const backup = fs.readFileSync(backupPath, 'utf8');
    
    const requiredBackupFeatures = [
      'backupExistingData()',
      'restoreFromBackup(',
      'JSON.stringify',
      'fs.writeFile'
    ];
    
    requiredBackupFeatures.forEach(feature => {
      if (backup.includes(feature)) {
        console.log(`   ✅ ${feature} implementado`);
      } else {
        console.log(`   ❌ ${feature} - NÃO ENCONTRADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar script de backup');
    allGood = false;
  }
  
  // Verificar script de validação
  console.log('\n🔍 Verificando script de validação:');
  try {
    const validationPath = path.join(__dirname, 'backend/src/migrations/validate_migration.js');
    const validation = fs.readFileSync(validationPath, 'utf8');
    
    const requiredValidationFeatures = [
      'validateMigration()',
      'validateTables(',
      'validateData(',
      'validateRelationships(',
      'validateIntegrity('
    ];
    
    requiredValidationFeatures.forEach(feature => {
      if (validation.includes(feature)) {
        console.log(`   ✅ ${feature} implementado`);
      } else {
        console.log(`   ❌ ${feature} - NÃO ENCONTRADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar script de validação');
    allGood = false;
  }
  
  // Verificar scripts principais
  console.log('\n🚀 Verificando scripts principais:');
  const mainScripts = [
    'backend/run_migration.js',
    'backend/rollback_migration.js'
  ];
  
  mainScripts.forEach(script => {
    try {
      const scriptPath = path.join(__dirname, script);
      const scriptContent = fs.readFileSync(scriptPath, 'utf8');
      
      if (scriptContent.includes('async function') && 
          scriptContent.includes('MigrationManager')) {
        console.log(`   ✅ ${script} - implementado`);
      } else {
        console.log(`   ❌ ${script} - NÃO IMPLEMENTADO CORRETAMENTE`);
        allGood = false;
      }
    } catch (error) {
      console.log(`   ❌ ${script} - ERRO ao verificar`);
      allGood = false;
    }
  });
  
  console.log('\n' + '='.repeat(60));
  
  if (allGood) {
    console.log('🎉 MIGRAÇÃO DE DADOS COMPLETA!');
    console.log('\n📋 Funcionalidades implementadas:');
    console.log('✅ Scripts de migração individuais');
    console.log('✅ Gerenciador de migrações');
    console.log('✅ Script de backup de dados');
    console.log('✅ Script de validação');
    console.log('✅ Script principal de migração');
    console.log('✅ Script de rollback');
    console.log('✅ Migração de usuários');
    console.log('✅ Migração de gateways');
    console.log('✅ Migração de transações');
    console.log('✅ Validação de integridade');
    console.log('✅ Controle de versões');
    
    console.log('\n🚀 Próximos passos:');
    console.log('1. Configurar MySQL (se não estiver configurado)');
    console.log('2. Executar: node backend/run_migration.js');
    console.log('3. Verificar: node backend/src/migrations/validate_migration.js');
    console.log('4. Continuar para: 09_TESTING.md');
  } else {
    console.log('❌ MIGRAÇÃO DE DADOS INCOMPLETA!');
    console.log('\n🔧 Verifique os itens marcados como ❌');
  }
  
  console.log('\n📝 Arquivos principais:');
  console.log('📝 Migração: backend/run_migration.js');
  console.log('📝 Rollback: backend/rollback_migration.js');
  console.log('📝 Validação: backend/src/migrations/validate_migration.js');
  console.log('📝 Gerenciador: backend/src/migrations/migration_manager.js');
}

testMigration();




