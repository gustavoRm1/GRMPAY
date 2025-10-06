/**
 * Script para verificar e criar usuário admin
 */

import mysql from 'mysql2/promise';
import bcrypt from 'bcryptjs';

const dbConfig = {
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '', // Sem senha para XAMPP
  database: 'web_bot_multi_tenant'
};

async function checkAndCreateAdmin() {
  console.log('🔍 Verificando usuário admin...');
  
  try {
    const connection = await mysql.createConnection(dbConfig);
    console.log('✅ Conectado ao banco de dados');
    
    // Verificar se o admin existe
    const [rows] = await connection.execute(
      'SELECT id, username, email, role FROM users WHERE username = ?',
      ['admin']
    );
    
    if (rows.length > 0) {
      console.log('✅ Usuário admin encontrado:', rows[0]);
      
      // Verificar se a senha está correta
      const admin = rows[0];
      const testPassword = 'admin123';
      
      // Tentar fazer login via API para testar
      console.log('🧪 Testando login via API...');
      try {
        const response = await fetch('http://localhost:3001/api/auth/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            username: 'admin',
            password: 'admin123'
          })
        });
        
        const result = await response.json();
        
        if (result.success) {
          console.log('✅ Login via API funcionando!');
          console.log('Token:', result.token.substring(0, 20) + '...');
          console.log('Usuário:', result.user);
        } else {
          console.log('❌ Login via API falhou:', result.error);
          
          // Recriar usuário admin com senha correta
          console.log('🔄 Recriando usuário admin...');
          await connection.execute('DELETE FROM users WHERE username = ?', ['admin']);
          
          const hashedPassword = await bcrypt.hash('admin123', 12);
          await connection.execute(
            'INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)',
            ['admin', 'admin@webbot.com', hashedPassword, 'admin']
          );
          
          console.log('✅ Usuário admin recriado com sucesso!');
          
          // Testar login novamente
          const response2 = await fetch('http://localhost:3001/api/auth/login', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              username: 'admin',
              password: 'admin123'
            })
          });
          
          const result2 = await response2.json();
          
          if (result2.success) {
            console.log('✅ Login funcionando após recriação!');
          } else {
            console.log('❌ Ainda falhando após recriação:', result2.error);
          }
        }
        
      } catch (apiError) {
        console.log('❌ Erro ao testar API:', apiError.message);
      }
      
    } else {
      console.log('❌ Usuário admin não encontrado');
      console.log('🔄 Criando usuário admin...');
      
      const hashedPassword = await bcrypt.hash('admin123', 12);
      const [result] = await connection.execute(
        'INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)',
        ['admin', 'admin@webbot.com', hashedPassword, 'admin']
      );
      
      console.log('✅ Usuário admin criado com sucesso! ID:', result.insertId);
      
      // Testar login
      console.log('🧪 Testando login...');
      try {
        const response = await fetch('http://localhost:3001/api/auth/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            username: 'admin',
            password: 'admin123'
          })
        });
        
        const result = await response.json();
        
        if (result.success) {
          console.log('✅ Login funcionando!');
        } else {
          console.log('❌ Login falhou:', result.error);
        }
        
      } catch (apiError) {
        console.log('❌ Erro ao testar login:', apiError.message);
      }
    }
    
    await connection.end();
    console.log('🎉 Verificação concluída!');
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  }
}

checkAdmin();



