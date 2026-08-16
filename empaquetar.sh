#!/bin/bash
set -e

# ============================================================
# EMPAQUETAR SISTEMA DE PESAJE (Windows 64-bit)
# Uso: ./empaquetar.sh
# Genera en dist/:
#   Sistema_Pesaje_v<VERSION>.zip  -> portable
#   kit-instalador-windows/        -> kit para crear el instalador .exe
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"
VERSION="${VERSION:-1.0}"

cd "$PROJECT_DIR"

echo "========================================="
echo "  EMPAQUETAR SISTEMA DE PESAJE v$VERSION"
echo "========================================="
echo ""

# --- 1. Compilar ---
echo "[1/6] Compilando pesaje.exe para Windows 64-bit..."
./compilar.sh win64
echo ""

# --- 2. Descargar sqlite3.dll ---
echo "[2/6] Buscando sqlite3.dll..."
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
        echo "  WARNING: No se pudo descargar automaticamente."
        echo "  Bajalo manualmente de https://www.sqlite.org/download.html"
        echo "  (sqlite-dll-win-x64-*.zip) y pone sqlite3.dll en esta carpeta."
        echo "  Luego volve a correr este script."
        exit 1
    fi
fi
echo ""

# --- 3. Crear carpeta de distribucion portable ---
echo "[3/6] Preparando carpeta de distribucion portable..."
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
# NOTA: NO se copia pesaje.db. La base de datos se crea en
# %APPDATA%\SistemaPesaje para que los datos del usuario no se pierdan
# al actualizar el portable.
echo "  Archivos copiados a dist/Sistema_Pesaje_v${VERSION}/"
echo ""

# --- 4. Crear ZIP portable ---
echo "[4/6] Creando ZIP portable..."
ZIP_FILE="$PROJECT_DIR/dist/Sistema_Pesaje_v${VERSION}.zip"
rm -f "$ZIP_FILE"
cd "$PROJECT_DIR/dist"
zip -9 -r "Sistema_Pesaje_v${VERSION}.zip" "Sistema_Pesaje_v${VERSION}/"
cd "$PROJECT_DIR"
echo ""

# --- 5. Preparar kit para instalador Windows ---
echo "[5/6] Preparando kit para generar instalador .exe en Windows..."
KIT_DIR="$PROJECT_DIR/dist/kit-instalador-windows"
rm -rf "$KIT_DIR"
mkdir -p "$KIT_DIR"

# Archivos del instalador
cp pesaje.exe "$KIT_DIR/"
cp "$SQLITE_DLL" "$KIT_DIR/"
cp config.json "$KIT_DIR/"

# instalador.iss con la version inyectada (unica fuente: VERSION arriba)
sed "s/#define MyAppVersion \".*\"/#define MyAppVersion \"$VERSION\"/" \
    instalador.iss > "$KIT_DIR/instalador.iss"
cp generar_instalador_windows.bat "$KIT_DIR/"

# Carpeta assets necesaria para el instalador
mkdir -p "$KIT_DIR/assets"
cp assets/logo_pesaje.ico "$KIT_DIR/assets/"
cp assets/fa-solid-900.ttf "$KIT_DIR/assets/"

# README con instrucciones para Windows
cat > "$KIT_DIR/README_LEEME.txt" <<EOF
=====================================================================
  KIT PARA GENERAR EL INSTALADOR DE SISTEMA DE PESAJE (Windows)
  Version: $VERSION
=====================================================================

Este kit contiene todo lo necesario para crear el instalador
"Instalador_Sistema_Pesaje.exe" en una computadora con Windows.

Pasos:

1. Copia esta carpeta completa a una PC con Windows 7 SP1 o superior.

2. Instala Inno Setup 6 (gratuito) desde:
   https://jrsoftware.org/isinfo.php

   IMPORTANTE: durante la instalacion, asegurate de marcar la opcion
   "Install Inno Setup Preprocessor (ISPP)".

3. Abre esta carpeta en el Explorador de Windows.

4. Haz doble clic en:
      generar_instalador_windows.bat

   El script detecta automaticamente ISCC.exe y genera el instalador.

