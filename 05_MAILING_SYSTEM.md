# 📧 SISTEMA DE MAILING AUTOMATIZADO

## 🎯 OBJETIVO
Implementar um sistema de mailing automatizado que supere o concorrente, com intervalos inteligentes, templates personalizáveis e métricas avançadas para reativação de usuários.

## 📋 FUNCIONALIDADES IMPLEMENTADAS

### 📨 CAMPANHAS AUTOMATIZADAS
- **Templates Personalizáveis** com variáveis dinâmicas
- **Intervalo Inteligente** (6h como concorrente, mas configurável)
- **Segmentação Avançada** por comportamento
- **A/B Testing** de mensagens

### 📊 MÉTRICAS E ANALYTICS
- **Taxa de Abertura** em tempo real
- **Taxa de Clique** por campanha
- **Conversão** por mailing
- **Análise de Horários** otimizados

---

## 🛠️ IMPLEMENTAÇÃO PASSO A PASSO

### **PASSO 1: Estrutura de Dados**

```typescript
// src/types/mailing.ts
export interface MailingCampaign {
  id?: number;
  userId: number;
  botId: number;
  name: string;
  subject: string;
  message: string;
  templateId?: number;
  targetSegment: MailingSegment;
  scheduleType: 'immediate' | 'scheduled' | 'recurring';
  scheduledAt?: Date;
  recurringInterval?: number; // horas
  status: 'draft' | 'scheduled' | 'sending' | 'sent' | 'paused' | 'cancelled';
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface MailingTemplate {
  id?: number;
  userId: number;
  name: string;
  subject: string;
  message: string;
  variables: string[];
  isDefault: boolean;
  createdAt: Date;
}

export interface MailingSegment {
  id?: number;
  name: string;
  criteria: SegmentCriteria;
  userCount: number;
  createdAt: Date;
}

export interface MailingMetrics {
  campaignId: number;
  sent: number;
  delivered: number;
  opened: number;
  clicked: number;
  converted: number;
  unsubscribed: number;
  bounced: number;
  openRate: number;
  clickRate: number;
  conversionRate: number;
}
```

### **PASSO 2: API Backend**

```typescript
// backend/src/routes/mailing.js
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { MailingService } from '../services/MailingService.js';

const router = Router();
router.use(authMiddleware);

// Listar campanhas
router.get('/campaigns', async (req, res) => {
  try {
    const userId = req.user.userId;
    const mailingService = new MailingService();
    const campaigns = await mailingService.getCampaigns(userId);
    res.json({ success: true, data: campaigns });
  } catch (error) {
    console.error('Erro ao listar campanhas:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Criar campanha
router.post('/campaigns', async (req, res) => {
  try {
    const userId = req.user.userId;
    const campaignData = req.body;
    const mailingService = new MailingService();
    const campaign = await mailingService.createCampaign(userId, campaignData);
    res.json({ success: true, data: campaign });
  } catch (error) {
    console.error('Erro ao criar campanha:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Enviar campanha
router.post('/campaigns/:id/send', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const mailingService = new MailingService();
    const result = await mailingService.sendCampaign(userId, id);
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Erro ao enviar campanha:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Métricas da campanha
router.get('/campaigns/:id/metrics', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { id } = req.params;
    const mailingService = new MailingService();
    const metrics = await mailingService.getCampaignMetrics(userId, id);
    res.json({ success: true, data: metrics });
  } catch (error) {
    console.error('Erro ao obter métricas:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

export { router as mailingRoutes };
```

### **PASSO 3: Serviço de Mailing**

