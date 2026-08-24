#!/bin/bash

# ============================================================
# Resetear la base de datos del Sistema de Pesaje
# Detecta la ruta real igual que la app (DataModule.GetDataDirectory):
#   Windows: %APPDATA%\SistemaPesaje\pesaje.db
#   macOS:   ~/Library/Application Support/SistemaPesaje/pesaje.db
#   Linux:   ~/.local/share/SistemaPesaje/pesaje.db
# Uso: ./reset_bd.sh [ruta_opcional]
# Elimina todos los datos excepto el usuario admin.
# ============================================================

DB="${1:-}"

if [ -z "$DB" ]; then
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      DB="$(cygpath -u "${APPDATA:-$USERPROFILE}\\SistemaPesaje\\pesaje.db")"
      ;;
    Darwin)
      DB="$HOME/Library/Application Support/SistemaPesaje/pesaje.db"
      ;;
    *)
      DB="$HOME/.local/share/SistemaPesaje/pesaje.db"
      ;;
  esac
fi

if [ ! -f "$DB" ]; then
  echo "No se encuentra la base de datos: $DB"
  echo "Ejecuta primero el programa una vez para que la cree."
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

echo "Base de datos reseteada: $DB"
echo "Solo queda admin@sistema.com"
