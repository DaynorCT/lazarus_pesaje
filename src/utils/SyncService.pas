unit SyncService;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, sqldb, DataModule, ConfigService, Utils;

type
  { TSyncService }

  TSyncService = class
  private
    FTimer: TTimer;
    FBusy: Boolean;
    FConfig: TConfigSistema;
    FAccessToken: string;
    FEmail: string;
    FPassword: string;
    FTokenExpira: TDateTime;
    FUltimaSync: string;
    FUltimoError: string;
    FPendientes: Integer;
    FConectado: Boolean;
    procedure TimerTick(Sender: TObject);
    function HttpRequest(const Metodo, Ruta: string; const Body: string;
      out Respuesta: string; RespHeaders: TStrings): Integer;
    function AsegurarToken: Boolean;
    procedure ExtraerTokenDeCookies(Cabeceras: TStrings);
    function PullVehiculos: Boolean;
    function PullChoferes: Boolean;
    function PullProveedores: Boolean;
    function PullSimple(const Ruta, Tabla: string): Boolean;
    procedure ActualizarPendientes;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configurar(const Email, Password: string);
    function SincronizarAhora: Boolean;
    function SincronizarCatalogos: Boolean;
    function PushPesajesPendientes: Boolean;
    property Conectado: Boolean read FConectado;
    property Pendientes: Integer read FPendientes;
    property UltimaSync: string read FUltimaSync;
    property UltimoError: string read FUltimoError;
  end;

var
  SyncSvc: TSyncService;

implementation

uses
  db, fpjson, jsonparser, httpsend, LoginForm;

// ══════════════════════════════════════════════════════════════════
// Helpers JSON
// ══════════════════════════════════════════════════════════════════

