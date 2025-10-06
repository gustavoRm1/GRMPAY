# 🤖 SISTEMA DE BOTS AVANÇADO - CONFIGURAÇÃO COMPLETA

## 🎯 OBJETIVO
Implementar um sistema de bots avançado que permita configuração completa, similar ao concorrente, mas com UX superior e funcionalidades mais robustas.

## 📋 FUNCIONALIDADES IMPLEMENTADAS

### 🔧 CONFIGURAÇÕES BÁSICAS
- **Username e Token** do bot
- **Mensagem Inicial** personalizável com variáveis
- **Configuração de Mídia** (PNG, JPEG, MP4 até 25MB)
- **Configuração de Áudio** (OGG até 10MB)

### 🎯 CONFIGURAÇÕES AVANÇADAS
- **IDs de Grupos/Canais** (VIP e Registro)
- **Links Automáticos** gerados
- **Suporte do Bot** configurável
- **Planos de Assinatura** e Pacotes
- **Botões Personalizados**
- **CTA Button** configurável

---

## 🛠️ IMPLEMENTAÇÃO PASSO A PASSO

### **PASSO 1: Estrutura de Dados**

```typescript
// src/types/bot.ts
export interface BotConfiguration {
  id?: number;
  userId: number;
  username: string;
  token: string;
  initialMessage: string;
  mediaSettings: MediaSettings;
  audioSettings: AudioSettings;
  groupSettings: GroupSettings;
  supportSettings: SupportSettings;
  subscriptionPlans: SubscriptionPlan[];
  packagePlans: PackagePlan[];
  customButtons: CustomButton[];
  ctaButton: CTAButton;
  paymentSettings: PaymentSettings;
}

export interface MediaSettings {
  enabled: boolean;
  maxSize: number; // MB
  allowedFormats: string[];
  sendingMethod: 'separated' | 'album';
  mediaFiles: MediaFile[];
}

export interface GroupSettings {
  vipGroupId: string;
  registrationGroupId: string;
  vipLink: string;
}

export interface SubscriptionPlan {
  id?: number;
  name: string;
  duration: string;
  price: number;
  isActive: boolean;
}

export interface PackagePlan {
  id?: number;
  name: string;
  price: number;
  deliverable: string;
  isActive: boolean;
}
```

### **PASSO 2: API Backend**

```typescript
// backend/src/routes/botConfiguration.js
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { BotConfigurationService } from '../services/BotConfigurationService.js';

const router = Router();
router.use(authMiddleware);

// Obter configuração do bot
router.get('/:botId', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    
    const botService = new BotConfigurationService();
    const config = await botService.getBotConfiguration(userId, botId);
    
    res.json({ success: true, data: config });
  } catch (error) {
    console.error('Erro ao obter configuração do bot:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Salvar configuração do bot
router.put('/:botId', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    const configData = req.body;
    
    const botService = new BotConfigurationService();
    const result = await botService.updateBotConfiguration(userId, botId, configData);
    
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Erro ao salvar configuração:', error);
    res.status(500).json({ success: false, error: 'Erro interno' });
  }
});

// Upload de mídia
router.post('/:botId/media', async (req, res) => {
  try {
    const { botId } = req.params;
    const userId = req.user.userId;
    
    // Implementar upload de arquivo
    const botService = new BotConfigurationService();
    const result = await botService.uploadMedia(userId, botId, req.file);
    
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Erro no upload de mídia:', error);
    res.status(500).json({ success: false, error: 'Erro no upload' });
  }
});

export { router as botConfigurationRoutes };
```

### **PASSO 3: Serviço de Configuração**

