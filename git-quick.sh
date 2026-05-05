#!/usr/bin/env bash
set -euo pipefail

# Git Quick Push Helper - safer version
# Preferred auth modes:
#   1) GitHub CLI: gh auth login
#   2) SSH keys
#   3) Git Credential Manager
#   4) Fine-grained GitHub token fallback

CONFIG_FILE="$HOME/.git_quick_config"
GLOBAL_GITIGNORE="$HOME/.gitignore_global"

ensure_global_gitignore() {
    touch "$GLOBAL_GITIGNORE"

    if ! grep -qxF ".git_quick_config" "$GLOBAL_GITIGNORE"; then
        echo ".git_quick_config" >> "$GLOBAL_GITIGNORE"
    fi

    git config --global core.excludesfile "$GLOBAL_GITIGNORE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

save_config() {
    {
        echo "USER_NAME=\"${USER_NAME:-}\""
        echo "USER_EMAIL=\"${USER_EMAIL:-}\""
        echo "GH_USER=\"${GH_USER:-}\""
        echo "AUTH_MODE=\"${AUTH_MODE:-gh}\""
        # TOKEN intentionally not saved by default.
        # Use GitHub CLI, SSH, or Git Credential Manager instead.
    } > "$CONFIG_FILE"

    chmod 600 "$CONFIG_FILE"
}

show_security_notes() {
    cat <<'EOF'

Security recommendations:
  - Prefer GitHub CLI authentication:
      gh auth login

  - Or use SSH keys:
      ssh-keygen -t ed25519 -C "your.email@example.com"
      eval "$(ssh-agent -s)"
      ssh-add ~/.ssh/id_ed25519
      cat ~/.ssh/id_ed25519.pub

  - Or use Git Credential Manager:
      git credential-manager configure

  - If you must use a token, use a fine-grained GitHub token with only the minimum required repository permissions.

  - Never commit ~/.git_quick_config into any repository.
  - Never share screenshots or terminal logs containing tokens or credentials.

EOF
}

check_dependencies() {
    command -v git >/dev/null 2>&1 || {
        echo "ERROR: git is not installed."
        exit 1
    }

    if [ "${AUTH_MODE:-gh}" = "gh" ] && ! command -v gh >/dev/null 2>&1; then
        echo "ERROR: GitHub CLI is not installed, but AUTH_MODE=gh."
        echo "Install gh or run: $0 --config"
        exit 1
    fi
}

ensure_gh_auth() {
    if ! gh auth status >/dev/null 2>&1; then
        echo "GitHub CLI is not authenticated."
        echo "Starting: gh auth login"
        gh auth login
    fi
}

configure_credential_manager() {
    if command -v git-credential-manager >/dev/null 2>&1; then
        git credential-manager configure
    elif git credential-manager-core --version >/dev/null 2>&1; then
        git credential-manager-core configure
    else
        echo "WARNING: Git Credential Manager was not found."
        echo "Install it first or select another auth mode with: $0 --config"
    fi
}

build_remote_url() {
    case "${AUTH_MODE:-gh}" in
        gh)
            REMOTE_URL="https://github.com/$ORG/$REPO.git"
            ;;
        ssh)
            REMOTE_URL="git@github.com:$ORG/$REPO.git"
            ;;
        gcm)
            REMOTE_URL="https://github.com/$ORG/$REPO.git"
            ;;
        token)
            echo ""
            echo "Token mode selected."
            echo "Use a fine-grained GitHub token with minimum required permissions."
            read -r -s -p "GitHub fine-grained token: " TOKEN
            echo ""
            REMOTE_URL="https://$GH_USER:$TOKEN@github.com/$ORG/$REPO.git"
            ;;
        *)
            echo "ERROR: Unknown AUTH_MODE: $AUTH_MODE"
            exit 1
            ;;
    esac
}

configure_remote() {
    if git remote | grep -qx 'origin'; then
        git remote set-url origin "$REMOTE_URL"
    else
        git remote add origin "$REMOTE_URL"
    fi

    # Hide credentials from accidental terminal output where possible.
    if [ "${AUTH_MODE:-gh}" = "token" ]; then
        git remote set-url --push origin "https://github.com/$ORG/$REPO.git" || true
    fi
}

