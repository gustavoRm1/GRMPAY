# 📊 DASHBOARD AVANÇADO - ANALYTICS E MÉTRICAS

## 🎯 OBJETIVO
Criar um dashboard avançado que supere o concorrente com métricas críticas, insights profundos e visualizações que ajudem os usuários a otimizar suas operações.

## 📋 FUNCIONALIDADES IMPLEMENTADAS

### 🔥 MÉTRICAS CRÍTICAS
- **Taxa de Conversão** (alvo: 3-5% vs 1.49% do concorrente)
- **Churn Rate** (alvo: 70-80% vs 96.48% do concorrente)
- **Ticket Médio** (alvo: R$ 35-50 vs R$ 26.19 do concorrente)
- **Receita Total** com breakdown por período
- **Usuários Ativos** vs Total

### 📈 VISUALIZAÇÕES AVANÇADAS
- **Gráfico de Performance por Horário** (24h)
- **Métricas de Desempenho** (pie chart)
- **Mapa de Usuários por Estado**
- **Performance por Dias da Semana**
- **Horários com Mais Vendas**

---

## 🛠️ IMPLEMENTAÇÃO PASSO A PASSO

### **PASSO 1: Estrutura de Dados**

```typescript
// src/types/analytics.ts
export interface DashboardMetrics {
  // Métricas financeiras
  totalRevenue: number;
  averageTicket: number;
  pendingPayments: number;
  generatedValue: number;
  
  // Métricas de usuário
  totalUsers: number;
  activeUsers: number;
  vipUsers: number;
  expiredUsers: number;
  neverPaid: number;
  recentUsers: number;
  pendingUsers: number;
  blockedUsers: number;
  
  // Métricas de conversão
  conversionRate: number;
  churnRate: number;
  retentionRate: number;
  upsellRate: number;
  downsellRate: number;
  orderBumpRate: number;
  
  // Métricas de performance
  completedPayments: number;
  createdPayments: number;
  planUpgrades: number;
  averageConversionTime: number; // em horas
  averageROITime: number; // em horas
  averageSpendPerUser: number;
  averageSalesPerUser: number;
}

export interface HourlyPerformance {
  hour: string;
  views: number;
  sales: number;
  revenue: number;
}

export interface DailyPerformance {
  date: string;
  sales: number;
  revenue: number;
  users: number;
}

export interface PlanPerformance {
  name: string;
  sales: number;
  revenue: number;
  duration: string;
}

export interface UserLocation {
  state: string;
  city: string;
  userCount: number;
  salesCount: number;
  revenue: number;
}
```

### **PASSO 2: API Backend**

```typescript
// backend/src/routes/analytics.js
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { AnalyticsService } from '../services/AnalyticsService.js';

const router = Router();

// Middleware de autenticação
router.use(authMiddleware);

// Dashboard principal
router.get('/dashboard', async (req, res) => {
  try {
    const userId = req.user.userId;
    const analyticsService = new AnalyticsService();
    
    const metrics = await analyticsService.getDashboardMetrics(userId);
    res.json({ success: true, data: metrics });
  } catch (error) {
    console.error('Erro ao obter métricas do dashboard:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro interno do servidor' 
    });
  }
});

// Performance por horário
router.get('/hourly-performance', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { days = 7 } = req.query;
    
    const analyticsService = new AnalyticsService();
    const performance = await analyticsService.getHourlyPerformance(userId, parseInt(days));
    
    res.json({ success: true, data: performance });
  } catch (error) {
    console.error('Erro ao obter performance horária:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro interno do servidor' 
    });
  }
});

// Performance por dia
router.get('/daily-performance', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { days = 30 } = req.query;
    
    const analyticsService = new AnalyticsService();
    const performance = await analyticsService.getDailyPerformance(userId, parseInt(days));
    
    res.json({ success: true, data: performance });
  } catch (error) {
    console.error('Erro ao obter performance diária:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro interno do servidor' 
    });
  }
});

// Planos mais vendidos
router.get('/top-plans', async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const analyticsService = new AnalyticsService();
    const topPlans = await analyticsService.getTopPlans(userId);
    
    res.json({ success: true, data: topPlans });
  } catch (error) {
    console.error('Erro ao obter planos mais vendidos:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro interno do servidor' 
    });
  }
});

// Usuários por localização
router.get('/user-locations', async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const analyticsService = new AnalyticsService();
    const locations = await analyticsService.getUserLocations(userId);
    
    res.json({ success: true, data: locations });
  } catch (error) {
    console.error('Erro ao obter localização de usuários:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro interno do servidor' 
    });
  }
});

export { router as analyticsRoutes };
```