```typescript
// backend/src/services/BotConfigurationService.js
import { pool } from '../config/database.js';
import { encryptCredentials } from '../utils/encryption.js';

export class BotConfigurationService {
  
  async getBotConfiguration(userId, botId) {
    try {
      // Buscar configuração básica
      const [botRows] = await pool.execute(`
        SELECT * FROM user_bots 
        WHERE id = ? AND user_id = ?
      `, [botId, userId]);

      if (botRows.length === 0) {
        throw new Error('Bot não encontrado');
      }

      const bot = botRows[0];
      
      // Buscar planos de assinatura
      const [subscriptionRows] = await pool.execute(`
        SELECT * FROM subscription_plans 
        WHERE bot_id = ? AND is_active = 1
        ORDER BY price ASC
      `, [botId]);

      // Buscar planos de pacote
      const [packageRows] = await pool.execute(`
        SELECT * FROM package_plans 
        WHERE bot_id = ? AND is_active = 1
        ORDER BY price ASC
      `, [botId]);

      // Buscar botões personalizados
      const [buttonRows] = await pool.execute(`
        SELECT * FROM custom_buttons 
        WHERE bot_id = ? AND is_active = 1
        ORDER BY created_at ASC
      `, [botId]);

      // Buscar configurações de mídia
      const [mediaRows] = await pool.execute(`
        SELECT * FROM bot_media 
        WHERE bot_id = ? AND is_active = 1
        ORDER BY created_at ASC
      `, [botId]);

      return {
        id: bot.id,
        userId: bot.user_id,
        username: bot.username,
        token: bot.token,
        initialMessage: bot.initial_message,
        vipGroupId: bot.vip_group_id,
        registrationGroupId: bot.registration_group_id,
        vipLink: bot.vip_link,
        supportUsername: bot.support_username,
        mediaSettings: {
          enabled: bot.media_enabled,
          maxSize: bot.media_max_size,
          allowedFormats: JSON.parse(bot.media_formats || '[]'),
          sendingMethod: bot.media_sending_method,
          mediaFiles: mediaRows
        },
        subscriptionPlans: subscriptionRows,
        packagePlans: packageRows,
        customButtons: buttonRows,
        ctaButton: {
          enabled: bot.cta_enabled,
          text: bot.cta_text,
          url: bot.cta_url
        },
        paymentSettings: {
          showQRCode: bot.show_qr_code,
          paymentMethods: JSON.parse(bot.payment_methods || '[]')
        }
      };
    } catch (error) {
      console.error('Erro ao obter configuração do bot:', error);
      throw error;
    }
  }

  async updateBotConfiguration(userId, botId, configData) {
    try {
      const connection = await pool.getConnection();
      await connection.beginTransaction();

      try {
        // Atualizar configurações básicas
        await connection.execute(`
          UPDATE user_bots SET
            username = ?,
            token = ?,
            initial_message = ?,
            vip_group_id = ?,
            registration_group_id = ?,
            vip_link = ?,
            support_username = ?,
            media_enabled = ?,
            media_max_size = ?,
            media_formats = ?,
            media_sending_method = ?,
            cta_enabled = ?,
            cta_text = ?,
            cta_url = ?,
            show_qr_code = ?,
            payment_methods = ?,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND user_id = ?
        `, [
          configData.username,
          configData.token,
          configData.initialMessage,
          configData.vipGroupId,
          configData.registrationGroupId,
          configData.vipLink,
          configData.supportUsername,
          configData.mediaSettings?.enabled || false,
          configData.mediaSettings?.maxSize || 25,
          JSON.stringify(configData.mediaSettings?.allowedFormats || []),
          configData.mediaSettings?.sendingMethod || 'separated',
          configData.ctaButton?.enabled || false,
          configData.ctaButton?.text || '',
          configData.ctaButton?.url || '',
          configData.paymentSettings?.showQRCode || true,
          JSON.stringify(configData.paymentSettings?.paymentMethods || []),
          botId,
          userId
        ]);

        // Atualizar planos de assinatura
        if (configData.subscriptionPlans) {
          await this.updateSubscriptionPlans(connection, botId, configData.subscriptionPlans);
        }

        // Atualizar planos de pacote
        if (configData.packagePlans) {
          await this.updatePackagePlans(connection, botId, configData.packagePlans);
        }

        // Atualizar botões personalizados
        if (configData.customButtons) {
          await this.updateCustomButtons(connection, botId, configData.customButtons);
        }

        await connection.commit();
        
        return { success: true, message: 'Configuração atualizada com sucesso' };
      } catch (error) {
        await connection.rollback();
        throw error;
      } finally {
        connection.release();
      }
    } catch (error) {
      console.error('Erro ao atualizar configuração:', error);
      throw error;
    }
  }

  async updateSubscriptionPlans(connection, botId, plans) {
    // Desativar planos existentes
    await connection.execute(`
      UPDATE subscription_plans 
      SET is_active = 0, updated_at = CURRENT_TIMESTAMP 
      WHERE bot_id = ?
    `, [botId]);

    // Inserir novos planos
    for (const plan of plans) {
      if (plan.id) {
        // Atualizar plano existente
        await connection.execute(`
          UPDATE subscription_plans SET
            name = ?,
            duration = ?,
            price = ?,
            is_active = 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND bot_id = ?
        `, [plan.name, plan.duration, plan.price, plan.id, botId]);
      } else {
        // Inserir novo plano
        await connection.execute(`
          INSERT INTO subscription_plans (bot_id, name, duration, price, is_active)
          VALUES (?, ?, ?, ?, 1)
        `, [botId, plan.name, plan.duration, plan.price]);
      }
    }
  }

  async updatePackagePlans(connection, botId, plans) {
    // Desativar planos existentes
    await connection.execute(`
      UPDATE package_plans 
      SET is_active = 0, updated_at = CURRENT_TIMESTAMP 
      WHERE bot_id = ?
    `, [botId]);

    // Inserir novos planos
    for (const plan of plans) {
      if (plan.id) {
        // Atualizar plano existente
        await connection.execute(`
          UPDATE package_plans SET
            name = ?,
            price = ?,
            deliverable = ?,
            is_active = 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND bot_id = ?
        `, [plan.name, plan.price, plan.deliverable, plan.id, botId]);
      } else {
        // Inserir novo plano
        await connection.execute(`
          INSERT INTO package_plans (bot_id, name, price, deliverable, is_active)
          VALUES (?, ?, ?, ?, 1)
        `, [botId, plan.name, plan.price, plan.deliverable]);
      }
    }
  }

  async updateCustomButtons(connection, botId, buttons) {
    // Desativar botões existentes
    await connection.execute(`
      UPDATE custom_buttons 
      SET is_active = 0, updated_at = CURRENT_TIMESTAMP 
      WHERE bot_id = ?
    `, [botId]);

    // Inserir novos botões
    for (const button of buttons) {
      if (button.id) {
        // Atualizar botão existente
        await connection.execute(`
          UPDATE custom_buttons SET
            text = ?,
            url = ?,
            is_active = 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ? AND bot_id = ?
        `, [button.text, button.url, button.id, botId]);
      } else {
        // Inserir novo botão
        await connection.execute(`
          INSERT INTO custom_buttons (bot_id, text, url, is_active)
          VALUES (?, ?, ?, 1)
        `, [botId, button.text, button.url]);
      }
    }
  }

  async uploadMedia(userId, botId, file) {
    try {
      // Validar arquivo
      const allowedFormats = ['png', 'jpeg', 'jpg', 'mp4'];
      const maxSize = 25 * 1024 * 1024; // 25MB

      if (!allowedFormats.includes(file.originalname.split('.').pop().toLowerCase())) {
        throw new Error('Formato de arquivo não permitido');
      }

      if (file.size > maxSize) {
        throw new Error('Arquivo muito grande (máximo 25MB)');
      }

      // Salvar arquivo (implementar storage)
      const filePath = `uploads/bots/${botId}/${Date.now()}_${file.originalname}`;
      
      // Salvar no banco
      const [result] = await pool.execute(`
        INSERT INTO bot_media (bot_id, filename, original_name, file_path, file_size, mime_type, is_active)
        VALUES (?, ?, ?, ?, ?, ?, 1)
      `, [botId, file.filename, file.originalname, filePath, file.size, file.mimetype]);

      return {
        id: result.insertId,
        filename: file.filename,
        originalName: file.originalname,
        fileSize: file.size,
        mimeType: file.mimetype
      };
    } catch (error) {
      console.error('Erro no upload de mídia:', error);
      throw error;
    }
  }
}
```

