# 🚀 migrate-gitlab

Automation of **repository migration from GitLab Community (self-hosted)** to **GitLab Enterprise (gitlab.com)**.

This repository contains **reusable bash scripts** to facilitate the cloning, adjustment, and pushing of multiple projects with security, control, and standardization.

---

## 🗂️ Script Overview

| Script                  | Description                                                                 |
|------------------------|---------------------------------------------------------------------------|
| `clone-projects.sh`    | 🔄 Clones all projects from a source GitLab group                           |
| `replace_gitlab-ci.sh` | ✏️ Updates internal paths of `.gitlab-ci.yml` for the new repository        |
| `push_projects.sh`     | ⬆️ Reconfigures remotes, recreates source branches, and performs the final push|

---

## ⚙️ Prerequisites

- ✅ Git
- ✅ jq
- ✅ curl
- ✅ Bash (Linux or WSL)
- ✅ Access tokens (PAT) with the following permissions:
  - `read_api`
  - `read_repository`
  - `write_repository`

---

## 🔹 1. `clone-projects.sh`

### 📋 What does this script do?

- Accesses the source GitLab API
- Lists all projects in the specified group
- Clones the repositories into the `tmp-migration/` folder
- **Prevents overwriting already cloned projects**
- Removes the original remote
- Adds the remote for the target GitLab

### 🛡️ Additional security

- Validates if the folder already contains a `.git` repository
- Skips cloning if it’s already been done

### ⚙️ Customization

Edit in the script:
- `GROUP`: the name of the source group
- Tokens (`SOURCE_GITLAB_TOKEN`, `TARGET_GITLAB_TOKEN`)
- Source and target hosts and paths

### ▶️ How to run:

```bash
chmod +x clone-projects.sh
./clone-projects.sh
```

---

## 🔹 2. `replace_gitlab-ci.sh`

### ✏️ What does this script do?

- Finds all `.gitlab-ci.yml` files in `tmp-migration/`
- Replaces old paths with new ones (e.g., `pmid/libs` → `engbr/.../legacy/libs`)
- Creates `.bak` backups of the files before making changes

### 🛡️ Additional security

- Automatic backup of `.gitlab-ci.yml` files
- Displays a summary after replacements

### ⚙️ Customization

Edit in the script:

```bash
OLD_PATH="old/path"
NEW_PATH="new/path"
```

### ▶️ How to run:

```bash
chmod +x replace_gitlab-ci.sh
./replace_gitlab-ci.sh
```

---

## 🔹 3. `push_projects.sh`

### ⬆️ What does this script do?

- Accesses each cloned project
- Resets the `origin` remote to the **source** repository
- Fetches all branches from the source
- Locally creates each remote branch from the source
- Resets the `origin` remote to the **target** repository
- Pushes **all branches** and **tags**
- **Checks for local changes before committing**
- **Protects locally modified files, such as `.gitlab-ci.yml`**
- Checks if the project is archived in the source and replicates the archiving in the target

### ⚠️ Overwrite Prevention

> Locally changed files (e.g., `.gitlab-ci.yml`) **will not be overwritten** if they are already committed and nothing has changed after `git fetch`.

### ⚙️ Customization

Edit in the script:
- `GROUP`
- Source and target hosts and tokens
- Group paths

### ▶️ How to run:

```bash
chmod +x push_projects.sh
./push_projects.sh
```

---

## 📁 Expected Structure After Execution

```
.
├── clone-projects.sh
├── push_projects.sh
├── replace_gitlab-ci.sh
├── tmp-migration/
│   ├── project-1/
│   ├── project-2/
│   └── ...
└── README.md
```

---

## ✅ Expected Final Outcome

- ✅ Projects cloned locally in the `tmp-migration/` folder
- ✅ `.gitlab-ci.yml` updated with correct paths
- ✅ Complete push of branches and tags to GitLab Enterprise
- ✅ Archiving replicated in the target if applicable
- ✅ Protection against overwriting locally modified files

---

## 🧠 Final Tips

- Test with 1 or 2 projects before running it for all
- Use tokens with full scopes (including `write_repository`)
- Make a backup (snapshot) before mass modifications
- Structuring projects by subgroups (`subgroup1`, `subgroup2`, `subgroup3`, etc.) helps with organization
- Always prefer cloning with `git clone` rather than `--mirror` to maintain full control

