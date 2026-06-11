#!/bin/bash
# ══════════════════════════════════════════════
#  refresh_token.sh - Renovacion automatica del Access Token
#  Uso: Llamado internamente por backup_gdrive.sh
#  Retorna: El nuevo access_token como texto plano (stdout)
# ══════════════════════════════════════════════

CONFIG_DIR="$HOME/backup_gdrive/config"
CREDS="$CONFIG_DIR/credentials.json"
TOKEN_FILE="$CONFIG_DIR/token.json"

# Leer datos necesarios para la renovacion
CLIENT_ID=$(jq -r '.installed.client_id' "$CREDS")
CLIENT_SECRET=$(jq -r '.installed.client_secret' "$CREDS")
REFRESH_TOKEN=$(jq -r '.refresh_token' "$TOKEN_FILE")

# Solicitar nuevo access_token usando el refresh_token guardado
RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "refresh_token=${REFRESH_TOKEN}" \
  -d "grant_type=refresh_token")

# Actualizar el archivo token.json con el nuevo access_token
NEW_ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
UPDATED_TOKEN=$(jq --arg token "$NEW_ACCESS_TOKEN" '.access_token = $token' "$TOKEN_FILE")
echo "$UPDATED_TOKEN" > "$TOKEN_FILE"

# Devolver solo el access_token para que el script principal lo capture
echo "$NEW_ACCESS_TOKEN"
