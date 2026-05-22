unit ConfigBalanzaFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  sqldb, DataModule, Theme, LoginForm;

type

  { TFrameConfigBalanza }

  TFrameConfigBalanza = class(TFrame)
    constructor Create(AOwner: TComponent); override;
  private
    pnlMain: TPanel;
    cbPuerto, cbBaudRate, cbDataBits, cbParidad, cbStopBits, cbFlow: TComboBox;
    edtTimeout: TEdit;
    MemoDatos: TMemo;
    rbAuto, rbPosicion: TRadioButton;
    edtInicio, edtLongitud: TEdit;
    pnlPeso: TPanel;
    lblPeso: TLabel;
    btnConectar, btnLeer, btnGuardar: TPanel;
    lblBtnConectar, lblBtnLeer, lblBtnGuardar: TLabel;
    TimerLectura: TTimer;
    FConectado: Boolean;
    FPesoDetectado: string;

    procedure CargarConfiguracion;
    procedure GuardarConfiguracion;
    procedure ConectarClick(Sender: TObject);
    procedure LeerClick(Sender: TObject);
    procedure GuardarClick(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
    procedure MetodoLecturaChange(Sender: TObject);
    procedure PosicionChange(Sender: TObject);

    function ExtraerPesoAuto(const Trama: string): string;
    function ExtraerPesoPosicion(const Trama: string): string;
    procedure ActualizarPesoDetectado(const Trama: string);
    procedure LogDato(const Texto: string);
  public
    destructor Destroy; override;
  end;

implementation

{$R *.lfm}

constructor TFrameConfigBalanza.Create(AOwner: TComponent);
var
  Lbl: TLabel;
  Sep: TPanel;
const
  COL1 = 24;
  COL2 = 210;
  COL3 = 396;
  COL4 = 540;
  COMBO_W = 160;
  COL5 = 440;
begin
  inherited Create(AOwner);
  Self.Color := CLR_BG;
  FConectado := False;
  FPesoDetectado := '0';

  // =====================================================
  // SCROLLBOX
  // =====================================================

  pnlMain := TPanel.Create(Self);
  pnlMain.Parent := Self;
  pnlMain.Align := alClient;
  pnlMain.BorderSpacing.Left := 24;
  pnlMain.BorderSpacing.Right := 24;
  pnlMain.BorderSpacing.Top := 24;
  pnlMain.BorderSpacing.Bottom := 24;
  pnlMain.BevelOuter := bvNone;
  pnlMain.Color := clWhite;

  // =====================================================
  // TITULO
  // =====================================================

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Configuración balanza RS232';
  Lbl.Font.Size := 16;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(24, 20, 350, 30);

  Sep := TPanel.Create(Self);
  Sep.Parent := pnlMain;
  Sep.SetBounds(24, 58, 740, 1);
  Sep.BevelOuter := bvNone;
  Sep.Color := CLR_BORDER;

  // =====================================================
  // CONFIG SERIAL
  // =====================================================

  // PUERTO COM
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Puerto COM';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL1, 80, 120, 18);

  cbPuerto := TComboBox.Create(Self);
  cbPuerto.Parent := pnlMain;
  cbPuerto.SetBounds(COL1, 102, COMBO_W, 36);
  cbPuerto.Items.Add('COM1');
  cbPuerto.Items.Add('COM2');
  cbPuerto.Items.Add('COM3');
  cbPuerto.Items.Add('COM4');
  cbPuerto.Items.Add('COM5');
  cbPuerto.Items.Add('COM6');
  cbPuerto.Text := 'COM3';

  // BAUDRATE
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'BaudRate';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL2, 80, 120, 18);

  cbBaudRate := TComboBox.Create(Self);
  cbBaudRate.Parent := pnlMain;
  cbBaudRate.SetBounds(COL2, 102, COMBO_W, 36);
  cbBaudRate.Items.Add('1200');
  cbBaudRate.Items.Add('2400');
  cbBaudRate.Items.Add('4800');
  cbBaudRate.Items.Add('9600');
  cbBaudRate.Items.Add('19200');
  cbBaudRate.Items.Add('38400');
  cbBaudRate.Text := '9600';

  // DATABITS
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'DataBits';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL3, 80, 120, 18);

  cbDataBits := TComboBox.Create(Self);
  cbDataBits.Parent := pnlMain;
  cbDataBits.SetBounds(COL3, 102, 120, 36);
  cbDataBits.Items.Add('5');
  cbDataBits.Items.Add('6');
  cbDataBits.Items.Add('7');
  cbDataBits.Items.Add('8');
  cbDataBits.Text := '8';

  // PARIDAD
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Paridad';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL4, 80, 120, 18);

  cbParidad := TComboBox.Create(Self);
  cbParidad.Parent := pnlMain;
  cbParidad.SetBounds(COL4, 102, 140, 36);
  cbParidad.Items.Add('None (N)');
  cbParidad.Items.Add('Even (E)');
  cbParidad.Items.Add('Odd (O)');
  cbParidad.Text := 'None (N)';

  // STOPBITS
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'StopBits';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL1, 160, 120, 18);

  cbStopBits := TComboBox.Create(Self);
  cbStopBits.Parent := pnlMain;
  cbStopBits.SetBounds(COL1, 182, COMBO_W, 36);
  cbStopBits.Items.Add('1');
  cbStopBits.Items.Add('1.5');
  cbStopBits.Items.Add('2');
  cbStopBits.Text := '1';

  // FLOWCONTROL
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'FlowControl';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL2, 160, 120, 18);

  cbFlow := TComboBox.Create(Self);
  cbFlow.Parent := pnlMain;
  cbFlow.SetBounds(COL2, 182, COMBO_W, 36);
  cbFlow.Items.Add('None');
  cbFlow.Items.Add('RTS/CTS');
  cbFlow.Items.Add('XON/XOFF');
  cbFlow.Text := 'None';

  // TIMEOUT
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Timeout (ms)';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL3, 160, 120, 18);

  edtTimeout := TEdit.Create(Self);
  edtTimeout.Parent := pnlMain;
  edtTimeout.SetBounds(COL3, 182, 120, 36);
  edtTimeout.Text := '1000';

  // =====================================================
  // LINEA DIVISORA
  // =====================================================

  Sep := TPanel.Create(Self);
  Sep.Parent := pnlMain;
  Sep.SetBounds(24, 250, 740, 1);
  Sep.BevelOuter := bvNone;
  Sep.Color := CLR_BORDER;

  // =====================================================
  // DATOS RECIBIDOS
  // =====================================================

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Datos recibidos desde balanza';
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(24, 270, 300, 24);

  MemoDatos := TMemo.Create(Self);
  MemoDatos.Parent := pnlMain;
  MemoDatos.SetBounds(24, 300, 360, 120);
  MemoDatos.ScrollBars := ssVertical;
  MemoDatos.ReadOnly := True;
  MemoDatos.Font.Name := 'Monaco';
  MemoDatos.Font.Size := 10;
  MemoDatos.Font.Color := CLR_TEXT;

  // =====================================================
  // METODO LECTURA
  // =====================================================

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Método de lectura';
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(420, 270, 220, 24);

  rbAuto := TRadioButton.Create(Self);
  rbAuto.Parent := pnlMain;
  rbAuto.Caption := 'Extraer números automáticamente';
  rbAuto.SetBounds(420, 305, 300, 24);
  rbAuto.Checked := True;
  rbAuto.Font.Color := CLR_TEXT;
  rbAuto.OnClick := @MetodoLecturaChange;

  rbPosicion := TRadioButton.Create(Self);
  rbPosicion.Parent := pnlMain;
  rbPosicion.Caption := 'Usar posición fija';
  rbPosicion.SetBounds(420, 335, 200, 24);
  rbPosicion.Font.Color := CLR_TEXT;
  rbPosicion.OnClick := @MetodoLecturaChange;

  // INICIO
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Inicio';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(COL5, 370, 60, 18);

  edtInicio := TEdit.Create(Self);
  edtInicio.Parent := pnlMain;
  edtInicio.SetBounds(COL5, 392, 80, 34);
  edtInicio.Text := '8';
  edtInicio.OnChange := @PosicionChange;

  // LONGITUD
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Longitud';
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(540, 370, 80, 18);

  edtLongitud := TEdit.Create(Self);
  edtLongitud.Parent := pnlMain;
  edtLongitud.SetBounds(540, 392, 80, 34);
  edtLongitud.Text := '5';
  edtLongitud.OnChange := @PosicionChange;

  // =====================================================
  // PESO DETECTADO
  // =====================================================

  pnlPeso := TPanel.Create(Self);
  pnlPeso.Parent := pnlMain;
  pnlPeso.SetBounds(24, 455, 300, 74);
  pnlPeso.BevelOuter := bvNone;
  pnlPeso.Color := CLR_PRIMARY;

  lblPeso := TLabel.Create(Self);
  lblPeso.Parent := pnlPeso;
  lblPeso.Align := alClient;
  lblPeso.Alignment := taCenter;
  lblPeso.Layout := tlCenter;
  lblPeso.Caption := '0 kg';
  lblPeso.Font.Size := 22;
  lblPeso.Font.Style := [fsBold];
  lblPeso.Font.Color := clWhite;

  // =====================================================
  // BOTON CONECTAR
  // =====================================================

  btnConectar := TPanel.Create(Self);
  btnConectar.Parent := pnlMain;
  btnConectar.SetBounds(420, 460, 120, 44);
  btnConectar.BevelOuter := bvNone;
  btnConectar.Color := CLR_SUCCESS;
  btnConectar.Cursor := crHandPoint;
  btnConectar.OnClick := @ConectarClick;

  lblBtnConectar := TLabel.Create(Self);
  lblBtnConectar.Parent := btnConectar;
  lblBtnConectar.Align := alClient;
  lblBtnConectar.Alignment := taCenter;
  lblBtnConectar.Layout := tlCenter;
  lblBtnConectar.Caption := 'Conectar';
  lblBtnConectar.Font.Color := clWhite;
  lblBtnConectar.Font.Style := [fsBold];
  lblBtnConectar.Font.Size := 11;

  // BOTON LEER
  btnLeer := TPanel.Create(Self);
  btnLeer.Parent := pnlMain;
  btnLeer.SetBounds(560, 460, 120, 44);
  btnLeer.BevelOuter := bvNone;
  btnLeer.Color := CLR_PRIMARY;
  btnLeer.Cursor := crHandPoint;
  btnLeer.OnClick := @LeerClick;

  lblBtnLeer := TLabel.Create(Self);
  lblBtnLeer.Parent := btnLeer;
  lblBtnLeer.Align := alClient;
  lblBtnLeer.Alignment := taCenter;
  lblBtnLeer.Layout := tlCenter;
  lblBtnLeer.Caption := 'Leer peso';
  lblBtnLeer.Font.Color := clWhite;
  lblBtnLeer.Font.Style := [fsBold];
  lblBtnLeer.Font.Size := 11;

  // BOTON GUARDAR
  btnGuardar := TPanel.Create(Self);
  btnGuardar.Parent := pnlMain;
  btnGuardar.SetBounds(690, 460, 80, 44);
  btnGuardar.BevelOuter := bvNone;
  btnGuardar.Color := CLR_PRIMARY_DARK;
  btnGuardar.Cursor := crHandPoint;
  btnGuardar.OnClick := @GuardarClick;

  lblBtnGuardar := TLabel.Create(Self);
  lblBtnGuardar.Parent := btnGuardar;
  lblBtnGuardar.Align := alClient;
  lblBtnGuardar.Alignment := taCenter;
  lblBtnGuardar.Layout := tlCenter;
  lblBtnGuardar.Caption := 'Guardar';
  lblBtnGuardar.Font.Color := clWhite;
  lblBtnGuardar.Font.Style := [fsBold];
  lblBtnGuardar.Font.Size := 11;

  // =====================================================
  // TIMER LECTURA
  // =====================================================

  TimerLectura := TTimer.Create(Self);
  TimerLectura.Interval := 500;
  TimerLectura.Enabled := False;
  TimerLectura.OnTimer := @TimerLecturaTimer;

  // Cargar config guardada
  CargarConfiguracion;
