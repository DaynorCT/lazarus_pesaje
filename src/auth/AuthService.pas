unit AuthService;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, sha1, sqldb, DateUtils, DataModule;

type
  TAuthResult = (arSuccess, arInvalidEmail, arInvalidPassword, arInactiveUser, arError);

  TAuthService = class
  private
    class function Base64Encode(const S: string): string;
    class function Base64Decode(const S: string): string;
    class function GenerateSalt(Len: Integer): string;
    class function SHA1Hex(const S: string): string;
  public
    class function HashPassword(const Password: string): string;
    class function VerifyPassword(const Password, Hash: string): Boolean;
    class function Login(const Email, Password: string;
      out User: TUserRecord): TAuthResult;
    class function SeedAdminUser: Boolean;
  end;

implementation

class function TAuthService.Base64Encode(const S: string): string;
const
  B64: array[0..63] of Char = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  i, j: Integer;
  b0, b1, b2: Byte;
begin
  Result := '';
  i := 1;
  while i <= Length(S) do
  begin
    b0 := Ord(S[i]);
    if i + 1 <= Length(S) then b1 := Ord(S[i + 1]) else b1 := 0;
    if i + 2 <= Length(S) then b2 := Ord(S[i + 2]) else b2 := 0;

    j := b0 shr 2;                            Result := Result + B64[j];
    j := ((b0 and 3) shl 4) or (b1 shr 4);    Result := Result + B64[j];
    if i + 1 <= Length(S) then
    begin
      j := ((b1 and 15) shl 2) or (b2 shr 6); Result := Result + B64[j];
    end
    else
      Result := Result + '=';
    if i + 2 <= Length(S) then
    begin
      j := b2 and 63;                         Result := Result + B64[j];
    end
    else
      Result := Result + '=';

    Inc(i, 3);
  end;
end;

class function TAuthService.Base64Decode(const S: string): string;
const
  B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  // Faster lookup table
  function CharVal(c: Char): Byte;
  begin
    case c of
      'A'..'Z': Result := Ord(c) - 65;
      'a'..'z': Result := Ord(c) - 71;
      '0'..'9': Result := Ord(c) + 4;
      '+': Result := 62;
      '/': Result := 63;
    else
      Result := 255;
    end;
  end;
var
  i, j: Integer;
  B: array[0..3] of Byte;
  Decoded: array of Byte;
  Count: Integer;
  PadCount: Integer;
begin
  Result := '';
  if S = '' then Exit;

  Count := (Length(S) div 4) * 3;
  SetLength(Decoded, Count);
  j := 0;
  i := 1;

  while i <= Length(S) do
  begin
    B[0] := CharVal(S[i]);
    if i + 1 <= Length(S) then B[1] := CharVal(S[i+1]) else B[1] := 255;
    if i + 2 <= Length(S) then B[2] := CharVal(S[i+2]) else B[2] := 255;
    if i + 3 <= Length(S) then B[3] := CharVal(S[i+3]) else B[3] := 255;

    PadCount := 0;
    if B[2] = 255 then Inc(PadCount);
    if B[3] = 255 then Inc(PadCount);

    if j < Count then
      Decoded[j] := Byte((B[0] shl 2) or (B[1] shr 4));
    if (j + 1 < Count) and (B[2] <> 255) then
      Decoded[j + 1] := Byte((B[1] shl 4) or (B[2] shr 2));
    if (j + 2 < Count) and (B[3] <> 255) then
      Decoded[j + 2] := Byte((B[2] shl 6) or B[3]);

    Inc(j, 3 - PadCount);
    Inc(i, 4);
  end;

  SetLength(Decoded, j);
  SetLength(Result, j);
  for i := 0 to j - 1 do
    Result[i + 1] := AnsiChar(Decoded[i]);
end;

class function TAuthService.GenerateSalt(Len: Integer): string;
const
  Chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
var
  i: Integer;
begin
  Result := '';
  SetLength(Result, Len);
  for i := 1 to Len do
    Result[i] := Chars[Random(Length(Chars)) + 1];
end;

class function TAuthService.SHA1Hex(const S: string): string;
begin
  Result := SHA1Print(SHA1String(S));
end;

class function TAuthService.HashPassword(const Password: string): string;
var
  Salt: string;
begin
  Salt := GenerateSalt(16);
  Result := 'sha1:' + Base64Encode(SHA1Hex(Salt + Password)) + ':' + Base64Encode(Salt);
end;

class function TAuthService.VerifyPassword(const Password, Hash: string): Boolean;
var
  Parts: TStringArray;
  Salt, StoredHash: string;
