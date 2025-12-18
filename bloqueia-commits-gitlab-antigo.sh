#!/bin/bash

GITLAB_HOST="gitlab.com."
TOKEN="glpat-TOKEN"
GROUP_ID="888"  # ID numérico do grupo raiz

# Função para proteger todas as branches de um projeto
proteger_branches() {
  local project_id="$1"
  local project_name="$2"
  
  echo "🔒 Bloqueando projeto: $project_name (ID: $project_id)"
  
  # Protege a branch master (ou main)
  curl -s --request POST \
    --header "PRIVATE-TOKEN: $TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
      "name": "*",
      "push_access_level": 0,
      "merge_access_level": 0,
      "unprotect_access_level": 40,
      "allow_force_push": false
    }' \
    "https://$GITLAB_HOST/api/v4/projects/$project_id/protected_branches"
    
  # Opcional: Desabilita merge requests
  curl -s --request PUT \
    --header "PRIVATE-TOKEN: $TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
      "merge_requests_enabled": false
    }' \
    "https://$GITLAB_HOST/api/v4/projects/$project_id"
}

# Função recursiva para processar projetos em um grupo e seus subgrupos
processar_recursivo() {
  local group_id="$1"

  # Pega todos os projetos do grupo
  local projects_json=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" "https://$GITLAB_HOST/api/v4/groups/$group_id/projects?per_page=100")
  
  # Extrai IDs e nomes dos projetos
  local project_ids=($(echo "$projects_json" | jq -r '.[].id'))
  local project_names=($(echo "$projects_json" | jq -r '.[].name'))
  
  # Processa cada projeto
  for i in "${!project_ids[@]}"; do
    proteger_branches "${project_ids[$i]}" "${project_names[$i]}"
  done

  # Pega todos os subgrupos do grupo
  local subgroups=$(curl -s --header "PRIVATE-TOKEN: $TOKEN" "https://$GITLAB_HOST/api/v4/groups/$group_id/subgroups?all_available=true&per_page=100" | jq -r '.[].id')

  # Chama a função recursivamente para cada subgrupo
  for subgroup_id in $subgroups; do
    processar_recursivo "$subgroup_id"
  done
}

# Inicia o processo recursivo no grupo raiz
processar_recursivo "$GROUP_ID"

echo "✅ Todos os projetos foram bloqueados para commits e merges!"
