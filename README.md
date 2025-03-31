# 🚀 migrar-gitlab

Automação da **migração de repositórios do GitLab Community (self-hosted)** para o **GitLab Enterprise (gitlab.com)**.

Este repositório contém **scripts bash reutilizáveis** para facilitar a clonagem, ajuste e push de múltiplos projetos com segurança, controle e padronização.

---

## 🗂️ Visão geral dos scripts

| Script                  | Descrição                                                                 |
|------------------------|---------------------------------------------------------------------------|
| `clone-projects.sh`    | 🔄 Clona todos os projetos de um grupo GitLab origem                      |
| `replace_gitlab-ci.sh` | ✏️ Atualiza caminhos internos do `.gitlab-ci.yml` para o novo repositório |
| `push_projects.sh`     | ⬆️ Faz o push dos repositórios migrados para o GitLab de destino          |

---

## ⚙️ Pré-requisitos

- ✅ Git
- ✅ jq
- ✅ curl
- ✅ Bash (Linux ou WSL)
- ✅ Tokens de acesso (PAT) com permissões:
  - `read_api`
  - `read_repository`
  - `write_repository`

---

## 🔹 1. `clone-projects.sh`

### 📋 O que este script faz?

- Acessa a API do GitLab origem
- Lista todos os projetos do grupo informado
- Clona os repositórios na pasta `tmp-migracao/`
- Remove o remote original
- Adiciona o remote do GitLab destino

### ⚙️ Personalização

Edite no script:
- `GRUPO`: nome do grupo de origem
- Tokens (`SOURCE_GITLAB_TOKEN`, `TARGET_GITLAB_TOKEN`)
- Hosts e caminhos de origem/destino

### ▶️ Como executar:

```bash
chmod +x clone-projects.sh
./clone-projects.sh
```

---

## 🔹 2. `replace_gitlab-ci.sh`

### ✏️ O que este script faz?

- Localiza todos os arquivos `.gitlab-ci.yml` em `tmp-migracao/`
- Substitui caminhos antigos por novos (exemplo: `old-group/subgroup` → `new-root-group/.../legacy/subgroup`)
- Cria backups `.bak` dos arquivos antes de editar

### ⚙️ Personalização

Edite no script:

```bash
OLD_PATH="caminho/antigo"
NEW_PATH="caminho/novo"
```

### ▶️ Como executar:

```bash
chmod +x replace_gitlab-ci.sh
./replace_gitlab-ci.sh
```

---

## 🔹 3. `push_projects.sh`

### ⬆️ O que este script faz?

- Entra em cada projeto clonado
- Reconfigura o `origin` para o GitLab destino
- Comita alterações locais se necessário
- Faz push de **todas as branches** e **tags**
- Verifica se o projeto está arquivado na origem e arquiva no destino, se necessário

### ⚙️ Personalização

Edite:
- Tokens e hosts
- Caminho do grupo (`SOURCE_GROUP_PATH`, `TARGET_GROUP_PATH`)

### ▶️ Como executar:

```bash
chmod +x push_projects.sh
./push_projects.sh
```

---

## 📁 Estrutura esperada após a execução

```
.
├── clone-projects.sh
├── push_projects.sh
├── replace_gitlab-ci.sh
├── tmp-migracao/
│   ├── projeto-1/
│   ├── projeto-2/
│   └── ...
└── README.md
```

---

## ✅ Resultado final esperado

- ✅ Projetos clonados localmente na pasta `tmp-migracao/`
- ✅ `.gitlab-ci.yml` atualizado com caminhos corretos
- ✅ Push completo de branches e tags para o GitLab Enterprise
- ✅ Arquivamento replicado no destino, se aplicável

---

## 🧠 Dicas finais

- Teste com 1 ou 2 projetos antes de rodar com todos
- Use tokens com escopos completos (inclusive `write_repository`)
- Faça backup (snapshot) antes de alterações em massa
- Estruturar projetos por subgrupos (`subgrupo1`, `subgrupo2`, `subgrupo3`, etc.) ajuda na organização

---

## 👨‍💻 Autor

[![GitHub - clcesarval](https://img.shields.io/badge/GitHub-clcesarval-blue?logo=github)](https://github.com/clcesarval)

---

**Licença:** MIT – sinta-se à vontade para reutilizar e adaptar os scripts para seu contexto! 🚀
