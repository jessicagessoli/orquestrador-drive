# 🚀 Setup Completo - WhatsApp Gemini Automation

Guia passo-a-passo para liberar a automação e responder todas as mensagens com Gemini.

## 📋 Pré-requisitos

- ✅ Google Cloud Project com Gemini API habilitada
- ✅ Meta Developer Account com WhatsApp Cloud API
- ✅ n8n instalado (self-hosted ou n8n Cloud)
- ✅ BigQuery ativo no GCP
- ✅ Python 3.9+ (para scripts auxiliares)

---

## 1️⃣ Configurar Google Gemini API

### 1.1 Obter API Key

```bash
# 1. Ir para Google Cloud Console
# https://console.cloud.google.com/

# 2. Ir em: APIs & Services > Credentials

# 3. Criar nova credencial (API Key)
gcloud auth login
gcloud config set project seu-projeto-gcp

# 4. Habilitar Generative Language API
gcloud services enable generativelanguage.googleapis.com

# 5. Criar service account para BigQuery
gcloud iam service-accounts create whatsapp-gemini-sa \
  --display-name="WhatsApp Gemini Automation"

# 6. Dar permissões
gcloud projects add-iam-policy-binding seu-projeto \
  --member=serviceAccount:whatsapp-gemini-sa@seu-projeto.iam.gserviceaccount.com \
  --role=roles/bigquery.dataEditor

# 7. Criar e baixar key JSON
gcloud iam service-accounts keys create keyfile.json \
  --iam-account=whatsapp-gemini-sa@seu-projeto.iam.gserviceaccount.com
```

### 1.2 Testar conexão

```bash
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contents": [{"parts": [{"text": "Olá Gemini"}]}]}'
```

---

## 2️⃣ Configurar WhatsApp Cloud API (Meta)

### 2.1 Obter credenciais

```bash
# 1. Ir para: https://www.facebook.com/developers/
# 2. Criar app (tipo: Business)
# 3. Adicionar produto: WhatsApp

# 4. Gerar access token
# Em: Configurações da API > Gerar Token

# Salvar:
# - Phone Number ID (ex: 1103483716192608)
# - Business Account ID
# - Access Token
# - Verify Token (criar token aleatório para webhook)
```

### 2.2 Testar API

```bash
export WHATSAPP_TOKEN="seu-access-token"
export PHONE_ID="seu-phone-id"

# Testar envio de mensagem de teste
curl -X POST \
  "https://graph.instagram.com/v18.0/$PHONE_ID/messages" \
  -H "Authorization: Bearer $WHATSAPP_TOKEN" \
  -d '{
    "messaging_product": "whatsapp",
    "to": "seu-numero-teste",
    "type": "text",
    "text": {"body": "Teste de conexão"}
  }'
```

---

## 3️⃣ Configurar BigQuery

### 3.1 Criar dataset e tabelas

```bash
# 1. Ir para BigQuery no console

# 2. Criar dataset
bq mk --dataset \
  --location=US \
  --description="WhatsApp Gemini Automation" \
  whatsapp_gemini

# 3. Executar schema
bq query --use_legacy_sql=false < bigquery_schema.sql

# 4. Verificar tabelas
bq ls -t whatsapp_gemini
```

### 3.2 Dar permissões

```bash
# Service account precisa de:
# - bigquery.dataEditor
# - bigquery.jobUser

gcloud projects add-iam-policy-binding seu-projeto \
  --member=serviceAccount:whatsapp-gemini-sa@seu-projeto.iam.gserviceaccount.com \
  --role=roles/bigquery.dataEditor
```

---

## 4️⃣ Configurar n8n

### 4.1 Instalação local

```bash
# Opção 1: Docker
docker run -d \
  -p 5678:5678 \
  -e NODE_ENV=production \
  -v ~/.n8n:/home/node/.n8n \
  --restart unless-stopped \
  n8nio/n8n

# Opção 2: npm
npm install -g n8n
n8n start

# Acessar: http://localhost:5678
```

### 4.2 Configurar credenciais

**Em n8n Dashboard:**

1. **Settings** > **Credentials**

2. **Criar credencial: Google Gemini**
   - API Key: `seu-gemini-api-key`
   - Model: `gemini-1.5-flash`

3. **Criar credencial: Google BigQuery**
   - Type: `Service Account (JSON)`
   - Cole conteúdo do `keyfile.json`

4. **Criar credencial: HTTP Header Auth**
   - Header: `Authorization`
   - Value: `Bearer seu-whatsapp-token`

### 4.3 Importar workflow

