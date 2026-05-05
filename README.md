# Git Quick Push Helper

A safer Bash helper script to initialize a local Git repository, configure Git identity, create or switch to a branch, commit current files, and push the branch to GitHub.

The secure version avoids storing GitHub tokens by default and supports multiple authentication modes:

- GitHub CLI authentication with `gh auth login`
- SSH keys
- Git Credential Manager
- Fine-grained GitHub token fallback, requested per run and not saved to disk

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Recommended Authentication Mode](#recommended-authentication-mode)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Authentication Modes](#authentication-modes)
- [Configuration File](#configuration-file)
- [Security Notes](#security-notes)
- [Diagrams](#diagrams)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

This script automates a common Git workflow:

1. Load or create local script configuration.
2. Ensure `.git_quick_config` is globally ignored by Git.
3. Authenticate using GitHub CLI, SSH, Git Credential Manager, or a temporary fine-grained token.
4. Ask for organization, repository, branch, and commit message.
5. Initialize Git in the current directory.
6. Configure local Git user name and email.
7. Configure the GitHub remote.
8. Create or switch to the selected branch.
9. Add, commit, and push changes.

---

## Features

- Safer authentication workflow.
- Uses GitHub CLI by default.
- Supports SSH remotes.
- Supports Git Credential Manager.
- Supports token fallback without saving the token.
- Automatically protects `.git_quick_config` using global Git ignore.
- Stores only non-secret configuration by default.
- Fixes the remote URL format.
- Avoids empty commits when there are no changes.

---

## Recommended Authentication Mode

The recommended mode is GitHub CLI:

```bash
gh auth login
```

Then configure the script with:

```bash
./git-quick-push-secure.sh --config
```

Choose:

```text
gh
```

as the authentication mode.

---

## Requirements

You need:

- Bash
- Git
- A GitHub account
- A GitHub repository created beforehand

Optional, depending on authentication mode:

- GitHub CLI: `gh`
- SSH key configured in GitHub
- Git Credential Manager
- Fine-grained GitHub token with minimum required permissions

Check Git installation:

```bash
git --version
```

Check GitHub CLI installation:

```bash
gh --version
```

Check GitHub CLI authentication:

```bash
gh auth status
```

---

## Installation

Make the script executable:

```bash
chmod +x git-quick-push-secure.sh
```

Optionally move it to a directory in your `PATH`:

```bash
sudo cp git-quick-push-secure.sh /usr/local/bin/git-quick-push
```

Then run it from any project directory:

```bash
git-quick-push
```

---

## Usage

### First Run

Run the script from inside the folder you want to push:

```bash
./git-quick-push-secure.sh
```

On first run, the script asks for:

```text
USER_NAME
USER_EMAIL
GH_USER
AUTH_MODE
Organization
Repository name
Branch name
Commit message
```

Example:

```text
Primera configuración detectada.
USER_NAME: Esteban Armas
USER_EMAIL: esteban@example.com
GH_USER: esteban-armas

Selecciona modo de autenticación:
  1) gh    - GitHub CLI, recomendado
  2) ssh   - SSH keys
  3) gcm   - Git Credential Manager
  4) token - Fine-grained token, no se guarda en disco
AUTH_MODE [gh]: gh

Organización [work-code-hub]: work-code-hub
Nombre del Repositorio: my-project
Nombre de la rama: lenovo
Mensaje del commit: Initial commit
```

---

### Update Stored Configuration

Use:

```bash
./git-quick-push-secure.sh --config
```

This updates:

- Git user name
- Git email
- GitHub username
- Authentication mode

The script does not save GitHub tokens.

---

### Clear Stored Configuration

Use:

```bash
./git-quick-push-secure.sh --clear
```

This removes:

```bash
~/.git_quick_config
```

The global Git ignore protection remains enabled.

---

### Show Security Notes

Use:

```bash
./git-quick-push-secure.sh --security
```

---

### Show Help

Use:

```bash
./git-quick-push-secure.sh --help
```

---

## Authentication Modes

### 1. GitHub CLI Mode

Recommended mode.

Remote URL format:

```bash
https://github.com/ORG/REPO.git
```

Before using it, authenticate with:

```bash
gh auth login
```

The script checks:

```bash
gh auth status
```

If GitHub CLI is not authenticated, the script starts:

```bash
gh auth login
```

---

### 2. SSH Mode

Remote URL format:

```bash
git@github.com:ORG/REPO.git
```

Generate a key if needed:

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Add the public key to your GitHub account.

Test SSH access:

```bash
ssh -T git@github.com
```

---

### 3. Git Credential Manager Mode

Remote URL format:

```bash
https://github.com/ORG/REPO.git
```

Configure Git Credential Manager:

```bash
git credential-manager configure
```

Then run the script and select:

```text
gcm
```

---

### 4. Token Fallback Mode

This mode asks for a token during each run and does not save it to disk.

Use only a fine-grained GitHub token with the minimum required repository permissions.

Remote URL format during the push:

```bash
https://GH_USER:TOKEN@github.com/ORG/REPO.git
```

The token is intentionally not written to:

```bash
~/.git_quick_config
```

---

## Configuration File

The script stores only non-secret configuration in:

```bash
~/.git_quick_config
```

Example:

```bash
USER_NAME="Esteban Armas"
USER_EMAIL="esteban@example.com"
GH_USER="esteban-armas"
AUTH_MODE="gh"
```

The file is protected with:

```bash
chmod 600 ~/.git_quick_config
```

The script always adds this file to the global Git ignore file:

```bash
echo ".git_quick_config" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```

The script avoids duplicates by checking whether `.git_quick_config` already exists in `~/.gitignore_global`.

---

## Security Notes

Recommended practices:

- Use GitHub CLI authentication with `gh auth login`.
- Use SSH keys when suitable.
- Use Git Credential Manager when working with HTTPS remotes.
- Use fine-grained GitHub tokens only as a fallback.
- Use tokens with minimum required permissions.
- Never commit `.git_quick_config` into a repository.
- Never share screenshots or terminal logs containing tokens.
- Do not paste tokens into issue trackers, chats, screenshots, or documentation.
- Rotate any token that may have been exposed.

---

## Diagrams

### Main Workflow

```mermaid
flowchart TD
    A[Start script] --> B[Ensure global Git ignore protection]
    B --> C[Load ~/.git_quick_config]
    C --> D{Config complete?}
    D -- "No" --> E[Ask for user identity and auth mode]
    E --> F[Save non-secret config]
    D -- "Yes" --> G[Use existing config]
    F --> H[Check dependencies]
    G --> H
    H --> I{Auth mode}
    I -- "gh" --> J[Check gh auth status]
    I -- "ssh" --> K[Use SSH remote]
    I -- "gcm" --> L[Configure Git Credential Manager]
    I -- "token" --> M[Ask for fine-grained token for this run only]
    J --> N[Ask repo, branch and commit message]
    K --> N
    L --> N
    M --> N
    N --> O[git init]
    O --> P[Set local Git user.name and user.email]
    P --> Q[Configure origin remote]
    Q --> R[Create or switch branch]
    R --> S[git add .]
    S --> T{Any staged changes?}
    T -- "No" --> U[Skip commit]
    T -- "Yes" --> V[git commit]
    U --> W[git push -u origin HEAD]
    V --> W
    W --> X[Done]
```

---

### Configuration Commands

The labels containing `--config` and `--clear` are quoted to avoid Mermaid lexical errors in GitHub.

```mermaid
flowchart LR
    A[User runs script] --> B{Argument?}
    B -- "--config" --> C[Ask for new config values]
    C --> D[Save non-secret ~/.git_quick_config]
    B -- "--clear" --> E[Delete ~/.git_quick_config]
    B -- "--security" --> F[Show security notes]
    B -- "none" --> G[Run main Git workflow]
```

---

### Authentication Decision Flow

```mermaid
flowchart TD
    A[Select AUTH_MODE] --> B{Mode}
    B -- "gh" --> C[Use GitHub CLI]
    C --> D[Remote: https://github.com/ORG/REPO.git]
    B -- "ssh" --> E[Use SSH key]
    E --> F[Remote: git@github.com:ORG/REPO.git]
    B -- "gcm" --> G[Use Git Credential Manager]
    G --> H[Remote: https://github.com/ORG/REPO.git]
    B -- "token" --> I[Prompt for fine-grained token]
    I --> J[Token used only for current run]
```

---

### GitHub Push Sequence

```mermaid
sequenceDiagram
    participant User
    participant Script
    participant Git
    participant GitHub

    User->>Script: Run script
    Script->>Script: Load non-secret config
    Script->>Script: Ensure .git_quick_config is globally ignored
    Script->>User: Ask repository, branch and commit message
    Script->>Git: git init
    Script->>Git: git config user.name/user.email
    Script->>Git: git remote add or set-url origin
    Script->>Git: git checkout branch
    Script->>Git: git add .
    Script->>Git: git commit, if changes exist
    Script->>GitHub: git push -u origin HEAD
    GitHub-->>User: Branch pushed
```

---

## Troubleshooting

### Mermaid diagram does not render

If GitHub shows:

```text
Unable to render rich display
Lexical error on line 3. Unrecognized text.
```

Check whether an edge label contains raw `--config`, `--clear`, or similar values.

This can fail:

```mermaid
flowchart LR
    A[User runs script] --> B{Argument?}
    B -- --config --> C[Ask for new config values]
```

Use quoted labels instead:

```mermaid
flowchart LR
    A[User runs script] --> B{Argument?}
    B -- "--config" --> C[Ask for new config values]
```

---

### GitHub CLI is not installed

Install GitHub CLI, or change the authentication mode:

```bash
./git-quick-push-secure.sh --config
```

Then select:

```text
ssh
```

or:

```text
gcm
```

---

### GitHub CLI is not authenticated

Run:

```bash
gh auth login
```

Or let the script start the login flow automatically.

---

### Permission denied with SSH

Test SSH:

```bash
ssh -T git@github.com
```

Make sure your public key is added to your GitHub account.

---

### Authentication failed with token mode

Possible causes:

- Token expired.
- Token lacks repository permissions.
- Repository does not exist.
- Organization name is incorrect.
- GitHub username is incorrect.

Re-run:

```bash
./git-quick-push-secure.sh --config
```

Or choose another authentication mode.

---

### Nothing to commit

Git may show:

```text
No hay cambios para commitear.
```

This means there are no new staged changes. The script will still try to push the selected branch.

---

### Repository does not exist on GitHub

The script does not create GitHub repositories automatically.

Create the repository first, then run the script again.

---

## License

This project can be distributed under the MIT License.
