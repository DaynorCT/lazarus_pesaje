#!/bin/bash
set -e

# ============================================================
# Compilar Sistema de Pesaje
# Uso: ./compilar.sh [mac|win64]
#   mac   -> ejecutable macOS (por defecto)
#   win64 -> cross-compile Windows 64-bit
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"
LAZARUS_DIR="${LAZARUS_DIR:-/Applications/lazarus}"
FPCUP_CONFIG="${FPCUP_CONFIG:-/Users/jaru/fpcupdeluxe/config_lazarus}"
PPCROSS_DIR="${PPCROSS_DIR:-/Users/jaru/fpcupdeluxe/fpc/bin/aarch64-darwin}"

cd "$PROJECT_DIR"

TARGET="${1:-mac}"

case "$TARGET" in
  mac)
    echo "Compilando para macOS..."
    "$LAZARUS_DIR/lazbuild" \
        --pcp="$FPCUP_CONFIG" \
        --lazarusdir="$LAZARUS_DIR" \
        pesaje.lpi

    if [ -f "pesaje" ]; then
        echo "COMPILACION EXITOSA"
        ls -lh pesaje
    else
        echo "ERROR: La compilacion no genero el ejecutable"
        exit 1
    fi
    ;;

  win64)
    PPCROSS="$PPCROSS_DIR/ppcx64"
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
        echo "  ./empaquetar.sh"
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
    ;;

  *)
    echo "Uso: ./compilar.sh [mac|win64]"
    exit 1
    ;;
esac