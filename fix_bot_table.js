import mysql from 'mysql2/promise';

async function fixBotTable() {
  let connection;
  
  try {
    console.log('🔧 Conectando ao banco de dados...');
    connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'web_bot_multi_tenant'
    });

    console.log('✅ Conectado ao banco de dados');

    // Adicionar coluna last_active_at se não existir
    try {
      await connection.execute(`
        ALTER TABLE user_bots 
        ADD COLUMN last_active_at TIMESTAMP NULL DEFAULT NULL
      `);
      console.log('✅ Coluna last_active_at adicionada');
    } catch (error) {
      if (error.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️ Coluna last_active_at já existe');
      } else {
        throw error;
      }
    }

    // Verificar estrutura da tabela
    const [columns] = await connection.execute(`
      DESCRIBE user_bots
    `);
    
    console.log('\n📊 Estrutura da tabela user_bots:');
    columns.forEach(col => {
      console.log(`  - ${col.Field}: ${col.Type} ${col.Null === 'YES' ? '(NULL)' : '(NOT NULL)'}`);
    });

    console.log('\n✅ Tabela user_bots corrigida com sucesso!');

  } catch (error) {
    console.error('❌ Erro:', error.message);
  } finally {
    if (connection) {
      await connection.end();
      console.log('🔌 Desconectado do banco de dados');
    }
  }
}

fixBotTable();