### **PASSO 4: Schema do Banco**

```sql
-- backend/database/bot_configuration_schema.sql

-- Tabela principal de bots (expandida)
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS initial_message TEXT;
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS vip_group_id VARCHAR(100);
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS registration_group_id VARCHAR(100);
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS vip_link VARCHAR(255);
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS support_username VARCHAR(100);
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS media_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS media_max_size INT DEFAULT 25;
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS media_formats JSON;
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS media_sending_method ENUM('separated', 'album') DEFAULT 'separated';
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS cta_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS cta_text VARCHAR(100);
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS cta_url VARCHAR(255);
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS show_qr_code BOOLEAN DEFAULT TRUE;
ALTER TABLE user_bots ADD COLUMN IF NOT EXISTS payment_methods JSON;

-- Tabela de planos de assinatura
CREATE TABLE IF NOT EXISTS subscription_plans (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bot_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  duration VARCHAR(50) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE
);

-- Tabela de planos de pacote
CREATE TABLE IF NOT EXISTS package_plans (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bot_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  deliverable TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE
);

-- Tabela de botões personalizados
CREATE TABLE IF NOT EXISTS custom_buttons (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bot_id INT NOT NULL,
  text VARCHAR(100) NOT NULL,
  url VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE
);

-- Tabela de mídia dos bots
CREATE TABLE IF NOT EXISTS bot_media (
  id INT PRIMARY KEY AUTO_INCREMENT,
  bot_id INT NOT NULL,
  filename VARCHAR(255) NOT NULL,
  original_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  file_size INT NOT NULL,
  mime_type VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (bot_id) REFERENCES user_bots(id) ON DELETE CASCADE
);
```

### **PASSO 5: Componente Frontend**

