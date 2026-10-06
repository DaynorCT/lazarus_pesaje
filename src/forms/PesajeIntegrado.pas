unit PesajeIntegrado;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, sqldb, DataModule, Theme, LoginForm, SyncService, LMessages,
  ConfigBalanzaFrame, AppDialog;

type
  { TfrmPesajeIntegrado }

  TfrmPesajeIntegrado = class(TForm)
  published
    pnlTop, pnlContent, pnlMedio, pnlRegistroCard, pnlRegistro: TPanel;
    pnlDisplay, pnlSep1, pnlSep2: TPanel;
    pnlCapturarPeso: TPanel;
    pnlEnviar: TPanel;
    btnSwitchConectar: TPanel;
    btnSincronizar: TButton;
    btnEngranaje: TPanel;
    lblTitulo, lblPesoDisplay, lblRegistroTitle: TLabel;
    lblConexion, lblPesoCapturado, lblEstado: TLabel;
    TimerLectura, TimerEstado: TTimer;
    procedure PaintRounded(Sender: TObject);
    procedure PaintConnectButton(Sender: TObject);
    procedure PaintGearButton(Sender: TObject);
    procedure PaintCaptureButton(Sender: TObject);
    procedure PaintSendButton(Sender: TObject);
    procedure SwitchConectarClick(Sender: TObject);
    procedure CapturarPesoClick(Sender: TObject);
    procedure EnviarPesoClick(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
    procedure TimerEstadoTimer(Sender: TObject);
    procedure SincronizarClick(Sender: TObject);
    procedure EngranajeClick(Sender: TObject);
    procedure ContentClick(Sender: TObject);
    procedure FormShowHandler(Sender: TObject);
    procedure FormResize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  protected
    procedure WMCloseQuery(var Message: TLMessage); message LM_CLOSEQUERY;
  private
    FConectado: Boolean;
    FMetodoLectura: string;
    FPosInicio: Integer;
    FPosLongitud: Integer;
    FModoPrueba: Boolean;
    FPesoCapturado: Integer;

    FMenuEngranaje: TPanel;

    procedure MenuEngranajePaint(Sender: TObject);
    procedure ProcesarTrama(const Trama: string);
    function ExtraerPeso(const Trama: string): string;
    procedure MenuSistemaCompletoClick(Sender: TObject);
    procedure MenuConfigurarBalanzaClick(Sender: TObject);
    procedure MenuSalirClick(Sender: TObject);
    procedure CerrarMenuEngranaje;
    procedure ActualizarEstadoSync;
    procedure AjustarLayout;
  end;

var
  frmPesajeIntegrado: TfrmPesajeIntegrado;

implementation

{$R *.lfm}

const
  CREG_W   = 420;
  CREG_PAD = 20;

function PesoDesdeDisplay(const ACaption: string): Integer;
var
  S: string;
begin
  S := Trim(ACaption);
  if EndsText(' kg', S) then
    Delete(S, Length(S) - 2, 3);
  Result := StrToIntDef(S, 0);
end;

// ══════════════════════════════════════════════════════════════════
// Constructor
// ══════════════════════════════════════════════════════════════════

constructor TfrmPesajeIntegrado.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Randomize;
  FConectado := False;
  FMetodoLectura := 'AUTO';
  FPosInicio := 8;
  FPosLongitud := 5;
  FModoPrueba := False;
  FPesoCapturado := 0;

  FMenuEngranaje := TPanel.Create(Self);
  FMenuEngranaje.Parent := Self;
  FMenuEngranaje.Visible := False;
  FMenuEngranaje.Color := CLR_CARD;
  FMenuEngranaje.BevelOuter := bvNone;
  FMenuEngranaje.BorderStyle := bsNone;
  FMenuEngranaje.ParentBackground := False;
  FMenuEngranaje.ParentColor := False;
  FMenuEngranaje.OnPaint := @MenuEngranajePaint;
  FMenuEngranaje.SetBounds(0, 0, 250, 158);

  OnShow := @FormShowHandler;
  OnResize := @FormResize;

  ActualizarEstadoSync;
  AjustarLayout;
end;

destructor TfrmPesajeIntegrado.Destroy;
begin
  TimerLectura.Enabled := False;
  TimerEstado.Enabled := False;
  if FConectado and (DM <> nil) then
    DM.DesconectarSerial;
  inherited Destroy;
end;

// ══════════════════════════════════════════════════════════════════
// UI helpers
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.PaintRounded(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  if Pnl = pnlRegistroCard then
  begin
    Pnl.Canvas.Brush.Color := CLR_CARD;
    Pnl.Canvas.Brush.Style := bsSolid;
    Pnl.Canvas.FillRect(Pnl.ClientRect);
    Pnl.Canvas.Pen.Color := CLR_WHITE;
    Pnl.Canvas.Pen.Width := 1;
    Pnl.Canvas.Pen.Style := psSolid;
    Pnl.Canvas.Rectangle(0, 0, Pnl.Width, Pnl.Height);
    Exit;
  end;
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  if Pnl.Tag = 1 then
  begin
    Pnl.Canvas.Pen.Color := CLR_INFO;
    Pnl.Canvas.Pen.Width := 1;
    Pnl.Canvas.Pen.Style := psSolid;
    Pnl.Canvas.RoundRect(1, 1, Pnl.Width - 1, Pnl.Height - 1, 8, 8);
  end
  else
  begin
    Pnl.Canvas.Pen.Style := psClear;
    Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
  end;
end;

procedure TfrmPesajeIntegrado.PaintConnectButton(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Style := bsSolid;
  Pnl.Canvas.Brush.Color := CLR_SUCCESS;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
  Pnl.Canvas.Font.Assign(Pnl.Font);
  Pnl.Canvas.Font.Color := CLR_WHITE;
  Pnl.Canvas.Brush.Style := bsClear;
  Ts := Pnl.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, Pnl.Caption, Ts);
end;

procedure TfrmPesajeIntegrado.PaintGearButton(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Font.Assign(Pnl.Font);
  Pnl.Canvas.Font.Color := CLR_SUCCESS;
  Pnl.Canvas.Brush.Style := bsClear;
  Ts := Pnl.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, Pnl.Caption, Ts);
end;

procedure TfrmPesajeIntegrado.PaintCaptureButton(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Style := bsSolid;
  if Pnl.Enabled then
  begin
    Pnl.Canvas.Brush.Color := CLR_INFO;
    Pnl.Canvas.Font.Color := CLR_WHITE;
  end
  else
  begin
    Pnl.Canvas.Brush.Color := CLR_CARD;
    Pnl.Canvas.Font.Color := CLR_TEXT_MUTED;
  end;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
  Pnl.Canvas.Font.Assign(Pnl.Font);
  if Pnl.Enabled then
    Pnl.Canvas.Font.Color := CLR_WHITE
  else
    Pnl.Canvas.Font.Color := CLR_TEXT_MUTED;
  Pnl.Canvas.Brush.Style := bsClear;
  Ts := Pnl.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, Pnl.Caption, Ts);
end;

procedure TfrmPesajeIntegrado.PaintSendButton(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Style := bsSolid;
  if Pnl.Enabled then
  begin
    Pnl.Canvas.Brush.Color := CLR_PRIMARY;
    Pnl.Canvas.Font.Color := CLR_WHITE;
  end
  else
  begin
    Pnl.Canvas.Brush.Color := CLR_CARD;
    Pnl.Canvas.Font.Color := CLR_TEXT_MUTED;
  end;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
  Pnl.Canvas.Font.Assign(Pnl.Font);
  if Pnl.Enabled then
    Pnl.Canvas.Font.Color := CLR_WHITE
  else
    Pnl.Canvas.Font.Color := CLR_TEXT_MUTED;
  Pnl.Canvas.Brush.Style := bsClear;
  Ts := Pnl.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, Pnl.Caption, Ts);
end;

procedure TfrmPesajeIntegrado.FormShowHandler(Sender: TObject);
begin
  if btnEngranaje <> nil then
  begin
    btnEngranaje.Caption := FAIconoStr(FA_COG, '⚙');
    btnEngranaje.Font.Name := FAFuente;
    btnEngranaje.Font.Size := 18;
  end;
  if SyncSvc <> nil then
  begin
    Screen.Cursor := crHourGlass;
    try
      SyncSvc.SincronizarAhora;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
  ActualizarEstadoSync;
end;

procedure TfrmPesajeIntegrado.FormResize(Sender: TObject);
begin
  AjustarLayout;
end;

procedure TfrmPesajeIntegrado.AjustarLayout;
const
  CARD_W = 460;
  CARD_H = 380;
  DISP_H = 120;
  ROW_H  = 40;
var
  W, H, P, Gap, InnerW, YPos, BtnW, RowY: Integer;
begin
  if (pnlMedio = nil) or (pnlRegistroCard = nil) or (pnlRegistro = nil) then Exit;

  W := pnlMedio.ClientWidth;
  H := pnlMedio.ClientHeight;
  if (W < CARD_W) or (H < CARD_H) then Exit;

  // Card compacta y centrada (no llena la ventana)
  pnlRegistroCard.SetBounds((W - CARD_W) div 2, (H - CARD_H) div 2, CARD_W, CARD_H);

  P := 24;
  Gap := 10;
  InnerW := CARD_W - P * 2;

  // ── Titulo ──
  YPos := 12;
  if lblRegistroTitle <> nil then
  begin
    lblRegistroTitle.SetBounds(P, YPos, InnerW, 24);
    lblRegistroTitle.Font.Size := 12;
    YPos := YPos + 24 + 8;
  end;
  if pnlSep1 <> nil then begin pnlSep1.SetBounds(P, YPos, InnerW, 1); YPos := YPos + 10; end;

  // ── Display ──
  if pnlDisplay <> nil then
  begin
    pnlDisplay.SetBounds(P, YPos, InnerW, DISP_H);
    if pnlDisplay.ControlCount > 0 then
      TPanel(pnlDisplay.Controls[0]).SetBounds(2, 2, InnerW - 4, DISP_H - 4);
    if lblPesoDisplay <> nil then
      lblPesoDisplay.Font.Height := -42;
    YPos := YPos + DISP_H + 12;
  end;
  if pnlSep2 <> nil then begin pnlSep2.SetBounds(P, YPos, InnerW, 1); YPos := YPos + 10; end;

  // ── Fila conexion: switch + boton Capturar peso ──
  RowY := YPos;
  if btnSwitchConectar <> nil then
    btnSwitchConectar.SetBounds(P, RowY, 112, ROW_H);
  if lblConexion <> nil then
  begin
    lblConexion.SetBounds(P, RowY + ROW_H, 112, 14);
    lblConexion.Font.Size := 9;
  end;
  BtnW := InnerW - 112 - Gap;
  if pnlCapturarPeso <> nil then
    pnlCapturarPeso.SetBounds(P + 112 + Gap, RowY, BtnW, ROW_H);
  YPos := RowY + ROW_H + 10;

  // ── Peso capturado ──
  if lblPesoCapturado <> nil then
  begin
    lblPesoCapturado.SetBounds(P, YPos, InnerW, 18);
    lblPesoCapturado.Font.Size := 10;
    YPos := YPos + 22;
  end;

  // ── Boton Enviar a la web ──
  if pnlEnviar <> nil then
    pnlEnviar.SetBounds(P, YPos, InnerW, 46);
end;

// ══════════════════════════════════════════════════════════════════
// Estado de sincronización
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.ActualizarEstadoSync;
var
  Texto: string;
begin
  if SyncSvc = nil then Exit;
  if SyncSvc.Conectado then
  begin
    lblEstado.Font.Color := CLR_SUCCESS;
    Texto := FAIconoStr(FA_CHECK, '●') + ' Conectado';
  end
  else
  begin
    lblEstado.Font.Color := CLR_DESTRUCTIVE;
    Texto := FAIconoStr(FA_TIMES, '○') + ' Sin conexion';
  end;

  Texto := Texto + '   Pendientes: ' + IntToStr(SyncSvc.Pendientes);

  if SyncSvc.UltimaSync <> '' then
    Texto := Texto + '   Ultima: ' + Copy(SyncSvc.UltimaSync, 12, 5);

  if SyncSvc.UltimoError <> '' then
    Texto := Texto + '   ' + SyncSvc.UltimoError;

  lblEstado.Caption := Texto;
end;

procedure TfrmPesajeIntegrado.TimerEstadoTimer(Sender: TObject);
begin
  ActualizarEstadoSync;
end;

procedure TfrmPesajeIntegrado.SincronizarClick(Sender: TObject);
begin
  if SyncSvc = nil then Exit;
  Screen.Cursor := crHourGlass;
  try
    SyncSvc.SincronizarAhora;
  finally
    Screen.Cursor := crDefault;
  end;
  ActualizarEstadoSync;
end;

procedure TfrmPesajeIntegrado.EngranajeClick(Sender: TObject);
var
  YPos: Integer;

  procedure CrearItem(const ACaption: string; AClick: TNotifyEvent);
  var
    Btn: TButton;
  begin
    Btn := TButton.Create(FMenuEngranaje);
    Btn.Parent := FMenuEngranaje;
    Btn.SetBounds(8, YPos, FMenuEngranaje.Width - 16, 36);
    Btn.Caption := ACaption;
    Btn.Font.Color := CLR_TEXT;
    Btn.OnClick := AClick;
    YPos := YPos + 40;
  end;

  procedure CrearSeparador;
  var
    Sep: TPanel;
  begin
    Sep := TPanel.Create(FMenuEngranaje);
    Sep.Parent := FMenuEngranaje;
    Sep.SetBounds(16, YPos, FMenuEngranaje.Width - 32, 1);
    Sep.Color := CLR_BORDER;
    Sep.BevelOuter := bvNone;
    YPos := YPos + 8;
  end;

begin
  if FMenuEngranaje.Visible then
  begin
    CerrarMenuEngranaje;
    Exit;
  end;

  FMenuEngranaje.DestroyComponents;
  FMenuEngranaje.Left := btnEngranaje.Left + btnEngranaje.Width - FMenuEngranaje.Width;
  FMenuEngranaje.Top := pnlTop.Height + 2;
  YPos := 8;

  CrearItem('Sistema escritorio', @MenuSistemaCompletoClick);
  CrearSeparador;
  CrearItem('Configurar balanza', @MenuConfigurarBalanzaClick);
  CrearSeparador;
  CrearItem('Cerrar sesion', @MenuSalirClick);

  FMenuEngranaje.BringToFront;
  FMenuEngranaje.Invalidate;
  FMenuEngranaje.Visible := True;
end;

procedure TfrmPesajeIntegrado.MenuEngranajePaint(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.Pen.Color := CLR_BORDER;
  Pnl.Canvas.Pen.Width := 1;
  Pnl.Canvas.Pen.Style := psSolid;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width - 1, Pnl.Height - 1, 10, 10);
end;

procedure TfrmPesajeIntegrado.CerrarMenuEngranaje;
begin
  if FMenuEngranaje <> nil then
    FMenuEngranaje.Visible := False;
end;

procedure TfrmPesajeIntegrado.ContentClick(Sender: TObject);
begin
  CerrarMenuEngranaje;
end;

procedure TfrmPesajeIntegrado.MenuSistemaCompletoClick(Sender: TObject);
begin
  CerrarMenuEngranaje;
  if ConfirmarContrasenaActual('Acceso al sistema completo') then
  begin
    ModalResult := mrYes;
  end;
end;

procedure TfrmPesajeIntegrado.MenuConfigurarBalanzaClick(Sender: TObject);
var
  F: TForm;
  Frame: TFrameConfigBalanza;
begin
  CerrarMenuEngranaje;
  F := TForm.Create(nil);
  try
    F.Caption := 'Configuracion balanza RS232';
    F.Width := 900;
    F.Height := 700;
    F.Position := poMainFormCenter;
    F.BorderStyle := bsDialog;
    F.Color := CLR_BG;
    Frame := TFrameConfigBalanza.Create(F);
    Frame.Parent := F;
    Frame.Align := alClient;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmPesajeIntegrado.MenuSalirClick(Sender: TObject);
begin
  CerrarMenuEngranaje;
  if ConfirmarDialogo('Cerrar sesion', 'Seguro que desea cerrar sesion?') then
  begin
    ModalResult := mrCancel;
  end;
end;

// Cerrar con la X del modulo pesaje → cerrar el programa
procedure TfrmPesajeIntegrado.WMCloseQuery(var Message: TLMessage);
begin
  ModalResult := mrAbort;
  Message.Result := 0;
end;

// ══════════════════════════════════════════════════════════════════
// Balanza (lectura real del puerto configurado en config_balanza)
//
// NOTA: La balanza fisica aun no esta disponible. Mientras tanto este
// modulo queda operativo en MODO PRUEBA (pesos simulados). Cuando
// llegue la maquina real, probar la lectura por puerto serie
// (DM.LeerPuertoSerial) con la trama real y quitar/ajustar la
// simulacion marcada con "MODO PRUEBA" en SwitchConectarClick y
// TimerLecturaTimer.
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.SwitchConectarClick(Sender: TObject);
var
  Q: TSQLQuery;
  Puerto: string;
  Baud, Bits, Stop: Integer;
  ParidadChar: Char;
begin
  if FConectado then
  begin
    TimerLectura.Enabled := False;
    DM.DesconectarSerial;
    FConectado := False;
    FModoPrueba := False;
    pnlCapturarPeso.Enabled := False;
    btnSwitchConectar.Caption := 'Conectar';
    if lblConexion <> nil then lblConexion.Caption := 'Desconectada';
    if SyncSvc <> nil then SyncSvc.EnviarPesoVivo(0);
    Exit;
  end;

  Q := DM.AbrirQuery(
    'SELECT puerto_com, baudrate, databits, paridad, stopbits, metodo_lectura, posicion_inicio, posicion_longitud ' +
    'FROM config_balanza ORDER BY id DESC LIMIT 1');
  try
    if Q.EOF then
    begin
      // MODO PRUEBA: no hay balanza configurada, activamos simulacion
      FConectado := True;
      FModoPrueba := True;
      pnlCapturarPeso.Enabled := True;
      TimerLectura.Enabled := True;
      btnSwitchConectar.Caption := 'Desconectar';
      if lblConexion <> nil then lblConexion.Caption := 'Modo prueba';
      MostrarInfoDialogo('Balanza', 'No hay balanza configurada. Se activa MODO PRUEBA con pesos simulados.');
      Exit;
    end;
    Puerto := Q.Fields[0].AsString;
    Baud := Q.Fields[1].AsInteger;
    Bits := Q.Fields[2].AsInteger;
    if Q.Fields[3].AsString = 'E' then ParidadChar := 'E'
    else if Q.Fields[3].AsString = 'O' then ParidadChar := 'O'
    else ParidadChar := 'N';
    Stop := Q.Fields[4].AsInteger;
    FMetodoLectura := Q.Fields[5].AsString;
    FPosInicio := Q.Fields[6].AsInteger;
    FPosLongitud := Q.Fields[7].AsInteger;
  finally
    Q.Close;
  end;

  if DM.ConectarSerial(Puerto, Baud, Bits, ParidadChar, Stop) then
  begin
    FConectado := True;
    FModoPrueba := False;
    pnlCapturarPeso.Enabled := True;
    TimerLectura.Enabled := True;
  end
  else
  begin
    // MODO PRUEBA: fallo la conexion real (aun no tenemos la balanza)
    FConectado := True;
    FModoPrueba := True;
    pnlCapturarPeso.Enabled := True;
    TimerLectura.Enabled := True;
    btnSwitchConectar.Caption := 'Desconectar';
    if lblConexion <> nil then lblConexion.Caption := 'Modo prueba';
    MostrarInfoDialogo('Balanza', 'No se pudo conectar al puerto ' + Puerto +
      '. Se activa MODO PRUEBA con pesos simulados.');
  end;
  if FConectado and not FModoPrueba and (lblConexion <> nil) then
    lblConexion.Caption := 'Conectada';
  if FConectado then btnSwitchConectar.Caption := 'Desconectar';
end;

procedure TfrmPesajeIntegrado.TimerLecturaTimer(Sender: TObject);
var
  Trama: string;
  PesoSimulado: Integer;
begin
  if not FConectado then Exit;

  // MODO PRUEBA: aun no disponemos de la balanza fisica, se generan
  // pesos simulados para probar el flujo completo de captura/envio.
  if FModoPrueba then
  begin
    PesoSimulado := Random(4001) + 1000;
    lblPesoDisplay.Caption := IntToStr(PesoSimulado) + ' kg';
    Exit;
  end;

  if not DM.PuertoConectado then
  begin
    FConectado := False;
    TimerLectura.Enabled := False;
    pnlCapturarPeso.Enabled := False;
    btnSwitchConectar.Caption := 'Conectar';
    if lblConexion <> nil then lblConexion.Caption := 'Desconectada';
    Exit;
  end;
  Trama := DM.LeerPuertoSerial;
  if Trama <> '' then
    ProcesarTrama(Trama);
end;

function TfrmPesajeIntegrado.ExtraerPeso(const Trama: string): string;
var
  I: Integer;
  NumStr: string;
begin
  Result := '';
  if FMetodoLectura = 'POSICION' then
  begin
    if (FPosInicio > 0) and (FPosInicio + FPosLongitud - 1 <= Length(Trama)) then
      Result := Trim(Copy(Trama, FPosInicio, FPosLongitud));
    Exit;
  end;

  NumStr := '';
  for I := 1 to Length(Trama) do
    if Trama[I] in ['0'..'9'] then
      NumStr := NumStr + Trama[I]
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

procedure TfrmPesajeIntegrado.ProcesarTrama(const Trama: string);
var
  PesoStr: string;
  PesoVal: Integer;
begin
  PesoStr := ExtraerPeso(Trama);
  if PesoStr = '' then Exit;
  PesoVal := StrToIntDef(PesoStr, 0);
  lblPesoDisplay.Caption := IntToStr(PesoVal) + ' kg';
end;

// ══════════════════════════════════════════════════════════════════
// Captura de peso — primero se captura el peso del display y luego
// se envia con el boton "Enviar a la web" (dos pasos).
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.CapturarPesoClick(Sender: TObject);
var
  Peso: Integer;
begin
  if not FConectado then
  begin
    MostrarInfoDialogo('Balanza', 'Conecte la balanza primero');
    Exit;
  end;
  Peso := PesoDesdeDisplay(lblPesoDisplay.Caption);
  if Peso <= 0 then
  begin
    MostrarInfoDialogo('Peso', 'Peso invalido');
    Exit;
  end;
  FPesoCapturado := Peso;
  if lblPesoCapturado <> nil then
    lblPesoCapturado.Caption := 'Peso capturado: ' + IntToStr(Peso) + ' kg';
  if pnlEnviar <> nil then
    pnlEnviar.Enabled := True;
  pnlEnviar.Invalidate;
end;

procedure TfrmPesajeIntegrado.EnviarPesoClick(Sender: TObject);
begin
  if FPesoCapturado <= 0 then
  begin
    MostrarInfoDialogo('Peso', 'Capture el peso primero');
    Exit;
  end;
  if SyncSvc = nil then
  begin
    MostrarInfoDialogo('Sincronizacion', 'Servicio de sincronizacion no disponible');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    if SyncSvc.EnviarPesoVivo(FPesoCapturado) then
      MostrarInfoDialogo('Envio', 'Peso ' + IntToStr(FPesoCapturado) + ' kg enviado a la web.', dtExito)
    else
      MostrarInfoDialogo('Envio', 'No se pudo enviar el peso. Revise la conexion con el sistema web.', dtError);
  finally
    Screen.Cursor := crDefault;
  end;
  ActualizarEstadoSync;
end;

end.