```bash
# 1. Acessar n8n Dashboard
# 2. Workflows > Create New > Import from URL/File
# 3. Selecionar: whatsapp_gemini_webhook.json
# 4. Preencher variáveis de ambiente
# 5. Salvar e Ativar
```

### 4.4 Configurar webhook

**Em n8n:**

1. Clique no nó **Webhook - WhatsApp Input**
2. Copie a URL: `https://seu-n8n.com/webhook/whatsapp-gemini`

**Em Meta Developer Dashboard:**

1. Ir para: **WhatsApp** > **Configurações** > **Webhook**
2. Preencher:
   - **Callback URL**: `https://seu-n8n.com/webhook/whatsapp-gemini`
   - **Verify Token**: mesmo token configurado no n8n
3. **Verificar e Salvar**

---

## 5️⃣ Variáveis de Ambiente

### 5.1 Criar arquivo `.env`

```bash
cp gemini_config.env.example .env
```

### 5.2 Preencher `.env`

```bash
# Google Gemini
GEMINI_API_KEY=AIzaSyD...
GEMINI_MODEL=gemini-1.5-flash
GEMINI_TEMPERATURE=0.7
GEMINI_MAX_TOKENS=1000

# Google BigQuery
GCP_PROJECT=seu-projeto-123
GCP_DATASET=whatsapp_gemini
GCP_KEYFILE=./keyfile.json

# Meta WhatsApp
WHATSAPP_PHONE_NUMBER_ID=1103483716192608
WHATSAPP_ACCESS_TOKEN=EAABa...
WHATSAPP_VERIFY_TOKEN=seu_token_seguro_aqui

# n8n
N8N_BASE_URL=https://seu-n8n.com
WEBHOOK_PATH=/webhook/whatsapp-gemini
```

---

## 6️⃣ Testar End-to-End

### 6.1 Testar webhook

```bash
curl -X POST http://localhost:5678/webhook/whatsapp-gemini \
  -H "Content-Type: application/json" \
  -d '{
    "object": "whatsapp_business_account",
    "entry": [{
      "messaging": [{
        "sender": {"id": "5511999999999"},
        "message": {
          "text": "Olá, tudo bem?",
          "mid": "msg123"
        },
        "timestamp": 1698765432
      }]
    }]
  }'
```

### 6.2 Verificar logs

```bash
# Em n8n: Executions tab
# Em BigQuery: SELECT * FROM whatsapp_gemini.messages ORDER BY received_at DESC LIMIT 10;
# Em Google Cloud Console: Logs
```

### 6.3 Enviar mensagem real

1. Enviar mensagem de um WhatsApp para o número configurado
2. Validar resposta automática em < 2 segundos
3. Conferir registro em BigQuery

---

## 7️⃣ Monitoramento & Alertas

### 7.1 Dashboard BigQuery

```sql
-- Taxa de sucesso em tempo real
SELECT
  TIMESTAMP_TRUNC(received_at, MINUTE) as minute,
  COUNTIF(response_status = 'success') as success,
  COUNTIF(response_status = 'error') as errors,
  COUNTIF(response_status = 'pending') as pending
FROM whatsapp_gemini.messages
WHERE DATE(received_at) = CURRENT_DATE()
GROUP BY minute
ORDER BY minute DESC;
```

### 7.2 Alertas n8n

**Settings > Notifications:**

- Slack webhook para erros
- Email para taxa de erro > 5%

---

## 8️⃣ Troubleshooting

| Problema | Solução |
|----------|---------|
| Webhook retorna 401 | Verificar verify token |
| Gemini retorna erro 403 | API Key inválida ou API não habilitada |
| Mensagem não envia | Verificar access token WhatsApp expirou |
| BigQuery timeout | Aumentar quota ou usar índices |
| Resposta muito lenta | Reduzir max_tokens ou aumentar cache |

---

## ✅ Checklist Final

- [ ] Gemini API testada com `curl`
- [ ] WhatsApp API testada com `curl`
- [ ] BigQuery tabelas criadas
- [ ] n8n credenciais configuradas
- [ ] Workflow importado e ativado
- [ ] Webhook verificado em Meta
- [ ] Teste end-to-end bem-sucedido
- [ ] Logs aparecendo em BigQuery
- [ ] Alertas configurados

---

## 🎯 Pronto!

Sua automação está **production-ready** e respondendo todas as mensagens com Gemini! 🚀

**Próximos passos:**
- Monitorar performance
- Ajustar `GEMINI_TEMPERATURE` se necessário
- Escalar para múltiplos números
- Integrar com CRM

---

**Support**: Ver logs em `n8n` > **Executions** ou BigQuery `whatsapp_gemini.errors`