commit_changes() {
    git add .

    if git diff --cached --quiet; then
        echo "No hay cambios para commitear."
    else
        git commit -m "$MESSAGE"
    fi
}

push_changes() {
    echo "Subiendo cambios a $BRANCH..."
    git push -u origin HEAD
}

configure_interactively() {
    echo "Configuración:"
    read -r -p "USER_NAME (actual: ${USER_NAME:-}, ej. Esteban Armas): " NEW_USER_NAME
    read -r -p "USER_EMAIL (actual: ${USER_EMAIL:-}, ej. esarmas@ucm.es): " NEW_USER_EMAIL
    read -r -p "GH_USER (actual: ${GH_USER:-}, ej. esteban-armas): " NEW_GH_USER

    USER_NAME="${NEW_USER_NAME:-${USER_NAME:-}}"
    USER_EMAIL="${NEW_USER_EMAIL:-${USER_EMAIL:-}}"
    GH_USER="${NEW_GH_USER:-${GH_USER:-}}"

    echo ""
    echo "Selecciona modo de autenticación:"
    echo "  1) gh    - GitHub CLI, recomendado"
    echo "  2) ssh   - SSH keys"
    echo "  3) gcm   - Git Credential Manager"
    echo "  4) token - Fine-grained token, no se guarda en disco"
    read -r -p "AUTH_MODE [${AUTH_MODE:-gh}]: " NEW_AUTH_MODE

    AUTH_MODE="${NEW_AUTH_MODE:-${AUTH_MODE:-gh}}"

    save_config
    ensure_global_gitignore

    echo "Configuración actualizada con éxito."
    show_security_notes
}

usage() {
    cat <<EOF
Uso:
  $0              Ejecuta el flujo principal
  $0 --config    Actualiza configuración
  $0 --clear     Elimina configuración local
  $0 --security  Muestra recomendaciones de seguridad

Auth modes:
  gh      GitHub CLI authentication, recommended
  ssh     SSH keys
  gcm     Git Credential Manager
  token   Fine-grained GitHub token fallback, not saved
EOF
}

# Always protect config from accidental commits.
ensure_global_gitignore

case "${1:-}" in
    --config)
        load_config
        configure_interactively
        exit 0
        ;;
    --clear)
        rm -f "$CONFIG_FILE"
        ensure_global_gitignore
        echo "Configuración eliminada."
        exit 0
        ;;
    --security)
        show_security_notes
        exit 0
        ;;
    --help|-h)
        usage
        exit 0
        ;;
esac

load_config

if [ -z "${USER_NAME:-}" ] || [ -z "${USER_EMAIL:-}" ] || [ -z "${GH_USER:-}" ] || [ -z "${AUTH_MODE:-}" ]; then
    echo "Primera configuración detectada."
    configure_interactively
fi

check_dependencies

case "${AUTH_MODE:-gh}" in
    gh)
        ensure_gh_auth
        ;;
    gcm)
        configure_credential_manager
        ;;
    ssh)
        echo "Using SSH remote. Make sure your public SSH key is added to GitHub."
        ;;
    token)
        echo "Using token fallback. Token will be requested for this run and not saved."
        ;;
esac

read -r -p "Organización [work-code-hub]: " ORG
ORG="${ORG:-work-code-hub}"

read -r -p "Nombre del Repositorio: " REPO
if [ -z "$REPO" ]; then
    echo "ERROR: repository name cannot be empty."
    exit 1
fi

read -r -p "Nombre de la rama (ej. lenovo): " BRANCH
if [ -z "$BRANCH" ]; then
    echo "ERROR: branch name cannot be empty."
    exit 1
fi

read -r -p "Mensaje del commit: " MESSAGE
if [ -z "$MESSAGE" ]; then
    echo "ERROR: commit message cannot be empty."
    exit 1
fi

git init
git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"

build_remote_url
configure_remote

git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

commit_changes
push_changes

echo "Listo."
