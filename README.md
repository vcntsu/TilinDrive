# 🖥️ Sistema de Respaldo Automatizado en la Nube (Google Drive API v3)

**Asignatura:** Sistemas Operativos - Redes Avanzadas I  
**Plataforma:** Ubuntu Server 22.04 LTS  
**Autor:** Vicente Gálvez  

---

## 📋 Descripción del Proyecto

Sistema automatizado desarrollado en **Bash** para Ubuntu Server. Su objetivo es comprimir directorios locales y subirlos de forma segura a **Google Drive** usando la API oficial v3 mediante autenticación **OAuth2**. Incluye limpieza automática de respaldos antiguos, automatización con `cron` y notificaciones por correo.

---

## 📁 Estructura del Proyecto

```text
backup_gdrive/
├── config/                      # Credenciales y tokens (EXCLUIDOS de Git)
│   ├── credentials.json         # Credenciales de Google Cloud Platform
│   └── token.json               # Token OAuth2 generado (access + refresh)
├── logs/                        # Bitácoras del sistema (EXCLUIDAS de Git)
│   ├── backup_YYYYMM.log        # Historial detallado de respaldos
│   └── cron.log                 # Salidas del demonio Cron
├── scripts/                     # Scripts modulares en Bash
│   ├── auth_gdrive.sh           # Autenticación inicial OAuth2
│   ├── refresh_token.sh         # Renovación automática del Access Token
│   └── backup_gdrive.sh         # Script principal (respaldo + limpieza + email)
└── temp/                        # Almacenamiento temporal de archivos .tar.gz
```

---

## 🏗️ Arquitectura del Sistema

| Componente | Descripción |
|---|---|
| `auth_gdrive.sh` | Flujo OAuth2 inicial. Se ejecuta **una sola vez** para vincular la cuenta de Google y generar el `token.json`. |
| `refresh_token.sh` | Renueva el `access_token` de forma automática y transparente usando el `refresh_token` de larga duración. |
| `backup_gdrive.sh` | Corazón del sistema. Comprime, autentica, sube a Drive, limpia y envía alerta por email. |
| `cron` | Demonio del sistema que ejecuta el script principal todos los días a las **10:00 AM** de forma autónoma. |

---

## 🛠️ Requisitos e Instalación

### 1. Instalar dependencias
```bash
sudo apt update && sudo apt install -y curl jq tar gzip mailutils postfix
```

### 2. Crear la estructura de directorios
```bash
mkdir -p ~/backup_gdrive/{scripts,logs,config,temp}
```

### 3. Clonar este repositorio
```bash
git clone https://github.com/TU_USUARIO/backup-linux-gdrive.git ~/backup_gdrive
```

### 4. Asignar permisos de ejecución
```bash
chmod +x ~/backup_gdrive/scripts/*.sh
```

### 5. Copiar las credenciales de Google Cloud (NO están en el repo por seguridad)
```bash
# Transferir desde tu PC local al servidor
scp ~/Downloads/client_secret_*.json usuario@IP_SERVIDOR:~/backup_gdrive/config/credentials.json
chmod 600 ~/backup_gdrive/config/credentials.json
```

### 6. Ejecutar la autenticación inicial (solo una vez)
```bash
~/backup_gdrive/scripts/auth_gdrive.sh
```

---

## 🤖 Automatización con Cron

El sistema se ejecuta de forma **100% autónoma** todos los días a las 10:00 AM. Configuración del `crontab -e`:

```text
0 10 * * * /bin/bash /home/vice/backup_gdrive/scripts/backup_gdrive.sh >> /home/vice/backup_gdrive/logs/cron.log 2>&1
```

---

## ✨ Mejoras Implementadas (Puntos Extra)

### 1. Limpieza Automática de Respaldos Antiguos
Función `cleanup_old_backups` integrada en el script principal. Elimina automáticamente los archivos con más de **7 días de antigüedad** en Google Drive para optimizar el almacenamiento en la nube.

### 2. Notificaciones por Email
Implementación de `mailutils` y `Postfix` para enviar correos de alerta al administrador del sistema tras cada ejecución exitosa del respaldo.

```bash
echo "Respaldo completado: $BACKUP_NAME" | mail -s "Backup OK - $(date '+%Y-%m-%d')" admin@email.com
```

---

## 🔒 Seguridad

Las credenciales privadas de Google Cloud (`credentials.json` y `token.json`) están explícitamente protegidas en el archivo `.gitignore`. **Nunca se suben al repositorio público.**

---

## 📸 Evidencias de Implementación

### Estructura de directorios y permisos de scripts
*(Captura: `ls -la ~/backup_gdrive/scripts/`)*

### Crontab configurado a las 10:00 AM
*(Captura: `crontab -l`)*

### Log de respaldo exitoso
*(Captura: `cat ~/backup_gdrive/logs/backup_YYYYMM.log`)*

### Archivo respaldado en Google Drive
*(Captura: Carpeta `Respaldos_Linux` en drive.google.com)*
