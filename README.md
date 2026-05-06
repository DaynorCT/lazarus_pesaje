# Capturador de Peso - Lazarus

Sistema de escritorio para capturar peso de básculas RS232 y enviar al servidor SaaS.

## Resumen de Instalación

Este documento describe el proceso de instalación del entorno de desarrollo para compilar el proyecto en macOS con Apple Silicon (M1/M2/M3).

### Estado Final

| Componente | Versión | Ubicación |
|-----------|--------|----------|
| FPC | 3.2.3 | `/Users/jaru/fpcupdeluxe/fpc/bin/aarch64-darwin/` |
| Lazarus | 4.7 | `/Users/jaru/fpcupdeluxe/lazarus/` |
| LCL | Compiled for Cocoa | `/Users/jaru/fpcupdeluxe/lazarus/lcl/units/` |

### Errores Comunes y Soluciones

1. **"Cannot find unit Interfaces"** - Asegurate de usar Lazarus de fpcupdeluxe
2. **"Cannot find unit system"** - Verificar que las rutas de unidades estén configuradas
3. **"Undefined symbols UNNotification"** - Agregar `{$linkframework UserNotifications}` en el archivo .lpr
4. **".lpi has no main unit"** - Verificar que el proyecto tenga MainUnit configurado

## Requisitos

- macOS 11+ (Big Sur o superior)
- Xcode Command Line Tools instalado (`xcode-select --install`)

## Instalación con fpcupdeluxe (Recomendado)

### Paso 1: Descargar fpcupdeluxe

```bash
cd /tmp
curl -L -o fpcupdeluxe.zip "https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases/download/v2.4.0i/fpcupdeluxe-aarch64-darwin-cocoa.zip"
unzip -q fpcupdeluxe.zip
```

### Paso 2: Mover a una carpeta segura

Por seguridad, macOS no permite ejecutar apps desde Descargas:

```bash
mv fpcupdeluxe-aarch64-darwin-cocoa.app /Applications/
```

### Paso 3: Ejecutar fpcupdeluxe

```bash
open /Applications/fpcupdeluxe-aarch64-darwin-cocoa.app
```

En la ventana de fpcupdeluxe:
- **FPC version**: seleccionar **3.2.2** o **stable**
- **Lazarus version**: seleccionar **4.6** o **latest**
- Click **"Install"** o **"Setup+"**

Esperar ~10-15 minutos a que termine la instalación.

### Paso 4: Abrir el nuevo Lazarus

Después de instalar, usa el shortcut creado por fpcupdeluxe:

- Ve a tu carpeta de usuario (`/Users/jaru/`)
- Busca **`Lazarus_fpcupdeluxe.sh`** o `Lazarus_fpcupdeluxe`
- O ejecuta directamente:
  ```bash
  /Users/jaru/fpcupdeluxe/lazarus/lazarus.app/Contents/MacOS/lazarus
  ```

### Paso 5: Compilar el proyecto

1. En Lazarus: **File > Open**
2. Selecciona: `/Users/jaru/dev/lazarus-pesaje/project1.lpi`
3. Presiona **F9** para compilar

## Solución de Problemas

### Error: "Cannot find unit Interfaces"

Causa: Las unidades LCL no están en las rutas del proyecto.

Solución: Verificar que en Proyecto > Opciones del compilador > Rutas esté configurado:
- Other unit files: `units`
- LCL widgetset: `cocoa`

### Error: "Undefined symbols UNNotification"

Agregar al inicio del archivo `.lpr`:
```pascal
{$linkframework UserNotifications}
```

### Error: "Project has no main unit"

Verificar en `project1.lpi` que tenga:
```xml
<MainUnit Value="0"/>
```

Y en la sección Units esté referenciado el archivo .lpr:
```xml
<Unit0>
  <Filename Value="project1.lpr"/>
</Unit0>
```

## Compilación desde Línea de Comandos

### Usando lazbuild (recomendado)

```bash
cd /Users/jaru/dev/lazarus-pesaje
/Users/jaru/fpcupdeluxe/lazarus/lazbuild project1.lpi
```

### Usando FPC directamente

```bash
cd /Users/jaru/dev/lazarus-pesaje
/Users/jaru/fpcupdeluxe/fpc/bin/aarch64-darwin/fpc \
  -MObjFPC -Scghi -O1 -gw3 -gl -l \
  -Fu/Users/jaru/fpcupdeluxe/lazarus/lcl/units/aarch64-darwin/cocoa \
  -Fu/Users/jaru/fpcupdeluxe/lazarus/lcl/units/aarch64-darwin \
  -Fu/Users/jaru/fpcupdeluxe/lazarus/components/lazutils/lib/aarch64-darwin \
  -Fu/Users/jaru/fpcupdeluxe/fpc/units/aarch64-darwin/rtl \
  -k-framework -kUserNotifications \
  -Fu. -Fuunits project1.lpr
```

## Ejecutar la Aplicación

```bash
/Users/jaru/dev/lazarus-pesaje/project1
```

O buscar el ejecutable `project1` en la carpeta del proyecto y hacer doble clic.

## Estructura del Proyecto

```
lazarus-pesaje/
├── project1.lpi       # Proyecto Lazarus
├── project1.lpr       # Archivo principal del programa
├── project1           # Ejecutable compilado (14.5 MB)
├── project1.app/      # Aplicación macOS
├── config.json        # Configuración (se genera automáticamente)
├── units/
│   ├── main.pas      # Lógica principal
│   └── main.ppu     # Unidad compilada
└── lib/               # Archivos intermedios
```

## API del Servidor

El sistema envía un POST a `/api/pesajes` con:

```json
{
  "peso": "123.5",
  "timestamp": "2024-01-15 10:30:00",
  "dispositivo": "COM1",
  "apikey": "clave-del-cliente"
}
```

## Configuración

1. Seleccione el puerto COM de la báscula (COM1-COM10)
2. Configure el Baud Rate (9600 estándar para la mayoría de básculas)
3. Ingrese la URL del servidor SaaS
4. Ingrese el API Key del cliente
5. Guarde la configuración

## Uso

1. Conecte la báscula al puerto serie
2. Click en "Conectar" para iniciar la lectura
3. El peso se mostrará automáticamente
4. Active "Auto-enviar" para envío automático o use "Enviar Peso Ahora"

## Notas

- El proyecto está configurado para usar el widgetset Cocoa (macOS)
- Se requiere el framework UserNotifications para macOS 11+
- El ejecutable compilado es para arquitectura arm64 (Apple Silicon)