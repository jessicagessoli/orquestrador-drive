-- WhatsApp Gemini Automation - BigQuery Schema
-- Tabelas para armazenar histórico de chats e respostas

CREATE SCHEMA IF NOT EXISTS whatsapp_gemini
  OPTIONS(
    description="Schema para automação WhatsApp com Gemini",
    location="us-central1"
  );

-- Tabela: Chats (contatos únicos)
CREATE TABLE IF NOT EXISTS whatsapp_gemini.chats (
  wa_id STRING NOT NULL,
  phone_number STRING,
  sender_name STRING,
  first_message_at TIMESTAMP,
  last_message_at TIMESTAMP,
  total_messages INT64,
  last_gemini_response STRING,
  status STRING DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  
  PRIMARY KEY(wa_id) NOT ENFORCED
)
PARTITION BY DATE(created_at)
CLUSTER BY status, wa_id
OPTIONS(
  description="Contatos WhatsApp únicos",
  require_partition_filter=false
);

-- Tabela: Messages (histórico completo)
CREATE TABLE IF NOT EXISTS whatsapp_gemini.messages (
  message_id STRING NOT NULL,
  wa_id STRING NOT NULL,
  sender_name STRING,
  message_text STRING,
  message_type STRING DEFAULT 'text',
  direction STRING NOT NULL, -- 'inbound' ou 'outbound'
  
  -- Resposta Gemini
  gemini_prompt STRING,
  gemini_response STRING,
  gemini_model STRING DEFAULT 'gemini-1.5-flash',
  gemini_tokens_used INT64,
  response_time_ms INT64,
  
  -- Status
  response_status STRING DEFAULT 'pending',
  whatsapp_send_status STRING,
  error_message STRING,
  
  -- Timestamps
  message_timestamp TIMESTAMP,
  received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  responded_at TIMESTAMP,
  
  PRIMARY KEY(message_id) NOT ENFORCED
)
PARTITION BY DATE(received_at)
CLUSTER BY wa_id, direction, response_status
OPTIONS(
  description="Histórico completo de mensagens e respostas",
  require_partition_filter=false
);

-- Tabela: Errors (para troubleshooting)
CREATE TABLE IF NOT EXISTS whatsapp_gemini.errors (
  error_id STRING NOT NULL,
  message_id STRING,
  wa_id STRING,
  error_type STRING,
  error_message STRING,
  stack_trace STRING,
  context JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  
  PRIMARY KEY(error_id) NOT ENFORCED
)
PARTITION BY DATE(created_at)
OPTIONS(
  description="Registro de erros e exceções",
  require_partition_filter=false
);

-- Views para análise

-- View: Mensagens hoje por hora
CREATE OR REPLACE VIEW whatsapp_gemini.messages_by_hour AS
SELECT
  TIMESTAMP_TRUNC(received_at, HOUR) as hour,
  direction,
  response_status,
  COUNT(*) as count,
  AVG(response_time_ms) as avg_latency_ms
FROM whatsapp_gemini.messages
WHERE DATE(received_at) = CURRENT_DATE()
GROUP BY hour, direction, response_status
ORDER BY hour DESC;

-- View: Contatos mais ativos
CREATE OR REPLACE VIEW whatsapp_gemini.top_contacts AS
SELECT
  wa_id,
  sender_name,
  phone_number,
  total_messages,
  last_message_at,
  status
FROM whatsapp_gemini.chats
ORDER BY total_messages DESC
LIMIT 50;

-- View: Taxa de sucesso de respostas
CREATE OR REPLACE VIEW whatsapp_gemini.response_success_rate AS
SELECT
  DATE(received_at) as date,
  COUNTIF(response_status = 'success') as successful,
  COUNTIF(response_status = 'failed') as failed,
  COUNTIF(response_status = 'pending') as pending,
  COUNTIF(response_status = 'error') as errors,
  COUNT(*) as total,
  SAFE_DIVIDE(COUNTIF(response_status = 'success'), COUNT(*)) * 100 as success_rate
FROM whatsapp_gemini.messages
GROUP BY date
ORDER BY date DESC;
