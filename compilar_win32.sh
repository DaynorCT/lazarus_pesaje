#!/bin/bash
set -e

PROJECT_DIR="/Users/jaru/dev/lazarus-pesaje"
LAZARUS_DIR="/Applications/lazarus"
FPCUP_CONFIG="/Users/jaru/fpcupdeluxe/config_lazarus"

cd "$PROJECT_DIR"

# Detectar si el cross-compiler Win32 esta instalado
PPCROSS="/Users/jaru/fpcupdeluxe/fpc/bin/aarch64-darwin/ppcross386"
if [ ! -f "$PPCROSS" ]; then
  echo "ERROR: Cross-compiler i386-win32 no encontrado."
  echo ""
  echo "Abre fpcupdeluxe y haz clic en:"
  echo "  Cross > OS: Windows > CPU: i386 > Install"
  echo ""
  echo "O usa la GUI:"
  echo "  Setup+ tab > selecciona 'i386-win32' > Install cross compiler"
  exit 1
fi

echo "Compilando para Windows 32-bit..."
"$LAZARUS_DIR/lazbuild" \
    --pcp="$FPCUP_CONFIG" \
    --lazarusdir="$LAZARUS_DIR" \
    --os=win32 \
    --cpu=i386 \
    --ws=win32 \
    pesaje.lpi

if [ -f "pesaje.exe" ]; then
    echo "COMPILACION EXITOSA"
    ls -lh pesaje.exe
    echo ""
    echo "Para crear el instalador en Windows:"
    echo "  1. Copia pesaje.exe, sqlite3.dll, config.json, assets/ y instalador.iss a Windows"
    echo "  2. Instala Inno Setup (https://jrsoftware.org/isinfo.php)"
    echo "  3. Abre instalador.iss y presiona Compilar (Ctrl+F9)"
    echo "  El instalador se generara en la carpeta dist/"
    echo ""
    echo "NOTA: sqlite3.dll se descarga de https://www.sqlite.org/download.html"
    echo "      (Precompiled Binaries for Windows > sqlite-dll-win-x86-*.zip)"
else
    echo "ERROR: La compilacion no genero pesaje.exe"
    exit 1
fi
