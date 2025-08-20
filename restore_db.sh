#!/bin/bash

BACKUP_DIR="./db_backups"
DB_NAME="prestashop"
DB_USER="ps_user"
DB_PASS="ps_pass"
ROOT_PASS="supersegura123"
CONTAINER_NAME="mysql"

# Verificar si hay archivos de backup
BACKUPS=($(ls -1t ${BACKUP_DIR}/*.sql 2>/dev/null))

if [ ${#BACKUPS[@]} -eq 0 ]; then
  echo "❌ No hay backups disponibles en $BACKUP_DIR"
  exit 1
fi

# Mostrar lista y seleccionar uno
echo "📂 Backups disponibles:"
select BACKUP in "${BACKUPS[@]}"; do
  if [[ -n "$BACKUP" ]]; then
    echo "✅ Seleccionaste: $BACKUP"

    # Backup previo antes de restaurar
    DATE=$(date +"%Y-%m-%d_%H-%M-%S")
    PRE_BACKUP_FILE="$BACKUP_DIR/pre_restore_$DATE.sql"
    echo "🛟 Creando backup de seguridad antes de restaurar..."
    docker exec $CONTAINER_NAME sh -c 'exec mysqldump --no-tablespaces -u'"$DB_USER"' -p'"$DB_PASS"' '"$DB_NAME"'' > "$PRE_BACKUP_FILE"
    echo "✅ Backup previo guardado como $PRE_BACKUP_FILE"

    # Preguntar si desea limpiar la base antes
    read -p "¿Querés borrar y recrear la base de datos '$DB_NAME' antes de restaurar? (s/n): " OPCION
    if [[ "$OPCION" == "s" || "$OPCION" == "S" ]]; then
      echo "🧨 Borrando y recreando la base de datos '$DB_NAME'..."
      docker exec -i $CONTAINER_NAME mysql -uroot -p$ROOT_PASS -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"
      if [ $? -ne 0 ]; then
        echo "❌ Error al recrear la base. Abortando."
        exit 1
      fi
    fi

    echo "⏳ Restaurando backup: $BACKUP"
    cat "$BACKUP" | docker exec -i $CONTAINER_NAME mysql -u$DB_USER -p$DB_PASS $DB_NAME

    echo "✅ Restauración finalizada."
    echo "🔁 Podés revertir a: $PRE_BACKUP_FILE si algo sale mal."
    break
  else
    echo "⚠️ Opción inválida, intentá de nuevo."
  fi
done
