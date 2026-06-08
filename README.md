# Sistema de Respaldo Automático a Google Drive con Bash 🚀

## 📋 Descripción del Proyecto
Este proyecto consiste en un sistema automatizado desarrollado en Bash para sistemas Linux (Ubuntu Server 22.04 LTS). Su objetivo es comprimir directorios locales y subirlos de forma segura a Google Drive utilizando la API oficial de Google mediante flujos de autenticación OAuth2[cite: 2].

## 🏗️ Arquitectura del Sistema
El sistema se organiza bajo los siguientes componentes estructurales[cite: 2]:
* **`scripts/auth_gdrive.sh`**: Script encargado del flujo de autenticación inicial OAuth2[cite: 2].
* **`scripts/refresh_token.sh`**: Lógica automatizada encargada de renovar el `access_token` de corta duración utilizando el `refresh_token` de forma transparente[cite: 2].
* **`scripts/backup_gdrive.sh`**: Corazón del sistema. Ejecuta la compresión `tar.gz`, valida el token, busca/crea el directorio remoto y sube el respaldo[cite: 2].
* **`cron`**: Demonio del sistema encargado de despertar el script principal diariamente a las 10:00 AM[cite: 2].

## 🛡️ Mejoras Implementadas (Extras)
1. **Limpieza Automática (Mantenimiento de Espacio)**: Función integrada `cleanup_old_backups` que elimina los respaldos con más de 7 días de antigüedad en la nube para optimizar el almacenamiento[cite: 2].
2. **Notificaciones por Email**: Implementación del paquete `mailutils` para despachar correos informativos al administrador del sistema tras cada ejecución exitosa[cite: 2].