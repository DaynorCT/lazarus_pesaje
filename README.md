# Sistema de Pesaje - Lazarus

Sistema de escritorio para gestión de pesaje con básculas RS232, desarrollado en Lazarus/Free Pascal.

## Requisitos

- macOS 11+ (Apple Silicon)
- Lazarus 4.7 + FPC 3.2.3 instalado vía fpcupdeluxe
- Xcode Command Line Tools (`xcode-select --install`)

## Compilación

### macOS

```bash
./compilar.sh
```

### Windows (cross-compilación desde macOS)

Requiere instalar el cross-compiler **i386-win32** una sola vez desde fpcupdeluxe:

1. Abrir fpcupdeluxe
2. Pestaña **Cross** (o **Setup+**)
3. Seleccionar OS: **Windows**, CPU: **i386**
4. Clic en **Install cross compiler**

Luego:

```bash
./compilar_win32.sh
```

Genera `pesaje.exe` — compatible con Windows XP, 7, 8, 10, 11.

Para distribuir en Windows solo se necesita:
- `pesaje.exe`
- `sqlite3.dll` (descargar de sqlite.org, misma carpeta que el .exe)

## Ejecución

```bash
cd /Users/jaru/dev/lazarus-pesaje
./pesaje
```

### Login por defecto

| Campo | Valor |
|---|---|
| Usuario | `admin@sistema.com` |
| Contraseña | `admin123` |

Al primer arranque se crea automáticamente la base de datos `pesaje.db` con el admin sembrado.

## Base de Datos

**Archivo:** `pesaje.db` (SQLite, se crea en la raíz del proyecto)

### Resetear la BD

```bash
./reset_bd.sh
```

Elimina todos los datos excepto el usuario admin. Útil para desarrollo.

### Limpieza total (clean build)

```bash
rm -rf lib/*
rm -f pesaje pesaje.db
```

Borra ejecutable, base de datos y archivos intermedios. Luego:

```bash
./compilar.sh
./pesaje
```

Recompila desde cero y recrea la BD con el admin semilla.

### Abrir en DB Browser

```
File > Open Database > /Users/jaru/dev/lazarus-pesaje/pesaje.db
```

## Estructura del Proyecto

```
lazarus-pesaje/
├── compilar.sh               # Script de compilación
├── reset_bd.sh               # Resetear base de datos
├── pesaje.lpr                # Entry point
├── pesaje.lpi                # Proyecto Lazarus
├── pesaje                    # Ejecutable compilado
├── pesaje.app/               # App bundle macOS
├── pesaje.db                 # Base de datos SQLite
├── libsqlite3.dylib          # Librería SQLite
├── config.json               # Configuración
├── src/
│   ├── auth/
│   │   ├── AuthService.pas    # Autenticación (login, hash, seed admin)
│   │   └── LoginForm.pas      # Formulario de login
│   ├── database/
│   │   └── DataModule.pas     # Conexión SQLite, queries, esquema
│   ├── forms/
│   │   ├── MainForm.pas       # Ventana principal + navegación
│   │   ├── DashboardFrame.pas  # Dashboard inicio
│   │   ├── PesajeFrame.pas    # Módulo de pesaje
│   │   ├── UsuariosFrame.pas  # CRUD usuarios
│   │   ├── EmpresasFrame.pas  # CRUD empresas
│   │   ├── ChoferesFrame.pas  # CRUD choferes
│   │   ├── ProveedoresFrame.pas # CRUD proveedores
│   │   ├── VehiculosFrame.pas # CRUD vehículos
│   │   └── AbmSimpleFrame.pas # CRUD genérico (productos, orígenes, destinos)
│   ├── utils/
│   │   ├── Theme.pas          # Constantes de colores y estilos
│   │   └── Utils.pas          # Funciones utilitarias
│   └── reports/               # Reportes (pendiente)
├── lib/                       # Archivos intermedios de compilación
└── units/                     # Unidades compiladas
```

## Módulos del Sistema

