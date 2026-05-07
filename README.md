# Capturador de Peso - Lazarus

Sistema de escritorio para capturar peso de básculas RS232 y enviar al servidor SaaS.

## Estructura del Proyecto

```
lazarus-pesaje/
├── project1.lpi       # Proyecto Lazarus (configuración IDE)
├── project1.lpr       # Entry point (programa principal)
├── project1           # Ejecutable compilado (14MB)
├── project1.app/      # Aplicación macOS
├── config.json        # Configuración de usuario
├── units/
│   ├── main.pas      # UI + lógica (diseño, eventos, styling)
│   └── main.ppu     # Unidad compilada
├── lib/               # Archivos intermedios de compilación
└── .gitignore        # Archivos ignorados por git
```

## Archivos Principales Explicados

### units/main.pas
**Propósito:** UI + lógica completa de la aplicación

Este archivo contiene:
- Definición de componentes (labels, buttons, memo, panel, edit)
- Constructor que crea la UI programa ticamente
- Constantes de colores y styling
- Eventos de botones (click handlers)

**No depende de archivos .lfm** - todo en código Pascal puro.

```pascal
// Constantes de colores (formato BGR para Lazarus)
const
  COL_BG_PRINCIPAL = $00F5F5F5;
  COL_PRIMARIO = $00A65E25;
  COL_VERDE_EXITO = $00327D2E;
```

### project1.lpi
**Propósito:** Configuración del proyecto (Lazarus IDE)

Este archivo XML contiene:
- Título del proyecto
- Compilador y opciones
- Rutas de búsqueda de units
- Widget set (cocoa para macOS)
- Paquetes requeridos (LCL)

**No es código de aplicación** - solo config del IDE.

### project1.lpr
**Propósito:** Entry point del programa

```pascal
program project1;

uses
  Interfaces, Forms, Main;

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end;
```

Simplemente instancia el formulario Main.

## Sistema de Styling

### Diseño Minimalista (Tailwind-inspired)

El proyecto usa un diseño minimalista inspirado en Tailwind CSS:

| Elemento | Color | Hex |
|----------|-------|-----|
| Fondo principal | Gris claro | #F5F5F5 |
| Fondo blanco | Blanco | #FFFFFF |
| Color primario | Azul | #255EA6 |
| Estado conectado | Verde | #2E7D32 |
| Estado desconectado | Gris | #555F71 |
| Texto principal | Gris oscuro | #333333 |
| Borde sutil | Gris claro | #E0E0E0 |

### Cómo modificar colores

Los colores están definidos en `main.pas` líneas 38-47:

```pascal
const
  COL_BG_PRINCIPAL = $00F5F5F5;  // Fondo ventana
  COL_BG_BLANCO = $00FFFFFF;       // Paneles
  COL_PRIMARIO = $00A65E25;     // Botones principales
  COL_VERDE_EXITO = $00327D2E;   // Estado conectado
  COL_GRIS_ESTADO = $0071555F;   // Estado desconectado
```

**Nota:** Lazarus usa formato BGR ($00BBGGRR), no RGB.

### Propiedades de styling por componente

Los componentes se crean y estilizan en el constructor `TForm1.Create`:

```pascal
// Ejemplo: Label de título
lblTitulo := TLabel.Create(Self);
with lblTitulo do begin
  Caption := 'Sistema de Pesaje';
  Font.Size := 18;
  Font.Style := [fsBold];
  Font.Color := COL_TEXTO_PRINCIPAL;
end;

// Ejemplo: Botón
btnConectar := TButton.Create(Self);
with btnConectar do begin
  Caption := 'Conectar';
  Color := COL_PRIMARIO;
  Font.Color := COL_BG_BLANCO;
end;
```

## Buenas Prácticas de Código

### 1. Código Pascal Puro (No .lfm)

✅ **Recomendado:** Todo el diseño en código `.pas`

- Versionable en git
- Reproducible en cualquier máquina
- Sin dependencia del IDE
- Constants centralizadas

❌ **Evitar:** Diseño visual con .lfm generado por IDE

### 2. Constantes Centralizadas

```pascal
const
  COL_PRIMARIO = $00A65E25;
  COL_VERDE_EXITO = $00327D2E;

// Usar en componentes
btn.Color := COL_PRIMARIO;
```

### 3. Nombres Consistentes

- Constantes: `COL_NOMBRE` (MAYÚSCULAS con guiones bajos)
- Variables: `FNombre` (F prefix para campos)
- Componentes: `lblNombre`, `btnNombre` (prefijos hungarian)

### 4. Eventos como métodos

```pascal
procedure TForm1.btnConectarClick(Sender: TObject);
begin
  // Código del evento
end;
```

### 5. Unit de interface pública

```pascal
type
  TForm1 = class(TForm)
    // Solo declaraciones públicas
    // Implementación en implementation
  end;
```

## Compilación Cross-Platform

### Sistemas soportados

| SO | Target | Comando |
|----|-------|---------|
| **macOS** | darwin | `-Tdarwin` |
| **Windows** | win64 | `-Twin64` |
| **Linux** | linux | `-Tlinux` |
| **FreeBSD** | freebsd | `-Tfreebsd` |

### Compilar para diferentes SO

```bash
# macOS (default)
/Applications/lazarus/lazbuild project1.lpi

# Windows
/Applications/lazarus/lazbuild -Twin64 project1.lpi

# Linux
/Applications/lazarus/lazbuild -Tlinux project1.lpi
```

### Requisitos por SO

- **macOS:** Lazarus + FPC instalado
- **Windows:** Lazarus + FPC instalado
- **Linux:** Lazarus + FPC instalado

**No se necesita wine ni máquinas virtuales.**

## Configuración (config.json)

El archivo `config.json` guarda la configuración del usuario:

```json
{
  "puerto": "COM1",
  "baudrate": 9600,
  "url": "http://localhost:3000",
  "apikey": "",
  "autoenviar": true,
  "alwaysontop": false
}
```

| Campo | Descripción |
|-------|-------------|
| puerto | Puerto serie (COM1-COM10) |
| baudrate | Velocidad serie (9600 estándar) |
| url | URL del servidor SaaS |
| apikey | Clave del cliente |
| autoenviar | Envío automático de pesos |
| alwaysontop | Ventana siempre visible |

## API del Servidor

El sistema envía POST a `/api/pesajes`:

```json
{
  "peso": "123.5",
  "timestamp": "2024-01-15 10:30:00",
  "dispositivo": "COM1",
  "apikey": "clave-del-cliente"
}
```

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