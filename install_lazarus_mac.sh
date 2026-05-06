#!/bin/bash

# ============================================================
# Script de Instalación de Lazarus IDE en macOS
# Para Apple Silicon (M1/M2/M3) y Intel Mac
# ============================================================

set -e

echo "==============================================="
echo "  Instalador de Lazarus IDE para macOS"
echo "==============================================="

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar errores
error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# Función para mostrar éxito
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Función para mostrar advertencia
warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Detectar arquitectura
detect_arch() {
    if [ "$(uname -m)" = "arm64" ]; then
        echo "apple_silicon"
    else
        echo "intel"
    fi
}

# Detectar versión de macOS
detect_macOS() {
    sw_vers -prodVersion | cut -d. -f1
}

# ============================================================
# PRERREQUISITOS
# ============================================================

echo ""
echo "=== Verificando prerrequisitos ==="

# Verificar macOS
MACOS_VERSION=$(detect_macOS)
if [ "$MACOS_VERSION" -lt 11 ]; then
    error "macOS mínimo requerido: 11 (Big Sur)"
fi
success "macOS versión: $(sw_vers -prodVersion)"

# Verificar Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    echo ""
    warn "Xcode Command Line Tools no detectado"
    echo "Instalando..."
    xcode-select --install
    echo "Presiona Enter cuando hayas instalado Xcode Command Line Tools"
    read -p "Presiona Enter para continuar..."
else
    success "Xcode Command Line Tools instalado"
fi

# ============================================================
# INSTALAR HOMEBREW (si no existe)
# ============================================================

echo ""
echo "=== Verificando Homebrew ==="

if command -v brew &>/dev/null; then
    success "Homebrew ya instalado: $(brew --version | head -n1)"
else
    echo ""
    warn "Homebrew no detectado"
    echo "Instalando Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew instalado"
fi

# Actualizar Homebrew
echo ""
echo "=== Actualizando Homebrew ==="
brew update

# ============================================================
# INSTALAR FREE PASCAL (FPC)
# ============================================================

echo ""
echo "=== Instalando Free Pascal Compiler (FPC) ==="

if command -v fpc &>/dev/null; then
    warn "FPC ya instalado: $(fpc -v | head -n1)"
else
    echo "Instalando FPC via Homebrew..."
    brew install fpc
fi

# Verificar FPC
FPC_VERSION=$(fpc -v 2>&1 | head -n1)
success "FPC instalado: $FPC_VERSION"

# ============================================================
# INSTALAR FPC SOURCES
# ============================================================

echo ""
echo "=== Instalando Fuentes de FPC ==="

