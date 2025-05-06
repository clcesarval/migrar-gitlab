#!/bin/bash
set -euo pipefail

# ============================
# VARIÁVEIS
# ============================
GRUPO="nome-do-grupo"  # Exemplo: vas
TARGET_GITLAB_HOST="gitlab.example.com"
TARGET_GITLAB_TOKEN="SEU_TOKEN_GITLAB_DESTINO"
TARGET_GROUP_PATH="caminho/do/grupo/no/destino/$GRUPO/legacy"

BASE_DIR="tmp-migracao"

cd "$BASE_DIR" || { echo "❌ Diretório $BASE_DIR não encontrado."; exit 1; }

# ============================
# FUNÇÃO: CRIAR SUBGRUPOS
# ============================
criar_subgrupos() {
  local caminho="$1"
  local parent_id=""
  local path_so_far=""

  IFS='/' read -ra PARTES <<< "$caminho"
  for parte in "${PARTES[@]}"; do
    path_so_far="${path_so_far:+$path_so_far/}$parte"
    ENCODED_PATH=$(echo "$path_so_far" | sed 's|/|%2F|g')

    EXISTE=$(curl -s --header "PRIVATE-TOKEN: $TARGET_GITLAB_TOKEN" \
      "https://$TARGET_GITLAB_HOST/api/v4/groups/$ENCODED_PATH")

    if echo "$EXISTE" | grep -q '"id":'; then
      parent_id=$(echo "$EXISTE" | jq '.id')
      continue
    fi

    echo "📁 Criando subgrupo: $path_so_far"
    PAYLOAD="{\"name\": \"$parte\", \"path\": \"$parte\", \"visibility\": \"private\""
    if [[ -n "$parent_id" ]]; then
      PAYLOAD+=", \"parent_id\": $parent_id"
    fi
    PAYLOAD+="}"

    RESPOSTA=$(curl -s --request POST \
      --header "PRIVATE-TOKEN: $TARGET_GITLAB_TOKEN" \
      --header "Content-Type: application/json" \
      --data "$PAYLOAD" \
      "https://$TARGET_GITLAB_HOST/api/v4/groups")

    parent_id=$(echo "$RESPOSTA" | jq -r '.id')
    if [[ "$parent_id" == "null" || -z "$parent_id" ]]; then
      echo "❌ Falha ao criar subgrupo $path_so_far"
      return 1
    fi
  done
}

# ============================
# LOOP DE PUSH
# ============================
REPOS=$(find . -type d -name "*.git" | sed 's|^\./||' | sed 's|/\.git$||')

if [[ -z "$REPOS" ]]; then
  echo "⚠️ Nenhum repositório encontrado em $BASE_DIR"
  exit 0
fi

for RELATIVE_PATH in $REPOS; do
  echo -e "\n📦 Processando: $RELATIVE_PATH"

  REPO_NAME=$(basename "$RELATIVE_PATH")
  REPO_PATH_CLEAN=$(echo "$RELATIVE_PATH" | sed 's|\.git$||')
  DEST_REPO_PATH="$TARGET_GROUP_PATH/$REPO_PATH_CLEAN"
  DEST_REPO_URL="https://oauth2:$TARGET_GITLAB_TOKEN@$TARGET_GITLAB_HOST/$DEST_REPO_PATH.git"

  DEST_ENCODED_PATH=$(echo "$DEST_REPO_PATH" | sed 's|/|%2F|g')
  echo "🔍 Verificando se o projeto já existe em $DEST_REPO_PATH..."
  PROJECT_CHECK=$(curl -s --header "PRIVATE-TOKEN: $TARGET_GITLAB_TOKEN" \
    "https://$TARGET_GITLAB_HOST/api/v4/projects/$DEST_ENCODED_PATH")

  if echo "$PROJECT_CHECK" | grep -q '"message":"404 Project Not Found"'; then
    echo "📁 Projeto não encontrado. Criando $REPO_NAME..."

    PARENT_NAMESPACE=$(dirname "$DEST_REPO_PATH")
    criar_subgrupos "$PARENT_NAMESPACE"

    ENCODED_NAMESPACE=$(echo "$PARENT_NAMESPACE" | sed 's|/|%2F|g')
    NAMESPACE_ID=$(curl -s --header "PRIVATE-TOKEN: $TARGET_GITLAB_TOKEN" \
      "https://$TARGET_GITLAB_HOST/api/v4/groups/$ENCODED_NAMESPACE" | jq -r '.id')

    if [[ -z "$NAMESPACE_ID" || "$NAMESPACE_ID" == "null" ]]; then
      echo "❌ Não foi possível obter o ID do namespace $PARENT_NAMESPACE"
      continue
    fi

    curl -s --request POST "https://$TARGET_GITLAB_HOST/api/v4/projects" \
      --header "PRIVATE-TOKEN: $TARGET_GITLAB_TOKEN" \
      --header "Content-Type: application/json" \
      --data "{
        \"name\": \"$REPO_NAME\",
        \"path\": \"$REPO_NAME\",
        \"namespace_id\": $NAMESPACE_ID,
        \"visibility\": \"private\"
      }" > /dev/null

    echo "✅ Projeto $REPO_NAME criado no grupo $PARENT_NAMESPACE"
  else
    echo "✅ Projeto já existe no destino."
  fi

  cd "$RELATIVE_PATH" || { echo "❌ Falha ao acessar $RELATIVE_PATH"; continue; }

  echo "🔁 Reconfigurando remote para $DEST_REPO_URL"
  git remote remove origin || true
  git remote add origin "$DEST_REPO_URL"

  echo "⬆️ Enviando todas as branches..."
  git push --all origin

  echo "🏷️ Enviando todas as tags..."
  git push --tags origin

  echo "✅ Push realizado com sucesso para $REPO_PATH_CLEAN"

  cd - >/dev/null
done

echo -e "\n🏁 Push de todos os repositórios finalizado!"
