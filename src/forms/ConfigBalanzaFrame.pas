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
    edtTimeout, edtInicio, edtLongitud: TEdit;
    MemoDatos: TMemo;
    rbAuto, rbPosicion: TRadioButton;
    pnlPeso: TPanel;
    lblPeso: TLabel;
    btnConectar, btnLeer, btnGuardar: TPanel;
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
    procedure PaintRounded(Sender: TObject);
    procedure PaintPesoDisplay(Sender: TObject);

    function CrearBoton(AParent: TPanel; ATop, ALeft, AW, AH: Integer; const ACaption: string;
      AColor: TColor; AFontColor: TColor; ATag: Integer; AClick: TNotifyEvent): TPanel;
    function BtnLabel(ABtn: TPanel): TLabel;

    function ExtraerPesoAuto(const Trama: string): string;
    function ExtraerPesoPosicion(const Trama: string): string;
    procedure ActualizarPesoDetectado(const Trama: string);
    procedure LogDato(const Texto: string);
  public
    destructor Destroy; override;
  end;

implementation

{$R *.lfm}

function TFrameConfigBalanza.BtnLabel(ABtn: TPanel): TLabel;
begin
  if (ABtn <> nil) and (ABtn.ControlCount > 0) and (ABtn.Controls[0] is TLabel) then
    Result := TLabel(ABtn.Controls[0])
  else
    Result := nil;
end;

constructor TFrameConfigBalanza.Create(AOwner: TComponent);
var
  Lbl: TLabel;
  Sep, poOuter, poInner: TPanel;
  YPos: Integer;
