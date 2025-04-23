#!/bin/bash

# Script para deletar todas as issues de um projeto no GitLab
# ⚠️ Substitua os valores abaixo antes de executar

DEST_PROJECT_ID="ID_DO_PROJETO"
TOKEN="SEU_TOKEN_PRIVADO"

echo "🧹 Deletando todas as issues do projeto $DEST_PROJECT_ID..."

# Obter a lista de IIDs das issues
issues=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" \
  "https://gitlab.DESTINO.com/api/v4/projects/$DEST_PROJECT_ID/issues?per_page=100" | jq -r '.[].iid')

# Deletar cada issue
for iid in $issues; do
  echo "❌ Deletando issue #$iid"
  curl -s -X DELETE \
    --header "PRIVATE-TOKEN: $TOKEN" \
    "https://gitlab.DESTINO.com/api/v4/projects/$DEST_PROJECT_ID/issues/$iid"
done

echo "✅ Todas as issues foram removidas!"
