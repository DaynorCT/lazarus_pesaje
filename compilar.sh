#!/bin/bash
set -e

PROJECT_DIR="/Users/jaru/dev/lazarus-pesaje"
LAZARUS_DIR="/Applications/lazarus"
FPCUP_CONFIG="/Users/jaru/fpcupdeluxe/config_lazarus"

cd "$PROJECT_DIR"

echo "Compilando..."
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