unit DataModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, SQLite3Conn, synaser, FileUtil, Utils;

type
  TUserRecord = record
    ID: Integer;
    PersonaID: Integer;
    PersonaNombre: string;
    Email: string;
    Rol: string;
  end;

  { TDM }

  TDM = class(TDataModule)
    Conexion: TSQLite3Connection;
    Transaccion: TSQLTransaction;
    Query: TSQLQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FPuertoSerial: TBlockSerial;
    function GetDataDirectory: string;
    function GetDatabasePath: string;
    function GetOldDatabasePath: string;
    function GetAppBundleParentDatabasePath: string;
    procedure EnsureDataDirectory;
    procedure MigrateOldDatabase;
    procedure BackupDatabase;
    function ColumnaExiste(const NombreTabla, NombreColumna: string): Boolean;
    procedure AplicarMigracionesEsquema;
    // Helper: inicia transacción solo si no hay una activa
    procedure SafeStartTransaction;
    procedure SafeCommit;
    procedure SafeRollback;
  public
    function ConectarBaseDatos: Boolean;
    procedure InicializarBaseDatos;
    procedure EjecutarSQL(const SQL: string);
    function AbrirQuery(const SQL: string): TSQLQuery;
    function ObtenerUltimoID: Integer;
    function ExisteRegistro(const SQL: string): Boolean;

    // Serial
    function ConectarSerial(const Puerto: string; BaudRate: Integer;
      Bits: Integer; Paridad: Char; StopBits: Integer): Boolean;
    procedure DesconectarSerial;
    function LeerPuertoSerial: string;
    function PuertoConectado: Boolean;
    property PuertoSerial: TBlockSerial read FPuertoSerial;
  end;

var
  DM: TDM;

implementation

{$R *.lfm}

const
  APP_DATA_FOLDER = 'SistemaPesaje';
  DB_FILE_NAME    = 'pesaje.db';
  BACKUP_FILE_NAME = 'pesaje.db.backup';

// ══════════════════════════════════════════════════════════════════════
// Helpers de transacción seguros
// ══════════════════════════════════════════════════════════════════════

// Inicia transacción SOLO si no hay una activa.
// Esto evita el error "Transaction already active" que ocurre cuando
// EjecutarSQL/AbrirQuery abren una transacción implícita en SQLite
// y luego el código intenta abrir otra manualmente.
procedure TDM.SafeStartTransaction;
begin
  if not Transaccion.Active then
    Transaccion.StartTransaction;
end;

procedure TDM.SafeCommit;
begin
  if Transaccion.Active then
    Transaccion.Commit;
end;

procedure TDM.SafeRollback;
begin
  if Transaccion.Active then
    Transaccion.Rollback;
end;

// ══════════════════════════════════════════════════════════════════════
// Rutas de la base de datos
// ══════════════════════════════════════════════════════════════════════

function TDM.GetDataDirectory: string;
begin
{$IFDEF WINDOWS}
  Result := GetEnvironmentVariable('APPDATA');
  if Result = '' then
    Result := GetEnvironmentVariable('USERPROFILE');
  Result := IncludeTrailingPathDelimiter(Result) + APP_DATA_FOLDER;
{$ELSE}
  {$IFDEF DARWIN}
  Result := GetEnvironmentVariable('HOME') + '/Library/Application Support/' + APP_DATA_FOLDER;
  {$ELSE}
  Result := GetEnvironmentVariable('HOME') + '/.local/share/' + APP_DATA_FOLDER;
  {$ENDIF}
{$ENDIF}
end;

function TDM.GetDatabasePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetDataDirectory) + DB_FILE_NAME;
end;

function TDM.GetOldDatabasePath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + DB_FILE_NAME;
end;

function TDM.GetAppBundleParentDatabasePath: string;
{$IFDEF DARWIN}
var
  ExePath: string;
  i: Integer;
{$ENDIF}
begin
  Result := '';
{$IFDEF DARWIN}
  ExePath := ParamStr(0);
  i := Pos('.app/Contents/MacOS/', ExePath);
  if i > 0 then
    Result := ExtractFilePath(Copy(ExePath, 1, i - 1)) + DB_FILE_NAME;
{$ENDIF}
end;