| Módulo | Frame | Descripción |
|---|---|---|
| Dashboard | `TFrameDashboard` | Pantalla de inicio con estadísticas |
| Pesaje | `TFramePesaje` | Captura de peso desde báscula RS232 |
| Empresas | `TFrameEmpresas` | CRUD de empresas (logo incluido) |
| Choferes | `TFrameChoferes` | CRUD de choferes |
| Proveedores | `TFrameProveedores` | CRUD de proveedores |
| Usuarios | `TFrameUsuarios` | CRUD de usuarios |

### Catálogo (submenú)

| Módulo | Frame | Descripción |
|---|---|---|
| Vehículos | `TFrameVehiculos` | CRUD de vehículos |
| Productos | `TFrameAbmSimple` | CRUD de productos |
| Orígenes | `TFrameAbmSimple` | CRUD de orígenes |
| Destinos | `TFrameAbmSimple` | CRUD de destinos |

## Diseño y Estilos

Todos los colores están centralizados en `src/utils/Theme.pas`:

| Constante | Uso |
|---|---|
| `CLR_BG` | Fondo de página ($F5F5F5) |
| `CLR_CARD` | Fondo de tarjetas ($FFFFFF) |
| `CLR_PRIMARY` | Botones y acentos ($A65E25) |
| `CLR_TEXT_HEADING` | Títulos ($3B291E) |
| `CLR_TEXT` | Texto general ($1C1C1C) |
| `CLR_TEXT_SLATE` | Texto secundario ($8B7464) |
| `CLR_SUCCESS` / `CLR_SUCCESS_BG` | Badge ACTIVO |
| `CLR_DESTRUCTIVE` / `CLR_DESTRUCTIVE_BG` | Badge INACTIVO |
| `CLR_BORDER` | Bordes ($DEDEDE) |

**Nota:** Lazarus usa formato BGR (`$BBGGRR`).

### Patrones de UI

- **Frames**: toda la UI se crea por código en el constructor, sin diseño visual (.lfm mínimo)
- **Botones**: `TPanel` + `TLabel` con `PaintRounded` (esquinas redondeadas)
- **Inputs con borde**: panel externo (color borde) + panel interno (blanco, inset 1px) + `TEdit`
- **Tablas**: `TStringGrid` con `OnDrawCell` para badges de estado e íconos de acción
- **Modales**: `TForm` creado en runtime con funciones helper anidadas

## Base de Datos — Esquema

### Tablas principales

| Tabla | Descripción |
|---|---|
| `personas` | Entidad base (nombre, CI, teléfono) |
| `usuarios` | Autenticación (email, password_hash SHA1, rol) |
| `empresas` | Datos de la empresa (nombre, logo base64, estado) |
| `proveedores` | Proveedores (FK a personas) |
| `choferes` | Choferes (FK a personas) |
| `vehiculos` | Vehículos (placa, tara) |
| `pesajes` | Registros de pesaje (bruto, tara, neto, FK a varias tablas) |
| `productos` | Productos |
| `origenes` | Orígenes |
| `destinos` | Destinos |
| `bodegas` | Bodegas |
| `boleta_config` | Configuración de boleta de pesaje |

### Campos de auditoría (todas las tablas)

- `estado` — `ACTIVO` / `INACTIVO` (soft delete)
- `fecha_creacion` / `fecha_modificacion` — formato `YYYY-MM-DD HH:MM:SS`

## Autenticación

- SHA1 con salt aleatorio de 16 bytes
- Formato hash: `sha1:<hash_b64>:<salt_b64>`
- El admin se crea automáticamente al primer arranque si no existe

## Notas

- El proyecto usa widgetset Cocoa para macOS
- `{$linkframework UserNotifications}` requerido en el .lpr
- La BD se crea en el mismo directorio que el ejecutable
- Si se ejecuta desde el .app bundle, `DBPath` resuelve al directorio del proyecto
- No depende de archivos .lfm para el diseño de frames
