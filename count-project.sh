#!/bin/bash

GITLAB_URL="https://gitlab.com"
TOKEN="glpat-TOKEN"
ROOT_GROUP="GRUPO"
total=0

count_projects_recursively() {
  local group_path="$1"

  # URL encode o caminho
  encoded_path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$group_path''', safe=''))")

  # Pega o ID do grupo pelo caminho
  group_id=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" "$GITLAB_URL/api/v4/groups/$encoded_path" | jq -r '.id')

  if [ "$group_id" == "null" ] || [ -z "$group_id" ]; then
    echo "❌ Grupo não encontrado: $group_path"
    return
  fi

  # Conta os projetos neste grupo
  project_count=0
  page=1
  while :; do
    result=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" \
      "$GITLAB_URL/api/v4/groups/$group_id/projects?per_page=100&page=$page")
    count=$(echo "$result" | jq length)
    ((project_count+=count))
    ((count < 100)) && break || ((page++))
  done

  echo "📦 Grupo '$group_path' tem $project_count projetos"
  ((total+=project_count))

  # Lista subgrupos recursivamente
  subgroups=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" "$GITLAB_URL/api/v4/groups/$group_id/subgroups")
  subgroup_paths=$(echo "$subgroups" | jq -r '.[].full_path')

  for sg in $subgroup_paths; do
    count_projects_recursively "$sg"
  done
}

# Inicia a contagem
count_projects_recursively "$ROOT_GROUP"

echo ""
echo "✅ Total geral de projetos: $total"
