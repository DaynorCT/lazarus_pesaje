unit ConfigService;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TConfigSistema = record
    Url: string;
    ApiKey: string;
    AutoEnviar: Boolean;
    ModoOperacion: string;
    AlwaysOnTop: Boolean;
    Cargado: Boolean;
  end;

function GetConfigPath: string;
function CargarConfigSistema: TConfigSistema;
procedure GuardarConfigSistema(const C: TConfigSistema);

implementation

uses
  Classes, fpjson, jsonparser;

function GetConfigPath: string;
var
  ExePath: string;
  {$IFDEF DARWIN}
  i: Integer;
  BundleParent: string;
  {$ENDIF}
begin
  ExePath := ParamStr(0);
  Result := ExtractFilePath(ExePath) + 'config.json';
  if FileExists(Result) then Exit;

  {$IFDEF DARWIN}
  i := Pos('.app/Contents/MacOS/', ExePath);
  if i > 0 then
  begin
    BundleParent := ExtractFilePath(Copy(ExePath, 1, i - 1)) + 'config.json';
    if FileExists(BundleParent) then
      Result := BundleParent;
  end;
  {$ENDIF}
end;

function CargarConfigSistema: TConfigSistema;
var
  JSON: TJSONData;
  Obj: TJSONObject;
  D: TJSONData;
  S: string;
  List: TStringList;
  Ruta: string;

  function GetStr(const Nombre, Def: string): string;
  begin
    D := Obj.Find(Nombre);
    if (D <> nil) and (D is TJSONString) then
      Result := D.AsString
    else
      Result := Def;
  end;

  function GetBool(const Nombre: string; Def: Boolean): Boolean;
  begin
    D := Obj.Find(Nombre);
    if (D <> nil) and (D is TJSONBoolean) then
      Result := D.AsBoolean
    else
      Result := Def;
  end;

begin
  Result.Url := 'http://localhost:3000';
  Result.ApiKey := '';
  Result.AutoEnviar := True;
  Result.ModoOperacion := 'INTEGRADO';
  Result.AlwaysOnTop := False;
  Result.Cargado := False;

  Ruta := GetConfigPath;
  if (Ruta = '') or (not FileExists(Ruta)) then Exit;

  try
    List := TStringList.Create;
    try
      List.LoadFromFile(Ruta);
      S := List.Text;
    finally
      List.Free;
    end;

    JSON := GetJSON(S);
    try
      if JSON is TJSONObject then
      begin
        Obj := TJSONObject(JSON);
        Result.Url := Trim(GetStr('url', Result.Url));
        Result.ApiKey := GetStr('apikey', '');
        Result.AutoEnviar := GetBool('autoenviar', True);
        Result.ModoOperacion := UpperCase(GetStr('modo_operacion', 'INTEGRADO'));
        Result.AlwaysOnTop := GetBool('alwaysontop', False);
        Result.Cargado := True;
      end;
    finally
      JSON.Free;
    end;
  except
    // Config corrupta -> se usan los valores por defecto
    Result.Cargado := False;
  end;

  if (Result.ModoOperacion <> 'INTEGRADO') and (Result.ModoOperacion <> 'AUTONOMO') then
    Result.ModoOperacion := 'INTEGRADO';

  while (Result.Url <> '') and (Result.Url[Length(Result.Url)] = '/') do
    Delete(Result.Url, Length(Result.Url), 1);
end;

procedure GuardarConfigSistema(const C: TConfigSistema);
var
  Obj: TJSONObject;
  S: string;
  List: TStringList;
  Ruta: string;
begin
  Ruta := GetConfigPath;
  if Ruta = '' then
    Ruta := ExtractFilePath(ParamStr(0)) + 'config.json';

  Obj := TJSONObject.Create;
  try
    Obj.Add('url', C.Url);
    Obj.Add('apikey', C.ApiKey);
    Obj.Add('autoenviar', C.AutoEnviar);
    Obj.Add('modo_operacion', C.ModoOperacion);
    Obj.Add('alwaysontop', C.AlwaysOnTop);
    S := Obj.FormatJSON;
  finally
    Obj.Free;
  end;

  try
    List := TStringList.Create;
    try
      List.Text := S;
      List.SaveToFile(Ruta);
    finally
      List.Free;
    end;
  except
    // No bloquear la app si no se puede escribir
  end;
end;

end.
