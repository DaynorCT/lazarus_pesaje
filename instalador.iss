; Inno Setup script for Sistema de Pesaje
; Compatible with Windows 7 SP1 / 8 / 10 / 11 (64-bit)
; Compile with Inno Setup 6.x on Windows (ISCC.exe instalador.iss)

#define MyAppName "Sistema de Pesaje"
#define MyAppVersion "1.0"
#define MyAppPublisher "Lazarus Pesaje"
#define MyAppURL ""
#define MyAppExeName "pesaje.exe"

[Setup]
; AppId uniquely identifies this application. Do not reuse it for other apps.
AppId={{F4A9C1D2-8B3E-4C5F-9A6D-7E8B1C2A3D4E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\SistemaPesaje
DefaultGroupName={#MyAppName}
AllowNoIcons=yes

; Output
OutputDir=.\dist
OutputBaseFilename=Instalador_Sistema_Pesaje
SetupIconFile=assets\logo_pesaje.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}

; Compression
Compression=lzma2/ultra64
SolidCompression=yes

; Windows compatibility: 6.1sp1 = Windows 7 SP1
MinVersion=6.1sp1
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Instalador del Sistema de Pesaje
VersionInfoTextVersion={#MyAppVersion}
VersionInfoCopyright=Copyright (C) 2024 {#MyAppPublisher}

; 64-bit install mode: install into 64-bit Program Files on x64 Windows
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x86 x64

; Admin privileges required to install under Program Files
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline dialog

; UI options (Inno Setup 6 style)
WizardStyle=modern
DisableWelcomePage=no
DisableDirPage=no
DisableProgramGroupPage=no
DisableReadyPage=no
DisableFinishedPage=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce; OnlyBelowVersion: 6.2; Check: not IsAdminInstallMode

[Files]
; Main executable
Source: "pesaje.exe"; DestDir: "{app}"; Flags: ignoreversion

; SQLite library
Source: "sqlite3.dll"; DestDir: "{app}"; Flags: ignoreversion

; Configuration file: only install if it does not exist yet (preserves user settings)
Source: "config.json"; DestDir: "{app}"; Flags: ignoreversion onlyifdoesntexist

; Font Awesome icon font used by the application
Source: "assets\fa-solid-900.ttf"; DestDir: "{app}"; Flags: ignoreversion

; Application icon used for shortcuts
Source: "assets\logo_pesaje.ico"; DestDir: "{app}"; Flags: ignoreversion

; IMPORTANTE: NO incluir pesaje.db aqui. La base de datos se crea/usa en
; {userappdata}\SistemaPesaje para que los datos del usuario sobrevivan a
; actualizaciones y reinstalaciones del programa.

[Icons]
; Start Menu shortcuts
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\logo_pesaje.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; IconFilename: "{app}\logo_pesaje.ico"

; Desktop shortcut
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\logo_pesaje.ico"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
; Register the application path for external tools / shell integration
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\{#MyAppExeName}"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName}"; Flags: uninsdeletekey
