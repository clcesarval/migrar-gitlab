# 🚀 migrar-gitlab

Automação da migração de repositórios do GitLab Community (self-hosted) para o GitLab Enterprise (gitlab.com).

Este repositório contém scripts Bash reutilizáveis para facilitar a clonagem, ajuste, push, migração de metadados e governança pós-migração, mantendo histórico, rastreabilidade e segurança.

---

## 🗂️ Visão geral dos scripts

| Script | Descrição |
|------|------------|
| clone-projects.sh | Clona todos os projetos de um grupo GitLab origem |
| replace_gitlab-ci.sh | Atualiza caminhos internos do .gitlab-ci.yml |
| push_projects.sh | Reconfigura remotes, recria branches e faz push |
| migrate-group-variables.sh | Migra variáveis de grupo via API |
| migrate-issues.sh | Migra issues e comentários entre projetos |
| delete-issues.sh | Remove todas as issues de um projeto |
| gitlab-clone-recursive.sh | Clonagem recursiva preservando hierarquia |
| protect-projects.sh | Protege e bloqueia projetos antigos pós-migração |

---

## ⚙️ Pré-requisitos

- Git
- jq
- curl
- Bash (Linux ou WSL)
- Tokens de acesso do GitLab com permissões:
  - read_api
  - read_repository
  - write_repository
  - maintainer ou admin_group conforme o script

---

## 🔹 1. clone-projects.sh

Clona todos os projetos de um grupo GitLab de origem.

### O que faz:
- Consulta a API do GitLab
- Lista todos os projetos do grupo
- Clona os repositórios localmente
- Evita sobrescrever repositórios já clonados
- Remove o remote original
- Adiciona o remote do GitLab destino

### Observações:
- Seguro para reexecução
- Não perde histórico
- Ideal para migrações em massa

---

## 🔹 2. replace_gitlab-ci.sh

Atualiza referências internas nos arquivos .gitlab-ci.yml.

### O que faz:
- Localiza todos os .gitlab-ci.yml
- Substitui caminhos antigos por novos
- Cria backup .bak antes de alterar

### Configuração:
OLD_PATH="caminho/antigo"
NEW_PATH="caminho/novo"

---

## 🔹 3. push_projects.sh

Realiza o push completo para o GitLab destino.

### O que faz:
- Recria todas as branches
- Envia histórico completo
- Mantém integridade do repositório

---

## 🔹 4. migrate-group-variables.sh

Migração de variáveis de grupo entre instâncias GitLab.

### Funcionalidades:
- Variáveis de grupo migradas da origem para o destino via API
- Variáveis já existentes identificadas e não sobrescritas
- Logs criados para auditoria e troubleshooting
- Formato 100% compatível com a API v4 do GitLab

---

## 🔹 5. migrate-issues.sh and delete-issues.sh

## 🧩 Scripts de Migração e Limpeza de Issues no GitLab

Este repositório contém dois scripts Bash úteis para manipulação de issues entre projetos GitLab. Eles são especialmente úteis em cenários de migração entre instâncias do GitLab ou para limpeza total de issues existentes.

---

### 📦 migrate-issues.sh – Migração de Issues e Comentários

Este script migra todas as issues e seus comentários de um projeto GitLab de origem para um projeto GitLab de destino.

#### Funcionalidades:
- Exporta issues com título, descrição e data de criação
- Recria as issues no projeto de destino
- Preserva o estado original (aberta ou fechada)
- Migra comentários com autor e data

#### Variáveis necessárias:
DEST_PROJECT_ID="ID_DO_PROJETO_DESTINO"
TOKEN="TOKEN_DESTINO"
SOURCE_PROJECT_ENCODED="grupo%2Fprojeto"
SOURCE_TOKEN="TOKEN_ORIGEM"

---

### ❌ delete-issues.sh – Deleção em Massa de Issues

Script para remover todas as issues de um projeto GitLab.

⚠️ Atenção:
Esta operação é irreversível.

Variáveis:
DEST_PROJECT_ID="ID_DO_PROJETO"
TOKEN="TOKEN"

---

### Requisitos para issues:
- jq instalado
- Bash 4+
- Tokens com permissão de leitura e escrita
- Projeto de destino previamente criado

Observações:
- Scripts utilizam apenas a API REST do GitLab
- Testar sempre em ambiente não produtivo
- URLs são placeholders e devem ser ajustadas

---

## 🔹 6. gitlab-clone-recursive.sh

Clonagem recursiva de todos os repositórios de um grupo GitLab.

### Funcionalidades:
- Clona grupo raiz e subgrupos
- Preserva hierarquia local
- Usa autenticação via token
- Ignora repositórios já clonados

### Variáveis:
GITLAB_URL="https://gitlab.sua-instancia.com"
GITLAB_TOKEN="SEU_TOKEN"
ROOT_GROUP_ID=000
ROOT_GROUP_PATH="grupo/raiz"

---

## 🔹 7. protect-projects.sh – Proteção de Projetos Antigos (POST-MIGRAÇÃO)

Script responsável por **bloquear completamente projetos antigos ou migrados**, garantindo governança e impedindo alterações indevidas.

### O que este script faz:
- Protege todas as branches (*)
- Bloqueia push direto
- Bloqueia merge direto
- Permite apenas Maintainers remover proteção
- Des
