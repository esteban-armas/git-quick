#!/bin/bash

# Archivo donde se guarda la configuración
CONFIG_FILE="$HOME/.git_quick_config"

# Función para cargar configuración
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# Función para guardar configuración
save_config() {
    echo "USER_NAME=\"$USER_NAME\"" > "$CONFIG_FILE"
    echo "USER_EMAIL=\"$USER_EMAIL\"" >> "$CONFIG_FILE"
    echo "GH_USER=\"$GH_USER\"" >> "$CONFIG_FILE"
    echo "TOKEN=\"$TOKEN\"" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
}

# --- Lógica de Comandos Especiales ---
if [[ "$1" == "--config" ]]; then
    read -p "Nuevo USER_NAME (actual: $USER_NAME): " USER_NAME
    read -p "Nuevo USER_EMAIL (actual: $USER_EMAIL): " USER_EMAIL
    read -p "Nuevo GH_USER (actual: $GH_USER): " GH_USER
    read -s -p "Nuevo GitHub Token: " TOKEN
    echo ""
    save_config
    echo "Configuración actualizada con éxito."
    exit 0
fi

if [[ "$1" == "--clear" ]]; then
    rm -f "$CONFIG_FILE"
    echo "Configuración y Token eliminados."
    exit 0
fi

# --- Flujo Principal ---
load_config

# Si no hay config, pedir datos iniciales
if [ -z "$TOKEN" ]; then
    echo "Primera configuración detectada:"
    read -p "USER_NAME (ej. Esteban Armas): " USER_NAME
    read -p "USER_EMAIL (ej. esarmas@ucm.es): " USER_EMAIL
    read -p "GH_USER (ej. esteban-armas): " GH_USER
    read -s -p "GitHub Token: " TOKEN
    echo ""
    save_config
fi

# Preguntar datos del repositorio actual
read -p "Organización [work-code-hub]: " ORG
ORG=${ORG:-work-code-hub}
read -p "Nombre del Repositorio: " REPO
read -p "Nombre de la rama (ej. lenovo): " BRANCH
read -p "Mensaje del commit: " MESSAGE

# 1. Inicializar Git y configurar identidad local
git init
git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"

# 2. Configurar el remoto
REMOTE_URL="https://$GH_USER:$TOKEN@://github.com"
if git remote | grep -q 'origin'; then
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi

# 3. Crear rama y commit
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
git add .
git commit -m "$MESSAGE"

# 4. Push
echo "Subiendo cambios a $BRANCH..."
git push -u origin HEAD

