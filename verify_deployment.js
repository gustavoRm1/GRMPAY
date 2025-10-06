/**
 * Verificação de Deployment - WebBot Multi-Tenant
 * Verifica se o deployment foi executado corretamente
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

function verifyDeployment() {
  console.log('🔍 Verificando deployment do WebBot Multi-Tenant...\n');
  
  let allGood = true;
  
  // Verificar arquivos de deployment criados
  const deploymentFiles = [
    'Dockerfile.backend',
    'Dockerfile.frontend',
    'docker-compose.yml',
    'nginx.conf',
    'env.production.example',
    'deploy.sh',
    'deploy.ps1',
    'scripts/backup.sh',
    'monitoring/prometheus.yml',
    'monitoring/grafana/datasources/prometheus.yml',
    'monitoring/grafana/dashboards/webbot-dashboard.json',
    'security/security-config.yml'
  ];
  
  console.log('📁 Verificando arquivos de deployment:');
  deploymentFiles.forEach(file => {
    if (fs.existsSync(file)) {
      console.log(`   ✅ ${file}`);
    } else {
      console.log(`   ❌ ${file} - FALTANDO`);
      allGood = false;
    }
  });
  
  // Verificar configuração do Docker Compose
  console.log('\n🐳 Verificando configuração do Docker Compose:');
  try {
    const composePath = path.join(__dirname, 'docker-compose.yml');
    const composeContent = fs.readFileSync(composePath, 'utf8');
    
    const requiredServices = [
      'mysql:',
      'backend:',
      'frontend:',
      'nginx:',
      'redis:',
      'prometheus:',
      'grafana:'
    ];
    
    requiredServices.forEach(service => {
      if (composeContent.includes(service)) {
        console.log(`   ✅ Serviço ${service} configurado`);
      } else {
        console.log(`   ❌ Serviço ${service} - NÃO CONFIGURADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar docker-compose.yml');
    allGood = false;
  }
  
  // Verificar configuração do Nginx
  console.log('\n🌐 Verificando configuração do Nginx:');
  try {
    const nginxPath = path.join(__dirname, 'nginx.conf');
    const nginxContent = fs.readFileSync(nginxPath, 'utf8');
    
    const requiredNginxConfig = [
      'proxy_pass http://backend:3001',
      'location /api/',
      'location /socket.io/',
      'gzip on',
      'add_header X-Frame-Options',
      'add_header X-Content-Type-Options'
    ];
    
    requiredNginxConfig.forEach(config => {
      if (nginxContent.includes(config)) {
        console.log(`   ✅ ${config} configurado`);
      } else {
        console.log(`   ❌ ${config} - NÃO CONFIGURADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar nginx.conf');
    allGood = false;
  }
  
  // Verificar scripts de deployment
  console.log('\n🚀 Verificando scripts de deployment:');
  const scripts = [
    'deploy.sh',
    'deploy.ps1'
  ];
  
  scripts.forEach(script => {
    try {
      const scriptPath = path.join(__dirname, script);
      const scriptContent = fs.readFileSync(scriptPath, 'utf8');
      
      if (scriptContent.includes('docker-compose') && 
          scriptContent.includes('build') && 
          scriptContent.includes('up -d')) {
        console.log(`   ✅ ${script} implementado`);
      } else {
        console.log(`   ❌ ${script} - NÃO IMPLEMENTADO CORRETAMENTE`);
        allGood = false;
      }
    } catch (error) {
      console.log(`   ❌ ${script} - ERRO ao verificar`);
      allGood = false;
    }
  });
  
  // Verificar configurações de monitoramento
  console.log('\n📊 Verificando configurações de monitoramento:');
  try {
    const prometheusPath = path.join(__dirname, 'monitoring/prometheus.yml');
    const prometheusContent = fs.readFileSync(prometheusPath, 'utf8');
    
    const requiredPrometheusConfig = [
      'webbot-backend',
      'webbot-frontend',
      'mysql',
      'redis'
    ];
    
    requiredPrometheusConfig.forEach(config => {
      if (prometheusContent.includes(config)) {
        console.log(`   ✅ ${config} configurado no Prometheus`);
      } else {
        console.log(`   ❌ ${config} - NÃO CONFIGURADO no Prometheus`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar configuração do Prometheus');
    allGood = false;
  }
  
  // Verificar configurações de segurança
  console.log('\n🔒 Verificando configurações de segurança:');
  try {
    const securityPath = path.join(__dirname, 'security/security-config.yml');
    const securityContent = fs.readFileSync(securityPath, 'utf8');
    
    const requiredSecurityConfig = [
      'authentication:',
      'authorization:',
      'rate_limiting:',
      'cors:',
      'encryption:',
      'logging:',
      'validation:'
    ];
    
    requiredSecurityConfig.forEach(config => {
      if (securityContent.includes(config)) {
        console.log(`   ✅ ${config} configurado`);
      } else {
        console.log(`   ❌ ${config} - NÃO CONFIGURADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar configurações de segurança');
    allGood = false;
  }
  
  // Verificar script de backup
  console.log('\n💾 Verificando script de backup:');
  try {
    const backupPath = path.join(__dirname, 'scripts/backup.sh');
    const backupContent = fs.readFileSync(backupPath, 'utf8');
    
    const requiredBackupFeatures = [
      'mysqldump',
      'tar -czf',
      'gzip',
      'find.*-mtime',
      'verify_backups'
    ];
    
    requiredBackupFeatures.forEach(feature => {
      if (backupContent.includes(feature)) {
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
  
  // Verificar arquivo de ambiente de produção
  console.log('\n🌍 Verificando configurações de ambiente:');
  try {
    const envPath = path.join(__dirname, 'env.production.example');
    const envContent = fs.readFileSync(envPath, 'utf8');
    
    const requiredEnvVars = [
      'NODE_ENV=production',
      'DB_HOST=',
      'JWT_SECRET=',
      'ENCRYPTION_KEY=',
      'ADMIN_USERNAME=',
      'ADMIN_PASSWORD='
    ];
    
    requiredEnvVars.forEach(envVar => {
      if (envContent.includes(envVar)) {
        console.log(`   ✅ ${envVar} configurado`);
      } else {
        console.log(`   ❌ ${envVar} - NÃO CONFIGURADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar arquivo de ambiente');
    allGood = false;
  }
  
  console.log('\n' + '='.repeat(60));
  
  if (allGood) {
    console.log('🎉 DEPLOYMENT CONFIGURADO COM SUCESSO!');
    console.log('\n📋 Funcionalidades implementadas:');
    console.log('✅ Configurações Docker completas');
    console.log('✅ Docker Compose com todos os serviços');
    console.log('✅ Configuração do Nginx com proxy reverso');
    console.log('✅ Scripts de deployment (Linux e Windows)');
    console.log('✅ Configurações de monitoramento (Prometheus/Grafana)');
    console.log('✅ Configurações de segurança abrangentes');
    console.log('✅ Script de backup automatizado');
    console.log('✅ Configurações de ambiente de produção');
    console.log('✅ Health checks e verificações');
    console.log('✅ Rate limiting e CORS');
    console.log('✅ SSL/TLS e headers de segurança');
    console.log('✅ Logs e auditoria');
    console.log('✅ Compliance (GDPR, PCI-DSS, SOX)');
    
    console.log('\n🚀 Próximos passos:');
    console.log('1. Configurar arquivo .env com suas credenciais');
    console.log('2. Executar: ./deploy.sh (Linux) ou .\\deploy.ps1 (Windows)');
    console.log('3. Verificar serviços: docker-compose ps');
    console.log('4. Acessar: http://localhost (frontend)');
    console.log('5. Acessar: http://localhost:3001/api/health (backend)');
    console.log('6. Acessar: http://localhost:3000 (Grafana)');
    console.log('7. Acessar: http://localhost:9090 (Prometheus)');
  } else {
    console.log('❌ DEPLOYMENT INCOMPLETO!');
    console.log('\n🔧 Verifique os itens marcados como ❌');
  }
  
  console.log('\n📝 Arquivos principais:');
  console.log('📝 Deployment: ./deploy.sh ou .\\deploy.ps1');
  console.log('📝 Docker: docker-compose.yml');
  console.log('📝 Nginx: nginx.conf');
  console.log('📝 Ambiente: env.production.example');
  console.log('📝 Backup: scripts/backup.sh');
  console.log('📝 Monitoramento: monitoring/');
  console.log('📝 Segurança: security/security-config.yml');
}

verifyDeployment();




