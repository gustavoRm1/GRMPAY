/**
 * Script para configurar o banco de dados diretamente
 * Usa mysql2 para conectar e criar as tabelas
 */

import mysql from 'mysql2/promise';

const dbConfig = {
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '', // Sem senha para XAMPP
  multipleStatements: true
};

const schemaSQL = `
CREATE DATABASE IF NOT EXISTS web_bot_multi_tenant;
USE web_bot_multi_tenant;

CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'user') DEFAULT 'user',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  INDEX idx_username (username),
  INDEX idx_email (email),
  INDEX idx_role (role)
);

CREATE TABLE IF NOT EXISTS user_gateways (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  gateway_type VARCHAR(50) NOT NULL,
  credentials_encrypted TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_used TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE (user_id, gateway_type)
);

CREATE TABLE IF NOT EXISTS transactions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  gateway_id INT NOT NULL,
  transaction_id_gateway VARCHAR(255) UNIQUE NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'BRL',
  status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'pending',
  description TEXT,
  webhook_url VARCHAR(255),
  client_info JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gateway_id) REFERENCES user_gateways(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_bots (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  config JSON,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  action VARCHAR(255) NOT NULL,
  details JSON,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Criar usuário admin
INSERT IGNORE INTO users (username, email, password_hash, role) 
VALUES ('admin', 'admin@webbot.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4Q7VqBv8m2', 'admin');
`;

async function setupDatabase() {
  console.log('🗄️ Configurando banco de dados...');
  
  try {
    // Conectar ao MySQL
    console.log('🔌 Conectando ao MySQL...');
    const connection = await mysql.createConnection(dbConfig);
    console.log('✅ Conectado ao MySQL com sucesso!');
    
    // Executar schema
    console.log('📝 Criando banco e tabelas...');
    await connection.execute(schemaSQL);
    console.log('✅ Banco e tabelas criados com sucesso!');
    
    // Testar conexão com o banco específico
    console.log('🧪 Testando conexão com o banco...');
    const [rows] = await connection.execute('SELECT COUNT(*) as count FROM users');
    console.log('✅ Teste de conexão bem-sucedido!');
    console.log(`📊 Usuários encontrados: ${rows[0].count}`);
    
    // Fechar conexão
    await connection.end();
    
    console.log('🎉 Banco de dados configurado com sucesso!');
    console.log('\n📋 Próximos passos:');
    console.log('1. Configure o arquivo backend/.env');
    console.log('2. Execute: cd backend && npm run dev');
    console.log('3. Execute: npm run dev (frontend)');
    console.log('4. Acesse: http://localhost:5173');
    
  } catch (error) {
    console.error('❌ Erro ao configurar banco:', error.message);
    console.log('\n🔧 Soluções possíveis:');
    console.log('1. Verifique se o MySQL está rodando no XAMPP');
    console.log('2. Verifique se a porta 3306 está livre');
    console.log('3. Tente: mysql -u root -p (sem senha)');
  }
}

setupDatabase();




