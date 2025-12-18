

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
- Substitui caminhos antigos por novos (exemplo: `old-group/subgroup` → `new-root-group/.../legacy/subgroup`)
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


## 🔹 5. `migrate-issues.sh` and  `delete-issues.sh`


## 🧩 Scripts de Migração e Limpeza de Issues no GitLab

Este repositório contém dois scripts Bash úteis para manipulação de issues entre projetos GitLab. Eles são especialmente úteis em cenários de **migração entre instâncias do GitLab** (ex: de um GitLab self-hosted para o GitLab.com) ou para **limpeza total** de issues existentes.

---

### 📦 `migrar_issues.sh` – Migração de Issues e Comentários

Este script migra todas as issues (e seus comentários) de um projeto GitLab de origem para um projeto GitLab de destino.

#### ✅ Funcionalidades:
- Exporta issues com título, descrição e data de criação
- Recria as issues no projeto de destino
- Preserva o estado original (aberta/fechada)
- Migra comentários (notas) com nome do autor e data

#### 🛠️ Variáveis que você deve configurar:
```bash
DEST_PROJECT_ID="ID_DO_PROJETO_DESTINO"
TOKEN="SEU_TOKEN_PRIVADO_DESTINO"
SOURCE_PROJECT_ENCODED="grupo%2Fprojeto"  # Caminho do projeto de origem com %2F no lugar de /
SOURCE_TOKEN="SEU_TOKEN_PRIVADO_ORIGEM"
```

---

### ❌ `deletar_issues.sh` – Deleção em Massa de Issues

Script simples que deleta **todas as issues de um projeto GitLab**. Ideal para limpar projetos de teste, ambiente de staging ou recomeçar uma importação.

#### ⚠️ Aviso:

**Use com cuidado!** Este script não tem confirmação e deletará todas as issues no projeto indicado.

#### 🛠️ Variáveis que você deve configurar:
```bash
DEST_PROJECT_ID="ID_DO_PROJETO"
TOKEN="SEU_TOKEN_PRIVADO"
```

---

### 🧪 Requisitos

- `jq` instalado (`sudo apt install jq` ou equivalente)
- Bash 4+
- Tokens do GitLab com permissões de leitura e escrita em issues
- Projeto de destino previamente criado

---

### 📌 Observações

- Os scripts usam apenas a API REST do GitLab.
- É recomendado testar em um projeto temporário antes de aplicar em produção.
- As URLs dos servidores GitLab foram substituídas por placeholders (`gitlab.DESTINO.com`, `gitlab.ORIGEM.com`) para segurança. Atualize conforme necessário.

---


## 6. `gitlab-clone-recursive.sh` – Clonagem Recursiva de Repositórios GitLab

Este script clona todos os repositórios de um grupo GitLab (e seus subgrupos), preservando a hierarquia de diretórios localmente. É ideal para backup completo ou migração de um grupo GitLab para outra instância.

### ✅ Funcionalidades:
- Clona todos os projetos do grupo raiz e de subgrupos recursivamente.
- Preserva a estrutura original de grupos/subgrupos na pasta local.
- Usa autenticação via token.
- Ignora repositórios que já foram clonados previamente.

### 🔧 Variáveis que você deve configurar:
```bash
GITLAB_URL="https://gitlab.sua-instancia.com"
GITLAB_TOKEN="SEU_TOKEN_PRIVADO"
ROOT_GROUP_ID=000                    # ID do grupo raiz
ROOT_GROUP_PATH="grupo/raiz"        # Caminho do grupo raiz
```

### ▶️ Como executar:
```bash
bash gitlab-clone-recursive.sh
```

---

## 7. `gitlab-push-recursive.sh` – Push Recursivo com Criação Automática de Subgrupos

Este script percorre todos os repositórios clonados e os envia (`push`) para outro servidor GitLab, criando automaticamente os subgrupos e projetos se ainda não existirem no destino.

### ✅ Funcionalidades:
- Cria subgrupos ausentes automaticamente via API do GitLab.
- Cria o projeto correspondente no destino.
- Executa push de todas as branches e tags.
- Preserva a hierarquia original dos repositórios.

### 🔧 Variáveis que você deve configurar:
```bash
TARGET_GITLAB_HOST="gitlab.com"
TARGET_GITLAB_TOKEN="SEU_TOKEN_PRIVADO"
TARGET_GROUP_PATH="grupo/raiz/para/onde/vai"
```

### ▶️ Como executar:
```bash
bash gitlab-push-recursive.sh
```


---

## 🔹 8. `protect-projects.sh` – Proteção de Projetos Antigos (PÓS-MIGRAÇÃO)

Este script é utilizado **após a migração completa** para **bloquear projetos antigos ou já migrados**, garantindo governança, compliance e prevenindo alterações indevidas.

Ele é especialmente útil em cenários onde:
- Os projetos migrados devem permanecer **somente leitura**
- O ambiente de origem precisa ser **congelado**
- Há exigência de **auditoria e rastreabilidade**
- Não deve haver novos commits ou merges acidentais

---

### 📋 O que este script faz?

- Protege **todas as branches (`*`)** dos projetos
- Bloqueia:
  - Push direto
  - Merge direto
- Permite apenas **Maintainers** remover a proteção
- Desabilita **Merge Requests**
- Processa **grupos e subgrupos de forma recursiva**
- Atua em **todos os projetos** de um grupo raiz

---

### ⚙️ Configuração

Edite no início do script:

```bash
GITLAB_HOST="gitlab.com"
TOKEN="SEU_TOKEN_PRIVADO"
GROUP_ID="ID_NUMERICO_DO_GRUPO_RAIZ"



---

💡 **Dica:** Você pode usar `gitlab-clone-recursive.sh` para obter todos os repositórios de um GitLab self-hosted e, em seguida, `gitlab-push-recursive.sh` para enviá-los para o GitLab.com ou outro destino.

🛠 Ambos os scripts foram criados para facilitar a migração de grandes grupos entre diferentes instâncias do GitLab, com mínima intervenção manual.


### 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).



## 👨‍💻 Autor Claudio

[![GitHub - clcesarval](https://img.shields.io/badge/GitHub-clcesarval-blue?logo=github)](https://github.com/clcesarval)

---






<p align="center">
  <img src="https://img.shields.io/github/stars/clcesarval/migrar-gitlab?style=social" />
  <img src="https://img.shields.io/github/forks/clcesarval/migrar-gitlab?style=social" />
  <img src="https://img.shields.io/github/watchers/clcesarval/migrar-gitlab?style=social" />
  <img src="https://img.shields.io/github/issues/clcesarval/migrar-gitlab" />
  <img src="https://img.shields.io/github/license/clcesarval/migrar-gitlab" />
  <img src="https://hits.sh/github.com/clcesarval/migrar-gitlab.svg?style=flat-square" />
</p>


**Licença:** MIT – sinta-se à vontade para reutilizar e adaptar os scripts para o seu contexto! 🚀
 

Se você achou este projeto útil, considere deixar uma ⭐ e um comentário me dizendo se a sua experiência deu certo em https://github.com/clcesarval/migrar-gitlab/discussions 
Seu feedback e suas estrelas ajudam o toolkit a alcançar mais engenheiros que estão planejando ou executando migrações de GitLab → GitLab Enterprise.
