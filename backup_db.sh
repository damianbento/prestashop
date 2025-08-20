#!/bin/bash
# Ruta donde guardar los backups
BACKUP_DIR="./db_backups"
# Nombre del archivo con fecha y hora
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/backup_prestashop_$DATE.sql"

# Crear carpeta si no existe
mkdir -p "$BACKUP_DIR"

# Ejecutar mysqldump con opción para evitar error de tablespaces
docker exec mysql sh -c 'exec mysqldump --no-tablespaces -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > "$BACKUP_FILE"

# Mostrar mensaje
echo "Backup creado: $BACKUP_FILE"

# Eliminar backups más antiguos (mantener solo los últimos 7)
BACKUPS_TO_DELETE=$(ls -1t "$BACKUP_DIR"/*.sql | tail -n +8)
if [ ! -z "$BACKUPS_TO_DELETE" ]; then
  echo "Eliminando backups antiguos:"
  echo "$BACKUPS_TO_DELETE"
  rm -f $BACKUPS_TO_DELETE
fi