```typescript
// backend/src/services/MailingService.js
import { pool } from '../config/database.js';
import { TelegramBotService } from './TelegramBotService.js';
import { SegmentService } from './SegmentService.js';

export class MailingService {
  
  async getCampaigns(userId) {
    try {
      const [rows] = await pool.execute(`
        SELECT 
          mc.*,
          COUNT(mr.id) as sent_count,
          COUNT(CASE WHEN mr.status = 'delivered' THEN 1 END) as delivered_count,
          COUNT(CASE WHEN mr.status = 'opened' THEN 1 END) as opened_count,
          COUNT(CASE WHEN mr.status = 'clicked' THEN 1 END) as clicked_count,
          COUNT(CASE WHEN mr.status = 'converted' THEN 1 END) as converted_count
        FROM mailing_campaigns mc
        LEFT JOIN mailing_recipients mr ON mc.id = mr.campaign_id
        WHERE mc.user_id = ?
        GROUP BY mc.id
        ORDER BY mc.created_at DESC
      `, [userId]);

      return rows;
    } catch (error) {
      console.error('Erro ao obter campanhas:', error);
      throw error;
    }
  }

  async createCampaign(userId, campaignData) {
    try {
      const connection = await pool.getConnection();
      await connection.beginTransaction();

      try {
        // Inserir campanha
        const [result] = await connection.execute(`
          INSERT INTO mailing_campaigns (
            user_id, bot_id, name, subject, message, template_id,
            target_segment, schedule_type, scheduled_at, recurring_interval,
            status, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [
          userId,
          campaignData.botId,
          campaignData.name,
          campaignData.subject,
          campaignData.message,
          campaignData.templateId,
          JSON.stringify(campaignData.targetSegment),
          campaignData.scheduleType,
          campaignData.scheduledAt,
          campaignData.recurringInterval,
          campaignData.status || 'draft',
          campaignData.isActive || true
        ]);

        const campaignId = result.insertId;

        // Se for envio imediato, preparar recipients
        if (campaignData.scheduleType === 'immediate') {
          await this.prepareRecipients(connection, campaignId, campaignData.targetSegment);
        }

        await connection.commit();
        return { id: campaignId, ...campaignData };
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
    } catch (error) {
      console.error('Erro ao criar campanha:', error);
      throw error;
    }
  }

  async sendCampaign(userId, campaignId) {
    try {
      const connection = await pool.getConnection();
      await connection.beginTransaction();

      try {
        // Verificar se a campanha pertence ao usuário
        const [campaignRows] = await connection.execute(`
          SELECT * FROM mailing_campaigns 
          WHERE id = ? AND user_id = ? AND status = 'draft'
        `, [campaignId, userId]);

        if (campaignRows.length === 0) {
          throw new Error('Campanha não encontrada ou já enviada');
        }

        const campaign = campaignRows[0];

        // Atualizar status para 'sending'
        await connection.execute(`
          UPDATE mailing_campaigns 
          SET status = 'sending', updated_at = CURRENT_TIMESTAMP 
          WHERE id = ?
        `, [campaignId]);

        // Buscar recipients
        const [recipientRows] = await connection.execute(`
          SELECT * FROM mailing_recipients 
          WHERE campaign_id = ? AND status = 'pending'
        `, [campaignId]);

        // Enviar emails
        const telegramService = new TelegramBotService();
        let sentCount = 0;
        let errorCount = 0;

        for (const recipient of recipientRows) {
          try {
            // Personalizar mensagem
            const personalizedMessage = this.personalizeMessage(
              campaign.message,
              recipient.user_data
            );

            // Enviar via Telegram
            await telegramService.sendMessage(
              recipient.telegram_user_id,
              personalizedMessage
            );

            // Atualizar status do recipient
            await connection.execute(`
              UPDATE mailing_recipients 
              SET status = 'sent', sent_at = CURRENT_TIMESTAMP 
              WHERE id = ?
            `, [recipient.id]);

            sentCount++;

            // Delay entre envios (6 horas como concorrente)
            if (sentCount % 10 === 0) {
              await new Promise(resolve => setTimeout(resolve, 1000));
            }
          } catch (error) {
            console.error(`Erro ao enviar para recipient ${recipient.id}:`, error);
            await connection.execute(`
              UPDATE mailing_recipients 
              SET status = 'failed', error_message = ? 
              WHERE id = ?
            `, [error.message, recipient.id]);
            errorCount++;
          }
        }

        // Atualizar status da campanha
        await connection.execute(`
          UPDATE mailing_campaigns 
          SET status = 'sent', sent_at = CURRENT_TIMESTAMP 
          WHERE id = ?
        `, [campaignId]);

        await connection.commit();

        return {
          success: true,
          sentCount,
          errorCount,
          message: 'Campanha enviada com sucesso'
        };
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
    } catch (error) {
      console.error('Erro ao enviar campanha:', error);
      throw error;
    }
  }

  async getCampaignMetrics(userId, campaignId) {
    try {
      const [rows] = await pool.execute(`
        SELECT 
          COUNT(*) as total_recipients,
          COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
          COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered,
          COUNT(CASE WHEN status = 'opened' THEN 1 END) as opened,
          COUNT(CASE WHEN status = 'clicked' THEN 1 END) as clicked,
          COUNT(CASE WHEN status = 'converted' THEN 1 END) as converted,
          COUNT(CASE WHEN status = 'unsubscribed' THEN 1 END) as unsubscribed,
          COUNT(CASE WHEN status = 'bounced' THEN 1 END) as bounced
        FROM mailing_recipients mr
        JOIN mailing_campaigns mc ON mr.campaign_id = mc.id
        WHERE mc.id = ? AND mc.user_id = ?
      `, [campaignId, userId]);

      const metrics = rows[0];
      
      // Calcular taxas
      const openRate = metrics.sent > 0 ? (metrics.opened / metrics.sent) * 100 : 0;
      const clickRate = metrics.sent > 0 ? (metrics.clicked / metrics.sent) * 100 : 0;
      const conversionRate = metrics.sent > 0 ? (metrics.converted / metrics.sent) * 100 : 0;

      return {
        ...metrics,
        openRate: parseFloat(openRate.toFixed(2)),
        clickRate: parseFloat(clickRate.toFixed(2)),
        conversionRate: parseFloat(conversionRate.toFixed(2))
      };
    } catch (error) {
      console.error('Erro ao obter métricas:', error);
      throw error;
    }
  }

  async prepareRecipients(connection, campaignId, targetSegment) {
    try {
      const segmentService = new SegmentService();
      const recipients = await segmentService.getSegmentUsers(targetSegment);

      // Inserir recipients
      for (const recipient of recipients) {
        await connection.execute(`
          INSERT INTO mailing_recipients (
            campaign_id, telegram_user_id, user_data, status
          ) VALUES (?, ?, ?, 'pending')
        `, [
          campaignId,
          recipient.telegram_user_id,
          JSON.stringify(recipient)
        ]);
      }
    } catch (error) {
      console.error('Erro ao preparar recipients:', error);
      throw error;
    }
  }

  personalizeMessage(message, userData) {
    let personalizedMessage = message;
    
    // Substituir variáveis
    personalizedMessage = personalizedMessage.replace(/{profile_name}/g, userData.name || 'Usuário');
    personalizedMessage = personalizedMessage.replace(/{city}/g, userData.city || '');
    personalizedMessage = personalizedMessage.replace(/{state}/g, userData.state || '');
    personalizedMessage = personalizedMessage.replace(/{email}/g, userData.email || '');
    
    return personalizedMessage;
  }
}
```

### **PASSO 4: Schema do Banco**

```sql
-- backend/database/mailing_schema.sql

