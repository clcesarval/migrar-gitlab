# 🚀 migrar-gitlab

Automation for migrating repositories from GitLab Community (self-hosted) to GitLab Enterprise (gitlab.com).

This repository contains reusable Bash scripts to facilitate cloning, adjustment, pushing, metadata migration, and post-migration governance, preserving history, traceability, and security.

---

## 🗂️ Script Overview

| Script | Description |
|------|------------|
| clone-projects.sh | Clones all projects from a source GitLab group |
| replace_gitlab-ci.sh | Updates internal paths in .gitlab-ci.yml |
| push_projects.sh | Reconfigures remotes, recreates branches, and pushes |
| migrate-group-variables.sh | Migrates group variables via API |
| migrate-issues.sh | Migrates issues and comments between projects |
| delete-issues.sh | Removes all issues from a project |
| gitlab-clone-recursive.sh | Recursive cloning preserving hierarchy |
| protect-projects.sh | Protects and locks old projects post-migration |

---

## ⚙️ Prerequisites

- Git
- jq
- curl
- Bash (Linux or WSL)
- GitLab access tokens with permissions:
  - read_api
  - read_repository
  - write_repository
  - maintainer or admin_group depending on the script

---

## 🔹 1. clone-projects.sh

Clones all projects from a source GitLab group.

### What it does:
- Queries the GitLab API
- Lists all projects in the group
- Clones repositories locally
- Prevents overwriting already cloned repositories
- Removes the original remote
- Adds the destination GitLab remote

### Notes:
- Safe to re-run
- No history loss
- Ideal for large-scale migrations

---

## 🔹 2. replace_gitlab-ci.sh

Updates internal references in .gitlab-ci.yml files.

### What it does:
- Locates all .gitlab-ci.yml files
- Replaces old paths with new ones
- Creates .bak backups before changes

### Configuration:
OLD_PATH="old/path"
NEW_PATH="new/path"

---

## 🔹 3. push_projects.sh

Performs the full push to the destination GitLab.

### What it does:
- Recreates all branches
- Pushes full history
- Preserves repository integrity

---

## 🔹 4. migrate-group-variables.sh

Migration of group variables between GitLab instances.

### Features:
- Group variables migrated from source to destination via API
- Existing variables detected and not overwritten
- Logs created for auditing and troubleshooting
- 100% compatible with GitLab API v4

---

## 🔹 5. migrate-issues.sh and delete-issues.sh

## 🧩 GitLab Issue Migration and Cleanup Scripts

This repository contains two Bash scripts useful for manipulating issues between GitLab projects. They are especially useful in migration scenarios between GitLab instances or for full cleanup of existing issues.

---

### 📦 migrate-issues.sh – Issue and Comment Migration

This script migrates all issues and their comments from a source GitLab project to a destination GitLab project.

#### Features:
- Exports issues with title, description, and creation date
- Recreates issues in the destination project
- Preserves original state (open or closed)
- Migrates comments with author name and timestamp

#### Required variables:
DEST_PROJECT_ID="DESTINATION_PROJECT_ID"
TOKEN="DESTINATION_TOKEN"
SOURCE_PROJECT_ENCODED="group%2Fproject"
SOURCE_TOKEN="SOURCE_TOKEN"

---

### ❌ delete-issues.sh – Bulk Issue Deletion

Script to remove all issues from a GitLab project.

⚠️ Warning:
This operation is irreversible.

Variables:
DEST_PROJECT_ID="PROJECT_ID"
TOKEN="TOKEN"

---

### Requirements for issue scripts:
- jq installed
- Bash 4+
- Tokens with read and write permissions
- Destination project must already exist

Notes:
- Scripts use only the GitLab REST API
- Always test in a non-production environment
- URLs are placeholders and must be adjusted

---

## 🔹 6. gitlab-clone-recursive.sh

Recursive cloning of all repositories from a GitLab group.

### Features:
- Clones root group and subgroups
- Preserves local directory hierarchy
- Uses token-based authentication
- Skips repositories already cloned

### Variables:
GITLAB_URL="https://gitlab.your-instance.com"
GITLAB_TOKEN="YOUR_TOKEN"
ROOT_GROUP_ID=000
ROOT_GROUP_PATH="group/root"

---

## 🔹 7. protect-projects.sh – Old Project Protection (POST-MIGRATION)

Script responsible for completely locking old or migrated projects, ensuring governance and preventing unintended changes.

### What this script does:
- Protects all branches (*)
- Blocks direct pushes
- Blocks direct merges
- Allows only Maintainers to remove protection
- Disables merge requests
- Processes groups and subgroups recursively

### Configuration:
GITLAB_HOST="gitlab.com"
TOKEN="YOUR_TOKEN"
GROUP_ID="888"

### Notes:
- Ideal for legacy or frozen repositories
- Ensures read-only state after migration
- Prevents accidental commits or merges
- Strongly recommended for compliance and audit scenarios

---

## 🧠 Recommended Migration Flow

1. gitlab-clone-recursive.sh or clone-projects.sh
2. replace_gitlab-ci.sh
3. push_projects.sh
4. migrate-group-variables.sh
5. migrate-issues.sh
6. protect-projects.sh

---

## 📄 Final Notes

- Scripts are safe to re-run where applicable
- Designed for large-scale migrations
- Successfully used with thousands of repositories
- Fully based on the official GitLab REST API
- Suitable for enterprise governance, audit, and compliance scenarios

---

## 📌 License

Internal, educational, or corporate use.  
Adapt as required by your compliance policies.

