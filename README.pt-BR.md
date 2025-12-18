# 🚀 migrar-gitlab  
⭐ GitLab Stars: ![Stars](https://img.shields.io/gitlab/stars/SEU_GRUPO%2FSEU_REPO?style=social)  
👀 Repository Views: ![Views](https://komarev.com/ghpvc/?username=SEU_USUARIO&repo=SEU_REPO&label=Views)

Automação para migração de repositórios do **GitLab Community (self-hosted)** para o **GitLab Enterprise (gitlab.com)**.

Este repositório contém **scripts Bash reutilizáveis** para facilitar clonagem, ajustes, push, migração de metadados e **governança pós-migração**, preservando histórico, rastreabilidade e segurança.

---

## 🗂️ Visão geral dos scripts

| Script | Descrição |
|------|------------|
| clone-projects.sh | Clona todos os projetos de um grupo GitLab de origem |
| replace_gitlab-ci.sh | Atualiza caminhos internos no .gitlab-ci.yml |
| push_projects.sh | Reconfigura remotes, recria branches e realiza push |
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
  - maintainer ou admin_group, dependendo do script

---

## 🔹 1. clone-projects.sh

Clona todos os projetos de um grupo GitLab de origem.

### O que faz:
- Consulta a API do GitLab
- Lista todos os projetos do grupo
- Clona os repositórios localmente
- Evita sobrescrever projetos já clonados
- Remove o remote original
- Adiciona o remote do GitLab de destino

### Observações:
- Seguro para reexecução
- Não há perda de histórico
- Ideal para migrações em larga escala

---

## 🔹 2. replace_gitlab-ci.sh

Atualiza referências internas nos arquivos .gitlab-ci.yml.

### O que faz:
- Localiza todos os arquivos .gitlab-ci.yml
- Substitui caminhos antigos por novos
- Cria backups .bak antes das alterações

### Configuração:
OLD_PATH="old/path"  
NEW_PATH="new/path"

---

## 🔹 3. push_projects.sh

Executa o push completo para o GitLab de destino.

### O que faz:
- Recria todas as branches
- Envia o histórico completo
- Preserva a integridade do repositório

---

## 🔹 4. migrate-group-variables.sh

Migração de variáveis de grupo entre instâncias GitLab.

### Funcionalidades:
- Variáveis de grupo migradas da origem para o destino via API
- Variáveis existentes identificadas e não sobrescritas
- Logs criados para auditoria e troubleshooting
- 100% compatível com a API v4 do GitLab

---

## 🔹 5. migrate-issues.sh e delete-issues.sh

## 🧩 Scripts de Migração e Limpeza de Issues no GitLab

Este repositório contém dois scripts Bash úteis para manipulação de issues entre projetos GitLab.  
São especialmente úteis em cenários de migração entre instâncias do GitLab ou para limpeza total de issues existentes.

---

### 📦 migrate-issues.sh – Migração de Issues e Comentários

Este script migra todas as issues e seus comentários de um projeto GitLab de origem para um projeto GitLab de destino.

#### Funcionalidades:
- Exporta issues com título, descrição e data de criação
- Recria as issues no projeto de destino
- Preserva o estado original (aberta ou fechada)
- Migra comentários com nome do autor e timestamp

#### Variáveis obrigatórias:
DEST_PROJECT_ID="DESTINATION_PROJECT_ID"  
TOKEN="DESTINATION_TOKEN"  
SOURCE_PROJECT_ENCODED="group%2Fproject"  
SOURCE_TOKEN="SOURCE_TOKEN"

---

### ❌ delete-issues.sh – Deleção em Massa de Issues

Script para remover todas as issues de um projeto GitLab.

⚠️ Atenção:  
Esta operação é irreversível.

Variáveis:
DEST_PROJECT_ID="PROJECT_ID"  
TOKEN="TOKEN"

---

### Requisitos para os scripts de issues:
- jq instalado
- Bash 4+
- Tokens com permissão de leitura e escrita
- Projeto de destino previamente criado

Observações:
- Scripts utilizam apenas a API REST do GitLab
- Sempre testar em ambiente não produtivo
- URLs são placeholders e devem ser ajustadas

---

## 🔹 6. gitlab-clone-recursive.sh

Clonagem recursiva de todos os repositórios de um grupo GitLab.

### Funcionalidades:
- Clona grupo raiz e subgrupos
- Preserva a hierarquia de diretórios local
- Usa autenticação baseada em token
- Ignora repositórios já clonados

### Variáveis:
GITLAB_URL="https://gitlab.sua-instancia.com"  
GITLAB_TOKEN="SEU_TOKEN"  
ROOT_GROUP_ID=000  
ROOT_GROUP_PATH="group/root"

---

## 🔹 7. protect-projects.sh – Proteção de Projetos Antigos (PÓS-MIGRAÇÃO)

Script responsável por bloquear completamente projetos antigos ou migrados, garantindo governança e prevenindo alterações não intencionais.

### O que este script faz:
- Protege todas as branches (*)
- Bloqueia push direto
- Bloqueia merge direto
- Permite apenas Maintainers remover a proteção
- Desabilita merge requests
- Processa grupos e subgrupos de forma recursiva

### Configuração:
GITLAB_HOST="gitlab.com"  
TOKEN="SEU_TOKEN"  
GROUP_ID="888"

### Observações:
- Ideal para repositórios legados ou congelados
- Garante estado somente leitura após migração
- Evita commits ou merges acidentais
- Fortemente recomendado para cenários de compliance e auditoria

---

## 🧠 Fluxo recomendado de migração

1. gitlab-clone-recursive.sh ou clone-projects.sh  
2. replace_gitlab-ci.sh  
3. push_projects.sh  
4. migrate-group-variables.sh  
5. migrate-issues.sh  
6. protect-projects.sh  

---

## 📄 Observações finais

- Scripts seguros para reexecução quando aplicável
- Projetados para migrações em larga escala
- Utilizados com sucesso em migrações envolvendo milhares de repositórios
- Totalmente baseados na API REST oficial do GitLab
- Adequados para governança corporativa, auditoria e compliance

---

## 📌 Licença

Uso interno, educacional ou corporativo.  
Adapte conforme suas políticas de compliance.