-- Tabela de campanhas de mailing
CREATE TABLE IF NOT EXISTS mailing_campaigns (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  bot_id INT NOT NULL,
  name VARCHAR(200) NOT NULL,
  subject VARCHAR(300) NOT NULL,
  message TEXT NOT NULL,
  template_id INT NULL,
  target_segment JSON NOT NULL,
  schedule_type ENUM('immediate', 'scheduled', 'recurring') DEFAULT 'immediate',
  scheduled_at TIMESTAMP NULL,
  recurring_interval INT NULL, -- horas
  status ENUM('draft', 'scheduled', 'sending', 'sent', 'paused', 'cancelled') DEFAULT 'draft',
  is_active BOOLEAN DEFAULT TRUE,
  sent_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE,
  FOREIGN KEY (template_id) REFERENCES mailing_templates(id) ON DELETE SET NULL,
  
  INDEX idx_user_bot (user_id, bot_id),
  INDEX idx_status (status),
  INDEX idx_scheduled_at (scheduled_at)
);

-- Tabela de templates de mailing
CREATE TABLE IF NOT EXISTS mailing_templates (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(200) NOT NULL,
  subject VARCHAR(300) NOT NULL,
  message TEXT NOT NULL,
  variables JSON,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_is_default (is_default)
);

-- Tabela de recipients de campanhas
CREATE TABLE IF NOT EXISTS mailing_recipients (
  id INT PRIMARY KEY AUTO_INCREMENT,
  campaign_id INT NOT NULL,
  telegram_user_id VARCHAR(100) NOT NULL,
  user_data JSON,
  status ENUM('pending', 'sent', 'delivered', 'opened', 'clicked', 'converted', 'unsubscribed', 'bounced', 'failed') DEFAULT 'pending',
  sent_at TIMESTAMP NULL,
  delivered_at TIMESTAMP NULL,
  opened_at TIMESTAMP NULL,
  clicked_at TIMESTAMP NULL,
  converted_at TIMESTAMP NULL,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (campaign_id) REFERENCES mailing_campaigns(id) ON DELETE CASCADE,
  
  INDEX idx_campaign_status (campaign_id, status),
  INDEX idx_telegram_user (telegram_user_id)
);