begin
  if Copy(Hash, 1, 5) <> 'sha1:' then
    Exit(False);

  Parts := Copy(Hash, 6, Length(Hash)).Split(':');
  if Length(Parts) <> 2 then
    Exit(False);

  StoredHash := Base64Decode(Parts[0]);
  Salt := Base64Decode(Parts[1]);

  Result := (SHA1Hex(Salt + Password) = StoredHash);
end;

class function TAuthService.Login(const Email, Password: string;
  out User: TUserRecord): TAuthResult;
var
  SQL: string;
  HashDB: string;
  Estado: string;
  Q: TSQLQuery;
begin
  Result := arError;
  FillChar(User, SizeOf(User), 0);

  if DM = nil then Exit(arError);
  if not DM.Conexion.Connected then Exit(arError);

  SQL := 'SELECT u.id, u.persona_id, u.password_hash, u.rol, u.estado, ' +
    'p.nombre, p.apellido_paterno, p.apellido_materno ' +
    'FROM usuarios u ' +
    'INNER JOIN personas p ON p.id = u.persona_id ' +
    'WHERE u.email = ''' + StringReplace(Email, '''', '''''', [rfReplaceAll]) + '''';

  Q := DM.AbrirQuery(SQL);
  try
    if Q.EOF then
    begin
      Result := arInvalidEmail;
      Exit;
    end;

    Estado := Q.FieldByName('estado').AsString;
    if Estado <> 'ACTIVO' then
    begin
      Result := arInactiveUser;
      Exit;
    end;

    HashDB := Q.FieldByName('password_hash').AsString;
    if not VerifyPassword(Password, HashDB) then
    begin
      Result := arInvalidPassword;
      Exit;
    end;

    User.ID := Q.FieldByName('id').AsInteger;
    User.PersonaID := Q.FieldByName('persona_id').AsInteger;
    User.Email := Email;
    User.Rol := Q.FieldByName('rol').AsString;
    User.PersonaNombre := Trim(
      Q.FieldByName('nombre').AsString + ' ' +
      Q.FieldByName('apellido_paterno').AsString
    );

    DM.EjecutarSQL(
      'UPDATE usuarios SET ultimo_login = ' + IntToStr(DateTimeToUnix(Now)) +
      ' WHERE id = ' + IntToStr(User.ID)
    );

    Result := arSuccess;
  finally
    Q.Close;
  end;
end;

class function TAuthService.SeedAdminUser: Boolean;
var
  Hash: string;
  PersonaID: Integer;
  NowStr: string;
begin
  Result := False;

  if not DM.Conexion.Connected then
    DM.ConectarBaseDatos;

  if DM.ExisteRegistro('SELECT 1 FROM usuarios WHERE email=''admin@sistema.com''') then
    Exit(True);

  NowStr := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);

  if DM.Transaccion.Active then
    DM.Transaccion.Commit;
  DM.Transaccion.StartTransaction;
  try
    DM.EjecutarSQL(
      'INSERT INTO personas (nombre, apellido_paterno, correo, estado, ' +
      'fecha_creacion, fecha_modificacion) VALUES ' +
      '(''Admin'', ''Sistema'', ''admin@sistema.com'', ''ACTIVO'', ''' +
      NowStr + ''', ''' + NowStr + ''')'
    );
    PersonaID := DM.ObtenerUltimoID;

    Hash := HashPassword('admin123');

    DM.EjecutarSQL(
      'INSERT INTO usuarios (persona_id, email, password_hash, rol, estado, ' +
      'fecha_creacion, fecha_modificacion) VALUES (' +
      IntToStr(PersonaID) + ', ''admin@sistema.com'', ''' +
      StringReplace(Hash, '''', '''''', [rfReplaceAll]) +
      ''', ''administrador'', ''ACTIVO'', ''' + NowStr + ''', ''' + NowStr + ''')'
    );

    if not DM.ExisteRegistro('SELECT 1 FROM boleta_config') then
    begin
      DM.EjecutarSQL(
        'INSERT INTO boleta_config (salida, direccion, celular1, celular2, ciudad, ' +
        'titulo_superior, marca, titulo_documento, acreditacion) VALUES (' +
        '''Salida a Potosi'', ''Tarija km 2'', ''2782323'', ''1234343'', ' +
        '''POTOSI - BOLIVIA'', ''BALANZA DE PESAJE DIGITAL'', ''PRIMAVERA'', ' +
        '''BOLETA DE PESAJE'', ''ACREDITADO POR:'')'
      );
    end;

    DM.Transaccion.Commit;
    Result := True;
  except
    on E: Exception do
    begin
      DM.Transaccion.Rollback;
      WriteLn('Error seeding admin: ', E.Message);
    end;
  end;
end;

end.