end;

destructor TFrameConfigBalanza.Destroy;
begin
  if FConectado and (DM <> nil) then
    DM.DesconectarSerial;
  inherited Destroy;
end;

// ═══════════════════════════════════════════════
// CONFIGURACION
// ═══════════════════════════════════════════════

procedure TFrameConfigBalanza.CargarConfiguracion;
var Q: TSQLQuery;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;
  Q := DM.AbrirQuery(
    'SELECT puerto_com, baudrate, databits, paridad, stopbits, flowcontrol, ' +
    'timeout_ms, metodo_lectura, posicion_inicio, posicion_longitud ' +
    'FROM config_balanza ORDER BY id DESC LIMIT 1');
  try
    if Q.EOF then Exit;
    cbPuerto.Text := Q.Fields[0].AsString;
    cbBaudRate.Text := Q.Fields[1].AsString;
    cbDataBits.Text := Q.Fields[2].AsString;

    if Q.Fields[3].AsString = 'N' then cbParidad.Text := 'None (N)'
    else if Q.Fields[3].AsString = 'E' then cbParidad.Text := 'Even (E)'
    else if Q.Fields[3].AsString = 'O' then cbParidad.Text := 'Odd (O)';

    cbStopBits.Text := Q.Fields[4].AsString;
    cbFlow.Text := Q.Fields[5].AsString;
    edtTimeout.Text := Q.Fields[6].AsString;

    if Q.Fields[7].AsString = 'POSICION' then
    begin
      rbPosicion.Checked := True;
      edtInicio.Enabled := True;
      edtLongitud.Enabled := True;
    end
    else
    begin
      rbAuto.Checked := True;
      edtInicio.Enabled := False;
      edtLongitud.Enabled := False;
    end;

    edtInicio.Text := Q.Fields[8].AsString;
    edtLongitud.Text := Q.Fields[9].AsString;
  finally Q.Close; end;
