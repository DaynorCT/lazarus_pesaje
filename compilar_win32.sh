#!/bin/bash
set -e

PROJECT_DIR="/Users/jaru/dev/lazarus-pesaje"
LAZARUS_DIR="/Applications/lazarus"
FPCUP_CONFIG="/Users/jaru/fpcupdeluxe/config_lazarus"

cd "$PROJECT_DIR"

PPCROSS="/Users/jaru/fpcupdeluxe/fpc/bin/aarch64-darwin/ppcx64"
if [ ! -f "$PPCROSS" ]; then
  echo "ERROR: Cross-compiler x86_64-win64 no encontrado."
  echo ""
  echo "Abre fpcupdeluxe y haz clic en:"
  echo "  Cross > OS: Windows > CPU: x86_64 > Install"
  echo ""
  echo "O usa la GUI:"
  echo "  Setup+ tab > selecciona 'x86_64-win64' > Install cross compiler"
  exit 1
fi

echo "Compilando para Windows 64-bit..."
"$LAZARUS_DIR/lazbuild" \
    --pcp="$FPCUP_CONFIG" \
    --lazarusdir="$LAZARUS_DIR" \
    --os=win64 \
    --cpu=x86_64 \
    --ws=win32 \
    pesaje.lpi

if [ -f "pesaje.exe" ]; then
    echo "COMPILACION EXITOSA"
    ls -lh pesaje.exe
    echo ""
    echo "Para empaquetar (ZIP portable + kit del instalador .exe):"
    echo "  ./empaquetar_win64.sh"
    echo ""
    echo "Eso genera:"
    echo "  dist/Sistema_Pesaje_v1.0.zip          -> version portable"
    echo "  dist/kit-instalador-windows/          -> llevar a Windows para compilar el .exe"
    echo ""
    echo "NOTA: sqlite3.dll de 64 bits se descarga de https://www.sqlite.org/download.html"
    echo "      (Precompiled Binaries for Windows > sqlite-dll-win-x64-*.zip)"
else
    echo "ERROR: La compilacion no genero pesaje.exe"
    exit 1
fi
