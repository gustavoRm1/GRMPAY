# 🔗 SISTEMA DE REDIRECIONADORES INTELIGENTES

## 🎯 OBJETIVO
Implementar um sistema de redirecionadores inteligentes que supere o concorrente, com tracking avançado, A/B testing e métricas detalhadas para otimização de campanhas.

## 📋 FUNCIONALIDADES IMPLEMENTADAS

### 🎯 REDIRECIONADORES INTELIGENTES
- **URLs Curtas** personalizáveis
- **Tracking UTM** automático
- **A/B Testing** de destinos
- **Rotação Inteligente** de links

### 📊 ANALYTICS AVANÇADOS
- **Cliques por Fonte** (UTM)
- **Conversão por Link** 
- **Performance por Horário**
- **Heatmap de Cliques**

---

## 🛠️ IMPLEMENTAÇÃO PASSO A PASSO

### **PASSO 1: Estrutura de Dados**

```typescript
// src/types/redirector.ts
export interface Redirector {
  id?: number;
  userId: number;
  botId: number;
  name: string;
  shortCode: string;
  originalUrl: string;
  targetUrl: string;
  utmSource?: string;
  utmMedium?: string;
  utmCampaign?: string;
  utmTerm?: string;
  utmContent?: string;
  isActive: boolean;
  expiresAt?: Date;
  maxClicks?: number;
  currentClicks: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface RedirectorMetrics {
  redirectorId: number;
  totalClicks: number;
  uniqueClicks: number;
  conversions: number;
  conversionRate: number;
  topSources: SourceMetric[];
  hourlyStats: HourlyStat[];
  dailyStats: DailyStat[];
}

export interface SourceMetric {
  source: string;
  medium: string;
  campaign: string;
  clicks: number;
  conversions: number;
  conversionRate: number;
}

export interface A/BTest {
  id?: number;
  redirectorId: number;
  variantA: string;
  variantB: string;
  trafficSplit: number; // % para A
  status: 'active' | 'paused' | 'completed';
  startDate: Date;
  endDate?: Date;
  winner?: 'A' | 'B';
}
```

### **PASSO 2: API Backend**

```typescript
// backend/src/routes/redirector.js
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { RedirectorService } from '../services/RedirectorService.js';

const router = Router();
router.use(authMiddleware);

// Listar redirecionadores
router.get('/', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { botId } = req.query;
    const redirectorService = new RedirectorService();
    const redirectors = await redirectorService.getRedirectors(userId, botId);
    res.json({ success: true, data: redirectors });
  } catch (error) {
    console.error('Erro ao listar redirecionadores:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Criar redirecionador
router.post('/', async (req, res) => {
  try {
    const userId = req.user.userId;
    const redirectorData = req.body;
    const redirectorService = new RedirectorService();
    const redirector = await redirectorService.createRedirector(userId, redirectorData);
    res.json({ success: true, data: redirector });
  } catch (error) {
    console.error('Erro ao criar redirecionador:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Redirecionar (público)
router.get('/:shortCode', async (req, res) => {
  try {
    const { shortCode } = req.params;
    const { utm_source, utm_medium, utm_campaign, utm_term, utm_content } = req.query;
    const userAgent = req.get('User-Agent');
    const ip = req.ip;
    
    const redirectorService = new RedirectorService();
    const result = await redirectorService.redirect(
      shortCode,
      {
        utm_source,
        utm_medium,
        utm_campaign,
        utm_term,
        utm_content
      },
      { userAgent, ip }
    );
    
    if (result.success) {
      res.redirect(result.targetUrl);
    } else {
      res.status(404).json({ error: 'Redirecionador não encontrado' });
    }
  } catch (error) {
    console.error('Erro no redirecionamento:', error);
    res.status(500).json({ error: 'Erro interno' });
  }
});

// Métricas do redirecionador
router.get('/:id/metrics', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const { period = '30d' } = req.query;
    const redirectorService = new RedirectorService();
    const metrics = await redirectorService.getMetrics(userId, id, period);
    res.json({ success: true, data: metrics });
  } catch (error) {
    console.error('Erro ao obter métricas:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Criar A/B Test
router.post('/:id/ab-test', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const abTestData = req.body;
    const redirectorService = new RedirectorService();
    const abTest = await redirectorService.createABTest(userId, id, abTestData);
    res.json({ success: true, data: abTest });
  } catch (error) {
    console.error('Erro ao criar A/B test:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

export { router as redirectorRoutes };
```

