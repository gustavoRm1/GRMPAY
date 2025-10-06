/**
 * Script de Diagnóstico do Frontend
 * Identifica problemas que podem causar tela em branco
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 DIAGNÓSTICO DO FRONTEND - TELA EM BRANCO\n');

// 1. Verificar arquivos críticos
const criticalFiles = [
  'index.html',
  'src/main.tsx',
  'src/App.tsx',
  'vite.config.ts',
  'package.json'
];

console.log('📁 Verificando arquivos críticos:');
criticalFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`   ✅ ${file}`);
  } else {
    console.log(`   ❌ ${file} - FALTANDO`);
  }
});

// 2. Verificar dependências críticas
console.log('\n📦 Verificando dependências críticas:');
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  const criticalDeps = [
    'react',
    'react-dom',
    '@vitejs/plugin-react-swc',
    'vite'
  ];
  
  criticalDeps.forEach(dep => {
    if (packageJson.dependencies[dep] || packageJson.devDependencies[dep]) {
      console.log(`   ✅ ${dep}`);
    } else {
      console.log(`   ❌ ${dep} - FALTANDO`);
    }
  });
} catch (error) {
  console.log(`   ❌ Erro ao ler package.json: ${error.message}`);
}

// 3. Verificar componentes principais
console.log('\n🧩 Verificando componentes principais:');
const components = [
  'src/components/auth/LoginForm.tsx',
  'src/components/dashboard/MultiTenantDashboard.tsx',
  'src/hooks/useAuth.ts',
  'src/services/api.ts'
];

components.forEach(component => {
  if (fs.existsSync(component)) {
    console.log(`   ✅ ${component}`);
  } else {
    console.log(`   ❌ ${component} - FALTANDO`);
  }
});

// 4. Verificar se há erros de sintaxe no App.tsx
console.log('\n🔍 Verificando sintaxe do App.tsx:');
try {
  const appContent = fs.readFileSync('src/App.tsx', 'utf8');
  
  // Verificar imports problemáticos
  if (appContent.includes('import.*from.*@/')) {
    console.log('   ✅ Path aliases encontrados');
  } else {
    console.log('   ⚠️ Path aliases não encontrados');
  }
  
  // Verificar se há componentes sendo renderizados
  if (appContent.includes('<') && appContent.includes('>')) {
    console.log('   ✅ JSX encontrado');
  } else {
    console.log('   ❌ JSX não encontrado');
  }
  
  // Verificar se há erros de sintaxe básicos
  const openBraces = (appContent.match(/\{/g) || []).length;
  const closeBraces = (appContent.match(/\}/g) || []).length;
  
  if (openBraces === closeBraces) {
    console.log('   ✅ Chaves balanceadas');
  } else {
    console.log(`   ❌ Chaves desbalanceadas: ${openBraces} abertas, ${closeBraces} fechadas`);
  }
  
} catch (error) {
  console.log(`   ❌ Erro ao verificar App.tsx: ${error.message}`);
}

// 5. Verificar configuração do Vite
console.log('\n⚙️ Verificando configuração do Vite:');
try {
  const viteConfig = fs.readFileSync('vite.config.ts', 'utf8');
  
  if (viteConfig.includes('@": path.resolve')) {
    console.log('   ✅ Path alias @ configurado');
  } else {
    console.log('   ❌ Path alias @ não configurado');
  }
  
  if (viteConfig.includes('port: 5173')) {
    console.log('   ✅ Porta 5173 configurada');
  } else {
    console.log('   ⚠️ Porta não especificada');
  }
  
} catch (error) {
  console.log(`   ❌ Erro ao verificar vite.config.ts: ${error.message}`);
}

// 6. Verificar se node_modules existe
console.log('\n📦 Verificando node_modules:');
if (fs.existsSync('node_modules')) {
  console.log('   ✅ node_modules existe');
  
  // Verificar algumas dependências críticas
  const criticalNodeModules = [
    'node_modules/react',
    'node_modules/react-dom',
    'node_modules/vite'
  ];
  
  criticalNodeModules.forEach(module => {
    if (fs.existsSync(module)) {
      console.log(`   ✅ ${path.basename(module)} instalado`);
    } else {
      console.log(`   ❌ ${path.basename(module)} não instalado`);
    }
  });
} else {
  console.log('   ❌ node_modules não existe - Execute: npm install');
}

console.log('\n🎯 POSSÍVEIS CAUSAS DA TELA EM BRANCO:');
console.log('1. ❌ Erro de JavaScript não tratado');
console.log('2. ❌ Problema com imports/export');
console.log('3. ❌ Erro de renderização do React');
console.log('4. ❌ Problema com path aliases (@/)');
console.log('5. ❌ Dependências não instaladas');
console.log('6. ❌ Erro no console do navegador');

console.log('\n🔧 SOLUÇÕES RECOMENDADAS:');
console.log('1. Abra o DevTools (F12) e verifique o Console');
console.log('2. Execute: npm install');
console.log('3. Execute: npm run dev');
console.log('4. Verifique se o backend está rodando');
console.log('5. Limpe o cache: npm run build && npm run dev');

console.log('\n📋 COMANDOS PARA TESTAR:');
console.log('npm install');
console.log('npm run dev');
console.log('// Acesse: http://localhost:5173');




