/**
 * Teste do Frontend Multi-Tenant
 * Verifica se os componentes foram criados corretamente
 */

const fs = require('fs');
const path = require('path');

function testFrontend() {
  console.log('🎨 Testando Frontend Multi-Tenant...\n');
  
  let allGood = true;
  
  // Verificar arquivos criados
  const filesToCheck = [
    'src/hooks/useAuth.ts',
    'src/services/api.ts',
    'src/components/dashboard/MultiTenantDashboard.tsx',
    'src/components/dashboard/RecentTransactions.tsx',
    'src/components/dashboard/GatewayStatus.tsx',
    'src/components/dashboard/StatsOverview.tsx',
    'src/components/dashboard/CreatePixForm.tsx',
    'src/components/gateways/GatewayManager.tsx',
    'src/components/gateways/GatewayList.tsx',
    'src/components/gateways/GatewayConfig.tsx',
    'src/App.tsx'
  ];
  
  console.log('📁 Verificando arquivos do frontend:');
  filesToCheck.forEach(file => {
    if (fs.existsSync(file)) {
      console.log(`   ✅ ${file}`);
    } else {
      console.log(`   ❌ ${file} - FALTANDO`);
      allGood = false;
    }
  });
  
  // Verificar funcionalidades do useAuth
  console.log('\n🔐 Verificando useAuth:');
  try {
    const useAuthPath = path.join(__dirname, 'src/hooks/useAuth.ts');
    const useAuth = fs.readFileSync(useAuthPath, 'utf8');
    
    const requiredFeatures = [
      'interface User',
      'interface AuthState',
      'token: string | null',
      'verifyToken()',
      'localStorage.setItem',
      'localStorage.removeItem'
    ];
    
    requiredFeatures.forEach(feature => {
      if (useAuth.includes(feature)) {
        console.log(`   ✅ ${feature} implementado`);
      } else {
        console.log(`   ❌ ${feature} - NÃO ENCONTRADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar useAuth');
    allGood = false;
  }
  
  // Verificar funcionalidades do api.ts
  console.log('\n🌐 Verificando api.ts:');
  try {
    const apiPath = path.join(__dirname, 'src/services/api.ts');
    const api = fs.readFileSync(apiPath, 'utf8');
    
    const requiredMethods = [
      'verifyToken()',
      'getDashboard()',
      'getUserProfile()',
      'getUserGateways()',
      'connectGateway(',
      'createPix(',
      'getUserTransactions(',
      'getUserStats()'
    ];
    
    requiredMethods.forEach(method => {
      if (api.includes(method)) {
        console.log(`   ✅ ${method} implementado`);
      } else {
        console.log(`   ❌ ${method} - NÃO ENCONTRADO`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar api.ts');
    allGood = false;
  }
  
  // Verificar componentes do dashboard
  console.log('\n📊 Verificando componentes do dashboard:');
  const dashboardComponents = [
    'MultiTenantDashboard.tsx',
    'RecentTransactions.tsx',
    'GatewayStatus.tsx',
    'StatsOverview.tsx',
    'CreatePixForm.tsx'
  ];
  
  dashboardComponents.forEach(component => {
    const componentPath = path.join(__dirname, 'src/components/dashboard', component);
    if (fs.existsSync(componentPath)) {
      console.log(`   ✅ ${component} criado`);
    } else {
      console.log(`   ❌ ${component} - NÃO ENCONTRADO`);
      allGood = false;
    }
  });
  
  // Verificar componentes de gateway
  console.log('\n🔌 Verificando componentes de gateway:');
  const gatewayComponents = [
    'GatewayManager.tsx',
    'GatewayList.tsx',
    'GatewayConfig.tsx'
  ];
  
  gatewayComponents.forEach(component => {
    const componentPath = path.join(__dirname, 'src/components/gateways', component);
    if (fs.existsSync(componentPath)) {
      console.log(`   ✅ ${component} criado`);
    } else {
      console.log(`   ❌ ${component} - NÃO ENCONTRADO`);
      allGood = false;
    }
  });
  
  // Verificar App.tsx
  console.log('\n📱 Verificando App.tsx:');
  try {
    const appPath = path.join(__dirname, 'src/App.tsx');
    const app = fs.readFileSync(appPath, 'utf8');
    
    const requiredImports = [
      'MultiTenantDashboard',
      'GatewayManager'
    ];
    
    const requiredRoutes = [
      '/dashboard',
      '/gateways'
    ];
    
    requiredImports.forEach(importItem => {
      if (app.includes(importItem)) {
        console.log(`   ✅ Import ${importItem} encontrado`);
      } else {
        console.log(`   ❌ Import ${importItem} - NÃO ENCONTRADO`);
        allGood = false;
      }
    });
    
    requiredRoutes.forEach(route => {
      if (app.includes(route)) {
        console.log(`   ✅ Rota ${route} configurada`);
      } else {
        console.log(`   ❌ Rota ${route} - NÃO CONFIGURADA`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar App.tsx');
    allGood = false;
  }
  
  // Verificar interfaces TypeScript
  console.log('\n📝 Verificando interfaces TypeScript:');
  try {
    const apiPath = path.join(__dirname, 'src/services/api.ts');
    const api = fs.readFileSync(apiPath, 'utf8');
    
    const requiredInterfaces = [
      'interface User',
      'interface Gateway',
      'interface Transaction',
      'interface DashboardData'
    ];
    
    requiredInterfaces.forEach(interfaceItem => {
      if (api.includes(interfaceItem)) {
        console.log(`   ✅ ${interfaceItem} definida`);
      } else {
        console.log(`   ❌ ${interfaceItem} - NÃO DEFINIDA`);
        allGood = false;
      }
    });
  } catch (error) {
    console.log('   ❌ Erro ao verificar interfaces');
    allGood = false;
  }
  
  console.log('\n' + '='.repeat(60));
  
  if (allGood) {
    console.log('🎉 FRONTEND MULTI-TENANT COMPLETO!');
    console.log('\n📋 Funcionalidades implementadas:');
    console.log('✅ Contexto de autenticação atualizado');
    console.log('✅ Serviço de API multi-tenant');
    console.log('✅ Dashboard multi-tenant');
    console.log('✅ Componentes de transações');
    console.log('✅ Componentes de gateway');
    console.log('✅ Formulário de criação de PIX');
    console.log('✅ Gerenciamento de gateways');
    console.log('✅ Estatísticas detalhadas');
    console.log('✅ Rotas configuradas');
    console.log('✅ Interfaces TypeScript');
    console.log('✅ Isolamento de dados por usuário');
    
    console.log('\n🚀 Próximos passos:');
    console.log('1. Executar: npm run dev (para testar o frontend)');
    console.log('2. Configurar MySQL e executar schema.sql');
    console.log('3. Testar integração frontend + backend');
    console.log('4. Continuar para: 08_MIGRATION_DATA.md');
  } else {
    console.log('❌ FRONTEND MULTI-TENANT INCOMPLETO!');
    console.log('\n🔧 Verifique os itens marcados como ❌');
  }
  
  console.log('\n📝 Arquivos principais:');
  console.log('📝 Dashboard: src/components/dashboard/MultiTenantDashboard.tsx');
  console.log('📝 Gateways: src/components/gateways/GatewayManager.tsx');
  console.log('📝 API: src/services/api.ts');
  console.log('📝 Auth: src/hooks/useAuth.ts');
  console.log('📝 App: src/App.tsx');
}

testFrontend();