### **PASSO 3: Serviço de Redirecionadores**

```typescript
// backend/src/services/RedirectorService.js
import { pool } from '../config/database.js';
import { nanoid } from 'nanoid';
import crypto from 'crypto';

export class RedirectorService {
  
  async getRedirectors(userId, botId = null) {
    try {
      let query = `
        SELECT 
          r.*,
          COUNT(rc.id) as total_clicks,
          COUNT(DISTINCT rc.ip_address) as unique_clicks,
          COUNT(CASE WHEN rc.converted = 1 THEN 1 END) as conversions
        FROM redirectors r
        LEFT JOIN redirector_clicks rc ON r.id = rc.redirector_id
        WHERE r.user_id = ?
      `;
      
      const params = [userId];
      
      if (botId) {
        query += ' AND r.bot_id = ?';
        params.push(botId);
      }
      
      query += ' GROUP BY r.id ORDER BY r.created_at DESC';
      
      const [rows] = await pool.execute(query, params);
      return rows;
    } catch (error) {
      console.error('Erro ao obter redirecionadores:', error);
      throw error;
    }
  }

  async createRedirector(userId, redirectorData) {
    try {
      const connection = await pool.getConnection();
      await connection.beginTransaction();

      try {
        // Gerar código único se não fornecido
        let shortCode = redirectorData.shortCode;
        if (!shortCode) {
          shortCode = await this.generateUniqueShortCode();
        } else {
          // Verificar se já existe
          const [existing] = await connection.execute(
            'SELECT id FROM redirectors WHERE short_code = ?',
            [shortCode]
          );
          if (existing.length > 0) {
            throw new Error('Código já existe');
          }
        }

        // Inserir redirecionador
        const [result] = await connection.execute(`
          INSERT INTO redirectors (
            user_id, bot_id, name, short_code, original_url, target_url,
            utm_source, utm_medium, utm_campaign, utm_term, utm_content,
            is_active, expires_at, max_clicks, current_clicks
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
        `, [
          userId,
          redirectorData.botId,
          redirectorData.name,
          shortCode,
          redirectorData.originalUrl,
          redirectorData.targetUrl,
          redirectorData.utmSource,
          redirectorData.utmMedium,
          redirectorData.utmCampaign,
          redirectorData.utmTerm,
          redirectorData.utmContent,
          redirectorData.isActive || true,
          redirectorData.expiresAt,
          redirectorData.maxClicks
        ]);

        const redirectorId = result.insertId;

        await connection.commit();
        
        return {
          id: redirectorId,
          shortCode,
          shortUrl: `${process.env.BASE_URL}/r/${shortCode}`,
          ...redirectorData
        };
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
    } catch (error) {
      console.error('Erro ao criar redirecionador:', error);
      throw error;
    }
  }

  async redirect(shortCode, utmParams, requestInfo) {
    try {
      const connection = await pool.getConnection();
      await connection.beginTransaction();

      try {
        // Buscar redirecionador
        const [redirectorRows] = await connection.execute(`
          SELECT * FROM redirectors 
          WHERE short_code = ? AND is_active = 1
        `, [shortCode]);

        if (redirectorRows.length === 0) {
          await connection.rollback();
          return { success: false, error: 'Redirecionador não encontrado' };
        }

        const redirector = redirectorRows[0];

        // Verificar expiração
        if (redirector.expires_at && new Date() > new Date(redirector.expires_at)) {
          await connection.rollback();
          return { success: false, error: 'Redirecionador expirado' };
        }

        // Verificar limite de cliques
        if (redirector.max_clicks && redirector.current_clicks >= redirector.max_clicks) {
          await connection.rollback();
          return { success: false, error: 'Limite de cliques atingido' };
        }

        // Determinar URL de destino (A/B test ou padrão)
        let targetUrl = redirector.target_url;
        
        // Verificar se há A/B test ativo
        const [abTestRows] = await connection.execute(`
          SELECT * FROM redirector_ab_tests 
          WHERE redirector_id = ? AND status = 'active'
        `, [redirector.id]);

        if (abTestRows.length > 0) {
          const abTest = abTestRows[0];
          targetUrl = await this.getABTestUrl(abTest, requestInfo.ip);
        }

        // Adicionar parâmetros UTM se necessário
        targetUrl = this.addUTMParams(targetUrl, {
          utm_source: utmParams.utm_source || redirector.utm_source,
          utm_medium: utmParams.utm_medium || redirector.utm_medium,
          utm_campaign: utmParams.utm_campaign || redirector.utm_campaign,
          utm_term: utmParams.utm_term || redirector.utm_term,
          utm_content: utmParams.utm_content || redirector.utm_content
        });

        // Registrar clique
        await connection.execute(`
          INSERT INTO redirector_clicks (
            redirector_id, ip_address, user_agent, utm_source, utm_medium,
            utm_campaign, utm_term, utm_content, target_url, clicked_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        `, [
          redirector.id,
          requestInfo.ip,
          requestInfo.userAgent,
          utmParams.utm_source || redirector.utm_source,
          utmParams.utm_medium || redirector.utm_medium,
          utmParams.utm_campaign || redirector.utm_campaign,
          utmParams.utm_term || redirector.utm_term,
          utmParams.utm_content || redirector.utm_content,
          targetUrl
        ]);

        // Atualizar contador de cliques
        await connection.execute(`
          UPDATE redirectors 
          SET current_clicks = current_clicks + 1, updated_at = CURRENT_TIMESTAMP 
          WHERE id = ?
        `, [redirector.id]);

        await connection.commit();

        return {
          success: true,
          targetUrl,
          redirectorId: redirector.id
        };
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
    } catch (error) {
      console.error('Erro no redirecionamento:', error);
      throw error;
    }
  }

  async getMetrics(userId, redirectorId, period = '30d') {
    try {
      const days = period === '7d' ? 7 : period === '30d' ? 30 : 90;
      
      // Métricas gerais
      const [generalRows] = await pool.execute(`
        SELECT 
          COUNT(*) as total_clicks,
          COUNT(DISTINCT ip_address) as unique_clicks,
          COUNT(CASE WHEN converted = 1 THEN 1 END) as conversions,
          (COUNT(CASE WHEN converted = 1 THEN 1 END) / COUNT(*)) * 100 as conversion_rate
        FROM redirector_clicks rc
        JOIN redirectors r ON rc.redirector_id = r.id
        WHERE r.id = ? AND r.user_id = ?
          AND rc.clicked_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
      `, [redirectorId, userId, days]);

      // Top sources
      const [sourceRows] = await pool.execute(`
        SELECT 
          utm_source as source,
          utm_medium as medium,
          utm_campaign as campaign,
          COUNT(*) as clicks,
          COUNT(CASE WHEN converted = 1 THEN 1 END) as conversions,
          (COUNT(CASE WHEN converted = 1 THEN 1 END) / COUNT(*)) * 100 as conversion_rate
        FROM redirector_clicks rc
        JOIN redirectors r ON rc.redirector_id = r.id
        WHERE r.id = ? AND r.user_id = ?
          AND rc.clicked_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY utm_source, utm_medium, utm_campaign
        ORDER BY clicks DESC
        LIMIT 10
      `, [redirectorId, userId, days]);

      // Estatísticas horárias
      const [hourlyRows] = await pool.execute(`
        SELECT 
          HOUR(clicked_at) as hour,
          COUNT(*) as clicks,
          COUNT(CASE WHEN converted = 1 THEN 1 END) as conversions
        FROM redirector_clicks rc
        JOIN redirectors r ON rc.redirector_id = r.id
        WHERE r.id = ? AND r.user_id = ?
          AND rc.clicked_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY HOUR(clicked_at)
        ORDER BY hour
      `, [redirectorId, userId, days]);

      // Estatísticas diárias
      const [dailyRows] = await pool.execute(`
        SELECT 
          DATE(clicked_at) as date,
          COUNT(*) as clicks,
          COUNT(CASE WHEN converted = 1 THEN 1 END) as conversions
        FROM redirector_clicks rc
        JOIN redirectors r ON rc.redirector_id = r.id
        WHERE r.id = ? AND r.user_id = ?
          AND rc.clicked_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY DATE(clicked_at)
        ORDER BY date
      `, [redirectorId, userId, days]);

      return {
        general: generalRows[0],
        topSources: sourceRows,
        hourlyStats: hourlyRows,
        dailyStats: dailyRows
      };
    } catch (error) {
      console.error('Erro ao obter métricas:', error);
      throw error;
    }
  }

  async createABTest(userId, redirectorId, abTestData) {
    try {
      // Verificar se o redirecionador pertence ao usuário
      const [redirectorRows] = await pool.execute(`
        SELECT id FROM redirectors WHERE id = ? AND user_id = ?
      `, [redirectorId, userId]);

      if (redirectorRows.length === 0) {
        throw new Error('Redirecionador não encontrado');
      }

      // Inserir A/B test
      const [result] = await pool.execute(`
        INSERT INTO redirector_ab_tests (
          redirector_id, variant_a, variant_b, traffic_split,
          status, start_date, end_date
        ) VALUES (?, ?, ?, ?, 'active', CURRENT_TIMESTAMP, ?)
      `, [
        redirectorId,
        abTestData.variantA,
        abTestData.variantB,
        abTestData.trafficSplit || 50,
        abTestData.endDate
      ]);

      return {
        id: result.insertId,
        redirectorId,
        ...abTestData,
        status: 'active'
      };
    } catch (error) {
      console.error('Erro ao criar A/B test:', error);
      throw error;
    }
  }

  async generateUniqueShortCode() {
    let shortCode;
    let attempts = 0;
    
    do {
      shortCode = nanoid(8);
      const [existing] = await pool.execute(
        'SELECT id FROM redirectors WHERE short_code = ?',
        [shortCode]
      );
      if (existing.length === 0) break;
      attempts++;
    } while (attempts < 10);
    
    if (attempts >= 10) {
      throw new Error('Não foi possível gerar código único');
    }
    
    return shortCode;
  }

  async getABTestUrl(abTest, ip) {
    // Usar hash do IP para consistência
    const hash = crypto.createHash('md5').update(ip).digest('hex');
    const hashValue = parseInt(hash.substring(0, 8), 16);
    const percentage = hashValue % 100;
    
    return percentage < abTest.traffic_split ? abTest.variant_a : abTest.variant_b;
  }

  addUTMParams(url, utmParams) {
    const urlObj = new URL(url);
    
    Object.entries(utmParams).forEach(([key, value]) => {
      if (value) {
        urlObj.searchParams.set(key, value);
      }
    });
    
    return urlObj.toString();
  }
}
```

### **PASSO 4: Schema do Banco**

```sql
-- backend/database/redirector_schema.sql

-- Tabela de redirecionadores
CREATE TABLE IF NOT EXISTS redirectors (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  bot_id INT NOT NULL,
  name VARCHAR(200) NOT NULL,
  short_code VARCHAR(50) UNIQUE NOT NULL,
  original_url TEXT NOT NULL,
  target_url TEXT NOT NULL,
  utm_source VARCHAR(100),
  utm_medium VARCHAR(100),
  utm_campaign VARCHAR(100),
  utm_term VARCHAR(100),
  utm_content VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMP NULL,
  max_clicks INT NULL,
  current_clicks INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE,
  
  INDEX idx_user_bot (user_id, bot_id),
  INDEX idx_short_code (short_code),
  INDEX idx_is_active (is_active)
);

-- Tabela de cliques nos redirecionadores
CREATE TABLE IF NOT EXISTS redirector_clicks (
  id INT PRIMARY KEY AUTO_INCREMENT,
  redirector_id INT NOT NULL,
  ip_address VARCHAR(45) NOT NULL,
  user_agent TEXT,
  utm_source VARCHAR(100),
  utm_medium VARCHAR(100),
  utm_campaign VARCHAR(100),
  utm_term VARCHAR(100),
  utm_content VARCHAR(100),
  target_url TEXT NOT NULL,
  converted BOOLEAN DEFAULT FALSE,
  converted_at TIMESTAMP NULL,
  clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (redirector_id) REFERENCES redirectors(id) ON DELETE CASCADE,
  
  INDEX idx_redirector_clicked (redirector_id, clicked_at),
  INDEX idx_ip_address (ip_address),
  INDEX idx_converted (converted)
);

-- Tabela de A/B tests
CREATE TABLE IF NOT EXISTS redirector_ab_tests (
  id INT PRIMARY KEY AUTO_INCREMENT,
  redirector_id INT NOT NULL,
  variant_a TEXT NOT NULL,
  variant_b TEXT NOT NULL,
  traffic_split INT DEFAULT 50, -- % para variant A
  status ENUM('active', 'paused', 'completed') DEFAULT 'active',
  start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  end_date TIMESTAMP NULL,
  winner ENUM('A', 'B') NULL,
  confidence_level DECIMAL(5,2) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (redirector_id) REFERENCES redirectors(id) ON DELETE CASCADE,
  
  INDEX idx_redirector_status (redirector_id, status)
);

-- Tabela de métricas de redirecionadores
CREATE TABLE IF NOT EXISTS redirector_metrics (
  id INT PRIMARY KEY AUTO_INCREMENT,
  redirector_id INT NOT NULL,
  date DATE NOT NULL,
  total_clicks INT DEFAULT 0,
  unique_clicks INT DEFAULT 0,
  conversions INT DEFAULT 0,
  conversion_rate DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (redirector_id) REFERENCES redirectors(id) ON DELETE CASCADE,
  
  UNIQUE KEY unique_redirector_date (redirector_id, date),
  INDEX idx_redirector_date (redirector_id, date)
);
```

### **PASSO 5: Componente Frontend**

```typescript
// src/components/RedirectorSystem.tsx
import React, { useState, useEffect } from 'react';
import { useAuth } from "@/hooks/useAuth";
import { apiService } from "@/services/api";

export const RedirectorSystem = () => {
  const { user } = useAuth();
  const [redirectors, setRedirectors] = useState<Redirector[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [selectedRedirector, setSelectedRedirector] = useState<Redirector | null>(null);

  useEffect(() => {
    loadRedirectors();
  }, []);

  const loadRedirectors = async () => {
    setLoading(true);
    try {
      const response = await apiService.get('/redirector');
      if (response.success) {
        setRedirectors(response.data);
      }
    } catch (error) {
      console.error('Erro ao carregar redirecionadores:', error);
    }
    setLoading(false);
  };

  const createRedirector = async (redirectorData: Partial<Redirector>) => {
    try {
      const response = await apiService.post('/redirector', redirectorData);
      if (response.success) {
        setRedirectors(prev => [response.data, ...prev]);
        setShowCreateForm(false);
      }
    } catch (error) {
      console.error('Erro ao criar redirecionador:', error);
    }
  };

  if (loading) {
    return <div>Carregando...</div>;
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-white">Redirecionadores</h1>
        <button
          onClick={() => setShowCreateForm(true)}
          className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium"
        >
          + Novo Redirecionador
        </button>
      </div>

      {/* Lista de Redirecionadores */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {redirectors.map((redirector) => (
          <div key={redirector.id} className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
            <div className="flex justify-between items-start mb-4">
              <h3 className="text-lg font-semibold text-white">{redirector.name}</h3>
              <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                redirector.isActive ? 'bg-green-500/20 text-green-300' : 'bg-gray-500/20 text-gray-300'
              }`}>
                {redirector.isActive ? 'Ativo' : 'Inativo'}
              </span>
            </div>
            
            <div className="space-y-2 text-sm text-gray-300">
              <div>
                <span className="font-medium">URL Curta:</span>
                <div className="flex items-center space-x-2">
                  <code className="bg-white/10 px-2 py-1 rounded text-blue-300">
                    {process.env.REACT_APP_BASE_URL}/r/{redirector.shortCode}
                  </code>
                  <button
                    onClick={() => navigator.clipboard.writeText(`${process.env.REACT_APP_BASE_URL}/r/${redirector.shortCode}`)}
                    className="text-blue-400 hover:text-blue-300"
                  >
                    📋
                  </button>
                </div>
              </div>
              
              <div>
                <span className="font-medium">Destino:</span>
                <p className="text-xs text-gray-400 truncate">{redirector.targetUrl}</p>
              </div>
              
              <div className="flex justify-between">
                <span>Cliques: <span className="font-medium text-white">{redirector.currentClicks}</span></span>
                <span>Conversões: <span className="font-medium text-white">{redirector.conversions || 0}</span></span>
              </div>
              
              {redirector.maxClicks && (
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className="bg-blue-600 h-2 rounded-full" 
                    style={{ width: `${Math.min((redirector.currentClicks / redirector.maxClicks) * 100, 100)}%` }}
                  ></div>
                </div>
              )}
            </div>
            
            <div className="flex justify-end space-x-2 mt-4">
              <button
                onClick={() => setSelectedRedirector(redirector)}
                className="px-3 py-1 bg-gray-600 hover:bg-gray-700 text-white rounded text-sm"
              >
                Métricas
              </button>
              <button
                onClick={() => window.open(`${process.env.REACT_APP_BASE_URL}/r/${redirector.shortCode}`, '_blank')}
                className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded text-sm"
              >
                Testar
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Formulário de Criação */}
      {showCreateForm && (
        <CreateRedirectorForm
          onSubmit={createRedirector}
          onCancel={() => setShowCreateForm(false)}
        />
      )}

      {/* Modal de Métricas */}
      {selectedRedirector && (
        <RedirectorMetrics
          redirector={selectedRedirector}
          onClose={() => setSelectedRedirector(null)}
        />
      )}
    </div>
  );
};

