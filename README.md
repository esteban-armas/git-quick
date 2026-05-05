# Git Quick Push Helper

A small Bash helper script to initialize a local Git repository, configure Git identity, create or switch to a branch, commit all current files, and push the branch to GitHub.

> **Important:** The script stores your GitHub token in a local config file at `~/.git_quick_config`. This is convenient, but it must be protected carefully.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Installation](#installation)
- [How It Works](#how-it-works)
- [Usage](#usage)
- [Configuration](#configuration)
- [Security Notes](#security-notes)
- [Diagrams](#diagrams)
- [Troubleshooting](#troubleshooting)
- [Recommended Fixes](#recommended-fixes)
- [License](#license)

---

## Overview

This script automates a common Git workflow:

1. Load or create GitHub credentials.
2. Ask for repository, branch, and commit details.
3. Initialize the current directory as a Git repository.
4. Configure local Git username and email.
5. Configure the GitHub remote.
6. Create or switch to a branch.
7. Commit all files.
8. Push the branch to GitHub.

The script is useful for quickly pushing code from different machines, labs, or project folders.

---

## Features

- Interactive first-time configuration.
- Stores user name, email, GitHub username, and token.
- Supports updating stored configuration with `--config`.
- Supports deleting stored configuration with `--clear`.
- Initializes Git automatically.
- Creates or switches to the selected branch.
- Adds, commits, and pushes all files.

---

## Repository Structure

Example structure:

```text
.
├── git-quick.sh
├── README.md
└── your-project-files/
```

Recommended script name:

```bash
git-quick.sh
```

---

## Requirements

You need:

- Bash
- Git
- A GitHub account
- A GitHub Personal Access Token
- A GitHub repository created beforehand

Check Git installation:

```bash
git --version
```

---

## Installation

Clone or copy this repository, then make the script executable:

```bash
chmod +x git-quick.sh
```

Optionally move it to a directory in your `PATH`:

```bash
sudo cp git-quick.sh /usr/local/bin/git-quick
```

Then you can run it from any project directory:

```bash
git-quick
```

---

## How It Works

The script uses this config file:

```bash
~/.git_quick_config
```

The file stores:

```bash
USER_NAME="Your Name"
USER_EMAIL="your.email@example.com"
GH_USER="your-github-user"
TOKEN="your-github-token"
```

Permissions are restricted with:

```bash
chmod 600 ~/.git_quick_config
```

---

## Usage

### First Run

Run the script from inside the folder you want to push:

```bash
./git-quick.sh
```

On first run, the script asks for:

```text
USER_NAME
USER_EMAIL
GH_USER
GitHub Token
Organization
Repository name
Branch name
Commit message
```

Example:

```text
USER_NAME: Esteban Armas
USER_EMAIL: esteban@example.com
GH_USER: esteban-armas
GitHub Token: ********
Organización [work-code-hub]: work-code-hub
Nombre del Repositorio: my-project
Nombre de la rama: lenovo
Mensaje del commit: Initial commit
```

---

### Update Stored Configuration

Use:

```bash
./git-quick.sh --config
```

This allows you to update:

- Git user name
- Git email
- GitHub username
- GitHub token

---

### Clear Stored Configuration

Use:

```bash
./git-quick.sh --clear
```

This removes:

```bash
~/.git_quick_config
```

Run the script again to reconfigure it.

---

## Configuration

The script stores configuration locally in your home folder:

```bash
$HOME/.git_quick_config
```

To inspect it:

```bash
cat ~/.git_quick_config
```

To check permissions:

```bash
ls -l ~/.git_quick_config
```

Expected permission:

```text
-rw------- 1 user user ... /home/user/.git_quick_config
```

---

## Security Notes

This script stores the GitHub token in plain text in:

```bash
~/.git_quick_config
```

The script protects the file with:

```bash
chmod 600 "$CONFIG_FILE"
```

However, consider the following safer alternatives:

- Use GitHub CLI authentication with `gh auth login`.
- Use Git credential manager.
- Use SSH keys instead of HTTPS tokens.
- Use fine-grained GitHub tokens with minimum required permissions.
- Never commit `.git_quick_config` into a repository.
- Never share screenshots or terminal logs containing the token.

Add this to your global Git ignore file if needed:

```bash
echo ".git_quick_config" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

---

## Diagrams

### Main Workflow

```mermaid
flowchart TD
    A[Start script] --> B[Load ~/.git_quick_config]
    B --> C{Token exists?}
    C -- No --> D[Ask for USER_NAME, USER_EMAIL, GH_USER and TOKEN]
    D --> E[Save config with chmod 600]
    C -- Yes --> F[Use existing config]
    E --> G[Ask for organization, repository, branch and commit message]
    F --> G
    G --> H[git init]
    H --> I[Configure local Git identity]
    I --> J[Configure origin remote]
    J --> K[Create or switch branch]
    K --> L[git add .]
    L --> M[git commit -m message]
    M --> N[git push -u origin HEAD]
    N --> O[Done]
```

---

### Configuration Commands

```mermaid
flowchart LR
    A[User runs script] --> B{Argument?}
    B -- --config --> C[Ask for new config values]
    C --> D[Save ~/.git_quick_config]
    B -- --clear --> E[Delete ~/.git_quick_config]
    B -- none --> F[Run main Git workflow]
```

---

### GitHub Push Flow

```mermaid
sequenceDiagram
    participant User
    participant Script
    participant Git
    participant GitHub

    User->>Script: Run ./git-quick.sh
    Script->>User: Ask repo, branch and commit message
    Script->>Git: git init
    Script->>Git: git config user.name/user.email
    Script->>Git: git remote add/set-url origin
    Script->>Git: git checkout -b branch
    Script->>Git: git add .
    Script->>Git: git commit -m message
    Script->>GitHub: git push -u origin HEAD
    GitHub-->>User: Branch pushed
```

---

## Troubleshooting

### 1. Invalid remote URL

The current script contains this line:

```bash
REMOTE_URL="https://$GH_USER:$TOKEN@://github.com"
```

This URL is invalid.

It should include the organization and repository:

```bash
REMOTE_URL="https://$GH_USER:$TOKEN@github.com/$ORG/$REPO.git"
```

---

### 2. Authentication failed

Possible causes:

- Token is expired.
- Token does not have repository permissions.
- GitHub username is incorrect.
- Repository does not exist.
- Organization name is incorrect.

Reconfigure:

```bash
./git-quick.sh --config
```

---

### 3. Nothing to commit

Git may show:

```text
nothing to commit, working tree clean
```

This means there are no new changes to commit.

---

### 4. Branch already exists

The script handles this with:

```bash
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
```

It first tries to create the branch. If it already exists, it switches to it.

---

### 5. Repository does not exist on GitHub

The script does not create GitHub repositories automatically.

Create the repository manually first, then run the script again.

---

## Recommended Fixes

The original script is useful, but the remote URL should be fixed.

Replace:

```bash
REMOTE_URL="https://$GH_USER:$TOKEN@://github.com"
```

With:

```bash
REMOTE_URL="https://$GH_USER:$TOKEN@github.com/$ORG/$REPO.git"
```

Recommended improved remote block:

```bash
REMOTE_URL="https://$GH_USER:$TOKEN@github.com/$ORG/$REPO.git"

if git remote | grep -q '^origin$'; then
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi
```

Also consider avoiding commits when there are no changes:

```bash
if git diff --cached --quiet; then
    echo "No hay cambios para commitear."
else
    git commit -m "$MESSAGE"
fi
```

---

## Example Full Execution

```bash
$ ./git-quick.sh

Primera configuración detectada:
USER_NAME (ej. Esteban Armas): Esteban Armas
USER_EMAIL (ej. esarmas@ucm.es): esteban@example.com
GH_USER (ej. esteban-armas): esteban-armas
GitHub Token: ********

Organización [work-code-hub]: work-code-hub
Nombre del Repositorio: my-project
Nombre de la rama (ej. lenovo): lenovo
Mensaje del commit: Initial commit

Subiendo cambios a lenovo...
```

---

## License

This project can be distributed under the MIT License.
