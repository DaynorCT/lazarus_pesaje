#!/bin/bash
DB="${1:-$(dirname "$0")/pesaje.db}"

if [ ! -f "$DB" ]; then
  echo "No se encuentra la base de datos: $DB"
  exit 1
fi

sqlite3 "$DB" "
DELETE FROM usuarios WHERE id != 1;
DELETE FROM personas WHERE id != 1;
DELETE FROM empresas;
DELETE FROM choferes;
DELETE FROM proveedores;
DELETE FROM vehiculos;
DELETE FROM vehiculo_chofer;
DELETE FROM bodegas;
DELETE FROM productos;
DELETE FROM origenes;
DELETE FROM destinos;
DELETE FROM pesajes;
DELETE FROM boleta_config WHERE id != 1;
VACUUM;
"

echo "Base de datos reseteada. Solo queda admin@sistema.com"
