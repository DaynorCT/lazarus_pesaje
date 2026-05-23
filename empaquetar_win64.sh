#!/bin/bash
set -e

PROJECT_DIR="/Users/jaru/dev/lazarus-pesaje"
VERSION="1.0"

cd "$PROJECT_DIR"

echo "========================================="
echo "  EMPAQUETAR SISTEMA DE PESAJE v$VERSION"
echo "========================================="
echo ""

# --- 1. Compilar ---
echo "[1/4] Compilando pesaje.exe para Windows 64-bit..."
./compilar_win32.sh
echo ""

# --- 2. Descargar sqlite3.dll ---
echo "[2/4] Buscando sqlite3.dll..."
SQLITE_DLL="sqlite3.dll"

if [ -f "$SQLITE_DLL" ]; then
    echo "  sqlite3.dll ya existe, usando el actual."
else
    echo "  Descargando sqlite3.dll 64-bit de sqlite.org..."
    SQLITE_RELPATH=$(curl -sL https://www.sqlite.org/download.html 2>/dev/null \
        | grep -o '20[0-9]*\/sqlite-dll-win-x64-[0-9]*\.zip' \
        | head -1)

    if [ -n "$SQLITE_RELPATH" ]; then
        SQLITE_URL="https://www.sqlite.org/$SQLITE_RELPATH"
        echo "  URL: $SQLITE_URL"
        curl -sL -o sqlite_x64.zip "$SQLITE_URL"
        unzip -o sqlite_x64.zip sqlite3.dll
        rm -f sqlite_x64.zip sqlite3.def
        echo "  sqlite3.dll descargado OK"
    else
        echo "  WARNING: No se pudo descargar automáticamente."
        echo "  Bajalo manualmente de https://www.sqlite.org/download.html"
        echo "  (sqlite-dll-win-x64-*.zip) y poné sqlite3.dll en esta carpeta."
        echo "  Luego volvé a correr este script."
        exit 1
    fi
fi
echo ""

# --- 3. Crear carpeta de distribución ---
echo "[3/4] Preparando carpeta de distribución..."
DIST_DIR="$PROJECT_DIR/dist/Sistema_Pesaje_v${VERSION}"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
cp pesaje.exe "$DIST_DIR/"
cp "$SQLITE_DLL" "$DIST_DIR/"
if [ -f config.json ]; then
    cp config.json "$DIST_DIR/"
fi
if [ -f assets/fa-solid-900.ttf ]; then
    cp assets/fa-solid-900.ttf "$DIST_DIR/"
fi
echo "  Archivos copiados a dist/Sistema_Pesaje_v${VERSION}/"
echo ""

# --- 4. Crear ZIP ---
echo "[4/4] Creando ZIP..."
ZIP_FILE="$PROJECT_DIR/dist/Sistema_Pesaje_v${VERSION}.zip"
rm -f "$ZIP_FILE"
cd "$PROJECT_DIR/dist"
zip -9 -r "Sistema_Pesaje_v${VERSION}.zip" "Sistema_Pesaje_v${VERSION}/"
cd "$PROJECT_DIR"
echo ""

echo "========================================="
echo "  LISTO"
echo "========================================="
echo ""
echo "  Entregable: dist/Sistema_Pesaje_v${VERSION}.zip"
ls -lh "$ZIP_FILE"
echo ""
echo "  Contenido:"
echo "    - pesaje.exe"
echo "    - sqlite3.dll"
echo "    - config.json"
echo ""
echo "  El cliente descomprime el ZIP en cualquier carpeta"
echo "  de Windows y hace doble clic en pesaje.exe."
echo ""
