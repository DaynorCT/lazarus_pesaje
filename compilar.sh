#!/bin/bash
# Compilar proyecto Capturador de Peso para macOS

set -e

echo "============================================"
echo "  Compilando Capturador de Peso"
echo "============================================"

PROJECT_DIR="/Users/jaru/dev/lazarus-pesaje"
LAZARUS_DIR="/Applications/lazarus"
FPC="/usr/local/bin/fpc"

# Verificar que Lazarus existe
if [ ! -d "$LAZARUS_DIR" ]; then
    echo "ERROR: Lazarus no encontrado en $LAZARUS_DIR"
    echo "Por favor instala Lazarus primero"
    exit 1
fi

# Verificar que FPC existe
if [ ! -f "$FPC" ]; then
    echo "ERROR: Compilador FPC no encontrado"
    exit 1
fi

cd "$PROJECT_DIR"

echo "Compilando..."
"$LAZARUS_DIR/lazbuild" \
    --pcp="$LAZARUS_DIR/config" \
    --lazarusdir="$LAZARUS_DIR" \
    project1.lpi

if [ -f "project1" ]; then
    echo "============================================"
    echo "  COMPILACION EXITOSA"
    echo "============================================"
    ls -lh project1
else
    echo "ERROR: La compilacion no genero el ejecutable"
    exit 1
fi