function CadenaJSON(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '"';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      '"':  Result := Result + '\"';
      '\':  Result := Result + '\\';
      #8:   Result := Result + '\b';
      #9:   Result := Result + '\t';
      #10:  Result := Result + '\n';
      #12:  Result := Result + '\f';
      #13:  Result := Result + '\r';
    else
      if Ord(C) < 32 then
        Result := Result + '\u' + Format('%.4x', [Ord(C)])
      else
        Result := Result + C;
    end;
  end;
  Result := Result + '"';
end;

procedure AgregarCampo(Obj: TJSONObject; const Nombre: string; Campo: TField);
begin
  if Campo.IsNull then
    Obj.Add(Nombre, TJSONNull.Create)
  else
    Obj.Add(Nombre, Campo.AsInteger);
end;

// ══════════════════════════════════════════════════════════════════
// TSyncService
// ══════════════════════════════════════════════════════════════════

constructor TSyncService.Create;
begin
  inherited Create;
  FConfig := CargarConfigSistema;
  FAccessToken := '';
  FEmail := '';
  FPassword := '';
  FTokenExpira := 0;
  FUltimaSync := '';
  FUltimoError := '';
  FPendientes := 0;
  FConectado := False;
  FBusy := False;

  FTimer := TTimer.Create(nil);
  FTimer.Interval := 30000;
  FTimer.Enabled := False;
  FTimer.OnTimer := @TimerTick;
end;

destructor TSyncService.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  inherited Destroy;
end;

procedure TSyncService.Configurar(const Email, Password: string);
begin
  FEmail := Email;
  FPassword := Password;
  ActualizarPendientes;
  if FConfig.AutoEnviar then
  begin
    // Primer intento rápido (3s), luego el intervalo se ajusta solo
    FTimer.Interval := 3000;
    FTimer.Enabled := True;
  end;
end;

procedure TSyncService.TimerTick(Sender: TObject);
begin
  if FConfig.AutoEnviar and (not FBusy) then
    SincronizarAhora;
end;

// ══════════════════════════════════════════════════════════════════
// HTTP
// ══════════════════════════════════════════════════════════════════

function TSyncService.HttpRequest(const Metodo, Ruta: string; const Body: string;
  out Respuesta: string; RespHeaders: TStrings): Integer;
var
  HTTP: THTTPSend;
  URL: string;
begin
  Result := 0;
  Respuesta := '';

  HTTP := THTTPSend.Create;
  try
    HTTP.Timeout := 8000;
    HTTP.Headers.Add('Accept: application/json');
    if FAccessToken <> '' then
      HTTP.Headers.Add('Cookie: access_token=' + FAccessToken);

    URL := FConfig.Url + Ruta;

    try
      if Metodo = 'POST' then
      begin
        HTTP.MimeType := 'application/json';
        HTTP.Headers.Add('Content-Type: application/json');
        if Body <> '' then
          HTTP.Document.Write(Pointer(Body)^, Length(Body));
      end;

      HTTP.HTTPMethod(Metodo, URL);
      Result := HTTP.ResultCode;

      if HTTP.Document.Size > 0 then
        SetString(Respuesta, PChar(HTTP.Document.Memory), HTTP.Document.Size);

      if RespHeaders <> nil then
        RespHeaders.Assign(HTTP.Headers);
    except
      on E: Exception do
      begin
        Result := 0;
        FUltimoError := E.Message;
      end;
    end;
  finally
    HTTP.Free;
  end;
end;

// ══════════════════════════════════════════════════════════════════
// Autenticación web (JWT)
// ══════════════════════════════════════════════════════════════════

procedure TSyncService.ExtraerTokenDeCookies(Cabeceras: TStrings);
var
  I, P, P2: Integer;
  Linea: string;
begin
  for I := 0 to Cabeceras.Count - 1 do
  begin
    Linea := Cabeceras[I];
    P := Pos('set-cookie:', LowerCase(Linea));
    if P <> 1 then Continue;

    P := Pos('access_token=', LowerCase(Linea));
    if P = 0 then Continue;

    P := P + Length('access_token=');
    P2 := Pos(';', Copy(Linea, P, MaxInt));
    if P2 = 0 then
      FAccessToken := Trim(Copy(Linea, P, MaxInt))
    else
      FAccessToken := Trim(Copy(Linea, P, P2 - 1));

    // El access token dura 15 min; se renueva con margen
    FTokenExpira := Now + (14.0 / 1440.0);
    Break;
  end;
end;

function TSyncService.AsegurarToken: Boolean;
var
  Cuerpo: string;
  Respuesta: string;
  Cabeceras: TStringList;
  Codigo: Integer;
begin
  Result := False;
  if (FEmail = '') or (FPassword = '') then Exit;
  if (FAccessToken <> '') and (Now < FTokenExpira) then
    Exit(True);

  FAccessToken := '';
  Cuerpo := '{"usuario":' + CadenaJSON(FEmail) +
            ',"contrasena":' + CadenaJSON(FPassword) + '}';

  Cabeceras := TStringList.Create;
  try
    Codigo := HttpRequest('POST', '/api/auth/login', Cuerpo, Respuesta, Cabeceras);
    if Codigo <> 200 then
    begin
      FUltimoError := 'Login web fallo (' + IntToStr(Codigo) + ')';
      Exit;
    end;

    ExtraerTokenDeCookies(Cabeceras);
    Result := FAccessToken <> '';
    if not Result then
      FUltimoError := 'El servidor no devolvio el token de acceso';
  finally
    Cabeceras.Free;
  end;
end;

// ══════════════════════════════════════════════════════════════════
// PULL — catálogos desde la web (espejo con el id de la web)
// ══════════════════════════════════════════════════════════════════

function TSyncService.PullVehiculos: Boolean;
var
  Respuesta: string;
  Codigo: Integer;
  JSON: TJSONData;
  Arr: TJSONArray;
  Item: TJSONObject;
  I, Id, Tara: Integer;
  Placa, Tipo, Estado: string;
  Ahora: string;
begin
  Result := False;
  Codigo := HttpRequest('GET', '/api/vehiculos', '', Respuesta, nil);
  if Codigo = 401 then
  begin
    FAccessToken := '';
    if AsegurarToken then
      Codigo := HttpRequest('GET', '/api/vehiculos', '', Respuesta, nil);
  end;
  if Codigo <> 200 then
  begin
    FUltimoError := 'Error al obtener vehiculos (' + IntToStr(Codigo) + ')';
    Exit;
  end;

  try
    JSON := GetJSON(Respuesta);
    try
      if not (JSON is TJSONObject) then Exit;
      if not (TJSONObject(JSON).FindPath('data') is TJSONArray) then Exit;
      Arr := TJSONArray(TJSONObject(JSON).FindPath('data'));

      Ahora := FechaHoraActual;
      for I := 0 to Arr.Count - 1 do
      begin
        if not (Arr.Items[I] is TJSONObject) then Continue;
        Item := TJSONObject(Arr.Items[I]);
        Id := Item.Get('id', 0);
        if Id <= 0 then Continue;
        Placa := Item.Get('placa', '');
        Tipo := Item.Get('tipo_vehiculo', '');
        Tara := Item.Get('tara', 0);
        Estado := Item.Get('estado', 'ACTIVO');

        DM.EjecutarSQL(
          'INSERT INTO vehiculos (id, placa, tipo_vehiculo, tara, estado, usuario_modificacion, fecha_creacion, fecha_modificacion) VALUES (' +
          IntToStr(Id) + ',' + QuotedStr(Placa) + ',' + QuotedStr(Tipo) + ',' +
          IntToStr(Tara) + ',' + QuotedStr(Estado) + ',' + IntToStr(UsuarioActual.ID) +
          ',''' + Ahora + ''',''' + Ahora + ''') ' +
          'ON CONFLICT(id) DO UPDATE SET ' +
          'placa=excluded.placa, tipo_vehiculo=excluded.tipo_vehiculo, tara=excluded.tara, ' +
          'estado=excluded.estado, usuario_modificacion=excluded.usuario_modificacion, ' +
          'fecha_modificacion=excluded.fecha_modificacion');
      end;
      Result := True;
    finally
      JSON.Free;
    end;
  except
    on E: Exception do
      FUltimoError := 'Error al procesar vehiculos: ' + E.Message;
  end;
end;

function TSyncService.PullChoferes: Boolean;
var
  Respuesta: string;
  Codigo: Integer;
  JSON: TJSONData;
  Arr: TJSONArray;
  Item: TJSONObject;
  I, Id, PersonaID: Integer;
  Existe: Boolean;
  Nombre, Pat, Mat, CI, Tel, Lic, Estado: string;
  Ahora: string;
  Q: TSQLQuery;
begin
  Result := False;
  Codigo := HttpRequest('GET', '/api/choferes', '', Respuesta, nil);
  if Codigo = 401 then
  begin
    FAccessToken := '';
    if AsegurarToken then
      Codigo := HttpRequest('GET', '/api/choferes', '', Respuesta, nil);
  end;
  if Codigo <> 200 then
  begin
    FUltimoError := 'Error al obtener choferes (' + IntToStr(Codigo) + ')';
    Exit;
  end;

  Q := TSQLQuery.Create(nil);
  Q.DataBase := DM.Conexion;
  Q.Transaction := DM.Transaccion;
  try
    try
      JSON := GetJSON(Respuesta);
      try
        if not (JSON is TJSONObject) then Exit;
        if not (TJSONObject(JSON).FindPath('data') is TJSONArray) then Exit;
        Arr := TJSONArray(TJSONObject(JSON).FindPath('data'));

        Ahora := FechaHoraActual;
        for I := 0 to Arr.Count - 1 do
        begin
          if not (Arr.Items[I] is TJSONObject) then Continue;
          Item := TJSONObject(Arr.Items[I]);
          Id := Item.Get('id', 0);
          if Id <= 0 then Continue;
          Nombre := Item.Get('nombre', '');
          Pat := Item.Get('apellido_paterno', '');
          Mat := Item.Get('apellido_materno', '');
          CI := Item.Get('ci', '');
          Tel := Item.Get('telefono', '');
          Lic := Item.Get('licencia', '');
          Estado := Item.Get('estado', 'ACTIVO');

          Q.Close;
          Q.SQL.Text := 'SELECT persona_id FROM choferes WHERE id = ' + IntToStr(Id);
          Q.Open;
          Existe := not Q.EOF;
          if Existe then PersonaID := Q.Fields[0].AsInteger;
          Q.Close;

          if Existe then
          begin
            DM.EjecutarSQL(
              'UPDATE personas SET nombre=' + QuotedStr(Nombre) +
              ',apellido_paterno=' + QuotedStr(Pat) +
              ',apellido_materno=' + QuotedStr(Mat) +
              ',ci=' + QuotedStr(CI) +
              ',telefono=' + QuotedStr(Tel) +
              ',fecha_modificacion=''' + Ahora + ''' WHERE id=' + IntToStr(PersonaID));
            DM.EjecutarSQL(
              'UPDATE choferes SET licencia=' + QuotedStr(Lic) +
              ',telefono=' + QuotedStr(Tel) +
              ',estado=' + QuotedStr(Estado) +
              ',fecha_modificacion=''' + Ahora + ''' WHERE id=' + IntToStr(Id));
          end
          else
          begin
            DM.EjecutarSQL(
              'INSERT INTO personas (nombre, apellido_paterno, apellido_materno, ci, telefono, estado, fecha_creacion, fecha_modificacion) VALUES (' +
              QuotedStr(Nombre) + ',' + QuotedStr(Pat) + ',' + QuotedStr(Mat) + ',' +
              QuotedStr(CI) + ',' + QuotedStr(Tel) + ',''ACTIVO'',''' + Ahora + ''',''' + Ahora + ''')');
            PersonaID := DM.ObtenerUltimoID;
            DM.EjecutarSQL(
              'INSERT INTO choferes (id, persona_id, licencia, telefono, estado, fecha_creacion, fecha_modificacion) VALUES (' +
              IntToStr(Id) + ',' + IntToStr(PersonaID) + ',' + QuotedStr(Lic) + ',' +
              QuotedStr(Tel) + ',' + QuotedStr(Estado) + ',''' + Ahora + ''',''' + Ahora + ''')');
          end;
        end;
        Result := True;
      finally
        JSON.Free;
      end;
    except
      on E: Exception do
        FUltimoError := 'Error al procesar choferes: ' + E.Message;
    end;
  finally
    Q.Free;
  end;
end;

function TSyncService.PullProveedores: Boolean;
var
  Respuesta: string;
  Codigo: Integer;
  JSON: TJSONData;
  Arr: TJSONArray;
  Item: TJSONObject;
  I, Id, PersonaID: Integer;
  Existe: Boolean;
  Nombre, Pat, Mat, CI, Tel, Empresa, Desc, Estado: string;
  Ahora: string;
  Q: TSQLQuery;
begin
  Result := False;
  Codigo := HttpRequest('GET', '/api/proveedores', '', Respuesta, nil);
  if Codigo = 401 then
  begin
    FAccessToken := '';
    if AsegurarToken then
      Codigo := HttpRequest('GET', '/api/proveedores', '', Respuesta, nil);
  end;
  if Codigo <> 200 then
  begin
    FUltimoError := 'Error al obtener proveedores (' + IntToStr(Codigo) + ')';
    Exit;
  end;

  Q := TSQLQuery.Create(nil);
  Q.DataBase := DM.Conexion;
  Q.Transaction := DM.Transaccion;
  try
    try
      JSON := GetJSON(Respuesta);
      try
        if not (JSON is TJSONObject) then Exit;
        if not (TJSONObject(JSON).FindPath('data') is TJSONArray) then Exit;
        Arr := TJSONArray(TJSONObject(JSON).FindPath('data'));

        Ahora := FechaHoraActual;
        for I := 0 to Arr.Count - 1 do
        begin
          if not (Arr.Items[I] is TJSONObject) then Continue;
          Item := TJSONObject(Arr.Items[I]);
          Id := Item.Get('id', 0);
          if Id <= 0 then Continue;
          Nombre := Item.Get('nombre', '');
          Pat := Item.Get('apellido_paterno', '');
          Mat := Item.Get('apellido_materno', '');
          CI := Item.Get('ci', '');
          Tel := Item.Get('telefono', '');
          Empresa := Item.Get('nombre_empresa', '');
          Desc := Item.Get('descripcion', '');
          Estado := Item.Get('estado', 'ACTIVO');

          Q.Close;
          Q.SQL.Text := 'SELECT persona_id FROM proveedores WHERE id = ' + IntToStr(Id);
          Q.Open;
          Existe := not Q.EOF;
          if Existe then PersonaID := Q.Fields[0].AsInteger;
          Q.Close;

          if Existe then
          begin
            DM.EjecutarSQL(
              'UPDATE personas SET nombre=' + QuotedStr(Nombre) +
              ',apellido_paterno=' + QuotedStr(Pat) +
              ',apellido_materno=' + QuotedStr(Mat) +
              ',ci=' + QuotedStr(CI) +
              ',telefono=' + QuotedStr(Tel) +
              ',fecha_modificacion=''' + Ahora + ''' WHERE id=' + IntToStr(PersonaID));
            DM.EjecutarSQL(
              'UPDATE proveedores SET nombre_empresa=' + QuotedStr(Empresa) +
              ',descripcion=' + QuotedStr(Desc) +
              ',estado=' + QuotedStr(Estado) +
              ',fecha_modificacion=''' + Ahora + ''' WHERE id=' + IntToStr(Id));
          end
          else
          begin
            DM.EjecutarSQL(
              'INSERT INTO personas (nombre, apellido_paterno, apellido_materno, ci, telefono, estado, fecha_creacion, fecha_modificacion) VALUES (' +
              QuotedStr(Nombre) + ',' + QuotedStr(Pat) + ',' + QuotedStr(Mat) + ',' +
              QuotedStr(CI) + ',' + QuotedStr(Tel) + ',''ACTIVO'',''' + Ahora + ''',''' + Ahora + ''')');
            PersonaID := DM.ObtenerUltimoID;
            DM.EjecutarSQL(
              'INSERT INTO proveedores (id, persona_id, nombre_empresa, descripcion, estado, fecha_creacion, fecha_modificacion) VALUES (' +
              IntToStr(Id) + ',' + IntToStr(PersonaID) + ',' + QuotedStr(Empresa) + ',' +
              QuotedStr(Desc) + ',' + QuotedStr(Estado) + ',''' + Ahora + ''',''' + Ahora + ''')');
          end;
        end;
        Result := True;
      finally
        JSON.Free;
      end;
    except
      on E: Exception do
        FUltimoError := 'Error al procesar proveedores: ' + E.Message;
    end;
  finally
    Q.Free;
  end;
end;

function TSyncService.PullSimple(const Ruta, Tabla: string): Boolean;
var
  Respuesta: string;
  Codigo: Integer;
  JSON: TJSONData;
  Arr: TJSONArray;
  Item: TJSONObject;
  I, Id: Integer;
  Nombre, Desc, Estado: string;
  Ahora: string;
begin
  Result := False;
  Codigo := HttpRequest('GET', Ruta, '', Respuesta, nil);
  if Codigo = 401 then
  begin
    FAccessToken := '';
    if AsegurarToken then
      Codigo := HttpRequest('GET', Ruta, '', Respuesta, nil);
  end;
  if Codigo <> 200 then
  begin
    FUltimoError := 'Error al obtener ' + Tabla + ' (' + IntToStr(Codigo) + ')';
    Exit;
  end;

  try
    JSON := GetJSON(Respuesta);
    try
      if not (JSON is TJSONObject) then Exit;
      if not (TJSONObject(JSON).FindPath('data') is TJSONArray) then Exit;
      Arr := TJSONArray(TJSONObject(JSON).FindPath('data'));

      Ahora := FechaHoraActual;
      for I := 0 to Arr.Count - 1 do
      begin
        if not (Arr.Items[I] is TJSONObject) then Continue;
        Item := TJSONObject(Arr.Items[I]);
        Id := Item.Get('id', 0);
        if Id <= 0 then Continue;
        Nombre := Item.Get('nombre', '');
        Desc := Item.Get('descripcion', '');
        Estado := Item.Get('estado', 'ACTIVO');

        DM.EjecutarSQL(
          'INSERT INTO ' + Tabla + ' (id, nombre, descripcion, estado, usuario_modificacion, fecha_creacion, fecha_modificacion) VALUES (' +
          IntToStr(Id) + ',' + QuotedStr(Nombre) + ',' + QuotedStr(Desc) + ',' +
          QuotedStr(Estado) + ',' + IntToStr(UsuarioActual.ID) + ',''' + Ahora + ''',''' + Ahora + ''') ' +
          'ON CONFLICT(id) DO UPDATE SET ' +
          'nombre=excluded.nombre, descripcion=excluded.descripcion, estado=excluded.estado, ' +
          'usuario_modificacion=excluded.usuario_modificacion, fecha_modificacion=excluded.fecha_modificacion');
      end;
      Result := True;
    finally
      JSON.Free;
    end;
  except
    on E: Exception do
      FUltimoError := 'Error al procesar ' + Tabla + ': ' + E.Message;
  end;
end;

function TSyncService.SincronizarCatalogos: Boolean;
var
  Ok: Boolean;
begin
  Result := False;
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;
  if not AsegurarToken then Exit;

  Ok := True;
  try
    if not PullVehiculos then Ok := False;
    if not PullChoferes then Ok := False;
    if not PullProveedores then Ok := False;
    if not PullSimple('/api/productos', 'productos') then Ok := False;
    if not PullSimple('/api/origenes', 'origenes') then Ok := False;
    if not PullSimple('/api/destinos', 'destinos') then Ok := False;
  except
    on E: Exception do
    begin
      Ok := False;
      FUltimoError := E.Message;
    end;
  end;
  Result := Ok;
end;

// ══════════════════════════════════════════════════════════════════
// PUSH — pesajes pendientes hacia la web
// ══════════════════════════════════════════════════════════════════

function TSyncService.PushPesajesPendientes: Boolean;
var
  Q: TSQLQuery;
  Obj: TJSONObject;
  Cuerpo: string;
  Respuesta: string;
  Codigo: Integer;
  ID: Integer;
  Ok: Boolean;
begin
  Result := False;
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;
  if not AsegurarToken then Exit;

  Q := TSQLQuery.Create(nil);
  Q.DataBase := DM.Conexion;
  Q.Transaction := DM.Transaccion;
  try
    Q.SQL.Text :=
      'SELECT id, guia, vehiculo_id, chofer_id, proveedor_id, producto_id, id_origen, id_destino, ' +
      'peso_bruto, tara, costo_bs, flete_bs_pendiente, estado_balanza ' +
      'FROM pesajes WHERE sincronizado = 0 AND estado = ''ACTIVO'' ORDER BY id ASC';
    Q.Open;
    while not Q.EOF do
    begin
      ID := Q.Fields[0].AsInteger;

      Obj := TJSONObject.Create;
      try
        Obj.Add('guia', Q.Fields[1].AsString);
        Obj.Add('vehiculo_id', Q.Fields[2].AsInteger);
        AgregarCampo(Obj, 'chofer_id', Q.Fields[3]);
        AgregarCampo(Obj, 'proveedor_id', Q.Fields[4]);
        AgregarCampo(Obj, 'producto_id', Q.Fields[5]);
        AgregarCampo(Obj, 'id_origen', Q.Fields[6]);
        AgregarCampo(Obj, 'id_destino', Q.Fields[7]);
        Obj.Add('peso_bruto', Q.Fields[8].AsInteger);
        Obj.Add('tara', Q.Fields[9].AsInteger);
        Obj.Add('costo_bs', Q.Fields[10].AsInteger);
        Obj.Add('flete_bs_pendiente', Q.Fields[11].AsInteger);
        Obj.Add('estado_balanza', Q.Fields[12].AsString);
        Cuerpo := Obj.AsJSON;
      finally
        Obj.Free;
      end;

      Codigo := HttpRequest('POST', '/api/pesajes', Cuerpo, Respuesta, nil);
      Ok := Codigo = 200;

      if (not Ok) and (Codigo = 401) then
      begin
        FAccessToken := '';
        if AsegurarToken then
        begin
          Codigo := HttpRequest('POST', '/api/pesajes', Cuerpo, Respuesta, nil);
          Ok := Codigo = 200;
        end;
      end;

      if Ok then
      begin
        DM.EjecutarSQL('UPDATE pesajes SET sincronizado = 1, sync_error = NULL WHERE id = ' + IntToStr(ID));
        Result := True;
      end
      else
      begin
        DM.EjecutarSQL('UPDATE pesajes SET sync_error = ' +
          QuotedStr(Copy('HTTP ' + IntToStr(Codigo) + ' ' + Respuesta, 1, 190)) +
          ' WHERE id = ' + IntToStr(ID));
      end;

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

// ══════════════════════════════════════════════════════════════════
// Ciclo completo
// ══════════════════════════════════════════════════════════════════

function TSyncService.SincronizarAhora: Boolean;
var
  OkPull: Boolean;
  OkPush: Boolean;
begin
  Result := False;
  if FBusy then Exit;
  FBusy := True;
  try
    OkPull := False;
    OkPush := False;

    try
      OkPull := SincronizarCatalogos;
    except
      on E: Exception do
        FUltimoError := E.Message;
    end;

    try
      OkPush := PushPesajesPendientes;
    except
      on E: Exception do
        FUltimoError := E.Message;
    end;

    FConectado := OkPull or OkPush;
    if FConectado then
    begin
      FUltimaSync := FechaHoraActual;
      FUltimoError := '';
      FTimer.Interval := 30000;
    end
    else
      FTimer.Interval := 60000;

    Result := FConectado;
  finally
    FBusy := False;
  end;
  ActualizarPendientes;
end;

procedure TSyncService.ActualizarPendientes;
var
  Q: TSQLQuery;
begin
  FPendientes := 0;
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Q := TSQLQuery.Create(nil);
  Q.DataBase := DM.Conexion;
  Q.Transaction := DM.Transaccion;
  try
    Q.SQL.Text := 'SELECT COUNT(*) AS c FROM pesajes WHERE sincronizado = 0 AND estado = ''ACTIVO''';
    Q.Open;
    if not Q.EOF then
      FPendientes := Q.FieldByName('c').AsInteger;
  finally
    Q.Free;
  end;
end;

end.