const
  PAD = 24;
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

  pnlMain := TPanel.Create(Self);
  pnlMain.Parent := Self;
  pnlMain.Align := alClient;
  pnlMain.BorderSpacing.Left := PAD;
  pnlMain.BorderSpacing.Right := PAD;
  pnlMain.BorderSpacing.Top := PAD;
  pnlMain.BorderSpacing.Bottom := PAD;
  pnlMain.BevelOuter := bvLowered;
  pnlMain.BevelInner := bvNone;
  pnlMain.BevelWidth := 1;
  pnlMain.Color := CLR_CARD;

  // ── Título ──
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Configuración balanza RS232';
  Lbl.Font.Size := 16;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(PAD, 20, 400, 30);

  Sep := TPanel.Create(Self);
  Sep.Parent := pnlMain;
  Sep.SetBounds(PAD, 58, 740, 1);
  Sep.BevelOuter := bvNone;
  Sep.Color := CLR_BORDER;

  // ── Config serial ──
  YPos := 80;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Puerto COM';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL1, YPos, 120, 16);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'BaudRate';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL2, YPos, 120, 16);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'DataBits';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL3, YPos, 120, 16);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Paridad';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL4, YPos, 120, 16);
  YPos := YPos + 22;

  cbPuerto := TComboBox.Create(Self);
  cbPuerto.Parent := pnlMain;
  cbPuerto.SetBounds(COL1, YPos, COMBO_W, 40);
  cbPuerto.AutoSize := False;
  cbPuerto.Style := csDropDownList;
  cbPuerto.Font.Size := 12;
  cbPuerto.Color := CLR_WHITE;
  cbPuerto.Items.Add('COM1');
  cbPuerto.Items.Add('COM2');
  cbPuerto.Items.Add('COM3');
  cbPuerto.Items.Add('COM4');
  cbPuerto.Items.Add('COM5');
  cbPuerto.Items.Add('COM6');
  cbPuerto.Text := 'COM3';

  cbBaudRate := TComboBox.Create(Self);
  cbBaudRate.Parent := pnlMain;
  cbBaudRate.SetBounds(COL2, YPos, COMBO_W, 40);
  cbBaudRate.AutoSize := False;
  cbBaudRate.Style := csDropDownList;
  cbBaudRate.Font.Size := 12;
  cbBaudRate.Color := CLR_WHITE;
  cbBaudRate.Items.Add('1200');
  cbBaudRate.Items.Add('2400');
  cbBaudRate.Items.Add('4800');
  cbBaudRate.Items.Add('9600');
  cbBaudRate.Items.Add('19200');
  cbBaudRate.Items.Add('38400');
  cbBaudRate.Text := '9600';

  cbDataBits := TComboBox.Create(Self);
  cbDataBits.Parent := pnlMain;
  cbDataBits.SetBounds(COL3, YPos, 120, 40);
  cbDataBits.AutoSize := False;
  cbDataBits.Style := csDropDownList;
  cbDataBits.Font.Size := 12;
  cbDataBits.Color := CLR_WHITE;
  cbDataBits.Items.Add('5');
  cbDataBits.Items.Add('6');
  cbDataBits.Items.Add('7');
  cbDataBits.Items.Add('8');
  cbDataBits.Text := '8';

  cbParidad := TComboBox.Create(Self);
  cbParidad.Parent := pnlMain;
  cbParidad.SetBounds(COL4, YPos, 140, 40);
  cbParidad.AutoSize := False;
  cbParidad.Style := csDropDownList;
  cbParidad.Font.Size := 12;
  cbParidad.Color := CLR_WHITE;
  cbParidad.Items.Add('None (N)');
  cbParidad.Items.Add('Even (E)');
  cbParidad.Items.Add('Odd (O)');
  cbParidad.Text := 'None (N)';
  YPos := YPos + 58;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'StopBits';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL1, YPos, 120, 16);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'FlowControl';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL2, YPos, 120, 16);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Timeout (ms)';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL3, YPos, 120, 16);
  YPos := YPos + 22;

  cbStopBits := TComboBox.Create(Self);
  cbStopBits.Parent := pnlMain;
  cbStopBits.SetBounds(COL1, YPos, COMBO_W, 40);
  cbStopBits.AutoSize := False;
  cbStopBits.Style := csDropDownList;
  cbStopBits.Font.Size := 12;
  cbStopBits.Color := CLR_WHITE;
  cbStopBits.Items.Add('1');
  cbStopBits.Items.Add('1.5');
  cbStopBits.Items.Add('2');
  cbStopBits.Text := '1';

  cbFlow := TComboBox.Create(Self);
  cbFlow.Parent := pnlMain;
  cbFlow.SetBounds(COL2, YPos, COMBO_W, 40);
  cbFlow.AutoSize := False;
  cbFlow.Style := csDropDownList;
  cbFlow.Font.Size := 12;
  cbFlow.Color := CLR_WHITE;
  cbFlow.Items.Add('None');
  cbFlow.Items.Add('RTS/CTS');
  cbFlow.Items.Add('XON/XOFF');
  cbFlow.Text := 'None';

  poOuter := TPanel.Create(Self);
  poOuter.Parent := pnlMain;
  poOuter.SetBounds(COL3, YPos, 120, 40);
  poOuter.BevelOuter := bvNone;
  poOuter.Color := CLR_BORDER;
  poInner := TPanel.Create(poOuter);
  poInner.Parent := poOuter;
  poInner.SetBounds(1, 1, 118, 38);
  poInner.BevelOuter := bvNone;
  poInner.Color := CLR_WHITE;
  poInner.BorderWidth := 6;
  edtTimeout := TEdit.Create(poInner);
  edtTimeout.Parent := poInner;
  edtTimeout.Align := alClient;
  edtTimeout.BorderStyle := bsNone;
  edtTimeout.Font.Size := 11;
  edtTimeout.Color := CLR_WHITE;
  edtTimeout.Text := '1000';
  YPos := YPos + 58;

  Sep := TPanel.Create(Self);
  Sep.Parent := pnlMain;
  Sep.SetBounds(PAD, YPos, 740, 1);
  Sep.BevelOuter := bvNone;
  Sep.Color := CLR_BORDER;
  YPos := YPos + 20;

  // ── Datos recibidos ──
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Datos recibidos desde balanza';
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(PAD, YPos, 320, 20);
  YPos := YPos + 28;

  poOuter := TPanel.Create(Self);
  poOuter.Parent := pnlMain;
  poOuter.SetBounds(PAD, YPos, 360, 120);
  poOuter.BevelOuter := bvNone;
  poOuter.Color := CLR_BORDER;
  poInner := TPanel.Create(poOuter);
  poInner.Parent := poOuter;
  poInner.SetBounds(1, 1, 358, 118);
  poInner.BevelOuter := bvNone;
  poInner.Color := CLR_WHITE;
  poInner.BorderWidth := 4;
  MemoDatos := TMemo.Create(poInner);
  MemoDatos.Parent := poInner;
  MemoDatos.Align := alClient;
  MemoDatos.BorderStyle := bsNone;
  MemoDatos.ScrollBars := ssVertical;
  MemoDatos.ReadOnly := True;
  MemoDatos.Font.Name := 'Monaco';
  MemoDatos.Font.Size := 10;
  MemoDatos.Font.Color := CLR_TEXT;
  MemoDatos.Color := CLR_WHITE;

  // ── Método de lectura ──
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Método de lectura';
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(420, YPos - 28, 220, 20);

  rbAuto := TRadioButton.Create(Self);
  rbAuto.Parent := pnlMain;
  rbAuto.Caption := 'Extraer números automáticamente';
  rbAuto.SetBounds(420, YPos + 5, 300, 24);
  rbAuto.Checked := True;
  rbAuto.Font.Size := 11;
  rbAuto.Font.Color := CLR_TEXT;
  rbAuto.OnClick := @MetodoLecturaChange;

  rbPosicion := TRadioButton.Create(Self);
  rbPosicion.Parent := pnlMain;
  rbPosicion.Caption := 'Usar posición fija';
  rbPosicion.SetBounds(420, YPos + 35, 200, 24);
  rbPosicion.Font.Size := 11;
  rbPosicion.Font.Color := CLR_TEXT;
  rbPosicion.OnClick := @MetodoLecturaChange;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Inicio';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(COL5, YPos + 70, 60, 16);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Longitud';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.SetBounds(540, YPos + 70, 80, 16);

  poOuter := TPanel.Create(Self);
  poOuter.Parent := pnlMain;
  poOuter.SetBounds(COL5, YPos + 92, 80, 40);
  poOuter.BevelOuter := bvNone;
  poOuter.Color := CLR_BORDER;
  poInner := TPanel.Create(poOuter);
  poInner.Parent := poOuter;
  poInner.SetBounds(1, 1, 78, 38);
  poInner.BevelOuter := bvNone;
  poInner.Color := CLR_WHITE;
  poInner.BorderWidth := 6;
  edtInicio := TEdit.Create(poInner);
  edtInicio.Parent := poInner;
  edtInicio.Align := alClient;
  edtInicio.BorderStyle := bsNone;
  edtInicio.Font.Size := 11;
  edtInicio.Color := CLR_WHITE;
  edtInicio.Text := '8';
  edtInicio.OnChange := @PosicionChange;

  poOuter := TPanel.Create(Self);
  poOuter.Parent := pnlMain;
  poOuter.SetBounds(540, YPos + 92, 80, 40);
  poOuter.BevelOuter := bvNone;
  poOuter.Color := CLR_BORDER;
  poInner := TPanel.Create(poOuter);
  poInner.Parent := poOuter;
  poInner.SetBounds(1, 1, 78, 38);
  poInner.BevelOuter := bvNone;
  poInner.Color := CLR_WHITE;
  poInner.BorderWidth := 6;
  edtLongitud := TEdit.Create(poInner);
  edtLongitud.Parent := poInner;
  edtLongitud.Align := alClient;
  edtLongitud.BorderStyle := bsNone;
  edtLongitud.Font.Size := 11;
  edtLongitud.Color := CLR_WHITE;
  edtLongitud.Text := '5';
  edtLongitud.OnChange := @PosicionChange;

  YPos := YPos + 150;

  // ── Peso detectado ──
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlMain;
  Lbl.Caption := 'Peso detectado';
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.SetBounds(PAD, YPos, 200, 20);
  YPos := YPos + 28;

  pnlPeso := TPanel.Create(Self);
  pnlPeso.Parent := pnlMain;
  pnlPeso.SetBounds(PAD, YPos, 300, 60);
  pnlPeso.BevelOuter := bvNone;
  pnlPeso.Color := CLR_PRIMARY;
  pnlPeso.OnPaint := @PaintPesoDisplay;

  lblPeso := TLabel.Create(Self);
  lblPeso.Parent := pnlPeso;
  lblPeso.Align := alClient;
  lblPeso.Alignment := taCenter;
  lblPeso.Layout := tlCenter;
  lblPeso.Caption := '0 kg';
  lblPeso.Font.Size := 22;
  lblPeso.Font.Style := [fsBold];
  lblPeso.Font.Color := CLR_WHITE;
  lblPeso.Transparent := True;

  // ── Botones ──
  btnConectar := CrearBoton(pnlMain, YPos, 420, 120, 40, 'Conectar', CLR_PRIMARY, CLR_WHITE, 0, @ConectarClick);
  btnLeer := CrearBoton(pnlMain, YPos, 550, 120, 40, 'Leer peso', CLR_PRIMARY, CLR_WHITE, 0, @LeerClick);
  btnGuardar := CrearBoton(pnlMain, YPos, 680, 100, 40, 'Guardar', CLR_PRIMARY_DARK, CLR_WHITE, 0, @GuardarClick);

  TimerLectura := TTimer.Create(Self);
  TimerLectura.Interval := 500;
  TimerLectura.Enabled := False;
  TimerLectura.OnTimer := @TimerLecturaTimer;

  CargarConfiguracion;
