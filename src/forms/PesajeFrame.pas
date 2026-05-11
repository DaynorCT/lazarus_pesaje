unit PesajeFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  IniFiles, sqldb, DataModule, Utils, LoginForm;

type
  { TFramePesaje }

  TFramePesaje = class(TFrame)
    TimerLectura: TTimer;
    TimerReloj: TTimer;
    procedure FrameCreate(Sender: TObject);
    procedure FrameDestroy(Sender: TObject);
    procedure TimerRelojTimer(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
  private
    // UI
    pnlPesaje, pnlForm: TPanel;
    lblHora, lblFecha: TLabel;
    lblPesoDisplay, lblUnidad: TLabel;
    lblEstadoConexion, lblEstabilidad: TLabel;
    lblResultadoPeso, lblResultadoHora, lblResultadoID: TLabel;
    btnConectar, btnTara, btnGuardar, btnLimpiar: TButton;

    cmbVehiculo, cmbChofer, cmbProveedor: TComboBox;
    cmbProducto, cmbOrigen, cmbDestino: TComboBox;
    edtGuia, edtLote, edtCosto, edtFlete: TEdit;
    btnVehiculoNuevo, btnChoferNuevo, btnProveedorNuevo: TButton;
    btnProductoNuevo, btnOrigenNuevo, btnDestinoNuevo: TButton;

    // Datos
    FConectado: Boolean;
    FPesoActual: string;
    FPesoBruto: Double;
    FTara: Double;
    FUltimoID: Integer;
    FPuertoSerial: string;
    FBaudRate: Integer;
    FBits: Integer;
    FParidad: string;
    FStopBits: Integer;

    procedure CrearUI;
    procedure CargarConfigSerial;
    procedure CargarCombos;
    procedure btnConectarClick(Sender: TObject);
    procedure btnTaraClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure btnQuickCreateClick(Sender: TObject);
    procedure ProcesarTrama(const Trama: string);
    function ExtraerPeso(const Trama: string): string;
    function ParseFloatESP(const S: string): Double;
    procedure ActualizarPesoDisplay(const Peso: string);
    function GetIDFromCombo(const cmb: TComboBox; const Tabla: string): Integer;
    procedure GuardarPesaje;
  end;

implementation

{$R *.lfm}

// ====================================================================
// Helpers para construir UI
// ====================================================================

function CrearLabel(const AParent: TWinControl; const Cap: string;
  L, T: Integer): TLabel;
begin
  Result := TLabel.Create(AParent);
  Result.Parent := AParent;
  Result.Left := L; Result.Top := T;
  Result.Caption := Cap;
  Result.Font.Size := 11;
  Result.Font.Color := $555555;
end;

function CrearCombo(const AParent: TWinControl; L, T, W: Integer): TComboBox;
begin
  Result := TComboBox.Create(AParent);
  Result.Parent := AParent;
  Result.Left := L; Result.Top := T;
  Result.Width := W; Result.Height := 28;
  Result.Style := csDropDownList;
  Result.Font.Size := 12;
  Result.Items.Add('- Seleccione -');
  Result.ItemIndex := 0;
end;

function CrearBtnPlus(const AParent: TWinControl; L, T: Integer;
  Handler: TNotifyEvent; ATag: Integer): TButton;
begin
  Result := TButton.Create(AParent);
  Result.Parent := AParent;
  Result.Left := L; Result.Top := T;
  Result.Width := 32; Result.Height := 28;
  Result.Caption := '+';
  Result.Font.Style := [fsBold];
  Result.Tag := ATag;
  Result.OnClick := Handler;
end;

// ====================================================================
// TFramePesaje
// ====================================================================

procedure TFramePesaje.FrameCreate(Sender: TObject);
begin
  FConectado := False;
  FPesoActual := '0';
  FPesoBruto := 0;
  FTara := 0;
  FUltimoID := 0;

  TimerLectura := TTimer.Create(Self);
  TimerLectura.Interval := 300;
  TimerLectura.Enabled := False;
  TimerLectura.OnTimer := @TimerLecturaTimer;

  TimerReloj := TTimer.Create(Self);
  TimerReloj.Interval := 1000;
  TimerReloj.Enabled := False;
  TimerReloj.OnTimer := @TimerRelojTimer;

  CrearUI;
  CargarConfigSerial;

  if (DM <> nil) and DM.Conexion.Connected then
    CargarCombos;

  TimerReloj.Enabled := True;
end;

procedure TFramePesaje.FrameDestroy(Sender: TObject);
begin
  TimerLectura.Enabled := False;
  TimerReloj.Enabled := False;
  if (DM <> nil) and DM.PuertoConectado then
    DM.DesconectarSerial;
end;

procedure TFramePesaje.TimerRelojTimer(Sender: TObject);
begin
  lblHora.Caption := FormatDateTime('hh:nn:ss', Now);
  lblFecha.Caption := FormatDateTime('dd/mm/yyyy', Now);
end;

procedure TFramePesaje.TimerLecturaTimer(Sender: TObject);
var
  Trama: string;
begin
  if not DM.PuertoConectado then Exit;
  Trama := DM.LeerPuertoSerial;
  if Trama <> '' then
    ProcesarTrama(Trama);
end;

procedure TFramePesaje.CrearUI;
var
  pnlReloj, pnlDisplay, pnlResultados: TPanel;
  Lbl: TLabel;
begin
  Self.Color := $F0F2F5;

  // -- Panel izquierdo (pesaje) --
  pnlPesaje := TPanel.Create(Self);
  pnlPesaje.Parent := Self;
  pnlPesaje.Align := alLeft;
  pnlPesaje.Width := 430;
  pnlPesaje.BevelOuter := bvNone;
  pnlPesaje.Color := $F0F2F5;
  pnlPesaje.Caption := '';

  // Reloj
  pnlReloj := TPanel.Create(Self);
  pnlReloj.Parent := pnlPesaje;
  pnlReloj.SetBounds(24, 16, 382, 64);
  pnlReloj.BevelOuter := bvNone;
  pnlReloj.Color := $F0F2F5;
  pnlReloj.Caption := '';

  lblHora := TLabel.Create(Self);
  lblHora.Parent := pnlReloj;
  lblHora.SetBounds(0, 0, 380, 38);
  lblHora.Caption := '00:00:00';
  lblHora.Font.Height := -32;
  lblHora.Font.Style := [fsBold];
  lblHora.Font.Color := $333333;

  lblFecha := TLabel.Create(Self);
  lblFecha.Parent := pnlReloj;
  lblFecha.SetBounds(0, 44, 380, 20);
  lblFecha.Caption := '01/01/2026';
  lblFecha.Font.Size := 13;
  lblFecha.Font.Color := $777777;

  // Display peso
  pnlDisplay := TPanel.Create(Self);
  pnlDisplay.Parent := pnlPesaje;
  pnlDisplay.SetBounds(24, 96, 382, 160);
  pnlDisplay.BevelOuter := bvNone;
  pnlDisplay.Color := $2D6A4F;

  lblPesoDisplay := TLabel.Create(Self);
  lblPesoDisplay.Parent := pnlDisplay;
  lblPesoDisplay.Align := alTop;
  lblPesoDisplay.Height := 80;
  lblPesoDisplay.Alignment := taCenter;
  lblPesoDisplay.Layout := tlCenter;
  lblPesoDisplay.Caption := '0';
  lblPesoDisplay.Font.Height := -48;
  lblPesoDisplay.Font.Style := [fsBold];
  lblPesoDisplay.Font.Color := clWhite;

  lblUnidad := TLabel.Create(Self);
  lblUnidad.Parent := pnlDisplay;
  lblUnidad.Align := alBottom;
  lblUnidad.Height := 30;
  lblUnidad.Alignment := taCenter;
  lblUnidad.Caption := 'KILOGRAMOS';
  lblUnidad.Font.Size := 13;
  lblUnidad.Font.Color := $AADDBB;

  // Estado conexión
  lblEstadoConexion := TLabel.Create(Self);
  lblEstadoConexion.Parent := pnlPesaje;
  lblEstadoConexion.SetBounds(24, 268, 380, 20);
  lblEstadoConexion.Caption := 'SIN CONEXION';
  lblEstadoConexion.Font.Size := 11;
  lblEstadoConexion.Font.Style := [fsBold];
  lblEstadoConexion.Font.Color := $E63946;

  lblEstabilidad := TLabel.Create(Self);
  lblEstabilidad.Parent := pnlPesaje;
  lblEstabilidad.SetBounds(24, 288, 380, 20);
  lblEstabilidad.Caption := 'Esperando lectura...';
  lblEstabilidad.Font.Size := 11;
  lblEstabilidad.Font.Color := $888888;

  // Botones
  btnConectar := TButton.Create(Self);
  btnConectar.Parent := pnlPesaje;
  btnConectar.SetBounds(24, 320, 185, 42);
  btnConectar.Caption := 'CONECTAR BASCULA';
  btnConectar.Font.Size := 12; btnConectar.Font.Style := [fsBold];
  btnConectar.OnClick := @btnConectarClick;

  btnTara := TButton.Create(Self);
  btnTara.Parent := pnlPesaje;
  btnTara.SetBounds(219, 320, 185, 42);
  btnTara.Caption := 'CAPTURAR TARA';
  btnTara.Font.Size := 12; btnTara.Font.Style := [fsBold];
  btnTara.Enabled := False;
  btnTara.OnClick := @btnTaraClick;

  // Resultados
  pnlResultados := TPanel.Create(Self);
  pnlResultados.Parent := pnlPesaje;
  pnlResultados.SetBounds(24, 376, 382, 88);
  pnlResultados.BevelOuter := bvNone;
  pnlResultados.Color := clWhite;

  lblResultadoPeso := TLabel.Create(Self);
  lblResultadoPeso.Parent := pnlResultados;
  lblResultadoPeso.SetBounds(16, 12, 350, 20);
  lblResultadoPeso.Caption := 'Bruto: -- kg  |  Tara: -- kg';
  lblResultadoPeso.Font.Size := 12;
  lblResultadoPeso.Font.Color := $555555;

  lblResultadoHora := TLabel.Create(Self);
  lblResultadoHora.Parent := pnlResultados;
  lblResultadoHora.SetBounds(16, 36, 350, 24);
  lblResultadoHora.Caption := 'Neto: -- kg';
  lblResultadoHora.Font.Size := 14;
  lblResultadoHora.Font.Style := [fsBold];
  lblResultadoHora.Font.Color := $2D6A4F;

  lblResultadoID := TLabel.Create(Self);
  lblResultadoID.Parent := pnlResultados;
  lblResultadoID.SetBounds(290, 56, 80, 20);
  lblResultadoID.Caption := 'ID: --';
  lblResultadoID.Font.Size := 11;
  lblResultadoID.Font.Color := $AAAAAA;

  // ================================================================
  // Panel formulario (derecha)
  // ================================================================
  pnlForm := TPanel.Create(Self);
  pnlForm.Parent := Self;
  pnlForm.Align := alClient;
  pnlForm.BevelOuter := bvNone;
  pnlForm.Color := clWhite;
  pnlForm.Caption := '';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlForm;
  Lbl.SetBounds(24, 16, 300, 22);
  Lbl.Caption := 'DATOS DEL PESAJE';
  Lbl.Font.Size := 14;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := $333333;

  // Guía y Lote
  CrearLabel(pnlForm, 'Guía', 24, 56);
  edtGuia := TEdit.Create(Self);
  edtGuia.Parent := pnlForm;
  edtGuia.SetBounds(24, 76, 150, 28); edtGuia.Font.Size := 12;

  CrearLabel(pnlForm, 'Lote', 190, 56);
  edtLote := TEdit.Create(Self);
  edtLote.Parent := pnlForm;
  edtLote.SetBounds(190, 76, 150, 28); edtLote.Font.Size := 12;

  // Vehículo
  CrearLabel(pnlForm, 'Vehículo', 24, 112);
  cmbVehiculo := CrearCombo(pnlForm, 24, 132, 280);
  btnVehiculoNuevo := CrearBtnPlus(pnlForm, 312, 132, @btnQuickCreateClick, 1);

  // Chofer
  CrearLabel(pnlForm, 'Chofer', 24, 168);
  cmbChofer := CrearCombo(pnlForm, 24, 188, 280);
  btnChoferNuevo := CrearBtnPlus(pnlForm, 312, 188, @btnQuickCreateClick, 2);

  // Proveedor
  CrearLabel(pnlForm, 'Proveedor', 24, 224);
  cmbProveedor := CrearCombo(pnlForm, 24, 244, 280);
  btnProveedorNuevo := CrearBtnPlus(pnlForm, 312, 244, @btnQuickCreateClick, 3);

  // Producto
  CrearLabel(pnlForm, 'Producto', 24, 280);
  cmbProducto := CrearCombo(pnlForm, 24, 300, 280);
  btnProductoNuevo := CrearBtnPlus(pnlForm, 312, 300, @btnQuickCreateClick, 4);

  // Origen
  CrearLabel(pnlForm, 'Origen', 24, 336);
  cmbOrigen := CrearCombo(pnlForm, 24, 356, 280);
  btnOrigenNuevo := CrearBtnPlus(pnlForm, 312, 356, @btnQuickCreateClick, 5);

  // Destino
  CrearLabel(pnlForm, 'Destino', 24, 392);
  cmbDestino := CrearCombo(pnlForm, 24, 412, 280);
  btnDestinoNuevo := CrearBtnPlus(pnlForm, 312, 412, @btnQuickCreateClick, 6);

  // Costo y Flete
  CrearLabel(pnlForm, 'Costo (Bs)', 24, 452);
  edtCosto := TEdit.Create(Self);
  edtCosto.Parent := pnlForm;
  edtCosto.SetBounds(24, 472, 150, 28); edtCosto.Font.Size := 12; edtCosto.Text := '0';

  CrearLabel(pnlForm, 'Flete pendiente (Bs)', 190, 452);
  edtFlete := TEdit.Create(Self);
  edtFlete.Parent := pnlForm;
  edtFlete.SetBounds(190, 472, 150, 28); edtFlete.Font.Size := 12; edtFlete.Text := '0';

  // Botones
  btnGuardar := TButton.Create(Self);
  btnGuardar.Parent := pnlForm;
  btnGuardar.SetBounds(24, 520, 160, 44);
  btnGuardar.Caption := 'GUARDAR PESAJE';
  btnGuardar.Font.Size := 12; btnGuardar.Font.Style := [fsBold];
  btnGuardar.Enabled := False;
  btnGuardar.OnClick := @btnGuardarClick;

  btnLimpiar := TButton.Create(Self);
  btnLimpiar.Parent := pnlForm;
  btnLimpiar.SetBounds(192, 520, 160, 44);
  btnLimpiar.Caption := 'LIMPIAR';
  btnLimpiar.Font.Size := 12; btnLimpiar.Font.Style := [fsBold];
  btnLimpiar.OnClick := @btnLimpiarClick;
end;

// ====================================================================
// CONFIGURACION SERIAL
// ====================================================================

procedure TFramePesaje.CargarConfigSerial;
var
  Ini: TIniFile;
  Path: string;
begin
  Path := ExtractFilePath(ParamStr(0)) + 'config.ini';
  Ini := TIniFile.Create(Path);
  try
    FPuertoSerial := Ini.ReadString('serial', 'port', 'COM4');
    FBaudRate := Ini.ReadInteger('serial', 'baud', 9600);
    FBits := Ini.ReadInteger('serial', 'bits', 8);
    FParidad := Ini.ReadString('serial', 'parity', 'N');
    FStopBits := Ini.ReadInteger('serial', 'stopbits', 1);
  finally
    Ini.Free;
  end;
end;

// ====================================================================
// CARGAR COMBOS
// ====================================================================

procedure TFramePesaje.CargarCombos;

  procedure LlenarCombo(cmb: TComboBox; const SQL, Campo: string);
  var
    Q: TSQLQuery;
  begin
    if (DM = nil) or (not DM.Conexion.Connected) then Exit;
    cmb.Items.Clear;
    cmb.Items.Add('- Seleccione -');
    Q := DM.AbrirQuery(SQL);
    while not Q.EOF do
    begin
      cmb.Items.Add(Q.FieldByName(Campo).AsString);
      Q.Next;
    end;
    Q.Close;
    cmb.ItemIndex := 0;
  end;

begin
  LlenarCombo(cmbVehiculo,
    'SELECT id, placa FROM vehiculos WHERE estado=''ACTIVO'' ORDER BY placa', 'placa');
  LlenarCombo(cmbChofer,
    'SELECT c.id, p.nombre||'' ''||COALESCE(p.apellido_paterno,'''') AS nom ' +
    'FROM choferes c INNER JOIN personas p ON p.id=c.persona_id ' +
    'WHERE c.estado=''ACTIVO'' ORDER BY nom', 'nom');
  LlenarCombo(cmbProveedor,
    'SELECT pr.id, COALESCE(pr.nombre_empresa,p.nombre) AS nom FROM proveedores pr ' +
    'INNER JOIN personas p ON p.id=pr.persona_id WHERE pr.estado=''ACTIVO'' ORDER BY nom', 'nom');
  LlenarCombo(cmbProducto,
    'SELECT id, nombre FROM productos WHERE estado=''ACTIVO'' ORDER BY nombre', 'nombre');
  LlenarCombo(cmbOrigen,
    'SELECT id, nombre FROM origenes WHERE estado=''ACTIVO'' ORDER BY nombre', 'nombre');
  LlenarCombo(cmbDestino,
    'SELECT id, nombre FROM destinos WHERE estado=''ACTIVO'' ORDER BY nombre', 'nombre');
end;

// ====================================================================
// QUICK CREATE
// ====================================================================

procedure TFramePesaje.btnQuickCreateClick(Sender: TObject);
var
  NewTag: Integer;
  F: TForm;
  Lbl: TLabel;
  edtNombre: TEdit;
  Tabla: string;
  Titulo: string;
begin
  NewTag := TButton(Sender).Tag;

  if NewTag in [1,2,3] then begin ShowMessage('Creacion rapida disponible en Fase 2.1'); Exit; end;

  case NewTag of
    4: begin Tabla := 'productos'; Titulo := 'Nuevo Producto'; end;
    5: begin Tabla := 'origenes'; Titulo := 'Nuevo Origen'; end;
    6: begin Tabla := 'destinos'; Titulo := 'Nuevo Destino'; end;
  else Exit;
  end;

  F := TForm.Create(nil);
  try
    F.Caption := Titulo; F.Width := 400; F.Height := 200;
    F.Position := poOwnerFormCenter; F.BorderStyle := bsDialog;

    Lbl := TLabel.Create(F); Lbl.Parent := F;
    Lbl.SetBounds(24, 20, 350, 16); Lbl.Caption := 'Nombre *'; Lbl.Font.Style := [fsBold];
    edtNombre := TEdit.Create(F); edtNombre.Parent := F;
    edtNombre.SetBounds(24, 44, 350, 32); edtNombre.Font.Size := 12;

    with TButton.Create(F) do begin Parent := F; SetBounds(100, 100, 90, 32);
      Caption := 'Guardar'; Font.Style := [fsBold]; ModalResult := mrOK; end;
    with TButton.Create(F) do begin Parent := F; SetBounds(200, 100, 90, 32);
      Caption := 'Cancelar'; ModalResult := mrCancel; end;

    if F.ShowModal = mrOK then
    begin
      if Trim(edtNombre.Text) = '' then
      begin ShowMessage('El nombre es obligatorio'); Exit; end;
      DM.EjecutarSQL('INSERT INTO ' + Tabla + ' (nombre, estado, fecha_creacion, fecha_modificacion) VALUES (' +
        QuotedStr(Trim(edtNombre.Text)) + ', ''ACTIVO'', ''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
      CargarCombos;
    end;
  finally
    F.Free;
  end;
end;

// ====================================================================
// BOTONES
// ====================================================================

procedure TFramePesaje.btnConectarClick(Sender: TObject);
  function ParidadChar: Char;
  begin
    if FParidad = 'E' then Result := 'E'
    else if FParidad = 'O' then Result := 'O'
    else Result := 'N';
  end;
begin
  if DM.PuertoConectado then
  begin
    DM.DesconectarSerial;
    FConectado := False;
    TimerLectura.Enabled := False;
    btnConectar.Caption := 'CONECTAR BASCULA';
    lblEstadoConexion.Caption := 'SIN CONEXION';
    lblEstadoConexion.Font.Color := $E63946;
    lblEstabilidad.Caption := 'Esperando lectura...';
    btnTara.Enabled := False;
    btnGuardar.Enabled := False;
    Exit;
  end;

  if DM.ConectarSerial(FPuertoSerial, FBaudRate, FBits, ParidadChar, FStopBits) then
  begin
    FConectado := True;
    TimerLectura.Enabled := True;
    btnConectar.Caption := 'DESCONECTAR';
    lblEstadoConexion.Caption := 'CONECTADO - ' + FPuertoSerial;
    lblEstadoConexion.Font.Color := $2D6A4F;
    lblEstabilidad.Caption := 'Esperando datos...';
    btnTara.Enabled := True;
  end
  else
  begin
    ShowMessage('Error al conectar al puerto ' + FPuertoSerial);
    lblEstadoConexion.Caption := 'ERROR DE CONEXION';
    lblEstadoConexion.Font.Color := $E63946;
  end;
end;

procedure TFramePesaje.btnTaraClick(Sender: TObject);
var
  Peso: Double;
begin
  Peso := ParseFloatESP(FPesoActual);
  if Peso <= 0 then
  begin
    ShowMessage('No hay un peso valido para capturar como tara');
    Exit;
  end;
  FTara := Peso;
  FPesoBruto := 0;
  lblResultadoPeso.Caption := 'Bruto: -- kg  |  Tara: ' + FormatFloat('0.00', FTara) + ' kg';
  lblResultadoHora.Caption := 'Neto: PENDIENTE. Capture peso bruto';
  lblResultadoHora.Font.Color := $E63946;
  btnGuardar.Enabled := False;
end;

procedure TFramePesaje.btnGuardarClick(Sender: TObject);
begin
  GuardarPesaje;
end;

procedure TFramePesaje.btnLimpiarClick(Sender: TObject);
begin
  FPesoBruto := 0;
  FTara := 0;
  edtGuia.Text := '';
  edtLote.Text := '';
  edtCosto.Text := '0';
  edtFlete.Text := '0';
  cmbVehiculo.ItemIndex := 0;
  cmbChofer.ItemIndex := 0;
  cmbProveedor.ItemIndex := 0;
  cmbProducto.ItemIndex := 0;
  cmbOrigen.ItemIndex := 0;
  cmbDestino.ItemIndex := 0;
  btnGuardar.Enabled := False;
  lblResultadoPeso.Caption := 'Bruto: -- kg  |  Tara: -- kg';
  lblResultadoHora.Caption := 'Neto: -- kg';
  lblResultadoHora.Font.Color := $2D6A4F;
  lblResultadoID.Caption := 'ID: --';
end;

// ====================================================================
// PARSEO
// ====================================================================

procedure TFramePesaje.ProcesarTrama(const Trama: string);
var
  PesoStr: string;
begin
  PesoStr := ExtraerPeso(Trama);
  if PesoStr <> '' then
  begin
    FPesoActual := PesoStr;
    ActualizarPesoDisplay(PesoStr);
  end;
end;

function TFramePesaje.ExtraerPeso(const Trama: string): string;
var
  i: Integer;
  InNum: Boolean;
  Buf: string;
begin
  Result := '';
  Buf := '';
  InNum := False;
  for i := 1 to Length(Trama) do
  begin
    if (Trama[i] >= '0') and (Trama[i] <= '9') then
    begin
      if not InNum then
      begin
        InNum := True;
        Buf := '';
      end;
      Buf := Buf + Trama[i];
    end
    else if (Trama[i] = '.') and InNum then
      Buf := Buf + '.'
    else if InNum then
      Break;
  end;
  if (Buf <> '') and (Length(Buf) >= 2) then
    Result := Buf;
end;

function TFramePesaje.ParseFloatESP(const S: string): Double;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := StrToFloatDef(S, 0, FS);
end;

procedure TFramePesaje.ActualizarPesoDisplay(const Peso: string);
var
  PesoVal, PesoNeto: Double;
begin
  lblPesoDisplay.Caption := Peso;
  lblEstabilidad.Caption := 'Peso estable';
  lblEstabilidad.Font.Color := $2D6A4F;

  PesoVal := ParseFloatESP(Peso);
  if (FTara > 0) and (PesoVal > 0) then
  begin
    FPesoBruto := PesoVal;
    PesoNeto := FPesoBruto - FTara;
    lblResultadoPeso.Caption := 'Bruto: ' + FormatFloat('0.00', FPesoBruto) +
      ' kg  |  Tara: ' + FormatFloat('0.00', FTara) + ' kg';
    lblResultadoHora.Caption := 'Neto: ' + FormatFloat('0.00', PesoNeto) + ' kg';
    if PesoNeto >= 0 then
      lblResultadoHora.Font.Color := $2D6A4F
    else
      lblResultadoHora.Font.Color := $E63946;
    btnGuardar.Enabled := True;
  end;
end;

// ====================================================================
// GUARDAR EN BD
// ====================================================================

function TFramePesaje.GetIDFromCombo(const cmb: TComboBox; const Tabla: string): Integer;
var
  SQL, Nombre: string;
  Q: TSQLQuery;
begin
  Result := 0;
  if cmb.ItemIndex <= 0 then Exit;
  Nombre := StringReplace(cmb.Text, '''', '''''', [rfReplaceAll]);

  case Tabla of
    'vehiculos':
      SQL := 'SELECT id FROM vehiculos WHERE placa=''' + Nombre + ''' AND estado=''ACTIVO'' LIMIT 1';
    'choferes':
      SQL := 'SELECT c.id FROM choferes c INNER JOIN personas p ON p.id=c.persona_id ' +
        'WHERE p.nombre||'' ''||p.apellido_paterno=''' + Nombre + ''' AND c.estado=''ACTIVO'' LIMIT 1';
    'proveedores':
      SQL := 'SELECT pr.id FROM proveedores pr INNER JOIN personas p ON p.id=pr.persona_id ' +
        'WHERE (pr.nombre_empresa=''' + Nombre + ''' OR p.nombre=''' + Nombre + ''') AND pr.estado=''ACTIVO'' LIMIT 1';
  else
    SQL := 'SELECT id FROM ' + Tabla + ' WHERE nombre=''' + Nombre + ''' AND estado=''ACTIVO'' LIMIT 1';
  end;

  Q := DM.AbrirQuery(SQL);
  if not Q.EOF then
    Result := Q.FieldByName('id').AsInteger;
  Q.Close;
end;

procedure TFramePesaje.GuardarPesaje;
var
  SQL: string;
  VehiculoID, ChoferID, ProveedorID, ProductoID: Integer;
  OrigenID, DestinoID: Integer;
  PesoNeto: Double;

  function Nvl(ID: Integer): string;
  begin
    if ID > 0 then Result := IntToStr(ID) else Result := 'NULL';
  end;

begin
  if cmbVehiculo.ItemIndex <= 0 then
  begin
    ShowMessage('Seleccione un vehiculo');
    Exit;
  end;
  if FPesoBruto <= 0 then
  begin
    ShowMessage('Capture el peso bruto antes de guardar');
    Exit;
  end;

  PesoNeto := FPesoBruto - FTara;

  VehiculoID := GetIDFromCombo(cmbVehiculo, 'vehiculos');
  ChoferID := GetIDFromCombo(cmbChofer, 'choferes');
  ProveedorID := GetIDFromCombo(cmbProveedor, 'proveedores');
  ProductoID := GetIDFromCombo(cmbProducto, 'productos');
  OrigenID := GetIDFromCombo(cmbOrigen, 'origenes');
  DestinoID := GetIDFromCombo(cmbDestino, 'destinos');

  if VehiculoID = 0 then
  begin
    ShowMessage('Vehiculo no encontrado en la base de datos');
    Exit;
  end;

  DM.Transaccion.StartTransaction;
  try
    SQL := 'INSERT INTO pesajes (guia, lote, vehiculo_id, chofer_id, proveedor_id, ' +
      'producto_id, id_origen, id_destino, peso_bruto, tara, peso_neto, ' +
      'costo_bs, flete_bs_pendiente, pesador_id, estado, estado_balanza, ' +
      'fecha_creacion, fecha_modificacion) VALUES (';

    SQL := SQL + QuotedStr(edtGuia.Text) + ', ' + QuotedStr(edtLote.Text) + ', ';
    SQL := SQL + IntToStr(VehiculoID) + ', ' + Nvl(ChoferID) + ', ';
    SQL := SQL + Nvl(ProveedorID) + ', ' + Nvl(ProductoID) + ', ';
    SQL := SQL + Nvl(OrigenID) + ', ' + Nvl(DestinoID) + ', ';
    SQL := SQL + IntToStr(Round(FPesoBruto)) + ', ' + IntToStr(Round(FTara)) + ', ';
    SQL := SQL + IntToStr(Round(PesoNeto)) + ', ';
    SQL := SQL + edtCosto.Text + ', ' + edtFlete.Text + ', ';
    SQL := SQL + IntToStr(UsuarioActual.ID) + ', ';
    SQL := SQL + '''ACTIVO'', ''FINALIZADO'', ';
    SQL := SQL + '''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')';

    DM.EjecutarSQL(SQL);
    FUltimoID := DM.ObtenerUltimoID;
    DM.Transaccion.Commit;

    lblResultadoID.Caption := 'ID: ' + IntToStr(FUltimoID);
    ShowMessage('Pesaje Nro ' + IntToStr(FUltimoID) + ' guardado correctamente');
    btnLimpiarClick(nil);
  except
    on E: Exception do
    begin
      DM.Transaccion.Rollback;
      ShowMessage('Error al guardar pesaje: ' + E.Message);
    end;
  end;
end;

end.
