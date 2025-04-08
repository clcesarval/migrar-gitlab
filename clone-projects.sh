#!/bin/bash

# Segurança e depuração
set -euo pipefail

# ============================
# CONFIGURAÇÃO PERSONALIZÁVEL
# ============================

# Nome do grupo a ser migrado
GRUPO="SEU_GRUPO"

# GitLab de origem
SOURCE_GITLAB_HOST="gitlab.seudominio.com.br"
SOURCE_GITLAB_TOKEN="SEU_TOKEN_DE_ORIGEM"
SOURCE_GROUP_PATH="grupo%2F$GRUPO"  # Caminho URL-encoded

# GitLab de destino
TARGET_GITLAB_HOST="gitlab.com"
TARGET_GITLAB_TOKEN="SEU_TOKEN_DE_DESTINO"
TARGET_GROUP_PATH="destino/estrutura/$GRUPO"

# ============================
# CLONAGEM DOS PROJETOS
# ============================

mkdir -p tmp-migracao && cd tmp-migracao || exit 1

PROJECTS=()
page=1
while :; do
  response=$(curl --silent --header "PRIVATE-TOKEN: $SOURCE_GITLAB_TOKEN" \
    "https://$SOURCE_GITLAB_HOST/api/v4/groups/$SOURCE_GROUP_PATH/projects?include_subgroups=false&per_page=100&page=$page")

  result=$(echo "$response" | jq -r '.[].path_with_namespace')

  if [[ -z "$result" || "$result" == "null" ]]; then
    break
  fi

  PROJECTS+=($result)
  ((page++))
done

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  echo "❌ Nenhum projeto encontrado no grupo '$GRUPO'. Verifique o token e o nome do grupo."
  exit 1
fi

for SOURCE_PROJECT in "${PROJECTS[@]}"; do
  DEST_PROJECT_NAME=$(basename "$SOURCE_PROJECT")
  DEST_FULL_PATH="$TARGET_GROUP_PATH/$DEST_PROJECT_NAME"

  # Pula se o projeto já foi clonado
  if [[ -d "$DEST_PROJECT_NAME/.git" ]]; then
    echo "⏩ [$DEST_PROJECT_NAME] já existe localmente. Pulando clonagem..."
    continue
  fi

  echo -e "\n🔄 Clonando projeto: $SOURCE_PROJECT → $DEST_FULL_PATH"

  if git clone --origin origin "https://oauth2:$SOURCE_GITLAB_TOKEN@$SOURCE_GITLAB_HOST/$SOURCE_PROJECT.git" "$DEST_PROJECT_NAME"; then
    cd "$DEST_PROJECT_NAME" || continue

    git fetch --all --tags

    git remote remove origin
    git remote add origin "https://oauth2:$TARGET_GITLAB_TOKEN@$TARGET_GITLAB_HOST/$DEST_FULL_PATH.git"

    echo "✅ [$DEST_PROJECT_NAME] clonado com sucesso!"
    cd ..
  else
    echo "❌ Falha ao clonar $SOURCE_PROJECT"
  fi
done

echo -e "\n🏁 Clonagem concluída. Repositórios prontos para edição local e push posterior."

# ============================
# VERIFICAÇÃO DE REFERÊNCIAS NO .gitlab-ci.yml
# ============================

echo -e "\n📂 Verificando arquivos .gitlab-ci.yml com referências antigas de projeto:\n"
MATCHES=$(find . -type f -name ".gitlab-ci.yml" -exec grep -H '^[[:space:]]*-[[:space:]]project:' {} \; || true)

if [[ -n "$MATCHES" ]]; then
  echo "$MATCHES"
else
  echo "⚠️ Nenhum arquivo .gitlab-ci.yml com '- project:' encontrado."
fi

# ============================
# SUGESTÃO DE CAMINHOS PARA SUBSTITUIÇÃO
# ============================

echo -e "\n📌 Use os caminhos abaixo no seu script de substituição:"
echo "OLD_PATH=\"grupo/$GRUPO\""
echo "NEW_PATH=\"destino/estrutura/$GRUPO\""
