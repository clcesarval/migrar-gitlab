# migrar-gitlab
Migração de Pipes do Gitlab Comunity para o Enterprise


# migrar-gitlab

Automação da migração de repositórios GitLab de uma instância **Community Edition (self-hosted)** para uma instância **GitLab Enterprise (gitlab.com)**.

Este repositório contém 3 scripts bash usados para clonar, ajustar e subir projetos GitLab durante o processo de migração.

---

## 📁 Estrutura dos scripts

| Script                     | Objetivo                                                      |
|---------------------------|---------------------------------------------------------------|
| `clone-projects.sh`       | Clona todos os repositórios de um grupo do GitLab origem      |
| `replace_gitlab-ci.sh`    | Atualiza caminhos de projeto nos arquivos `.gitlab-ci.yml`    |
| `push_projects.sh`        | Faz push dos repositórios migrados para o GitLab de destino   |

---

## 🧰 Pré-requisitos

- `git`
- `jq`
- `curl`
- Permissões com `token` (personal access token) para ambos os GitLab
- Ambiente Linux ou WSL

---

## 🔹 1. clone-projects.sh

### 📋 O que faz?
Este script:
- Acessa a API do GitLab origem
- Lista os projetos do grupo informado
- Clona cada um dos repositórios para a pasta `tmp-migracao/`
- Remove o remote original e configura o remote do GitLab destino

### ▶️ Como executar:
```bash
chmod +x clone-projects.sh
./clone-projects.sh
