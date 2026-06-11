#!/bin/bash
# ══════════════════════════════════════════════
#  auth_gdrive.sh - Autenticación inicial OAuth2 con Google Drive
#  Uso: Ejecutar UNA sola vez para generar el token.json
# ══════════════════════════════════════════════

CONFIG_DIR="$HOME/backup_gdrive/config"
CREDS="$CONFIG_DIR/credentials.json"
TOKEN_FILE="$CONFIG_DIR/token.json"

# Leer client_id y client_secret desde el archivo de credenciales
CLIENT_ID=$(jq -r '.installed.client_id' "$CREDS")
CLIENT_SECRET=$(jq -r '.installed.client_secret' "$CREDS")

# Permiso solicitado: solo archivos creados por esta app
SCOPE="https://www.googleapis.com/auth/drive.file"

# URI de redireccion local (metodo moderno aceptado por Google)
REDIRECT_URI="http://localhost"

# Construir la URL de autorizacion
AUTH_URL="https://accounts.google.com/o/oauth2/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SCOPE}&response_type=code&access_type=offline"

echo "=== AUTENTICACION GOOGLE DRIVE ==="
echo ""
echo "1. Abra la siguiente URL en su navegador (modo incognito recomendado):"
echo ""
echo "$AUTH_URL"
echo ""
echo "2. Inicie sesion con su cuenta Gmail, acepte los permisos."
echo "3. Al aparecer 'localhost rechazo la conexion', copie el codigo de la barra de URL."
echo "   (Es el texto entre 'code=' y '&scope')"
echo ""
read -p "Pegue el codigo de autorizacion aqui: " AUTH_CODE

# Intercambiar el codigo por tokens de acceso y refresco
RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d "code=${AUTH_CODE}" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "redirect_uri=${REDIRECT_URI}" \
  -d "grant_type=authorization_code")

# Guardar el token con permisos seguros
echo "$RESPONSE" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

echo ""
echo "[OK] Token guardado correctamente en $TOKEN_FILE"
