#!/bin/bash
set -euo pipefail

# =============== CONFIGURAÇÃO ================
ROOT_GROUP_ID="SEU_GROUP_ID_AQUI"
ROOT_GROUP_PATH="NOME_DO_GRUPO_RAIZ"
GITLAB_URL="https://gitlab.seu-gitlab.com"
GITLAB_TOKEN="${GITLAB_TOKEN:?Defina a variável de ambiente GITLAB_TOKEN com seu token de acesso pessoal}"

BASE_DIR="tmp-migracao"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# =============== FUNÇÃO: CLONAR PROJETOS DE UM GRUPO ================
clonar_projetos_do_grupo() {
  local group_path="$1"
  local group_id="$2"

  echo -e "\n🔍 Buscando projetos em: $group_path (ID $group_id)..."
  page=1
  while :; do
    result=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      "$GITLAB_URL/api/v4/groups/$group_id/projects?per_page=100&page=$page")

    count=$(echo "$result" | jq length)
    ((count == 0)) && break

    echo "$result" | jq -r '.[] | [.path_with_namespace, .http_url_to_repo] | @tsv' | while IFS=$'\t' read -r full_path http_url; do
      corrected_path=$(echo "$full_path" | sed "s|^$ROOT_GROUP_PATH/||")
      local_path="$corrected_path.git"

      repo_dir=$(dirname "$local_path")
      mkdir -p "$repo_dir"

      if [ -d "$local_path" ]; then
        echo "⚠️  Pulando $full_path → já existe em ./$local_path"
        continue
      fi

      http_url_with_token=$(echo "$http_url" | sed "s|https://|https://oauth2:$GITLAB_TOKEN@|")
      echo "📦 Clonando $full_path → ./$local_path"
      git clone --bare "$http_url_with_token" "$local_path"
    done

    ((count < 100)) && break || ((page++))
  done
}

# =============== CLONAR PROJETOS DO GRUPO RAIZ ================
clonar_projetos_do_grupo "$ROOT_GROUP_PATH" "$ROOT_GROUP_ID"

# =============== CLONAR PROJETOS DE TODOS OS SUBGRUPOS ================
echo -e "\n🔍 Buscando subgrupos de $ROOT_GROUP_PATH..."
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_URL/api/v4/groups/$ROOT_GROUP_ID/subgroups" | \
  jq -c '.[]' | while read -r subgroup; do
    subgroup_id=$(echo "$subgroup" | jq -r .id)
    subgroup_path=$(echo "$subgroup" | jq -r .full_path)
    clonar_projetos_do_grupo "$subgroup_path" "$subgroup_id"
  done

echo -e "\n✅ Clonagem concluída com sucesso."

# =============== VERIFICAÇÃO DE .gitlab-ci.yml ================

echo -e "\n📂 Verificando arquivos .gitlab-ci.yml com referências antigas de projeto:\n"
MATCHES=$(find . -type f -name ".gitlab-ci.yml" -exec grep -H '^[[:space:]]*-[[:space:]]project:' {} \; || true)

if [[ -n "$MATCHES" ]]; then
  echo "$MATCHES"
else
  echo "⚠️ Nenhum arquivo .gitlab-ci.yml com '- project:' encontrado."
fi

# =============== SUGESTÃO DE CAMINHOS ================
echo -e "\n📌 Use os caminhos abaixo no seu script de substituição:"
echo "OLD_PATH=\"$ROOT_GROUP_PATH\""
echo "NEW_PATH=\"engbr/telco-and-media/tim/$ROOT_GROUP_PATH/legacy\""