procedure TDM.EnsureDataDirectory;
begin
  if not DirectoryExists(GetDataDirectory) then
    ForceDirectories(GetDataDirectory);
end;

procedure TDM.MigrateOldDatabase;
var
  OldPath, AppBundlePath, NewPath, SourcePath: string;
begin
  NewPath := GetDatabasePath;
  if FileExists(NewPath) then Exit;

  OldPath      := GetOldDatabasePath;
  AppBundlePath := GetAppBundleParentDatabasePath;

  SourcePath := '';
  if FileExists(OldPath) then
    SourcePath := OldPath
  else if (AppBundlePath <> '') and FileExists(AppBundlePath) then
    SourcePath := AppBundlePath;

  if SourcePath = '' then Exit;

  EnsureDataDirectory;
  CopyFile(SourcePath, NewPath);
end;

procedure TDM.BackupDatabase;
var
  DBPath, BackupPath: string;
begin
  DBPath := GetDatabasePath;
  if not FileExists(DBPath) then Exit;
  BackupPath := IncludeTrailingPathDelimiter(GetDataDirectory) + BACKUP_FILE_NAME;
  try
    CopyFile(DBPath, BackupPath, [cffOverwriteFile]);
  except
    // El backup no debe bloquear el arranque
  end;
end;

// ══════════════════════════════════════════════════════════════════════
// Migraciones de esquema
// ══════════════════════════════════════════════════════════════════════

function TDM.ColumnaExiste(const NombreTabla, NombreColumna: string): Boolean;
var
  Q: TSQLQuery;
begin
  Result := False;
  if not Conexion.Connected then Exit;

  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase    := Conexion;
    Q.Transaction := Transaccion;
    Q.SQL.Text    := 'PRAGMA table_info(' + NombreTabla + ')';
    Q.Open;
    while not Q.EOF do begin
      if LowerCase(Q.FieldByName('name').AsString) = LowerCase(NombreColumna) then begin
        Result := True;
        Break;
      end;
      Q.Next;
    end;
  finally
    Q.Close;
    Q.Free;
  end;
end;

procedure TDM.AplicarMigracionesEsquema;
// ─────────────────────────────────────────────────────────────────────
// IMPORTANTE: usa SafeStartTransaction para no chocar con la transacción
// principal de InicializarBaseDatos. Cada migración tiene su propio
// commit/rollback aislado.
// ─────────────────────────────────────────────────────────────────────
begin
  if not Conexion.Connected then Exit;

  // Migración 1: columna telefono en choferes
  if not ColumnaExiste('choferes', 'telefono') then begin
    SafeStartTransaction;
    try
      EjecutarSQL('ALTER TABLE choferes ADD COLUMN telefono TEXT');
      SafeCommit;
    except
      SafeRollback;
      // La columna puede ya existir en otra sesión; continuar sin bloquear
    end;
  end;

  // Agregar aquí más migraciones futuras con el mismo patrón:
  // if not ColumnaExiste('tabla', 'columna') then begin
  //   SafeStartTransaction;
  //   try
  //     EjecutarSQL('ALTER TABLE tabla ADD COLUMN columna TEXT');
  //     SafeCommit;
  //   except SafeRollback; end;
  // end;
end;

// ══════════════════════════════════════════════════════════════════════
// DataModule lifecycle
// ══════════════════════════════════════════════════════════════════════

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  Conexion.Transaction  := Transaccion;
  Transaccion.Database  := Conexion;
  Query.DataBase        := Conexion;
  Query.Transaction     := Transaccion;
  FPuertoSerial := nil;
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
  if Conexion.Connected then
    Conexion.Close;
  if FPuertoSerial <> nil then begin
    DesconectarSerial;
    FPuertoSerial.Free;
  end;
end;

// ══════════════════════════════════════════════════════════════════════
// Base de datos
// ══════════════════════════════════════════════════════════════════════

function TDM.ConectarBaseDatos: Boolean;
begin
  try
    Conexion.DatabaseName := GetDatabasePath;
    Conexion.Open;
    Result := Conexion.Connected;
  except
    Result := False;
  end;
end;

procedure TDM.EjecutarSQL(const SQL: string);
begin
  Query.Close;
  Query.SQL.Text := SQL;
  Query.ExecSQL;
end;

