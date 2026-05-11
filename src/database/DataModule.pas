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

implementation

{$R *.lfm}

function TDM.DBPath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'pesaje.db';
end;

procedure TDM.DataModuleCreate(Sender: TObject);
begin
  Conexion := TSQLite3Connection.Create(Self);
  Transaccion := TSQLTransaction.Create(Self);
  Query := TSQLQuery.Create(Self);

  Conexion.Transaction := Transaccion;
  Transaccion.Database := Conexion;
  Query.DataBase := Conexion;
  Query.Transaction := Transaccion;

  FPuertoSerial := TBlockSerial.Create;
  InicializarBaseDatos;
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
      WriteLn('Error conectando BD: ', E.Message);
      Result := False;
    end;
  end;
end;

procedure TDM.InicializarBaseDatos;
var
  SchemaFile: string;
  SchemaSQL: TStringList;
begin
  if not ConectarBaseDatos then
    Exit;

  SchemaFile := ExtractFilePath(ParamStr(0)) + 'src' + DirectorySeparator +
    'database' + DirectorySeparator + 'schema.sql';

  if not FileExists(SchemaFile) then
    SchemaFile := ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator +
      'src' + DirectorySeparator + 'database' + DirectorySeparator + 'schema.sql';

  if not FileExists(SchemaFile) then
    Exit;

  Transaccion.StartTransaction;
  try
    SchemaSQL := TStringList.Create;
    try
      SchemaSQL.LoadFromFile(SchemaFile);
      EjecutarSQL(SchemaSQL.Text);
    finally
      SchemaSQL.Free;
    end;
    Transaccion.Commit;
  except
    on E: Exception do
    begin
      Transaccion.Rollback;
      WriteLn('Error inicializando BD: ', E.Message);
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
