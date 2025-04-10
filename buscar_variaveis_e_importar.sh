#!/bin/bash

# Substitua pelos seus próprios tokens e IDs ao usar este script
TOKEN_ORIGEM="SEU_TOKEN_ORIGEM"
TOKEN_DESTINO="SEU_TOKEN_DESTINO"
GROUP_ID_ORIGEM="ID_DO_GRUPO_ORIGEM"
GROUP_ID_DESTINO="ID_DO_GRUPO_DESTINO"
URL_ORIGEM_BASE="https://seu.gitlab.origem/api/v4/groups/$GROUP_ID_ORIGEM/variables"
URL_DESTINO="https://gitlab.com/api/v4/groups/$GROUP_ID_DESTINO/variables"

# Arquivos de log
LOG_EXISTENTES="variaveis_existentes.log"
LOG_FALHAS="variaveis_falha.log"
LOG_GERAL="migracao_variaveis.log"
JSON_SAIDA="variables.json"

> "$LOG_EXISTENTES"
> "$LOG_FALHAS"
> "$LOG_GERAL"
> "$JSON_SAIDA"

PAGE=1
PER_PAGE=100
TOTAL=0

echo "🔎 Buscando variáveis da origem com paginação..."

while :; do
  echo "📄 Página $PAGE"

  RESPONSE=$(curl -sS --header "PRIVATE-TOKEN: $TOKEN_ORIGEM" "$URL_ORIGEM_BASE?per_page=$PER_PAGE&page=$PAGE")

  VARIAVEIS=$(echo "$RESPONSE" | jq -c '.[]')
  [ -z "$VARIAVEIS" ] && break

  while IFS= read -r VAR; do
    KEY=$(echo "$VAR" | jq -r '.key')
    VALUE=$(echo "$VAR" | jq -r '.value')
    PROTECTED=$(echo "$VAR" | jq -r '.protected')
    MASKED=$(echo "$VAR" | jq -r '.masked')
    ENV_SCOPE=$(echo "$VAR" | jq -r '.environment_scope')

    JSON_ESCAPADO=$(jq -n \
      --arg key "$KEY" \
      --arg value "$VALUE" \
      --argjson protected "$PROTECTED" \
      --argjson masked "$MASKED" \
      --arg env_scope "$ENV_SCOPE" \
      '{key: $key, value: $value, protected: $protected, masked: $masked, environment_scope: $env_scope}')

    echo "$JSON_ESCAPADO" >> "$JSON_SAIDA"

    RESPOSTA_API=$(curl -s -w "%{http_code}" -o /tmp/resp.json -X POST "$URL_DESTINO" \
      --header "PRIVATE-TOKEN: $TOKEN_DESTINO" \
      --header "Content-Type: application/json" \
      -d "$JSON_ESCAPADO")

    if grep -q "has already been taken" /tmp/resp.json; then
      echo "🔄 Variável $KEY já existe no destino." | tee -a "$LOG_EXISTENTES"
    elif [[ "$RESPOSTA_API" == "201" ]]; then
      echo "✅ Variável $KEY migrada com sucesso."
    else
      echo -e "⚠️ ERRO $RESPOSTA_API ao migrar variável $KEY" | tee -a "$LOG_FALHAS"
      echo "🔍 Conteúdo completo da variável:" | tee -a "$LOG_FALHAS"
      echo "KEY: $KEY" | tee -a "$LOG_FALHAS"
      echo "VALOR ORIGINAL: $VALUE" | tee -a "$LOG_FALHAS"
      echo "JSON ENVIADO:" | tee -a "$LOG_FALHAS"
      echo "$JSON_ESCAPADO" | tee -a "$LOG_FALHAS"
      echo "📦 RESPOSTA DA API:" | tee -a "$LOG_FALHAS"
      cat /tmp/resp.json | tee -a "$LOG_FALHAS"
    fi
  done <<< "$VARIAVEIS"

  PAGE=$((PAGE + 1))
done

echo "✅ Migração concluída em: $(date)" | tee -a "$LOG_GERAL"