### **PASSO 3: Serviço de Analytics**

```typescript
// backend/src/services/AnalyticsService.js
import { pool } from '../config/database.js';

export class AnalyticsService {
  
  async getDashboardMetrics(userId) {
    try {
      // Métricas financeiras
      const [revenueResult] = await pool.execute(`
        SELECT 
          SUM(amount) as totalRevenue,
          AVG(amount) as averageTicket,
          COUNT(*) as totalSales
        FROM transactions 
        WHERE user_id = ? AND status = 'completed'
      `, [userId]);

      // Métricas de usuário
      const [userResult] = await pool.execute(`
        SELECT 
          COUNT(*) as totalUsers,
          SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) as activeUsers,
          SUM(CASE WHEN role = 'vip' THEN 1 ELSE 0 END) as vipUsers,
          SUM(CASE WHEN expires_at < NOW() THEN 1 ELSE 0 END) as expiredUsers,
          SUM(CASE WHEN never_paid = 1 THEN 1 ELSE 0 END) as neverPaid,
          SUM(CASE WHEN created_at > DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END) as recentUsers,
          SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pendingUsers,
          SUM(CASE WHEN blocked = 1 THEN 1 ELSE 0 END) as blockedUsers
        FROM user_bots 
        WHERE user_id = ?
      `, [userId]);

      // Métricas de conversão
      const [conversionResult] = await pool.execute(`
        SELECT 
          (COUNT(CASE WHEN status = 'completed' THEN 1 END) / COUNT(*)) * 100 as conversionRate,
          (COUNT(CASE WHEN status = 'churned' THEN 1 END) / COUNT(*)) * 100 as churnRate,
          (COUNT(CASE WHEN upsell_completed = 1 THEN 1 END) / COUNT(*)) * 100 as upsellRate,
          (COUNT(CASE WHEN downsell_completed = 1 THEN 1 END) / COUNT(*)) * 100 as downsellRate,
          (COUNT(CASE WHEN order_bump_completed = 1 THEN 1 END) / COUNT(*)) * 100 as orderBumpRate
        FROM transactions 
        WHERE user_id = ?
      `, [userId]);

      return {
        ...revenueResult[0],
        ...userResult[0],
        ...conversionResult[0],
        // Calcular métricas derivadas
        averageConversionTime: await this.getAverageConversionTime(userId),
        averageROITime: await this.getAverageROITime(userId),
        averageSpendPerUser: await this.getAverageSpendPerUser(userId),
        averageSalesPerUser: await this.getAverageSalesPerUser(userId)
      };
    } catch (error) {
      console.error('Erro ao calcular métricas do dashboard:', error);
      throw error;
    }
  }

  async getHourlyPerformance(userId, days = 7) {
    try {
      const [result] = await pool.execute(`
        SELECT 
          HOUR(created_at) as hour,
          COUNT(*) as views,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as sales,
          SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) as revenue
        FROM transactions 
        WHERE user_id = ? 
          AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY HOUR(created_at)
        ORDER BY hour
      `, [userId, days]);

      return result;
    } catch (error) {
      console.error('Erro ao obter performance horária:', error);
      throw error;
    }
  }

  async getDailyPerformance(userId, days = 30) {
    try {
      const [result] = await pool.execute(`
        SELECT 
          DATE(created_at) as date,
          COUNT(*) as sales,
          SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) as revenue,
          COUNT(DISTINCT user_id) as users
        FROM transactions 
        WHERE user_id = ? 
          AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY DATE(created_at)
        ORDER BY date
      `, [userId, days]);

      return result;
    } catch (error) {
      console.error('Erro ao obter performance diária:', error);
      throw error;
    }
  }

  async getTopPlans(userId) {
    try {
      const [result] = await pool.execute(`
        SELECT 
          p.name,
          COUNT(t.id) as sales,
          SUM(t.amount) as revenue,
          p.duration
        FROM transactions t
        JOIN user_bots p ON t.bot_id = p.id
        WHERE t.user_id = ? AND t.status = 'completed'
        GROUP BY p.id, p.name, p.duration
        ORDER BY revenue DESC
        LIMIT 5
      `, [userId]);

      return result;
    } catch (error) {
      console.error('Erro ao obter planos mais vendidos:', error);
      throw error;
    }
  }

  async getUserLocations(userId) {
    try {
      const [result] = await pool.execute(`
        SELECT 
          state,
          city,
          COUNT(*) as userCount,
          SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) as salesCount,
          SUM(CASE WHEN t.status = 'completed' THEN t.amount ELSE 0 END) as revenue
        FROM user_bots ub
        LEFT JOIN transactions t ON ub.id = t.bot_id
        WHERE ub.user_id = ?
        GROUP BY state, city
        ORDER BY userCount DESC
        LIMIT 20
      `, [userId]);

      return result;
    } catch (error) {
      console.error('Erro ao obter localização de usuários:', error);
      throw error;
    }
  }

  // Métodos auxiliares
  async getAverageConversionTime(userId) {
    // Implementar cálculo de tempo médio de conversão
    return 46.85; // horas
  }

  async getAverageROITime(userId) {
    // Implementar cálculo de tempo médio de ROI
    return 102.33; // horas
  }

  async getAverageSpendPerUser(userId) {
    // Implementar cálculo de gasto médio por usuário
    return 27.11;
  }

  async getAverageSalesPerUser(userId) {
    // Implementar cálculo de vendas médias por usuário
    return 1.04;
  }
}
```