end;

procedure TFrameConfigBalanza.GuardarConfiguracion;
var
  ParidadChar: string;
  Metodo: string;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  if cbParidad.Text = 'None (N)' then ParidadChar := 'N'
  else if cbParidad.Text = 'Even (E)' then ParidadChar := 'E'
  else ParidadChar := 'O';

  if rbAuto.Checked then Metodo := 'AUTO' else Metodo := 'POSICION';

  DM.EjecutarSQL(
    'INSERT INTO config_balanza (puerto_com, baudrate, databits, paridad, stopbits, ' +
    'flowcontrol, timeout_ms, metodo_lectura, posicion_inicio, posicion_longitud, ' +
    'usuario_modificacion, fecha_modificacion) VALUES (' +
    QuotedStr(cbPuerto.Text) + ', ' +
    cbBaudRate.Text + ', ' +
    cbDataBits.Text + ', ' +
    QuotedStr(ParidadChar) + ', ' +
    cbStopBits.Text + ', ' +
    QuotedStr(cbFlow.Text) + ', ' +
    edtTimeout.Text + ', ' +
    QuotedStr(Metodo) + ', ' +
    edtInicio.Text + ', ' +
    edtLongitud.Text + ', ' +
    IntToStr(UsuarioActual.ID) + ', ' +
    QuotedStr(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)) + ')');

  ShowMessage('Configuración guardada correctamente.');