end;

destructor TFrameConfigBalanza.Destroy;
begin
  if FConectado and (DM <> nil) then
    DM.DesconectarSerial;
  inherited Destroy;
end;

function TFrameConfigBalanza.CrearBoton(AParent: TPanel; ATop, ALeft, AW, AH: Integer;
  const ACaption: string; AColor: TColor; AFontColor: TColor; ATag: Integer;
  AClick: TNotifyEvent): TPanel;
var
  Lbl: TLabel;
begin
  Result := TPanel.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AW, AH);
  Result.BevelOuter := bvNone;
  Result.Color := AColor;
  Result.Tag := ATag;
  Result.Cursor := crHandPoint;
  Result.OnClick := AClick;
  Result.OnPaint := @PaintRounded;
  Result.ParentBackground := False;
  Result.ParentColor := False;

  Lbl := TLabel.Create(Result);
  Lbl.Parent := Result;
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Caption := ACaption;
  Lbl.Font.Size := 12;
  Lbl.Font.Style := [];
  Lbl.Font.Color := AFontColor;
  Lbl.Transparent := True;
  Lbl.OnClick := AClick;
end;

procedure TFrameConfigBalanza.PaintRounded(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  if Pnl.Tag = 1 then
  begin
    Pnl.Canvas.Pen.Color := CLR_INFO;
    Pnl.Canvas.Pen.Width := 1;
    Pnl.Canvas.RoundRect(1, 1, Pnl.Width - 1, Pnl.Height - 1, 8, 8);
  end
  else
  begin
    Pnl.Canvas.Pen.Style := psClear;
    Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
  end;
end;

procedure TFrameConfigBalanza.PaintPesoDisplay(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := CLR_PRIMARY;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
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
  LblBtn: TLabel;
begin
  LblBtn := BtnLabel(btnConectar);
  if FConectado then
  begin
    TimerLectura.Enabled := False;
    DM.DesconectarSerial;
    FConectado := False;
    if LblBtn <> nil then LblBtn.Caption := 'Conectar';
    btnConectar.Color := CLR_PRIMARY;
    btnConectar.Invalidate;
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
    if LblBtn <> nil then LblBtn.Caption := 'Desconectar';
    btnConectar.Color := CLR_DESTRUCTIVE;
    btnConectar.Invalidate;
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
  LblBtn: TLabel;
begin
  if not FConectado then Exit;
  if not DM.PuertoConectado then
  begin
    FConectado := False;
    TimerLectura.Enabled := False;
    LblBtn := BtnLabel(btnConectar);
    if LblBtn <> nil then LblBtn.Caption := 'Conectar';
    btnConectar.Color := CLR_PRIMARY;
    btnConectar.Invalidate;
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