---

## 🔹 4. `migrate-variables.sh`

### 📋 What does this script do?

- Accesses the GitLab **self-hosted** (Community) API
- Lists all group environment variables from the source group (with pagination)
- Creates these variables in the corresponding group in GitLab **Enterprise** (gitlab.com)
- Handles variables already existing in the target and logs detailed information

### 🛡️ Security and Traceability

- Creates separate logs:
  - `variables_existing.log`: variables already present in the target
  - `variables_failed.log`: variables that failed to migrate (e.g., 400 error)
  - `migration_variables.log`: final summary
  - `variables.json`: complete dump of variables read from the source
- Displays migration progress on the screen with visual icons

### ⚙️ Customization

At the start of the script, edit the following values:

```bash
SOURCE_TOKEN="YOUR_SOURCE_TOKEN"
TARGET_TOKEN="YOUR_TARGET_TOKEN"
SOURCE_GROUP_ID="ID_OF_THE_SOURCE_GROUP"
TARGET_GROUP_ID="ID_OF_THE_TARGET_GROUP"
SOURCE_BASE_URL="https://your.source.gitlab/api/v4/groups/$SOURCE_GROUP_ID/variables"
TARGET_URL="https://gitlab.com/api/v4/groups/$TARGET_GROUP_ID/variables"
```

> Tokens must have read and write permissions for group variables.

### ▶️ How to run:

```bash
chmod +x migrate-variables.sh
./migrate-variables.sh
```

---

## 📁 Expected Structure After Execution

```
.
├── clone-projects.sh
├── push_projects.sh
├── replace_gitlab-ci.sh
├── migrate-variables.sh
├── tmp-migration/
│   ├── project-1/
│   ├── project-2/
│   └── ...
├── variables_existing.log
├── variables_failed.log
├── migration_variables.log
├── variables.json
└── README.md
```

---

## ✅ Expected Final Outcome

- ✅ Group variables migrated from source to target via API
- ✅ Pre-existing variables identified and not overwritten
- ✅ Logs created for auditing and troubleshooting
- ✅ Fully compatible with GitLab API v4

---

## 🔹 5. `migrate-issues.sh` and  `delete-issues.sh`

## 🧩 Migration and Cleanup Scripts for Issues in GitLab

