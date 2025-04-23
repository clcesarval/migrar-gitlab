#!/bin/bash

# Script para migrar issues e comentários entre projetos GitLab
# ⚠️ Substitua os valores abaixo com os seus dados reais antes de usar.

ARQUIVO="issues_exportadas.json"
DEST_PROJECT_ID="ID_DO_PROJETO_DESTINO"  # Altere para o ID do projeto no GitLab de destino
TOKEN="SEU_TOKEN_DESTINO"
SOURCE_PROJECT_ENCODED="grupo%2Fprojeto"  # Caminho URL-encoded do projeto de origem
SOURCE_TOKEN="SEU_TOKEN_ORIGEM"

# Obter issues do projeto de origem e salvar no arquivo local
curl -s --header "PRIVATE-TOKEN: $SOURCE_TOKEN" \
  "https://gitlab.ORIGEM.com/api/v4/projects/$SOURCE_PROJECT_ENCODED/issues?per_page=100" \
  -o "$ARQUIVO"

# Obter lista de títulos já existentes no projeto de destino
EXISTING_TITLES=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" \
  "https://gitlab.DESTINO.com/api/v4/projects/$DEST_PROJECT_ID/issues?per_page=100" | jq -r '.[].title')

total=$(jq length "$ARQUIVO")
echo "📦 Total de issues: $total"

for i in $(seq 0 $((total - 1))); do
  title=$(jq -r ".[$i].title" "$ARQUIVO")
  description=$(jq -r ".[$i].description" "$ARQUIVO")
  created_at=$(jq -r ".[$i].created_at" "$ARQUIVO")
  state=$(jq -r ".[$i].state" "$ARQUIVO")
  original_iid=$(jq -r ".[$i].iid" "$ARQUIVO")

  if echo "$EXISTING_TITLES" | grep -Fxq "$title"; then
    echo "⚠️ Issue já existe: $title - pulando..."
    continue
  fi

  echo -e "\n➡️ Migrando issue: $title"

  title_encoded=$(jq -rn --arg t "$title" '$t')
  description_encoded=$(jq -rn --arg d "$description" '$d')

  RESPONSE=$(curl -s -X POST \
    --header "PRIVATE-TOKEN: $TOKEN" \
    --data-urlencode "title=$title_encoded" \
    --data-urlencode "description=$description_encoded" \
    --data-urlencode "created_at=$created_at" \
    "https://gitlab.DESTINO.com/api/v4/projects/$DEST_PROJECT_ID/issues")

  issue_iid=$(echo "$RESPONSE" | jq -r .iid)

  echo "📤 Response:"
  echo "$RESPONSE" | jq .

  if [[ "$state" == "closed" && "$issue_iid" != "null" ]]; then
    curl -s -X PUT \
      --header "PRIVATE-TOKEN: $TOKEN" \
      --data "state_event=close" \
      "https://gitlab.DESTINO.com/api/v4/projects/$DEST_PROJECT_ID/issues/$issue_iid" >/dev/null
    echo "🚪 Issue $issue_iid fechada como no original."
  fi

  NOTES=$(curl -s --header "PRIVATE-TOKEN: $SOURCE_TOKEN" \
    "https://gitlab.ORIGEM.com/api/v4/projects/$SOURCE_PROJECT_ENCODED/issues/$original_iid/notes")

  if echo "$NOTES" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
    echo "$NOTES" | jq -c '.[]' | while read -r note; do
      body=$(echo "$note" | jq -r .body)
      created_at_note=$(echo "$note" | jq -r .created_at)
      author=$(echo "$note" | jq -r .author.name)
      body=$(echo -e "💬 *Comentário migrado do GitLab de origem. Autor original:* **$author**\n\n$body")

      curl -s -X POST \
        --header "PRIVATE-TOKEN: $TOKEN" \
        --data-urlencode "body=$body" \
        --data-urlencode "created_at=$created_at_note" \
        "https://gitlab.DESTINO.com/api/v4/projects/$DEST_PROJECT_ID/issues/$issue_iid/notes" >/dev/null

      echo "🗨️ Comentário migrado para issue $issue_iid"
    done
  else
    echo "⚠️ Nenhum comentário encontrado para a issue $original_iid"
  fi

done
