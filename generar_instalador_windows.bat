@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo =========================================
echo   GENERAR INSTALADOR WINDOWS
echo   Sistema de Pesaje
echo =========================================
echo.

set "ORIGINAL_DIR=%CD%"

:: -------------------------------------------------------------
:: 1. Buscar Inno Setup Compiler (ISCC.exe)
:: -------------------------------------------------------------
set "ISCC="
set "PATHS[0]=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
set "PATHS[1]=C:\Program Files\Inno Setup 6\ISCC.exe"
set "PATHS[2]=C:\Program Files (x86)\Inno Setup 5\ISCC.exe"
set "PATHS[3]=C:\Program Files\Inno Setup 5\ISCC.exe"

for /L %%i in (0,1,3) do (
    if exist "!PATHS[%%i]!" (
        set "ISCC=!PATHS[%%i]!"
        goto :found_iscc
    )
)

:: Also check in PATH
for %%X in (ISCC.exe) do (
    if not "%%~$PATH:X"=="" (
        set "ISCC=%%~$PATH:X"
        goto :found_iscc
    )
)

echo ERROR: No se encontro ISCC.exe (Inno Setup Compiler).
echo.
echo Instala Inno Setup desde: https://jrsoftware.org/isinfo.php
echo Asegurate de instalarlo con soporte para ISPP (Inno Setup Preprocessor).
echo.
pause
exit /b 1

:found_iscc
echo [OK] Inno Setup encontrado:
echo   %ISCC%
echo.

:: -------------------------------------------------------------
:: 2. Verificar archivos necesarios
:: -------------------------------------------------------------
if not exist "pesaje.exe" (
    echo ERROR: No se encontro pesaje.exe en la carpeta actual.
    echo.
    echo Compila primero desde macOS con: ./compilar.sh win64
    echo o desde Lazarus IDE para Windows 64-bit.
    echo.
    pause
    exit /b 1
)

if not exist "sqlite3.dll" (
    echo ERROR: No se encontro sqlite3.dll en la carpeta actual.
    echo.
    echo Descargalo de https://www.sqlite.org/download.html
    echo busca: sqlite-dll-win-x64-*.zip
    echo.
    pause
    exit /b 1
)

if not exist "config.json" (
    echo ERROR: No se encontro config.json en la carpeta actual.
    echo.
    pause
    exit /b 1
)

if not exist "assets\fa-solid-900.ttf" (
    echo ERROR: No se encontro assets\fa-solid-900.ttf
    echo.
    pause
    exit /b 1
)

if not exist "assets\logo_pesaje.ico" (
    echo ERROR: No se encontro assets\logo_pesaje.ico
    echo.
    pause
    exit /b 1
)

echo [OK] Archivos necesarios encontrados.
echo.

:: -------------------------------------------------------------
:: 3. Crear carpeta de salida
:: -------------------------------------------------------------
if not exist "dist" mkdir dist

:: -------------------------------------------------------------
:: 4. Compilar instalador
:: -------------------------------------------------------------
echo [PROCESO] Compilando instalador con Inno Setup...
echo.

"%ISCC%" "instalador.iss"

if errorlevel 1 (
    echo.
    echo ERROR: La compilacion del instalador fallo.
    echo.
    pause
    exit /b 1
)

:: -------------------------------------------------------------
:: 5. Resultado
:: -------------------------------------------------------------
echo.
echo =========================================
echo   INSTALADOR GENERADO CORRECTAMENTE
echo =========================================
echo.

set "OUTPUT_FILE=%ORIGINAL_DIR%\dist\Instalador_Sistema_Pesaje.exe"
if exist "%OUTPUT_FILE%" (
    echo Archivo: %OUTPUT_FILE%
    for %%F in ("%OUTPUT_FILE%") do echo Tamano: %%~zF bytes
) else (
    echo El instalador se genero pero no se encontro en la ruta esperada.
    echo Revisa la carpeta dist/.
)

echo.
echo Caracteristicas:
echo   - Compatible con Windows 7 SP1 / 8 / 10 / 11 (64-bit)
echo   - Instala en Archivos de Programa\SistemaPesaje
echo   - Crea acceso directo en escritorio y menu Inicio
echo   - Incluye desinstalador
echo   - Conserva config.json existente del usuario
echo.
pause
