# 💰 FUNIL DE VENDAS COMPLETO - ORDER BUMP, UPSELL, DOWNSELL

## 🎯 OBJETIVO
Implementar um funil de vendas completo que supere o concorrente, com Order Bump (43.40% de conversão), Upsell e Downsell para maximizar a receita por cliente.

## 📋 FUNCIONALIDADES IMPLEMENTADAS

### 🎯 ORDER BUMP
- **Ofertas Adicionais** no checkout
- **Configuração por Plano** específico
- **Mensagens Personalizáveis**
- **Tracking de Conversão**

### 📈 UPSELL
- **Vendas de Valor Maior** após compra
- **Mensagens Automáticas** configuráveis
- **Múltiplas Ofertas** sequenciais
- **Timing Personalizado**

### 📉 DOWNSELL
- **Ofertas Alternativas** mais baratas
- **Recuperação de Abandono**
- **Mensagens de Urgência**
- **Ofertas Especiais**

---

## 🛠️ IMPLEMENTAÇÃO PASSO A PASSO

### **PASSO 1: Estrutura de Dados**

```typescript
// src/types/salesFunnel.ts
export interface SalesFunnel {
  botId: number;
  orderBump: OrderBumpConfig;
  upsell: UpsellConfig;
  downsell: DownsellConfig;
}

export interface OrderBumpConfig {
  enabled: boolean;
  offers: OrderBumpOffer[];
}

export interface OrderBumpOffer {
  id?: number;
  planId: number;
  title: string;
  description: string;
  originalPrice: number;
  offerPrice: number;
  discountPercentage: number;
  urgencyMessage?: string;
  isActive: boolean;
  displayOrder: number;
}

export interface UpsellConfig {
  enabled: boolean;
  messages: UpsellMessage[];
}

export interface UpsellMessage {
  id?: number;
  title: string;
  message: string;
  targetPlans: number[];
  delayMinutes: number;
  maxAttempts: number;
  isActive: boolean;
  displayOrder: number;
}

export interface DownsellConfig {
  enabled: boolean;
  offers: DownsellOffer[];
}

export interface DownsellOffer {
  id?: number;
  originalPlanId: number;
  alternativePlanId: number;
  title: string;
  message: string;
  discountPercentage: number;
  urgencyMessage: string;
  delayHours: number;
  maxAttempts: number;
  isActive: boolean;
  displayOrder: number;
}
```

### **PASSO 2: API Backend**

```typescript
// backend/src/routes/salesFunnel.js
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { SalesFunnelService } from '../services/SalesFunnelService.js';

const router = Router();
router.use(authMiddleware);

// Obter configuração do funil
router.get('/:botId', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    
    const funnelService = new SalesFunnelService();
    const config = await funnelService.getSalesFunnel(userId, botId);
    
    res.json({ success: true, data: config });
  } catch (error) {
    console.error('Erro ao obter funil de vendas:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Salvar configuração do funil
router.put('/:botId', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    const funnelData = req.body;
    
    const funnelService = new SalesFunnelService();
    const result = await funnelService.updateSalesFunnel(userId, botId, funnelData);
    
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Erro ao salvar funil de vendas:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Executar Order Bump
router.post('/:botId/order-bump', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    const { transactionId, selectedOffer } = req.body;
    
    const funnelService = new SalesFunnelService();
    const result = await funnelService.executeOrderBump(userId, botId, transactionId, selectedOffer);
    
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Erro ao executar order bump:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Executar Upsell
router.post('/:botId/upsell', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    const { transactionId, messageId } = req.body;
    
    const funnelService = new SalesFunnelService();
    const result = await funnelService.executeUpsell(userId, botId, transactionId, messageId);
    
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Erro ao executar upsell:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Executar Downsell
router.post('/:botId/downsell', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    const { transactionId, offerId } = req.body;
    
    const funnelService = new SalesFunnelService();
    const result = await funnelService.executeDownsell(userId, botId, transactionId, offerId);
    
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Erro ao executar downsell:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

export { router as salesFunnelRoutes };
```

### **PASSO 3: Serviço de Funil de Vendas**