end;

// ═══════════════════════════════════════════════
// SERIAL
// ═══════════════════════════════════════════════

procedure TFrameConfigBalanza.ConectarClick(Sender: TObject);
var
  ParidadChar: Char;
  Baud, Bits: Integer;
  SB: Integer;
  SBStr: string;
begin
  if FConectado then
  begin
    TimerLectura.Enabled := False;
    DM.DesconectarSerial;
    FConectado := False;
    lblBtnConectar.Caption := 'Conectar';
    btnConectar.Color := CLR_SUCCESS;
    LogDato('Desconectado del puerto ' + cbPuerto.Text);
    Exit;
  end;

  Baud := StrToIntDef(cbBaudRate.Text, 9600);
  Bits := StrToIntDef(cbDataBits.Text, 8);

  if cbParidad.Text = 'None (N)' then ParidadChar := 'N'
  else if cbParidad.Text = 'Even (E)' then ParidadChar := 'E'
  else ParidadChar := 'O';

  SBStr := cbStopBits.Text;
  if SBStr = '1.5' then SB := 3
  else if SBStr = '2' then SB := 2
  else SB := 1;

  if DM.ConectarSerial(cbPuerto.Text, Baud, Bits, ParidadChar, SB) then
  begin
    FConectado := True;
    lblBtnConectar.Caption := 'Desconectar';
    btnConectar.Color := CLR_DESTRUCTIVE;
    TimerLectura.Enabled := True;
    LogDato('Conectado a ' + cbPuerto.Text + ' ' + IntToStr(Baud) + '-' +
      IntToStr(Bits) + ParidadChar + '-' + SBStr);
  end
  else
  begin
    FConectado := False;
    LogDato('Error al conectar a ' + cbPuerto.Text);
    ShowMessage('No se pudo conectar al puerto ' + cbPuerto.Text);
  end;