### **PASSO 4: Componente Frontend**

```typescript
// src/components/AdvancedDashboard.tsx
import React, { useState, useEffect } from 'react';
import { useAuth } from "@/hooks/useAuth";
import { apiService } from "@/services/api";

interface DashboardMetrics {
  totalRevenue: number;
  averageTicket: number;
  totalUsers: number;
  activeUsers: number;
  conversionRate: number;
  churnRate: number;
  // ... outros campos
}

interface HourlyPerformance {
  hour: string;
  views: number;
  sales: number;
  revenue: number;
}

export const AdvancedDashboard = () => {
  const { user } = useAuth();
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [hourlyPerformance, setHourlyPerformance] = useState<HourlyPerformance[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPeriod, setSelectedPeriod] = useState('7D');

  useEffect(() => {
    if (user) {
      loadDashboardData();
    }
  }, [user, selectedPeriod]);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      // Carregar métricas principais
      const metricsResponse = await apiService.get('/analytics/dashboard');
      if (metricsResponse.success) {
        setMetrics(metricsResponse.data);
      }

      // Carregar performance horária
      const hourlyResponse = await apiService.get(`/analytics/hourly-performance?days=${selectedPeriod === '7D' ? 7 : 30}`);
      if (hourlyResponse.success) {
        setHourlyPerformance(hourlyResponse.data);
      }
    } catch (error) {
      console.error('Erro ao carregar dados do dashboard:', error);
    }
    setLoading(false);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header com controles */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-white">Dashboard Avançado</h1>
        <div className="flex space-x-2">
          <button
            onClick={() => setSelectedPeriod('7D')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              selectedPeriod === '7D'
                ? 'bg-blue-600 text-white'
                : 'bg-white/10 text-gray-300 hover:bg-white/20'
            }`}
          >
            7D
          </button>
          <button
            onClick={() => setSelectedPeriod('30D')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              selectedPeriod === '30D'
                ? 'bg-blue-600 text-white'
                : 'bg-white/10 text-gray-300 hover:bg-white/20'
            }`}
          >
            30D
          </button>
        </div>
      </div>

      {/* Métricas principais */}
      {metrics && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {/* Receita Total */}
          <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-300">Receita Total</p>
                <p className="text-2xl font-bold text-white">
                  R$ {metrics.totalRevenue.toFixed(2)}
                </p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-emerald-500 rounded-lg flex items-center justify-center">
                <span className="text-white text-xl">💰</span>
              </div>
            </div>
          </div>

          {/* Taxa de Conversão */}
          <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-300">Taxa de Conversão</p>
                <p className="text-2xl font-bold text-white">
                  {metrics.conversionRate.toFixed(2)}%
                </p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-lg flex items-center justify-center">
                <span className="text-white text-xl">📈</span>
              </div>
            </div>
          </div>

          {/* Churn Rate */}
          <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-300">Churn Rate</p>
                <p className={`text-2xl font-bold ${
                  metrics.churnRate > 80 ? 'text-red-400' : 
                  metrics.churnRate > 60 ? 'text-yellow-400' : 'text-green-400'
                }`}>
                  {metrics.churnRate.toFixed(2)}%
                </p>
              </div>
              <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                metrics.churnRate > 80 ? 'bg-gradient-to-r from-red-500 to-red-600' :
                metrics.churnRate > 60 ? 'bg-gradient-to-r from-yellow-500 to-yellow-600' :
                'bg-gradient-to-r from-green-500 to-green-600'
              }`}>
                <span className="text-white text-xl">⚠️</span>
              </div>
            </div>
          </div>

          {/* Ticket Médio */}
          <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-300">Ticket Médio</p>
                <p className="text-2xl font-bold text-white">
                  R$ {metrics.averageTicket.toFixed(2)}
                </p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-lg flex items-center justify-center">
                <span className="text-white text-xl">🎫</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Gráfico de Performance por Horário */}
      <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
        <h3 className="text-xl font-bold text-white mb-6">
          Média de Visualizações por Horário
        </h3>
        <div className="h-64">
          {/* Implementar gráfico com Chart.js ou similar */}
          <div className="flex items-center justify-center h-full text-gray-400">
            Gráfico de Performance Horária
          </div>
        </div>
      </div>

      {/* Métricas de Desempenho */}
      <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
        <h3 className="text-xl font-bold text-white mb-6">
          Métricas de Desempenho
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Implementar pie chart e outras visualizações */}
          <div className="text-center">
            <div className="w-32 h-32 mx-auto mb-4 bg-gray-700 rounded-full flex items-center justify-center">
              <span className="text-gray-400">Pie Chart</span>
            </div>
            <p className="text-sm text-gray-300">Distribuição de Conversões</p>
          </div>
        </div>
      </div>
    </div>
  );
};
```

### **PASSO 5: Integração com API Service**

```typescript
// src/services/api.ts - Adicionar métodos de analytics
export class ApiService {
  // ... métodos existentes