function TDM.AbrirQuery(const SQL: string): TSQLQuery;
begin
  Query.Close;
  Query.SQL.Text := SQL;
  Query.Open;
  Result := Query;
end;

function TDM.ObtenerUltimoID: Integer;
begin
  Query.Close;
  Query.SQL.Text := 'SELECT last_insert_rowid() AS id';
  Query.Open;
  Result := Query.FieldByName('id').AsInteger;
  Query.Close;
end;

function TDM.ExisteRegistro(const SQL: string): Boolean;
begin
  Query.Close;
  Query.SQL.Text := SQL;
  Query.Open;
  Result := not Query.EOF;
  Query.Close;
end;

// ══════════════════════════════════════════════════════════════════════
// Inicialización — crea tablas si no existen
// ══════════════════════════════════════════════════════════════════════

procedure TDM.InicializarBaseDatos;
begin
  MigrateOldDatabase;
  EnsureDataDirectory;

  if not ConectarBaseDatos then Exit;

  BackupDatabase;

  // Las migraciones de esquema se ejecutan ANTES de la transacción
  // principal, con sus propias transacciones internas, para evitar
  // el error "Transaction already active".
  AplicarMigracionesEsquema;

  // Crear tablas base en una sola transacción
  SafeStartTransaction;
  try
    EjecutarSQL('CREATE TABLE IF NOT EXISTS personas (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'nombre TEXT NOT NULL, apellido_paterno TEXT, apellido_materno TEXT, ' +
      'ci TEXT, telefono TEXT, correo TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS usuarios (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'persona_id INTEGER NOT NULL UNIQUE REFERENCES personas(id) ON DELETE CASCADE, ' +
      'email TEXT NOT NULL UNIQUE, password_hash TEXT, ' +
      'rol TEXT NOT NULL DEFAULT ''usuario'', ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ultimo_login INTEGER, ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE UNIQUE INDEX IF NOT EXISTS idx_usuarios_persona ON usuarios(persona_id)');
    EjecutarSQL('CREATE UNIQUE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS empresas (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'nombre_empresa TEXT NOT NULL, actividad_economica TEXT, ' +
      'correo_electronico TEXT, telefono TEXT, logo TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS proveedores (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'persona_id INTEGER NOT NULL REFERENCES personas(id) ON DELETE CASCADE, ' +
      'nombre_empresa TEXT, descripcion TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS choferes (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'persona_id INTEGER NOT NULL UNIQUE REFERENCES personas(id) ON DELETE CASCADE, ' +
      'licencia TEXT, telefono TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE UNIQUE INDEX IF NOT EXISTS idx_choferes_persona ON choferes(persona_id)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS vehiculos (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'placa TEXT NOT NULL, tipo_vehiculo TEXT, tara INTEGER NOT NULL DEFAULT 0, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS vehiculo_chofer (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'vehiculo_id INTEGER NOT NULL REFERENCES vehiculos(id) ON DELETE CASCADE, ' +
      'chofer_id INTEGER NOT NULL REFERENCES choferes(id) ON DELETE CASCADE, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS bodegas (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'nombre TEXT NOT NULL, descripcion TEXT, ubicacion TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS productos (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'nombre TEXT NOT NULL, descripcion TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS origenes (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'nombre TEXT NOT NULL, descripcion TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS destinos (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'nombre TEXT NOT NULL, descripcion TEXT, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS pesajes (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'guia TEXT, lote TEXT, ' +
      'vehiculo_id INTEGER NOT NULL REFERENCES vehiculos(id) ON DELETE SET NULL, ' +
      'chofer_id INTEGER REFERENCES choferes(id) ON DELETE SET NULL, ' +
      'proveedor_id INTEGER REFERENCES proveedores(id) ON DELETE SET NULL, ' +
      'producto_id INTEGER REFERENCES productos(id) ON DELETE SET NULL, ' +
      'id_origen INTEGER REFERENCES origenes(id) ON DELETE SET NULL, ' +
      'id_destino INTEGER REFERENCES destinos(id) ON DELETE SET NULL, ' +
      'peso_bruto INTEGER, tara INTEGER, peso_neto INTEGER, ' +
      'costo_bs INTEGER, flete_bs_pendiente INTEGER, ' +
      'pesador_id INTEGER REFERENCES personas(id) ON DELETE SET NULL, ' +
      'estado TEXT NOT NULL DEFAULT ''ACTIVO'', ' +
      'estado_balanza TEXT NOT NULL DEFAULT ''EN_PROCESO'', ' +
      'usuario_creacion INTEGER, usuario_modificacion INTEGER, ' +
      'fecha_creacion TEXT, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE INDEX IF NOT EXISTS idx_pesajes_fecha ON pesajes(fecha_creacion)');
    EjecutarSQL('CREATE INDEX IF NOT EXISTS idx_pesajes_vehiculo ON pesajes(vehiculo_id)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS boleta_config (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'salida TEXT NOT NULL DEFAULT ''Salida a Potosi'', ' +
      'direccion TEXT NOT NULL DEFAULT ''Tarija km 2'', ' +
      'celular1 TEXT NOT NULL DEFAULT ''2782323'', ' +
      'celular2 TEXT NOT NULL DEFAULT ''1234343'', ' +
      'ciudad TEXT NOT NULL DEFAULT ''POTOSI - BOLIVIA'', ' +
      'titulo_superior TEXT NOT NULL DEFAULT ''BALANZA DE PESAJE DIGITAL'', ' +
      'marca TEXT NOT NULL DEFAULT ''PRIMAVERA'', ' +
      'titulo_documento TEXT NOT NULL DEFAULT ''BOLETA DE PESAJE'', ' +
      'acreditacion TEXT, ' +
      'usuario_modificacion INTEGER, fecha_modificacion TEXT)');

    EjecutarSQL('CREATE TABLE IF NOT EXISTS config_balanza (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ' +
      'puerto_com TEXT NOT NULL DEFAULT ''COM1'', ' +
      'baudrate INTEGER NOT NULL DEFAULT 9600, ' +
      'databits INTEGER NOT NULL DEFAULT 8, ' +
      'paridad TEXT NOT NULL DEFAULT ''N'', ' +
      'stopbits INTEGER NOT NULL DEFAULT 1, ' +
      'flowcontrol TEXT NOT NULL DEFAULT ''None'', ' +
      'timeout_ms INTEGER NOT NULL DEFAULT 1000, ' +
      'metodo_lectura TEXT NOT NULL DEFAULT ''AUTO'', ' +
      'posicion_inicio INTEGER NOT NULL DEFAULT 8, ' +
      'posicion_longitud INTEGER NOT NULL DEFAULT 5, ' +
      'usuario_modificacion INTEGER, fecha_modificacion TEXT)');

    SafeCommit;
  except
    on E: Exception do
      SafeRollback;
  end;
end;

// ══════════════════════════════════════════════════════════════════════
// Serial (synaser) — compatible Windows 7-11 y macOS
// ══════════════════════════════════════════════════════════════════════

function TDM.ConectarSerial(const Puerto: string; BaudRate: Integer;
  Bits: Integer; Paridad: Char; StopBits: Integer): Boolean;
begin
  Result := False;
  try
    if FPuertoSerial = nil then
      FPuertoSerial := TBlockSerial.Create;

    FPuertoSerial.Connect(Puerto);
    if FPuertoSerial.LastError <> 0 then Exit;

    FPuertoSerial.Config(BaudRate, Bits, Paridad, StopBits, False, False);
    if FPuertoSerial.LastError <> 0 then begin
      FPuertoSerial.CloseSocket;
      Exit;
    end;

    Result := True;
  except
    Result := False;
  end;
end;

procedure TDM.DesconectarSerial;
begin
  if FPuertoSerial <> nil then begin
    try
      FPuertoSerial.CloseSocket;
    except
    end;
  end;
end;

function TDM.LeerPuertoSerial: string;
var
  Buffer: string;
begin
  Result := '';
  if (FPuertoSerial = nil) or (not FPuertoSerial.InstanceActive) then Exit;
  Buffer := '';
  while FPuertoSerial.WaitingData > 0 do begin
    Buffer := Buffer + FPuertoSerial.RecvPacket(50);
    if Buffer <> '' then Break;
  end;
  Result := Buffer;
end;

function TDM.PuertoConectado: Boolean;
begin
  Result := (FPuertoSerial <> nil) and FPuertoSerial.InstanceActive;
end;

end.