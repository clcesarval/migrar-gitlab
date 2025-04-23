# 🚀 migrar-gitlab

Automação da **migração de repositórios do GitLab Community (self-hosted)** para o **GitLab Enterprise (gitlab.com)**.

Este repositório contém **scripts bash reutilizáveis** para facilitar a clonagem, ajuste e push de múltiplos projetos com segurança, controle e padronização.

---

## 🗂️ Visão geral dos scripts

| Script                  | Descrição                                                                 |
|------------------------|---------------------------------------------------------------------------|
| `clone-projects.sh`    | 🔄 Clona todos os projetos de um grupo GitLab origem                      |
| `replace_gitlab-ci.sh` | ✏️ Atualiza caminhos internos do `.gitlab-ci.yml` para o novo repositório |
| `push_projects.sh`     | ⬆️ Reconfigura remotes, recria branches da origem e faz push final        |

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
- **Evita sobrescrever projetos já clonados**
- Remove o remote original
- Adiciona o remote do GitLab destino

### 🛡️ Segurança adicional

- Valida se a pasta já contém repositório `.git`
- Pula clonagem caso já tenha sido feito anteriormente

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
- Substitui caminhos antigos por novos (exemplo: `pmid/libs` → `engbr/.../legacy/libs`)
- Cria backups `.bak` dos arquivos antes de editar

### 🛡️ Segurança adicional

- Backup automático dos arquivos `.gitlab-ci.yml`
- Exibe um resumo após as substituições

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

- Acessa cada projeto clonado
- Redefine o remote `origin` para o repositório **de origem**
- Busca todas as branches da origem
- Cria localmente cada branch remota da origem
- Redefine o `origin` para o repositório de **destino**
- Realiza push de **todas as branches** e **tags**
- **Verifica se há alterações locais antes de commitar**
- **Protege arquivos modificados localmente, como o `.gitlab-ci.yml`**
- Verifica se o projeto está arquivado na origem e replica o arquivamento no destino

### ⚠️ Prevenção de sobrescrita

> Arquivos alterados localmente (ex: `.gitlab-ci.yml`) **não serão sobrescritos** se já houver commit e nada mudou após o `git fetch`.

### ⚙️ Personalização

Edite no script:
- `GRUPO`
- Hosts e tokens de origem/destino
- Caminhos dos grupos

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
- ✅ Proteção contra sobrescrita de arquivos modificados localmente

---

## 🧠 Dicas finais

- Teste com 1 ou 2 projetos antes de rodar com todos
- Use tokens com escopos completos (inclusive `write_repository`)
- Faça backup (snapshot) antes de alterações em massa
- Estruturar projetos por subgrupos (`subgrupo1`, `subgrupo2`, `subgrupo3`, etc.) ajuda na organização
- Prefira sempre clonar com `git clone` e evitar `--mirror` para manter controle total

---



---

## 🔹 4. `migrar-variaveis.sh`

### 📋 O que este script faz?

- Acessa a API do GitLab **self-hosted** (Community)
- Lista todas as variáveis de ambiente do grupo de origem (com paginação)
- Cria essas variáveis no grupo correspondente no GitLab **Enterprise** (gitlab.com)
- Trata variáveis já existentes no destino e registra logs detalhados

### 🛡️ Segurança e rastreabilidade

- Cria logs separados:
  - `variaveis_existentes.log`: variáveis já presentes no destino
  - `variaveis_falha.log`: variáveis que falharam ao ser migradas (ex: erro 400)
  - `migracao_variaveis.log`: resumo final
  - `variables.json`: dump completo das variáveis lidas da origem
- Exibe na tela o progresso da migração com ícones visuais

### ⚙️ Personalização

No início do script, edite os seguintes valores:

```bash
TOKEN_ORIGEM="SEU_TOKEN_ORIGEM"
TOKEN_DESTINO="SEU_TOKEN_DESTINO"
GROUP_ID_ORIGEM="ID_DO_GRUPO_ORIGEM"
GROUP_ID_DESTINO="ID_DO_GRUPO_DESTINO"
URL_ORIGEM_BASE="https://seu.gitlab.origem/api/v4/groups/$GROUP_ID_ORIGEM/variables"
URL_DESTINO="https://gitlab.com/api/v4/groups/$GROUP_ID_DESTINO/variables"
```

> Os tokens devem ter escopos com permissões de leitura e escrita em variáveis de grupo.

### ▶️ Como executar:

```bash
chmod +x migrar-variaveis.sh
./migrar-variaveis.sh
```

---

## 📁 Estrutura esperada após a execução

```
.
├── clone-projects.sh
├── push_projects.sh
├── replace_gitlab-ci.sh
├── migrar-variaveis.sh
├── tmp-migracao/
│   ├── projeto-1/
│   ├── projeto-2/
│   └── ...
├── variaveis_existentes.log
├── variaveis_falha.log
├── migracao_variaveis.log
├── variables.json
└── README.md
```

---

## ✅ Resultado final esperado

- ✅ Variáveis de grupo migradas da origem para o destino via API
- ✅ Variáveis já existentes identificadas e não sobrescritas
- ✅ Logs criados para auditoria e troubleshooting
- ✅ Formato 100% compatível com a API v4 do GitLab

---


## 👨‍💻 Autor Claudio

[![GitHub - clcesarval](https://img.shields.io/badge/GitHub-clcesarval-blue?logo=github)](https://github.com/clcesarval)

---

**Licença:** MIT – sinta-se à vontade para reutilizar e adaptar os scripts para seu contexto! 🚀