const CreateRedirectorForm = ({ onSubmit, onCancel }: {
  onSubmit: (data: Partial<Redirector>) => void;
  onCancel: () => void;
}) => {
  const [formData, setFormData] = useState<Partial<Redirector>>({
    name: '',
    shortCode: '',
    originalUrl: '',
    targetUrl: '',
    utmSource: '',
    utmMedium: '',
    utmCampaign: '',
    utmTerm: '',
    utmContent: '',
    isActive: true
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
      <h2 className="text-xl font-bold text-white mb-6">Novo Redirecionador</h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-300 mb-2">Nome</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
              required
            />
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-2">Código Curto (opcional)</label>
            <input
              type="text"
              value={formData.shortCode}
              onChange={(e) => setFormData(prev => ({ ...prev, shortCode: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
              placeholder="Será gerado automaticamente se vazio"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm text-gray-300 mb-2">URL Original</label>
          <input
            type="url"
            value={formData.originalUrl}
            onChange={(e) => setFormData(prev => ({ ...prev, originalUrl: e.target.value }))}
            className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            required
          />
        </div>

        <div>
          <label className="block text-sm text-gray-300 mb-2">URL Destino</label>
          <input
            type="url"
            value={formData.targetUrl}
            onChange={(e) => setFormData(prev => ({ ...prev, targetUrl: e.target.value }))}
            className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            required
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm text-gray-300 mb-2">UTM Source</label>
            <input
              type="text"
              value={formData.utmSource}
              onChange={(e) => setFormData(prev => ({ ...prev, utmSource: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-2">UTM Medium</label>
            <input
              type="text"
              value={formData.utmMedium}
              onChange={(e) => setFormData(prev => ({ ...prev, utmMedium: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-sm text-gray-300 mb-2">UTM Campaign</label>
            <input
              type="text"
              value={formData.utmCampaign}
              onChange={(e) => setFormData(prev => ({ ...prev, utmCampaign: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-2">UTM Term</label>
            <input
              type="text"
              value={formData.utmTerm}
              onChange={(e) => setFormData(prev => ({ ...prev, utmTerm: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-2">UTM Content</label>
            <input
              type="text"
              value={formData.utmContent}
              onChange={(e) => setFormData(prev => ({ ...prev, utmContent: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>
        </div>

        <div className="flex justify-end space-x-4">
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium"
          >
            Cancelar
          </button>
          <button
            type="submit"
            className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium"
          >
            Criar Redirecionador
          </button>
        </div>
      </form>
    </div>
  );
};
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### **Backend:**
- [ ] Criar tipos TypeScript para redirector
- [ ] Implementar rotas de redirector
- [ ] Criar RedirectorService
- [ ] Implementar sistema de A/B testing
- [ ] Adicionar tracking de cliques
- [ ] Implementar métricas avançadas

### **Frontend:**
- [ ] Criar componente RedirectorSystem
- [ ] Implementar formulário de criação
- [ ] Adicionar lista de redirecionadores
- [ ] Implementar modal de métricas
- [ ] Adicionar A/B testing interface
- [ ] Implementar cópia de URL

### **Integração:**
- [ ] Conectar rotas no index.js
- [ ] Atualizar API service
- [ ] Testar redirecionamentos
- [ ] Implementar tracking de eventos
- [ ] Adicionar logs de auditoria

**Próximo arquivo:** `07_TRACKING_ADVANCED.md` 🚀