```typescript
// backend/src/services/SalesFunnelService.js
import { pool } from '../config/database.js';
import { TelegramBotService } from './TelegramBotService.js';
import { PaymentService } from './PaymentService.js';

export class SalesFunnelService {
  
  async getSalesFunnel(userId, botId) {
    try {
      // Verificar se o bot pertence ao usuário
      const [botRows] = await pool.execute(`
        SELECT id FROM user_bots WHERE id = ? AND user_id = ?
      `, [botId, userId]);

      if (botRows.length === 0) {
        throw new Error('Bot não encontrado');
      }

      // Buscar configuração do Order Bump
      const [orderBumpRows] = await pool.execute(`
        SELECT * FROM order_bump_offers 
        WHERE bot_id = ? AND is_active = 1
        ORDER BY display_order ASC
      `, [botId]);

      // Buscar configuração do Upsell
      const [upsellRows] = await pool.execute(`
        SELECT * FROM upsell_messages 
        WHERE bot_id = ? AND is_active = 1
        ORDER BY display_order ASC
      `, [botId]);

      // Buscar configuração do Downsell
      const [downsellRows] = await pool.execute(`
        SELECT * FROM downsell_offers 
        WHERE bot_id = ? AND is_active = 1
        ORDER BY display_order ASC
      `, [botId]);

      return {
        botId: parseInt(botId),
        orderBump: {
          enabled: orderBumpRows.length > 0,
          offers: orderBumpRows
        },
        upsell: {
          enabled: upsellRows.length > 0,
          messages: upsellRows
        },
        downsell: {
          enabled: downsellRows.length > 0,
          offers: downsellRows
        }
      };
    } catch (error) {
      console.error('Erro ao obter funil de vendas:', error);
      throw error;
    }
  }

  async updateSalesFunnel(userId, botId, funnelData) {
    try {
      const connection = await pool.getConnection();
      await connection.beginTransaction();

      try {
        // Atualizar Order Bump
        if (funnelData.orderBump) {
          await this.updateOrderBump(connection, botId, funnelData.orderBump);
        }

        // Atualizar Upsell
        if (funnelData.upsell) {
          await this.updateUpsell(connection, botId, funnelData.upsell);
        }

        // Atualizar Downsell
        if (funnelData.downsell) {
          await this.updateDownsell(connection, botId, funnelData.downsell);
        }

        await connection.commit();
        
        return { success: true, message: 'Funil de vendas atualizado com sucesso' };
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
    } catch (error) {
      console.error('Erro ao atualizar funil de vendas:', error);
      throw error;
    }
  }

  async updateOrderBump(connection, botId, orderBumpConfig) {
    // Desativar ofertas existentes
    await connection.execute(`
      UPDATE order_bump_offers 
      SET is_active = 0, updated_at = CURRENT_TIMESTAMP 
      WHERE bot_id = ?
    `, [botId]);

    // Inserir novas ofertas
    for (const offer of orderBumpConfig.offers || []) {
      if (offer.id) {
        // Atualizar oferta existente
        await connection.execute(`
          UPDATE order_bump_offers SET
            plan_id = ?,
            title = ?,
            description = ?,
            original_price = ?,
            offer_price = ?,
            discount_percentage = ?,
            urgency_message = ?,
            display_order = ?,
            is_active = 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND bot_id = ?
        `, [
          offer.planId, offer.title, offer.description,
          offer.originalPrice, offer.offerPrice, offer.discountPercentage,
          offer.urgencyMessage, offer.displayOrder,
          offer.id, botId
        ]);
      } else {
        // Inserir nova oferta
        await connection.execute(`
          INSERT INTO order_bump_offers (
            bot_id, plan_id, title, description, original_price, 
            offer_price, discount_percentage, urgency_message, 
            display_order, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
        `, [
          botId, offer.planId, offer.title, offer.description,
          offer.originalPrice, offer.offerPrice, offer.discountPercentage,
          offer.urgencyMessage, offer.displayOrder
        ]);
      }
    }
  }

  async updateUpsell(connection, botId, upsellConfig) {
    // Desativar mensagens existentes
    await connection.execute(`
      UPDATE upsell_messages 
      SET is_active = 0, updated_at = CURRENT_TIMESTAMP 
      WHERE bot_id = ?
    `, [botId]);

    // Inserir novas mensagens
    for (const message of upsellConfig.messages || []) {
      if (message.id) {
        // Atualizar mensagem existente
        await connection.execute(`
          UPDATE upsell_messages SET
            title = ?,
            message = ?,
            target_plans = ?,
            delay_minutes = ?,
            max_attempts = ?,
            display_order = ?,
            is_active = 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND bot_id = ?
        `, [
          message.title, message.message, JSON.stringify(message.targetPlans),
          message.delayMinutes, message.maxAttempts, message.displayOrder,
          message.id, botId
        ]);
      } else {
        // Inserir nova mensagem
        await connection.execute(`
          INSERT INTO upsell_messages (
            bot_id, title, message, target_plans, delay_minutes,
            max_attempts, display_order, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 1)
        `, [
          botId, message.title, message.message, JSON.stringify(message.targetPlans),
          message.delayMinutes, message.maxAttempts, message.displayOrder
        ]);
      }
    }
  }

  async updateDownsell(connection, botId, downsellConfig) {
    // Desativar ofertas existentes
    await connection.execute(`
      UPDATE downsell_offers 
      SET is_active = 0, updated_at = CURRENT_TIMESTAMP 
      WHERE bot_id = ?
    `, [botId]);

    // Inserir novas ofertas
    for (const offer of downsellConfig.offers || []) {
      if (offer.id) {
        // Atualizar oferta existente
        await connection.execute(`
          UPDATE downsell_offers SET
            original_plan_id = ?,
            alternative_plan_id = ?,
            title = ?,
            message = ?,
            discount_percentage = ?,
            urgency_message = ?,
            delay_hours = ?,
            max_attempts = ?,
            display_order = ?,
            is_active = 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND bot_id = ?
        `, [
          offer.originalPlanId, offer.alternativePlanId, offer.title,
          offer.message, offer.discountPercentage, offer.urgencyMessage,
          offer.delayHours, offer.maxAttempts, offer.displayOrder,
          offer.id, botId
        ]);
      } else {
        // Inserir nova oferta
        await connection.execute(`
          INSERT INTO downsell_offers (
            bot_id, original_plan_id, alternative_plan_id, title, message,
            discount_percentage, urgency_message, delay_hours, max_attempts,
            display_order, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
        `, [
          botId, offer.originalPlanId, offer.alternativePlanId, offer.title,
          offer.message, offer.discountPercentage, offer.urgencyMessage,
          offer.delayHours, offer.maxAttempts, offer.displayOrder
        ]);
      }
    }
  }

  async executeOrderBump(userId, botId, transactionId, selectedOffer) {
    try {
      const telegramService = new TelegramBotService();
      const paymentService = new PaymentService();

      // Buscar dados da transação
      const [transactionRows] = await pool.execute(`
        SELECT * FROM transactions WHERE id = ? AND user_id = ?
      `, [transactionId, userId]);

      if (transactionRows.length === 0) {
        throw new Error('Transação não encontrada');
      }

      const transaction = transactionRows[0];

      // Buscar dados da oferta
      const [offerRows] = await pool.execute(`
        SELECT * FROM order_bump_offers WHERE id = ? AND bot_id = ?
      `, [selectedOffer.offerId, botId]);

      if (offerRows.length === 0) {
        throw new Error('Oferta não encontrada');
      }

      const offer = offerRows[0];

      // Criar nova transação para o order bump
      const orderBumpTransaction = await paymentService.createTransaction({
        userId,
        botId,
        planId: offer.plan_id,
        amount: offer.offer_price,
        type: 'order_bump',
        parentTransactionId: transactionId,
        description: `Order Bump: ${offer.title}`
      });

      // Enviar mensagem para o usuário
      await telegramService.sendOrderBumpMessage(
        transaction.telegram_user_id,
        offer,
        orderBumpTransaction.id
      );

      // Registrar evento
      await this.logFunnelEvent(userId, botId, 'order_bump_triggered', {
        transactionId,
        offerId: selectedOffer.offerId,
        orderBumpTransactionId: orderBumpTransaction.id
      });

      return {
        success: true,
        orderBumpTransactionId: orderBumpTransaction.id,
        message: 'Order bump executado com sucesso'
      };
    } catch (error) {
      console.error('Erro ao executar order bump:', error);
      throw error;
    }
  }

  async executeUpsell(userId, botId, transactionId, messageId) {
    try {
      const telegramService = new TelegramBotService();

      // Buscar dados da transação
      const [transactionRows] = await pool.execute(`
        SELECT * FROM transactions WHERE id = ? AND user_id = ?
      `, [transactionId, userId]);

      if (transactionRows.length === 0) {
        throw new Error('Transação não encontrada');
      }

      const transaction = transactionRows[0];

      // Buscar dados da mensagem de upsell
      const [messageRows] = await pool.execute(`
        SELECT * FROM upsell_messages WHERE id = ? AND bot_id = ?
      `, [messageId, botId]);

      if (messageRows.length === 0) {
        throw new Error('Mensagem de upsell não encontrada');
      }

      const message = messageRows[0];

      // Verificar se já foi enviado o número máximo de tentativas
      const [attemptRows] = await pool.execute(`
        SELECT COUNT(*) as attempts FROM funnel_events 
        WHERE transaction_id = ? AND event_type = 'upsell_attempt'
      `, [transactionId]);

      if (attemptRows[0].attempts >= message.max_attempts) {
        throw new Error('Número máximo de tentativas de upsell atingido');
      }

      // Enviar mensagem de upsell
      await telegramService.sendUpsellMessage(
        transaction.telegram_user_id,
        message,
        transactionId
      );

      // Registrar evento
      await this.logFunnelEvent(userId, botId, 'upsell_attempt', {
        transactionId,
        messageId,
        attemptNumber: attemptRows[0].attempts + 1
      });

      return {
        success: true,
        message: 'Upsell executado com sucesso'
      };
    } catch (error) {
      console.error('Erro ao executar upsell:', error);
      throw error;
    }
  }

  async executeDownsell(userId, botId, transactionId, offerId) {
    try {
      const telegramService = new TelegramBotService();
      const paymentService = new PaymentService();

      // Buscar dados da transação
      const [transactionRows] = await pool.execute(`
        SELECT * FROM transactions WHERE id = ? AND user_id = ?
      `, [transactionId, userId]);

      if (transactionRows.length === 0) {
        throw new Error('Transação não encontrada');
      }

      const transaction = transactionRows[0];

      // Buscar dados da oferta de downsell
      const [offerRows] = await pool.execute(`
        SELECT * FROM downsell_offers WHERE id = ? AND bot_id = ?
      `, [offerId, botId]);

      if (offerRows.length === 0) {
        throw new Error('Oferta de downsell não encontrada');
      }

      const offer = offerRows[0];

      // Criar nova transação para o downsell
      const downsellTransaction = await paymentService.createTransaction({
        userId,
        botId,
        planId: offer.alternative_plan_id,
        amount: offer.discount_percentage > 0 ? 
          (transaction.amount * (1 - offer.discount_percentage / 100)) : 
          transaction.amount,
        type: 'downsell',
        parentTransactionId: transactionId,
        description: `Downsell: ${offer.title}`
      });

      // Enviar mensagem para o usuário
      await telegramService.sendDownsellMessage(
        transaction.telegram_user_id,
        offer,
        downsellTransaction.id
      );

      // Registrar evento
      await this.logFunnelEvent(userId, botId, 'downsell_triggered', {
        transactionId,
        offerId,
        downsellTransactionId: downsellTransaction.id
      });

      return {
        success: true,
        downsellTransactionId: downsellTransaction.id,
        message: 'Downsell executado com sucesso'
      };
    } catch (error) {
      console.error('Erro ao executar downsell:', error);
      throw error;
    }
  }

  async logFunnelEvent(userId, botId, eventType, eventData) {
    try {
      await pool.execute(`
        INSERT INTO funnel_events (user_id, bot_id, event_type, event_data, created_at)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
      `, [userId, botId, eventType, JSON.stringify(eventData)]);
    } catch (error) {
      console.error('Erro ao registrar evento do funil:', error);
    }
  }
}
```

### **PASSO 4: Schema do Banco**

```sql
-- backend/database/sales_funnel_schema.sql

-- Tabela de ofertas de Order Bump
CREATE TABLE IF NOT EXISTS order_bump_offers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bot_id INT NOT NULL,
  plan_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  original_price DECIMAL(10,2) NOT NULL,
  offer_price DECIMAL(10,2) NOT NULL,
  discount_percentage DECIMAL(5,2) NOT NULL,
  urgency_message TEXT,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE,
  FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE
);

-- Tabela de mensagens de Upsell
CREATE TABLE IF NOT EXISTS upsell_messages (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bot_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  target_plans JSON,
  delay_minutes INT DEFAULT 60,
  max_attempts INT DEFAULT 3,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE
);

-- Tabela de ofertas de Downsell
CREATE TABLE IF NOT EXISTS downsell_offers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bot_id INT NOT NULL,
  original_plan_id INT NOT NULL,
  alternative_plan_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  discount_percentage DECIMAL(5,2) DEFAULT 0,
  urgency_message TEXT,
  delay_hours INT DEFAULT 24,
  max_attempts INT DEFAULT 2,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE,
  FOREIGN KEY (original_plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (alternative_plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE
);

-- Tabela de eventos do funil
CREATE TABLE IF NOT EXISTS funnel_events (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  bot_id INT NOT NULL,
  transaction_id INT,
  event_type VARCHAR(50) NOT NULL,
  event_data JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL,
  INDEX idx_user_bot_event (user_id, bot_id, event_type),
  INDEX idx_transaction_event (transaction_id, event_type)
);

-- Tabela de métricas do funil
CREATE TABLE IF NOT EXISTS funnel_metrics (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  bot_id INT NOT NULL,
  date DATE NOT NULL,
  order_bump_impressions INT DEFAULT 0,
  order_bump_conversions INT DEFAULT 0,
  upsell_impressions INT DEFAULT 0,
  upsell_conversions INT DEFAULT 0,
  downsell_impressions INT DEFAULT 0,
  downsell_conversions INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_bot_date (user_id, bot_id, date)
);
```

### **PASSO 5: Componente Frontend**

```typescript
// src/components/SalesFunnel.tsx
import React, { useState, useEffect } from 'react';
import { useAuth } from "@/hooks/useAuth";
import { apiService } from "@/services/api";

export const SalesFunnel = ({ botId }: { botId: string }) => {
  const { user } = useAuth();
  const [funnel, setFunnel] = useState<SalesFunnel | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (botId) {
      loadSalesFunnel();
    }
  }, [botId]);

  const loadSalesFunnel = async () => {
    setLoading(true);
    try {
      const response = await apiService.get(`/sales-funnel/${botId}`);
      if (response.success) {
        setFunnel(response.data);
      }
    } catch (error) {
      console.error('Erro ao carregar funil de vendas:', error);
    }
    setLoading(false);
  };

  const saveFunnel = async () => {
    setSaving(true);
    try {
      const response = await apiService.put(`/sales-funnel/${botId}`, funnel);
      if (response.success) {
        // Sucesso
      }
    } catch (error) {
      console.error('Erro ao salvar funil de vendas:', error);
    }
    setSaving(false);
  };

  if (loading) {
    return <div>Carregando...</div>;
  }

  return (
    <div className="space-y-8">
      {/* Order Bump */}
      <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold text-white">Order Bump</h3>
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={funnel?.orderBump.enabled || false}
              onChange={(e) => setFunnel(prev => ({
                ...prev,
                orderBump: { ...prev.orderBump, enabled: e.target.checked }
              }))}
              className="w-4 h-4 text-blue-600 rounded"
            />
            <span className="text-gray-300">Ativo</span>
          </label>
        </div>

        {funnel?.orderBump.enabled && (
          <div className="space-y-4">
            {funnel.orderBump.offers?.map((offer, index) => (
              <div key={offer.id || index} className="bg-white/5 rounded-lg p-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm text-gray-300 mb-1">Título</label>
                    <input
                      type="text"
                      value={offer.title}
                      onChange={(e) => {
                        const newOffers = [...funnel.orderBump.offers];
                        newOffers[index].title = e.target.value;
                        setFunnel(prev => ({
                          ...prev,
                          orderBump: { ...prev.orderBump, offers: newOffers }
                        }));
                      }}
                      className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-300 mb-1">Preço Original</label>
                    <input
                      type="number"
                      step="0.01"
                      value={offer.originalPrice}
                      onChange={(e) => {
                        const newOffers = [...funnel.orderBump.offers];
                        newOffers[index].originalPrice = parseFloat(e.target.value);
                        setFunnel(prev => ({
                          ...prev,
                          orderBump: { ...prev.orderBump, offers: newOffers }
                        }));
                      }}
                      className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-300 mb-1">Preço Oferta</label>
                    <input
                      type="number"
                      step="0.01"
                      value={offer.offerPrice}
                      onChange={(e) => {
                        const newOffers = [...funnel.orderBump.offers];
                        newOffers[index].offerPrice = parseFloat(e.target.value);
                        setFunnel(prev => ({
                          ...prev,
                          orderBump: { ...prev.orderBump, offers: newOffers }
                        }));
                      }}
                      className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-300 mb-1">Desconto (%)</label>
                    <input
                      type="number"
                      step="0.01"
                      value={offer.discountPercentage}
                      onChange={(e) => {
                        const newOffers = [...funnel.orderBump.offers];
                        newOffers[index].discountPercentage = parseFloat(e.target.value);
                        setFunnel(prev => ({
                          ...prev,
                          orderBump: { ...prev.orderBump, offers: newOffers }
                        }));
                      }}
                      className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                    />
                  </div>
                </div>
                <div className="mt-4">
                  <label className="block text-sm text-gray-300 mb-1">Descrição</label>
                  <textarea
                    value={offer.description}
                    onChange={(e) => {
                      const newOffers = [...funnel.orderBump.offers];
                      newOffers[index].description = e.target.value;
                      setFunnel(prev => ({
                        ...prev,
                        orderBump: { ...prev.orderBump, offers: newOffers }
                      }));
                    }}
                    rows={3}
                    className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  />
                </div>
              </div>
            ))}
            
            <button
              onClick={() => {
                const newOffers = [...(funnel?.orderBump.offers || []), {
                  title: '', description: '', originalPrice: 0, offerPrice: 0, discountPercentage: 0
                }];
                setFunnel(prev => ({
                  ...prev,
                  orderBump: { ...prev.orderBump, offers: newOffers }
                }));
              }}
              className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium"
            >
              + Adicionar Oferta Order Bump
            </button>
          </div>
        )}
      </div>

      {/* Upsell */}
      <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold text-white">Upsell</h3>
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={funnel?.upsell.enabled || false}
              onChange={(e) => setFunnel(prev => ({
                ...prev,
                upsell: { ...prev.upsell, enabled: e.target.checked }
              }))}
              className="w-4 h-4 text-blue-600 rounded"
            />
            <span className="text-gray-300">Ativo</span>
          </label>
        </div>

        {funnel?.upsell.enabled && (
          <div className="space-y-4">
            {funnel.upsell.messages?.map((message, index) => (
              <div key={message.id || index} className="bg-white/5 rounded-lg p-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm text-gray-300 mb-1">Título</label>
                    <input
                      type="text"
                      value={message.title}
                      onChange={(e) => {
                        const newMessages = [...funnel.upsell.messages];
                        newMessages[index].title = e.target.value;
                        setFunnel(prev => ({
                          ...prev,
                          upsell: { ...prev.upsell, messages: newMessages }
                        }));
                      }}
                      className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-sm text-gray-300 mb-1">Delay (minutos)</label>
                    <input
                      type="number"
                      value={message.delayMinutes}
                      onChange={(e) => {
                        const newMessages = [...funnel.upsell.messages];
                        newMessages[index].delayMinutes = parseInt(e.target.value);
                        setFunnel(prev => ({
                          ...prev,
                          upsell: { ...prev.upsell, messages: newMessages }
                        }));
                      }}
                      className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                    />
                  </div>
                </div>
                <div className="mt-4">
                  <label className="block text-sm text-gray-300 mb-1">Mensagem</label>
                  <textarea
                    value={message.message}
                    onChange={(e) => {
                      const newMessages = [...funnel.upsell.messages];
                      newMessages[index].message = e.target.value;
                      setFunnel(prev => ({
                        ...prev,
                        upsell: { ...prev.upsell, messages: newMessages }
                      }));
                    }}
                    rows={4}
                    className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  />
                </div>
              </div>
            ))}
            
            <button
              onClick={() => {
                const newMessages = [...(funnel?.upsell.messages || []), {
                  title: '', message: '', delayMinutes: 60, maxAttempts: 3
                }];
                setFunnel(prev => ({
                  ...prev,
                  upsell: { ...prev.upsell, messages: newMessages }
                }));
              }}
              className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium"
            >
              + Adicionar Mensagem Upsell
            </button>
          </div>
        )}
      </div>

      {/* Botões de Ação */}
      <div className="flex justify-end space-x-4">
        <button
          onClick={saveFunnel}
          disabled={saving}
          className="px-6 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium disabled:opacity-50"
        >
          {saving ? 'Salvando...' : 'Salvar Funil de Vendas'}
        </button>
      </div>
    </div>
  );
};
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### **Backend:**
- [ ] Criar tipos TypeScript para sales funnel
- [ ] Implementar rotas do funil de vendas
- [ ] Criar SalesFunnelService
- [ ] Atualizar schema do banco
- [ ] Implementar lógica de execução
- [ ] Adicionar tracking de eventos

### **Frontend:**
- [ ] Criar componente SalesFunnel
- [ ] Implementar formulários dinâmicos
- [ ] Adicionar validações
- [ ] Implementar preview de mensagens
- [ ] Adicionar métricas de performance
- [ ] Implementar auto-save

### **Integração:**
- [ ] Conectar rotas no index.js
- [ ] Atualizar API service
- [ ] Testar todas as funcionalidades
- [ ] Implementar tratamento de erros
- [ ] Otimizar performance

**Próximo arquivo:** `04_DATABASE_SCHEMA.md` 🚀