5. El archivo resultante estara en:
      dist\Instalador_Sistema_Pesaje.exe

Caracteristicas del instalador:
   - Compatible con Windows 7 SP1 / 8 / 10 / 11 (64-bit)
   - Instala en Archivos de Programa\SistemaPesaje
   - Crea accesos directos en escritorio y menu Inicio
   - Incluye desinstalador
   - Conserva config.json si el usuario ya lo configuro

Archivos incluidos en este kit:
   - pesaje.exe              (aplicacion)
   - sqlite3.dll             (libreria SQLite)
   - config.json             (configuracion inicial)
   - assets\logo_pesaje.ico  (icono del instalador)
   - assets\fa-solid-900.ttf (fuente de iconos)
   - instalador.iss          (script de Inno Setup)
   - generar_instalador_windows.bat

NOTA: la base de datos (pesaje.db) NO se incluye en el instalador.
El programa la crea automaticamente en %APPDATA%\SistemaPesaje la primera
vez que se ejecuta, para que los datos del usuario se conserven entre
instalaciones.

=====================================================================
EOF

echo "  Archivos copiados a dist/kit-instalador-windows/"
echo ""

# --- 6. Verificar kit ---
echo "[6/6] Verificando kit y portable..."
echo ""
echo "  Contenido del kit:"
FAILED=0
for f in "pesaje.exe" "sqlite3.dll" "config.json" "instalador.iss" \
         "generar_instalador_windows.bat" "assets/logo_pesaje.ico" \
         "assets/fa-solid-900.ttf" "README_LEEME.txt"; do
    if [ -f "$KIT_DIR/$f" ]; then
        SIZE=$(stat -f "%z" "$KIT_DIR/$f")
        printf "    [OK] %-28s %s bytes\n" "$f" "$SIZE"
    else
        echo "    [FALTA] $f"
        FAILED=1
    fi
done

echo ""
echo "  Contenido del portable:"
for f in "pesaje.exe" "sqlite3.dll" "config.json" "fa-solid-900.ttf"; do
    if [ -f "$DIST_DIR/$f" ]; then
        SIZE=$(stat -f "%z" "$DIST_DIR/$f")
        printf "    [OK] %-28s %s bytes\n" "$f" "$SIZE"
    else
        echo "    [FALTA] $f"
        FAILED=1
    fi
done

# Version inyectada en el instalador.iss del kit
ISS_VERSION=$(grep -o '#define MyAppVersion "[^"]*"' "$KIT_DIR/instalador.iss" | head -1)
echo ""
echo "  Version en instalador.iss: $ISS_VERSION"

# Detectar fuentes mas nuevas que el binario (evita kits viejos)
echo ""
echo "  Chequeo de frescura del binario:"
NEWEST_SRC=$(stat -f "%m" pesaje.lpi)
for f in pesaje.lpr $(find src -name '*.pas'); do
    MT=$(stat -f "%m" "$f")
    [ "$MT" -gt "$NEWEST_SRC" ] && NEWEST_SRC=$MT
done
EXE_MT=$(stat -f "%m" pesaje.exe)
if [ "$NEWEST_SRC" -gt "$EXE_MT" ]; then
    echo "    [OBSOLETO] pesaje.exe es mas viejo que las fuentes (recompilar)"
    STALE=1
else
    echo "    [OK] pesaje.exe esta al dia respecto a las fuentes"
fi

echo ""
if [ "$FAILED" = "1" ]; then
    echo "  ERROR: Faltan archivos en el kit/portable. Revisa arriba."
    exit 1
fi

# --- Resumen final ---
echo "========================================="
echo "  LISTO"
echo "========================================="
echo ""
echo "  Entregables generados:"
echo ""
echo "  1) ZIP portable (sin instalador):"
ls -lh "$ZIP_FILE"
echo "     Uso: descomprimir en Windows y ejecutar pesaje.exe"
echo ""
echo "  2) Kit para crear instalador .exe:"
echo "     Carpeta: dist/kit-instalador-windows/"
echo "     Uso: llevar a una PC Windows, instalar Inno Setup y ejecutar"
echo "          generar_instalador_windows.bat"
echo ""