```typescript
// src/components/BotConfiguration.tsx
import React, { useState, useEffect } from 'react';
import { useAuth } from "@/hooks/useAuth";
import { apiService } from "@/services/api";

export const BotConfiguration = ({ botId }: { botId: string }) => {
  const { user } = useAuth();
  const [config, setConfig] = useState<BotConfiguration | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (botId) {
      loadBotConfiguration();
    }
  }, [botId]);

  const loadBotConfiguration = async () => {
    setLoading(true);
    try {
      const response = await apiService.get(`/bot-configuration/${botId}`);
      if (response.success) {
        setConfig(response.data);
      }
    } catch (error) {
      console.error('Erro ao carregar configuração:', error);
    }
    setLoading(false);
  };

  const saveConfiguration = async () => {
    setSaving(true);
    try {
      const response = await apiService.put(`/bot-configuration/${botId}`, config);
      if (response.success) {
        // Sucesso
      }
    } catch (error) {
      console.error('Erro ao salvar configuração:', error);
    }
    setSaving(false);
  };

  if (loading) {
    return <div>Carregando...</div>;
  }

  return (
    <div className="space-y-8">
      {/* Configurações Básicas */}
      <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
        <h3 className="text-xl font-bold text-white mb-6">
          Configurações do Bot
        </h3>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm text-gray-300 mb-2">Username</label>
            <input
              type="text"
              value={config?.username || ''}
              onChange={(e) => setConfig(prev => ({ ...prev, username: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>

          <div>
            <label className="block text-sm text-gray-300 mb-2">Token</label>
            <input
              type="password"
              value={config?.token || ''}
              onChange={(e) => setConfig(prev => ({ ...prev, token: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>

          <div>
            <label className="block text-sm text-gray-300 mb-2">Mensagem Inicial</label>
            <textarea
              value={config?.initialMessage || ''}
              onChange={(e) => setConfig(prev => ({ ...prev, initialMessage: e.target.value }))}
              rows={8}
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white"
              placeholder="Digite a mensagem inicial do bot..."
            />
            <p className="text-xs text-gray-400 mt-1">
              Variáveis disponíveis: {`{profile_name}, {city}, {state}`}
            </p>
          </div>
        </div>
      </div>

      {/* Planos de Assinatura */}
      <div className="bg-white/10 backdrop-blur-md rounded-xl border border-white/20 p-6">
        <h3 className="text-xl font-bold text-white mb-6">
          Planos de Assinatura
        </h3>
        
        <div className="space-y-4">
          {config?.subscriptionPlans?.map((plan, index) => (
            <div key={plan.id || index} className="bg-white/5 rounded-lg p-4">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm text-gray-300 mb-1">Nome</label>
                  <input
                    type="text"
                    value={plan.name}
                    onChange={(e) => {
                      const newPlans = [...config.subscriptionPlans];
                      newPlans[index].name = e.target.value;
                      setConfig(prev => ({ ...prev, subscriptionPlans: newPlans }));
                    }}
                    className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-300 mb-1">Duração</label>
                  <input
                    type="text"
                    value={plan.duration}
                    onChange={(e) => {
                      const newPlans = [...config.subscriptionPlans];
                      newPlans[index].duration = e.target.value;
                      setConfig(prev => ({ ...prev, subscriptionPlans: newPlans }));
                    }}
                    className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm text-gray-300 mb-1">Valor</label>
                  <input
                    type="number"
                    step="0.01"
                    value={plan.price}
                    onChange={(e) => {
                      const newPlans = [...config.subscriptionPlans];
                      newPlans[index].price = parseFloat(e.target.value);
                      setConfig(prev => ({ ...prev, subscriptionPlans: newPlans }));
                    }}
                    className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  />
                </div>
              </div>
            </div>
          ))}
          
          <button
            onClick={() => {
              const newPlans = [...(config?.subscriptionPlans || []), { name: '', duration: '', price: 0 }];
              setConfig(prev => ({ ...prev, subscriptionPlans: newPlans }));
            }}
            className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium"
          >
            + Adicionar Plano
          </button>
        </div>
      </div>

      {/* Botões de Ação */}
      <div className="flex justify-end space-x-4">
        <button
          onClick={saveConfiguration}
          disabled={saving}
          className="px-6 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium disabled:opacity-50"
        >
          {saving ? 'Salvando...' : 'Salvar Alterações'}
        </button>
      </div>
    </div>
  );
};
```

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

### **Backend:**
- [ ] Criar tipos TypeScript para bot configuration
- [ ] Implementar rotas de configuração
- [ ] Criar BotConfigurationService
- [ ] Atualizar schema do banco
- [ ] Implementar upload de mídia
- [ ] Adicionar validações

### **Frontend:**
- [ ] Criar componente BotConfiguration
- [ ] Implementar formulários dinâmicos
- [ ] Adicionar upload de arquivos
- [ ] Implementar preview de mídia
- [ ] Adicionar validações frontend
- [ ] Implementar auto-save

### **Integração:**
- [ ] Conectar rotas no index.js
- [ ] Atualizar API service
- [ ] Testar todas as funcionalidades
- [ ] Implementar tratamento de erros
- [ ] Otimizar performance

**Próximo arquivo:** `03_SALES_FUNNEL.md` 🚀