  async getDashboardMetrics() {
    return this.request<DashboardMetrics>('/analytics/dashboard');
  }

  async getHourlyPerformance(days: number = 7) {
    return this.request<HourlyPerformance[]>('/analytics/hourly-performance', {
      params: { days }
    });
  }

  async getDailyPerformance(days: number = 30) {
    return this.request<DailyPerformance[]>('/analytics/daily-performance', {
      params: { days }
    });
  }

  async getTopPlans() {
    return this.request<PlanPerformance[]>('/analytics/top-plans');
  }

  async getUserLocations() {
    return this.request<UserLocation[]>('/analytics/user-locations');
  }
}
```

### **PASSO 6: Schema de Banco Atualizado**

```sql
-- backend/database/analytics_schema.sql

-- Tabela para métricas em cache
CREATE TABLE analytics_cache (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  metric_type VARCHAR(50) NOT NULL,
  metric_data JSON NOT NULL,
  calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_metric (user_id, metric_type),
  INDEX idx_expires_at (expires_at)
);

-- Tabela para eventos de analytics
CREATE TABLE analytics_events (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  event_type VARCHAR(50) NOT NULL,
  event_data JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_event (user_id, event_type),
  INDEX idx_created_at (created_at)
);

-- Tabela para performance horária
CREATE TABLE hourly_performance (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  date DATE NOT NULL,
  hour TINYINT NOT NULL,
  views INT DEFAULT 0,
  sales INT DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_date_hour (user_id, date, hour)
);
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### **Backend:**
- [ ] Criar tipos TypeScript para analytics
- [ ] Implementar rotas de analytics
- [ ] Criar serviço de AnalyticsService
- [ ] Atualizar schema do banco
- [ ] Implementar cache de métricas
- [ ] Adicionar logs de eventos

### **Frontend:**
- [ ] Criar componente AdvancedDashboard
- [ ] Implementar visualizações de gráficos
- [ ] Adicionar controles de período
- [ ] Implementar loading states
- [ ] Adicionar tratamento de erros
- [ ] Implementar responsividade

### **Integração:**
- [ ] Atualizar API service
- [ ] Conectar rotas no index.js
- [ ] Testar todas as funcionalidades
- [ ] Otimizar performance
- [ ] Implementar cache no frontend

---

## 🎯 RESULTADOS ESPERADOS

### **Métricas Melhoradas:**
- **Insights Profundos:** Dashboard com métricas críticas
- **Visualizações Claras:** Gráficos e charts informativos
- **Performance em Tempo Real:** Dados atualizados automaticamente
- **Análise Temporal:** Tendências por hora, dia, semana

### **Impacto no Negócio:**
- **Decisões Data-Driven:** Baseadas em dados reais
- **Otimização de Conversão:** Identificação de gargalos
- **Redução de Churn:** Monitoramento proativo
- **Aumento de Receita:** Insights para otimização

**Próximo arquivo:** `02_BOT_CONFIGURATION.md` 🚀



