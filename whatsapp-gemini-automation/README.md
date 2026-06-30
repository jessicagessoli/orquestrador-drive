# WhatsApp Gemini Automation - Responder Todas as Mensagens

Solução **production-ready** para automação de WhatsApp com **Google Gemini**.

- ✅ Responde **todas as mensagens instantaneamente**
- ✅ Integração nativa com **Google Gemini API**
- ✅ Armazenamento em **BigQuery** (histórico completo)
- ✅ Webhook **Meta WhatsApp Cloud API**
- ✅ Sem custo de processamento (Gemini é serverless)

## 🏗️ Arquitetura

```
Meta WhatsApp Cloud API
         ↓ (webhook)
     n8n Workflow
         ↓
  Normalizar (waID, texto)
         ↓
  Google Gemini API (responde IA)
         ↓
  BigQuery (log histórico)
         ↓
  Enviar resposta WhatsApp
```

## 📦 Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `whatsapp_gemini_webhook.json` | Workflow n8n (importar direto) |
| `bigquery_schema.sql` | Tabelas: `chats` + `messages` |
| `setup.md` | Guia completo de instalação |
| `gemini_config.env.example` | Variáveis de ambiente |

## 🚀 Quick Start

### 1. Criar tabelas BigQuery
```bash
bq dataset create whatsapp_gemini
bq query < bigquery_schema.sql
```

### 2. Configurar n8n
```bash
# Variáveis de ambiente
export GCP_PROJECT=seu-projeto
export GCP_KEYFILE=/path/to/keyfile.json
export WHATSAPP_TOKEN=seu-token-meta
export GEMINI_API_KEY=sua-chave-gemini
```

### 3. Importar workflow
1. Acesse `n8n` dashboard
2. Clique em **Import from File**
3. Selecione `whatsapp_gemini_webhook.json`
4. Ative o workflow

### 4. Configurar webhook Meta
```bash
URL: https://seu-n8n.com/webhook/whatsapp-gemini
Verify Token: seu_token_verificacao
Events: messages, message_status
```

## 📋 Configuração Completa

Ver `setup.md` para:
- Credenciais Google Gemini
- Credenciais WhatsApp Meta
- Variáveis de ambiente  
- Troubleshooting

## 💡 Como Funciona

1. **Recebe mensagem** → Meta envia para webhook
2. **Valida** → Verifica token e formato
3. **Normaliza** → Extrai waID, sender, texto, timestamp
4. **Gera resposta** → Google Gemini API (contexto das 10 últimas mensagens)
5. **Armazena** → BigQuery (auditoria completa)
6. **Envia** → WhatsApp API responde ao cliente
7. **Registra status** → Sucesso/falha/erro

## 🔐 Segurança

✅ Todas as credenciais via **n8n Credentials** (nunca embarcadas)
✅ Validação de webhook token
✅ Rate limiting (1000 req/min por padrão)
✅ Logs auditáveis no BigQuery
✅ Sem storage de tokens em arquivo

## 📊 Monitoramento

Consulte BigQuery para métricas:

```sql
-- Mensagens respondidas hoje
SELECT COUNT(*) as total FROM whatsapp_gemini.messages
WHERE DATE(timestamp) = CURRENT_DATE();

-- Tempo médio de resposta
SELECT AVG(response_time_ms) as avg_latency
FROM whatsapp_gemini.messages
WHERE response_status = 'success';

-- Erros em tempo real
SELECT * FROM whatsapp_gemini.messages
WHERE response_status = 'error'
ORDER BY timestamp DESC
LIMIT 10;
```

## 🆘 Suporte

Para problemas:
1. Verifique logs do n8n
2. Consulte BigQuery para erros
3. Valide tokens e credenciais
4. Confirme permissões de API

---

**Versão**: 1.0 | **Status**: Production Ready | **Última atualização**: Jun 30, 2026