This repository contains two useful Bash scripts for manipulating issues between GitLab projects. They are especially useful in scenarios of **migration between GitLab instances** (e.g., from [...]

---

### 📦 `migrate_issues.sh` – Migration of Issues and Comments

This script migrates all issues (and their comments) from a source GitLab project to a target GitLab project.

#### ✅ Features:
- Exports issues with title, description, and creation date
- Recreates the issues in the target project
- Preserves the original state (open/closed)
- Migrates comments (notes) with author name and date

#### 🛠️ Variables to Configure:
```bash
TARGET_PROJECT_ID="ID_OF_THE_TARGET_PROJECT"
TARGET_TOKEN="YOUR_PRIVATE_TARGET_TOKEN"
SOURCE_PROJECT_ENCODED="group%2Fproject"  # Path of the source project with %2F instead of /
SOURCE_TOKEN="YOUR_PRIVATE_SOURCE_TOKEN"
```

---

### ❌ `delete-issues.sh` – Bulk Deletion of Issues

A simple script that deletes **all issues in a GitLab project**. Ideal for cleanup in test projects, staging environments, or restarting an import.

#### ⚠️ Warning:

**Use with caution!** This script does not prompt for confirmation and will delete all issues in the indicated project.

#### 🛠️ Variables to Configure:
```bash
TARGET_PROJECT_ID="ID_OF_THE_PROJECT"
TARGET_TOKEN="YOUR_PRIVATE_TOKEN"
```

---

### 🧪 Requirements

- `jq` installed (`sudo apt install jq` or equivalent)
- Bash 4+
- GitLab tokens with read and write permissions in issues
- Target project already created

---

### 📌 Notes

- The scripts use only the GitLab REST API.
- It is recommended to test in a temporary project before applying in production.
- URLs for GitLab servers have been replaced with placeholders (`gitlab.TARGET.com`, `gitlab.SOURCE.com`) for security. Please update as necessary.

---

## 6. `gitlab-clone-recursive.sh` – Recursive GitLab Repository Cloning

This script clones all repositories of a GitLab group (and its subgroups), preserving the directory hierarchy locally. It is ideal for a complete backup or migration of a GitLab group to [...]

### ✅ Features:
- Clones all projects from the root group and subgroups recursively.
- Preserves the original structure of groups/subgroups in the local folder.
- Uses token authentication.
- Skips repositories that have already been cloned.

### 🔧 Variables to Configure:
```bash
GITLAB_URL="https://gitlab.your-instance.com"
GITLAB_TOKEN="YOUR_PRIVATE_TOKEN"
ROOT_GROUP_ID=000                    # ID of the root group
ROOT_GROUP_PATH="root/group/path"    # Path of the root group
```

### ▶️ How to run:
```bash
bash gitlab-clone-recursive.sh
```

---

## 7. `gitlab-push-recursive.sh` – Recursive Push with Automatic Subgroup Creation

This script navigates through all cloned repositories and pushes them to another GitLab server, automatically creating subgroups and projects if they don’t yet exist in the target.

### ✅ Features:
- Automatically creates missing subgroups via the GitLab API.
- Creates the corresponding project in the target.
- Pushes all branches and tags.
- Preserves the original hierarchy of repositories.

### 🔧 Variables to Configure:
```bash
TARGET_GITLAB_HOST="gitlab.com"
TARGET_GITLAB_TOKEN="YOUR_PRIVATE_TOKEN"
TARGET_GROUP_PATH="root/group/path"
```

### ▶️ How to run:
```bash
bash gitlab-push-recursive.sh
```

---

## 🔹 8. `protect-projects.sh` – Protection of Old Projects (POST-MIGRATION)

This script is used **after the complete migration** to **lock old or already migrated projects**, ensuring governance, compliance, and preventing unauthorized changes.

It is especially useful in scenarios where:
- Migrated projects should remain **read-only**
- The source environment needs to be **frozen**
- **Auditability and traceability** are required
- No new commits or merges should occur accidentally

---

### 📋 What does this script do?

- Protects **all branches (`*`)** of the projects
- Blocks:
  - Direct push
  - Direct merge
- Allows only **Maintainers** to remove protection
- Disables **Merge Requests**
- Processes **groups and subgroups recursively**
- Acts on **all projects** of a root group

---

### ⚙️ Configuration

Edit at the start of the script:

```bash
GITLAB_HOST="gitlab.com"
TOKEN="YOUR_PRIVATE_TOKEN"
GROUP_ID="ID_OF_THE_ROOT_GROUP"
```

---

## 🔹 9. `count-projects-recursively.sh` – Recursive Project Count by Group

This script performs a **recursive count of GitLab projects** starting from a **root group**, traversing **all nested subgroups**.

It is especially useful for:
- Migration planning
- Scope auditing
- Pre-migration validation
- Effort and timeline estimation for large-scale operations

---

### 📋 What does this script do?

- Accepts a **root group path**
- Resolves the **group ID** using the GitLab API
- Counts all projects within the group (with pagination)
- Recursively traverses all subgroups
- Displays:
  - Project count per group
  - A consolidated total at the end

---

### ⚙️ Configuration

Edit the following variables at the beginning of the script:

```bash
GITLAB_URL="https://gitlab.your-instance.com"
TOKEN="YOUR_PRIVATE_TOKEN"
ROOT_GROUP="root/group/path"



---

💡 **Tip:** You can use `gitlab-clone-recursive.sh` to fetch all repositories from a self-hosted GitLab and then `gitlab-push-recursive.sh` to migrate them to GitLab.com or another target.

🛠 Both scripts are designed to ease the migration of large groups between GitLab instances with minimal manual intervention.

### 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👨‍💻 Author: Claudio

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

**License:** MIT – feel free to reuse and adapt the scripts for your context! 🚀

If you found this project useful, consider leaving a ⭐ and a comment sharing whether your experience was successful in  
[GitHub Discussions](https://github.com/clcesarval/migrar-gitlab/discussions)

Your feedback and stars help the toolkit reach more engineers who are planning or running GitLab → GitLab Enterprise migrations.


If you find this project useful, consider leaving a ⭐ on the repo.
Your feedback and stars help the toolkit reach more engineers who are planning or running GitLab → GitLab Enterprise migrations.
