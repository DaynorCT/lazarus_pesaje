[Setup]
AppName=Sistema de Pesaje
AppVersion=1.0
AppPublisher=Lazarus Pesaje
DefaultDirName={pf}\SistemaPesaje
DefaultGroupName=Sistema de Pesaje
OutputDir=.\dist
OutputBaseFilename=Instalador_Sistema_Pesaje
Compression=lzma
SolidCompression=yes
SetupIconFile=assets\logo_pesaje.ico
UninstallDisplayIcon={app}\pesaje.exe
PrivilegesRequired=admin
DisableProgramGroupPage=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos adicionales:"

[Files]
Source: "pesaje.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "sqlite3.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "config.json"; DestDir: "{app}"; Flags: ignoreversion onlyifdoesntexist

[Icons]
Name: "{commondesktop}\Sistema de Pesaje"; Filename: "{app}\pesaje.exe"; Tasks: desktopicon
Name: "{group}\Sistema de Pesaje"; Filename: "{app}\pesaje.exe"
Name: "{group}\Desinstalar Sistema de Pesaje"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\pesaje.exe"; Description: "Iniciar Sistema de Pesaje"; Flags: nowait postinstall skipifsilent