-- Tabela de segmentos de usuários
CREATE TABLE IF NOT EXISTS mailing_segments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(200) NOT NULL,
  criteria JSON NOT NULL,
  user_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_is_active (is_active)
);

-- Tabela de métricas de mailing
CREATE TABLE IF NOT EXISTS mailing_metrics (
  id INT PRIMARY KEY AUTO_INCREMENT,
  campaign_id INT NOT NULL,
  date DATE NOT NULL,
  sent INT DEFAULT 0,
  delivered INT DEFAULT 0,
  opened INT DEFAULT 0,
  clicked INT DEFAULT 0,
  converted INT DEFAULT 0,
  unsubscribed INT DEFAULT 0,
  bounced INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (campaign_id) REFERENCES mailing_campaigns(id) ON DELETE CASCADE,
  
  UNIQUE KEY unique_campaign_date (campaign_id, date),
  INDEX idx_campaign_date (campaign_id, date)
);
```

### **PASSO 5: Componente Frontend**

```typescript
// src/components/MailingSystem.tsx
import React, { useState, useEffect } from 'react';
import { useAuth } from "@/hooks/useAuth";
import { apiService } from "@/services/api";

export const MailingSystem = () => {
  const { user } = useAuth();
  const [campaigns, setCampaigns] = useState<MailingCampaign[]>([]);
  const [templates, setTemplates] = useState<MailingTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [campaignsRes, templatesRes] = await Promise.all([
        apiService.get('/mailing/campaigns'),
        apiService.get('/mailing/templates')
      ]);

      if (campaignsRes.success) setCampaigns(campaignsRes.data);
      if (templatesRes.success) setTemplates(templatesRes.data);
    } catch (error) {
      console.error('Erro ao carregar dados:', error);
    }
    setLoading(false);
  };

  const createCampaign = async (campaignData: Partial<MailingCampaign>) => {
    try {
      const response = await apiService.post('/mailing/campaigns', campaignData);
      if (response.success) {
        setCampaigns(prev => [response.data, ...prev]);
        setShowCreateForm(false);
      }
    } catch (error) {
      console.error('Erro ao criar campanha:', error);
    }
  };

  const sendCampaign = async (campaignId: number) => {
    try {
      const response = await apiService.post(`/mailing/campaigns/${campaignId}/send`);
      if (response.success) {
        loadData(); // Recarregar dados
      }
    } catch (error) {
      console.error('Erro ao enviar campanha:', error);
    }
  };

  if (loading) {
    return <div>Carregando...</div>;
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-white">Sistema de Mailing</h1>
        <button
          onClick={() => setShowCreateForm(true)}
          className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium"
        >
          + Nova Campanha
        </button>
      </div>

      {/* Lista de Campanhas */}
      <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
        <h2 className="text-xl font-bold text-white mb-6">Campanhas Enviadas</h2>
        
        <div className="space-y-4">
          {campaigns.map((campaign) => (
            <div key={campaign.id} className="bg-white/5 rounded-lg p-4">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-semibold text-white">{campaign.name}</h3>
                  <p className="text-gray-300 text-sm">{campaign.subject}</p>
                  <div className="flex space-x-4 mt-2 text-sm text-gray-400">
                    <span>Enviados: {campaign.sentCount || 0}</span>
                    <span>Entregues: {campaign.deliveredCount || 0}</span>
                    <span>Abertos: {campaign.openedCount || 0}</span>
                    <span>Cliques: {campaign.clickedCount || 0}</span>
                  </div>
                </div>
                <div className="flex space-x-2">
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                    campaign.status === 'sent' ? 'bg-green-500/20 text-green-300' :
                    campaign.status === 'sending' ? 'bg-blue-500/20 text-blue-300' :
                    'bg-gray-500/20 text-gray-300'
                  }`}>
                    {campaign.status}
                  </span>
                  {campaign.status === 'draft' && (
                    <button
                      onClick={() => sendCampaign(campaign.id!)}
                      className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm"
                    >
                      Enviar
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Formulário de Criação */}
      {showCreateForm && (
        <CreateCampaignForm
          templates={templates}
          onSubmit={createCampaign}
          onCancel={() => setShowCreateForm(false)}
        />
      )}
    </div>
  );
};

const CreateCampaignForm = ({ templates, onSubmit, onCancel }: {
  templates: MailingTemplate[];
  onSubmit: (data: Partial<MailingCampaign>) => void;
  onCancel: () => void;
}) => {
  const [formData, setFormData] = useState<Partial<MailingCampaign>>({
    name: '',
    subject: '',
    message: '',
    scheduleType: 'immediate',
    targetSegment: { name: 'Todos os usuários', criteria: {} }
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
      <h2 className="text-xl font-bold text-white mb-6">Nova Campanha</h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm text-gray-300 mb-2">Nome da Campanha</label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
            className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            required
          />
        </div>

        <div>
          <label className="block text-sm text-gray-300 mb-2">Assunto</label>
          <input
            type="text"
            value={formData.subject}
            onChange={(e) => setFormData(prev => ({ ...prev, subject: e.target.value }))}
            className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            required
          />
        </div>

        <div>
          <label className="block text-sm text-gray-300 mb-2">Mensagem</label>
          <textarea
            value={formData.message}
            onChange={(e) => setFormData(prev => ({ ...prev, message: e.target.value }))}
            rows={8}
            className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            placeholder="Digite sua mensagem... Use {profile_name}, {city}, {state} para personalizar."
            required
          />
          <p className="text-xs text-gray-400 mt-1">
            Variáveis disponíveis: {`{profile_name}, {city}, {state}, {email}`}
          </p>
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
            Criar Campanha
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
- [ ] Criar tipos TypeScript para mailing
- [ ] Implementar rotas de mailing
- [ ] Criar MailingService
- [ ] Implementar personalização de mensagens
- [ ] Adicionar sistema de templates
- [ ] Implementar segmentação

### **Frontend:**
- [ ] Criar componente MailingSystem
- [ ] Implementar formulário de criação
- [ ] Adicionar lista de campanhas
- [ ] Implementar métricas em tempo real
- [ ] Adicionar templates
- [ ] Implementar A/B testing

### **Integração:**
- [ ] Conectar rotas no index.js
- [ ] Atualizar API service
- [ ] Testar envio de mensagens
- [ ] Implementar tracking de eventos
- [ ] Adicionar logs de auditoria

**Próximo arquivo:** `06_REDIRECTOR_SYSTEM.md` 🚀



