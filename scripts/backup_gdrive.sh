#!/bin/bash
# ══════════════════════════════════════════════
#  backup_gdrive.sh - Script Principal de Respaldo Automatizado
#  Funciones: Compresion, subida a Google Drive, limpieza
#             automatica de respaldos antiguos y notificacion por email.
#  Automatizacion: Ejecutado por cron todos los dias a las 10:00 AM
# ══════════════════════════════════════════════

# Rutas absolutas para que cron encuentre todos los comandos del sistema
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# --- Configuracion General ---
BASE_DIR="$HOME/backup_gdrive"
SCRIPT_DIR="$BASE_DIR/scripts"
LOG_FILE="$BASE_DIR/logs/backup_$(date +%Y%m).log"
TEMP_DIR="$BASE_DIR/temp"
SOURCE_DIR="$HOME/datos"                 # Directorio local a respaldar
BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
GDRIVE_FOLDER="Respaldos_Linux"          # Carpeta destino en Google Drive
EMAIL_DESTINO="vicentegalvezcl@gmail.com" # Correo para notificaciones

# --- Funcion de registro (log) ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ══════════════════════════════════════════════
#  MEJORA OPCIONAL 1: Limpieza automatica de respaldos
#  Elimina archivos con mas de 7 dias en Google Drive
# ══════════════════════════════════════════════
cleanup_old_backups() {
  local ACCESS_TOKEN=$1
  local FOLDER_ID=$2
  local MAX_DAYS=7
  local CUTOFF=$(date -d "-${MAX_DAYS} days" '+%Y-%m-%dT%H:%M:%S')

  log "Iniciando limpieza de respaldos con mas de $MAX_DAYS dias en Google Drive..."

  OLD_FILES=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://www.googleapis.com/drive/v3/files?q=parents='$FOLDER_ID'+and+createdTime<'${CUTOFF}Z'&fields=files(id,name)")

  echo "$OLD_FILES" | jq -r '.files[] | .id' | while read FILE_ID; do
    if [ "$FILE_ID" != "null" ] && [ -n "$FILE_ID" ]; then
      curl -s -X DELETE \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        "https://www.googleapis.com/drive/v3/files/$FILE_ID"
      log "Eliminado respaldo antiguo de Drive con ID: $FILE_ID"
    fi
  done
}

# ══════════════════════════════════════════════
#  INICIO DEL PROCESO DE RESPALDO
# ══════════════════════════════════════════════
log "======= INICIO DE RESPALDO ======="

# --- Paso 1: Comprimir directorio fuente ---
log "Comprimiendo $SOURCE_DIR..."
tar -czf "$TEMP_DIR/$BACKUP_NAME" -C "$(dirname $SOURCE_DIR)" "$(basename $SOURCE_DIR)" 2>> "$LOG_FILE"

if [ $? -ne 0 ]; then
  log "ERROR: Fallo la compresion. Abortando."
  exit 1
fi
log "Archivo creado: $TEMP_DIR/$BACKUP_NAME"

# --- Paso 2: Obtener token de acceso actualizado ---
ACCESS_TOKEN=$(bash $SCRIPT_DIR/refresh_token.sh)
if [ -z "$ACCESS_TOKEN" ]; then
  log "ERROR: No se pudo obtener token de acceso."
  exit 1
fi

# --- Paso 3: Buscar o crear la carpeta en Google Drive ---
log "Buscando carpeta '$GDRIVE_FOLDER' en Google Drive..."
FOLDER_SEARCH=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://www.googleapis.com/drive/v3/files?q=name='$GDRIVE_FOLDER'+and+mimeType='application/vnd.google-apps.folder'+and+trashed=false&fields=files(id,name)")

FOLDER_ID=$(echo "$FOLDER_SEARCH" | jq -r '.files[0].id')

if [ "$FOLDER_ID" == "null" ] || [ -z "$FOLDER_ID" ]; then
  log "Carpeta no encontrada. Creando '$GDRIVE_FOLDER'..."
  FOLDER_RESP=$(curl -s -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"'$GDRIVE_FOLDER'","mimeType":"application/vnd.google-apps.folder"}' \
    https://www.googleapis.com/drive/v3/files)
  FOLDER_ID=$(echo "$FOLDER_RESP" | jq -r '.id')
  log "Carpeta creada con ID: $FOLDER_ID"
fi

# --- Paso 4: Subir el archivo comprimido a Google Drive ---
log "Subiendo $BACKUP_NAME a Google Drive..."
UPLOAD_RESP=$(curl -s -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -F "metadata={name:'$BACKUP_NAME',parents:['$FOLDER_ID']};type=application/json" \
  -F "file=@$TEMP_DIR/$BACKUP_NAME;type=application/gzip" \
  https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart)

FILE_ID=$(echo "$UPLOAD_RESP" | jq -r '.id')

if [ "$FILE_ID" != "null" ] && [ -n "$FILE_ID" ]; then
  log "Respaldo subido correctamente. ID Drive: $FILE_ID"
else
  log "ERROR al subir el archivo. Respuesta: $UPLOAD_RESP"
  exit 1
fi

# --- Paso 5: Limpieza automatica de respaldos antiguos (Mejora Extra) ---
cleanup_old_backups "$ACCESS_TOKEN" "$FOLDER_ID"

# --- Paso 6: Eliminar archivo temporal local ---
rm -f "$TEMP_DIR/$BACKUP_NAME"
log "Archivo temporal eliminado."
log "======= RESPALDO COMPLETADO ======="

# ══════════════════════════════════════════════
#  MEJORA OPCIONAL 2: Notificacion por Email
#  Envia alerta al administrador tras cada respaldo exitoso
# ══════════════════════════════════════════════
echo "Respaldo completado exitosamente en Google Drive: $BACKUP_NAME" | \
  /usr/bin/mail -s "Backup OK - $(date '+%Y-%m-%d')" "$EMAIL_DESTINO"

exit 0