FPC_VERSION_NUM=$(fpc -v 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
FPCSOURCE_DIR="/usr/local/share/fpcsrc/$FPC_VERSION_NUM"

if [ -d "$FPCSOURCE_DIR" ]; then
    warn "Fuentes de FPC ya instaladas en: $FPCSOURCE_DIR"
else
    echo "Descargando fuentes de FPC..."
    FPCCONTRIB_URL="https://downloads.sourceforge.net/project/freepascal/fpcsrc/$FPC_VERSION_NUM/fpcsrc-$FPC_VERSION_NUM.tar.gz"
    
    cd /tmp
    curl -L -o fpcsrc.tar.gz "$FPCCONTRIB_URL" || error "Error descargando fuentes"
    
    echo "Extrayendo fuentes..."
    mkdir -p /usr/local/share/fpcsrc
    tar -xzf fpcsrc.tar.gz -C /usr/local/share/fpcsrc
    
    # Renombrar directorio si es necesario
    if [ -d "/usr/local/share/fpcsrc/fpcsrc-$FPC_VERSION_NUM" ]; then
        mv "/usr/local/share/fpcsrc/fpcsrc-$FPC_VERSION_NUM" "$FPCSOURCE_DIR"
    fi
    
    success "Fuentes instaladas en: $FPCSOURCE_DIR"
fi

# ============================================================
# INSTALAR LAZARUS
# ============================================================

echo ""
echo "=== Instalando Lazarus IDE ==="

APP_DIR="/Applications/Lazarus.app"

if [ -d "$APP_DIR" ]; then
    warn "Lazarus ya instalado en $APP_DIR"
else
    echo ""
    echo "Descargando Lazarus..."
    
    # Detectar la última versión estable
    LAZARUS_VERSION="2.2.6"
    ARCH=$(detect_arch)
    
    if [ "$ARCH" = "apple_silicon" ]; then
        LAZARUS_URL="https://downloads.sourceforge.net/project/lazarus/Lazarus%20macOS%20aarch64/Lazarus%20$LAZARUS_VERSION/Lazarus-$LAZARUS_VERSION-$ARCH-macosx.dmg"
    else
        LAZARUS_URL="https://downloads.sourceforge.net/project/lazarus/Lazarus%20macOS%20x86-64/Lazarus%20$LAZARUS_VERSION/Lazarus-$LAZARUS_VERSION-x86_64-macosx.dmg"
    fi
    
    cd /tmp
    
    # Intentar descargar
    if curl -L -o lazarus.dmg "$LAZARUS_URL" 2>/dev/null; then
        echo "Montando imagen de disco..."
        hdiutil attach lazarus.dmg -nobrowse -mountpoint /Volumes/Lazarus 2>/dev/null || true
        
        echo "Instalando Lazarus..."
        cp -R "/Volumes/Lazarus/Lazarus.app" /Applications/
        
        hdiutil detach /Volumes/Lazarus 2>/dev/null || true
        
        success "Lazarus instalado"
    else
        # Método alternativo: Homebrew Cask
        warn "Descarga directa falló, intentando via Homebrew..."
        brew install --cask lazarus
        success "Lazarus instalado via Homebrew"
    fi
fi

# ============================================================
# INSTALAR GDB (Debugger)
# ============================================================

echo ""
echo "=== Instalando GDB (Debugger) ==="

if command -v gdb &>/dev/null; then
    success "GDB ya instalado"
else
    echo "Instalando GDB via Homebrew..."
    brew install gdb
    
    # Firmar GDB para que funcione
    echo ""
    warn "Firmando GDB para ejecución..."
    echo "Esto requerirá tu contraseña de administrador"
    sudo codesign --force --deep --sign - "$(brew --prefix)/bin/gdb"
fi

# ============================================================
# CONFIGURACIÓN DE LAZARUS
# ============================================================

echo ""
echo "=== Configurando Lazarus ==="

# Obtener directorio de configuración de Lazarus
LAZARUS_CONFIG_DIR=~/.lazarus

if [ ! -d "$LAZARUS_CONFIG_DIR" ]; then
    mkdir -p "$LAZARUS_CONFIG_DIR"
fi

# Crear archivo de configuración básico si no existe
if [ ! -f "$LAZARUS_CONFIG_DIR/ideintf" ]; then
    # Crear configuración básica
    cat > "$LAZARUS_CONFIG_DIR/ideintf" << 'EOFCONFIG'
[Environment]
FpcSrcDir=/usr/local/share/fpcsrc/3.2.2
EOFCONFIG
    success "Archivo de configuración creado"
fi

# ============================================================
# MENSAJE FINAL
# ============================================================

echo ""
echo "==============================================="
echo "  ¡INSTALACIÓN COMPLETADA!"
echo "==============================================="
echo ""
echo "Pasos siguientes:"
echo "  1. Abre Lazarus desde: /Applications/Lazarus.app"
echo "  2. Ve a: Tools > Options > Environment > Files"
echo "  3. Verifica que:"
echo "     - Compiler: /usr/local/bin/fpc"
echo "     - FPC Source: $FPCSOURCE_DIR"
echo "  4. Si hay errores de seguridad, ejecuta:"
echo "     sudo codesign --force --deep --sign - /Applications/Lazarus.app/Contents/MacOS/startlazarus"
echo ""
echo "Para compilar tu proyecto (Capturador de Peso):"
echo "  - Abre project1.lpi"
echo "  - Presiona F9 o ve a Run > Run"
echo ""
echo "==============================================="

# Verificar si el proyecto existe en el directorio actual
if [ -f "project1.lpi" ]; then
    echo ""
    warn "Detecté que tienes un proyecto en el directorio actual"
    read -p "¿Quieres abrirlo en Lazarusahora? (s/n): " RESP
    if [ "$RESP" = "s" ] || [ "$RESP" = "S" ]; then
        open /Applications/Lazarus.app project1.lpi
    fi
fi