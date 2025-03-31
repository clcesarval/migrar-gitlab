#!/bin/bash

# ============================
# VARIÁVEL DO GRUPO
# ============================
GRUPO="nome-do-subgrupo"  # Altere para grupo1, grupo2, grupo3, ..etc

# Caminho base onde estão os repositórios clonados
cd tmp-migracao || exit 1

# GitLab de destino
TARGET_GITLAB_HOST="gitlab.com"
TARGET_GITLAB_TOKEN="SEU_TOKEN_GITLAB_DESTINO"
TARGET_GROUP_PATH="seu-grupo/gitlab-destino/$GRUPO"

# GitLab de origem
SOURCE_GITLAB_HOST="gitlab.seudominio.com"
SOURCE_GITLAB_TOKEN="SEU_TOKEN_GITLAB_ORIGEM"
SOURCE_GROUP_PATH="seu-grupo/gitlab-origem/$GRUPO"

for dir in */; do
  echo -e "\n📦 Entrando no projeto: $dir"
  cd "$dir" || continue

  PROJECT_NAME=$(basename "$PWD")
  DEST_REPO_URL="https://oauth2:$TARGET_GITLAB_TOKEN@$TARGET_GITLAB_HOST/$TARGET_GROUP_PATH/$PROJECT_NAME.git"

  echo "🔍 Verificando remote atual:"
  git remote -v

  echo "🔁 Reconfigurando 'origin' para o repositório de destino:"
  git remote remove origin || true
  git remote add origin "$DEST_REPO_URL"
  git remote -v

  echo "📝 Último commit local:"
  git log -1 --oneline || echo "⚠️ Nenhum commit encontrado."

  # Verifica alterações locais
  if [[ -n $(git status --porcelain) ]]; then
    echo "📄 Alterações detectadas. Adicionando e comitando..."
    git add .
    git commit -m "chore(migration): atualiza configurações após migração"
  else
    echo "⚠️ Nenhuma alteração para commitar."
  fi

  echo "⬆️ Enviando todas as branches..."
  git push --all origin

  echo "🏷️ Enviando todas as tags..."
  git push --tags origin

  # ============================
  # ARQUIVAMENTO AUTOMÁTICO
  # ============================
  echo "🔍 Verificando se o projeto está arquivado na origem..."
  SOURCE_ENCODED_PATH=$(echo "$SOURCE_GROUP_PATH/$PROJECT_NAME" | sed 's/\//%2F/g')
  IS_ARCHIVED=$(curl -s --header "PRIVATE-TOKEN: $SOURCE_GITLAB_TOKEN" \
    "https://$SOURCE_GITLAB_HOST/api/v4/projects/$SOURCE_ENCODED_PATH" | jq -r '.archived')

  if [[ "$IS_ARCHIVED" == "true" ]]; then
    echo "📦 Projeto $PROJECT_NAME está arquivado na origem. Arquivando no destino..."

    DEST_ENCODED_PATH=$(echo "$TARGET_GROUP_PATH/$PROJECT_NAME" | sed 's/\//%2F/g')

    ARCHIVE_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/archive_response.json \
      --request POST \
      --header "PRIVATE-TOKEN: $TARGET_GITLAB_TOKEN" \
      "https://$TARGET_GITLAB_HOST/api/v4/projects/$DEST_ENCODED_PATH/archive")

    HTTP_CODE=$(tail -c 3 <<< "$ARCHIVE_RESPONSE")

    if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "201" ]]; then
      echo "✅ Projeto $PROJECT_NAME arquivado no destino com sucesso."
    else
      echo "❌ Falha ao arquivar $PROJECT_NAME no destino (HTTP $HTTP_CODE)"
      echo "🔎 Resposta da API:"
      cat /tmp/archive_response.json
    fi
  else
    echo "📂 Projeto $PROJECT_NAME está ativo na origem. Mantendo ativo no destino."
  fi

  cd ..
done

echo -e "\n🏁 Push completo de todos os repositórios do grupo: $GRUPO"
