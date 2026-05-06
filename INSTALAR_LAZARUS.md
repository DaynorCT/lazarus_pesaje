# Guía de Instalación de Lazarus para macOS Apple Silicon

Esta guía describe cómo instalar y configurar el entorno de desarrollo Lazarus en macOS con procesador Apple Silicon (M1/M2/M3).

## Requisitos del Sistema

- macOS 11.0 (Big Sur) o superior
- Apple Silicon (M1, M2, M3, o posteriores)
- Xcode Command Line Tools

## Método Recomendado: fpcupdeluxe

### ¿Qué es fpcupdeluxe?

Es una herramienta que automatiza la instalación de Free Pascal Compiler y Lazarus, asegurando que todas las versiones sean compatibles entre sí.

### Paso 1: Descargar fpcupdeluxe

```bash
cd /tmp
curl -L -o fpcupdeluxe.zip "https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases/download/v2.4.0i/fpcupdeluxe-aarch64-darwin-cocoa.zip"
unzip -q fpcupdeluxe.zip
```

### Paso 2: Mover a una ubicación segura

macOS no permite ejecutar aplicaciones desde la carpeta Descargas por razones de seguridad:

```bash
# Opción A: Mover a /Applications/
mv fpcupdeluxe-aarch64-darwin-cocoa.app /Applications/

# Opción B: Mover a tu carpeta de usuario
mv fpcupdeluxe-aarch64-darwin-cocoa.app ~/
```

### Paso 3: Ejecutar fpcupdeluxe

```bash
open /Applications/fpcupdeluxe-aarch64-darwin-cocoa.app
```

En la ventana de fpcupdeluxe:

| Opción | Selección recomendada |
|-------|----------------|
| FPC version | 3.2.2 o stable |
| Lazarus version | 4.6 o latest |
| Click | **Install** o **Setup+** |

### Paso 4: Esperar la instalación

La instalación puede tomar entre 10-20 minutos. Verás mensajes como:
- Downloading FPC archives...
- Compiling RTL...
- Compiling LCL...
- Configuring Lazarus...

### Paso 5: Abrir el nuevo Lazarus

Después de completar la instalación:

```bash
# Usar el atajo creado
/Users/jaru/Lazarus_fpcupdeluxe.sh

# O ejecutar directamente
/Users/jaru/fpcupdeluxe/lazarus/lazarus.app/Contents/MacOS/lazarus
```

## Compilar el Proyecto

### Desde Lazarus IDE

1. Abrir `/Users/jaru/fpcupdeluxe/lazarus/lazarus.app`
2. File > Open
3. Seleccionar `/Users/jaru/dev/lazarus-pesaje/project1.lpi`
4. Presionar **F9** para compilar

### Desde línea de comandos

```bash
cd /Users/jaru/dev/lazarus-pesaje
/Users/jaru/fpcupdeluxe/lazarus/lazbuild project1.lpi
```

## Errores Comunes y Soluciones

### Error: "Cannot find unit Interfaces"

**Causa:** Las rutas de unidades LCL no están configuradas.

**Solución:** En Proyecto > Opciones del compilador > Rutas:
- Other unit files: `units`
- LCL widgetset: `cocoa`

### Error: "Cannot find unit system"

**Causa:** FPC no encuentra las unidades RTL.

**Solución:** Agregar las rutas en la configuración de FPC:
```bash
Fu/Users/jaru/fpcupdeluxe/fpc/units/aarch64-darwin/rtl
```

### Error: "Undefined symbols UNNotification"

**Causa:** Falta el framework de notificaciones.

**Solución:** Agregar al inicio del archivo `.lpr`:
```pascal
{$linkframework UserNotifications}
```

### Error: "Project has no main unit"

**Causa:** El proyecto no tiene unidad principal configurada.

**Solución:** Verificar en `project1.lpi`:
```xml
<MainUnit Value="0"/>
```

### Error: "ld: symbol(s) not found for architecture arm64"

**Causa:** Falta vincular un framework.

**Solución:** Agregar `{$linkframework UserNotifications}` en el archivo .lpr

## Estructura de Archivos después de instalar

```
/Users/jaru/fpcupdeluxe/
├── fpc/                          # Free Pascal Compiler
│   ├── bin/aarch64-darwin/
│   │   └── fpc                   # Compilador
│   └── units/aarch64-darwin/      # Unidades compiladas
│       ├── rtl/                 # RTL
│       └── fcl-base/            # FCL
├── lazarus/                      # Lazarus IDE
│   ├── lcl/                   # LCL
│   │   └── units/aarch64-darwin/cocoa/  # Widgetset Cocoa
│   ├── components/lazutils/     # Componentes adicionales
│   └── lazarus.app            # Aplicación
└── config_lazarus/            # Configuración
```

## Notas Importantes

1. ** Siempre usar el Lazarus de fpcupdeluxe**, no el anterior en `/Applications/lazarus/`

2. **No eliminar la instalación anterior** hasta confirmar que la nueva funciona

3. **El ejecutable compilado** se genera en:
   - `/Users/jaru/dev/lazarus-pesaje/project1` (binario)
   - `/Users/jaru/dev/lazarus-pesaje/project1.app` (aplicación macOS)

##links Útiles

- Página oficial de Lazarus: https://www.lazarus-ide.org/
- Descargas de fpcupdeluxe: https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases
- Documentación FPC: https://www.freepascal.org/docs/

## Configuración de Puertos Serie

Para conectar una báscula:
- Puerto: COM1, COM2, etc.
- Baud Rate: 9600 (estándar)
- Data Bits: 8
- Parity: None
- Stop Bits: 1

## API del Servidor

El sistema envía un POST a `/api/pesajes`:

```json
{
  "peso": "123.5",
  "timestamp": "2024-01-15 10:30:00",
  "dispositivo": "COM1",
  "apikey": "clave-del-cliente"
}
```