end;

procedure TFrameConfigBalanza.LeerClick(Sender: TObject);
var
  Trama: string;
begin
  if not FConectado then
  begin
    MemoDatos.Lines.Add('[Simulación] ST,GS,+ 258' + IntToStr(60 + Random(20)) + ' kg');
    ActualizarPesoDetectado(MemoDatos.Lines[MemoDatos.Lines.Count - 1]);
    Exit;
  end;

  Trama := DM.LeerPuertoSerial;
  if Trama <> '' then
  begin
    LogDato(Trama);
    ActualizarPesoDetectado(Trama);
  end
  else
    LogDato('Sin datos en el buffer');
end;

procedure TFrameConfigBalanza.TimerLecturaTimer(Sender: TObject);
var
  Trama: string;
begin
  if not FConectado then Exit;
  if not DM.PuertoConectado then
  begin
    FConectado := False;
    TimerLectura.Enabled := False;
    lblBtnConectar.Caption := 'Conectar';
    btnConectar.Color := CLR_SUCCESS;
    LogDato('Puerto desconectado inesperadamente');
    Exit;
  end;

  Trama := DM.LeerPuertoSerial;
  if Trama <> '' then
  begin
    LogDato(Trama);
    ActualizarPesoDetectado(Trama);
  end;
end;

// ═══════════════════════════════════════════════
// EXTRACCION DE PESO
// ═══════════════════════════════════════════════

function TFrameConfigBalanza.ExtraerPesoAuto(const Trama: string): string;
var
  i: Integer;
  NumStr: string;
begin
  Result := '';
  NumStr := '';
  for i := 1 to Length(Trama) do
    if Trama[i] in ['0'..'9'] then
      NumStr := NumStr + Trama[i]
    else if NumStr <> '' then
    begin
      if Length(NumStr) >= 4 then
      begin
        Result := NumStr;
        Exit;
      end;
      NumStr := '';
    end;

  if (Result = '') and (Length(NumStr) >= 4) then
    Result := NumStr;
end;

function TFrameConfigBalanza.ExtraerPesoPosicion(const Trama: string): string;
var
  Inicio, Long: Integer;
begin
  Inicio := StrToIntDef(edtInicio.Text, 8);
  Long := StrToIntDef(edtLongitud.Text, 5);
  Result := '';
  if (Inicio > 0) and (Inicio + Long - 1 <= Length(Trama)) then
    Result := Trim(Copy(Trama, Inicio, Long));
end;

procedure TFrameConfigBalanza.ActualizarPesoDetectado(const Trama: string);
var
  PesoExtraido: string;
begin
  if rbAuto.Checked then
    PesoExtraido := ExtraerPesoAuto(Trama)
  else
    PesoExtraido := ExtraerPesoPosicion(Trama);

  if PesoExtraido <> '' then
  begin
    FPesoDetectado := PesoExtraido;
    lblPeso.Caption := PesoExtraido + ' kg';
  end;
end;

// ═══════════════════════════════════════════════
// UI HELPERS
// ═══════════════════════════════════════════════

procedure TFrameConfigBalanza.LogDato(const Texto: string);
begin
  MemoDatos.Lines.Add(Trim(Texto));
  if MemoDatos.Lines.Count > 100 then
    while MemoDatos.Lines.Count > 50 do
      MemoDatos.Lines.Delete(0);
end;

procedure TFrameConfigBalanza.MetodoLecturaChange(Sender: TObject);
begin
  edtInicio.Enabled := rbPosicion.Checked;
  edtLongitud.Enabled := rbPosicion.Checked;
end;

procedure TFrameConfigBalanza.PosicionChange(Sender: TObject);
var
  Trama, Peso: string;
begin
  if MemoDatos.Lines.Count = 0 then Exit;
  Trama := MemoDatos.Lines[MemoDatos.Lines.Count - 1];
  Peso := ExtraerPesoPosicion(Trama);
  if Peso <> '' then
    lblPeso.Caption := Peso + ' kg';
end;

procedure TFrameConfigBalanza.GuardarClick(Sender: TObject);
begin
  GuardarConfiguracion;
end;

end.
