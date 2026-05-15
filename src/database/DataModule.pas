unit DataModule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, SQLite3Conn, synaser, Utils;

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
    function DBPath: string;
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
  DirectorioApp: string = '';

implementation

{$R *.lfm}

function TDM.DBPath: string;
begin
  Result := DirectorioApp + 'pesaje.db';
end;

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  Conexion.Transaction := Transaccion;
  Transaccion.Database := Conexion;
  Query.DataBase := Conexion;
  Query.Transaction := Transaccion;

  FPuertoSerial := nil;
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
  if Conexion.Connected then
    Conexion.Close;
  if FPuertoSerial <> nil then
  begin
    DesconectarSerial;
    FPuertoSerial.Free;
  end;
end;

function TDM.ConectarBaseDatos: Boolean;
begin
  try
    Conexion.DatabaseName := DBPath;
    Conexion.Open;
    Result := Conexion.Connected;
  except
    on E: Exception do
    begin
      Result := False;
    end;
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

procedure TDM.InicializarBaseDatos;
begin
  if not ConectarBaseDatos then
    Exit;

  Transaccion.StartTransaction;
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

    Transaccion.Commit;
  except
    on E: Exception do
      Transaccion.Rollback;
  end;
end;

// ====================================================================
// SERIAL - Refactorizado desde UnitDashboard.pas (synaser)
// ====================================================================

function TDM.ConectarSerial(const Puerto: string; BaudRate: Integer;
  Bits: Integer; Paridad: Char; StopBits: Integer): Boolean;
begin
  Result := False;
  try
    if FPuertoSerial = nil then
      FPuertoSerial := TBlockSerial.Create;

    FPuertoSerial.Connect(Puerto);
    if FPuertoSerial.LastError <> 0 then
      Exit;

    FPuertoSerial.Config(BaudRate, Bits, Paridad, StopBits, False, False);
    if FPuertoSerial.LastError <> 0 then
    begin
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
  if FPuertoSerial <> nil then
  begin
    try
      FPuertoSerial.CloseSocket;
    except
    end;
  end;
end;

function TDM.LeerPuertoSerial: string;
var
  Buffer: string;
  Timeout: Integer;
begin
  Result := '';
  if (FPuertoSerial = nil) or (not FPuertoSerial.InstanceActive) then
    Exit;

  Timeout := 50;
  Buffer := '';
  while FPuertoSerial.WaitingData > 0 do
  begin
    Buffer := Buffer + FPuertoSerial.RecvPacket(Timeout);
    if Buffer <> '' then
      Break;
  end;
  Result := Buffer;
end;

function TDM.PuertoConectado: Boolean;
begin
  Result := (FPuertoSerial <> nil) and FPuertoSerial.InstanceActive;
end;

end.
