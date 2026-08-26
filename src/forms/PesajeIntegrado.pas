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

    TimerLectura: TTimer;
    TimerEstado: TTimer;

    pnlTop: TPanel;
    pnlContent: TPanel;
    pnlMedio: TPanel;
    pnlRegistroCard: TPanel;
    pnlRegistro: TPanel;

    pnlDisplay: TPanel;
    lblPesoDisplay: TLabel;
    lblRegistroTitle: TLabel;
    pnlSep1, pnlSep2: TPanel;
    lblConexion: TLabel;

    pnlSwitchConectar: TPanel;
    pnlCapturarPeso: TPanel;
    lblPesoCapturado: TLabel;
    pnlEnviar: TPanel;

    pnlSincronizar: TPanel;
    pnlEngranaje: TPanel;
    FMenuEngranaje: TPanel;
    lblEstado: TLabel;

    procedure PaintRounded(Sender: TObject);
    procedure MenuEngranajePaint(Sender: TObject);
    procedure MenuItemPaint(Sender: TObject);
    procedure MenuItemMouseEnter(Sender: TObject);
    procedure MenuItemMouseLeave(Sender: TObject);
    procedure SwitchConectarPaint(Sender: TObject);
    procedure SwitchConectarClick(Sender: TObject);
    procedure CapturarPesoClick(Sender: TObject);
    procedure EnviarPesoClick(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
    procedure TimerEstadoTimer(Sender: TObject);
    procedure ProcesarTrama(const Trama: string);
    function ExtraerPeso(const Trama: string): string;
    procedure SincronizarClick(Sender: TObject);
    procedure EngranajeClick(Sender: TObject);
    procedure MenuSistemaCompletoClick(Sender: TObject);
    procedure MenuConfigurarBalanzaClick(Sender: TObject);
    procedure MenuSalirClick(Sender: TObject);
    procedure CerrarMenuEngranaje;
    procedure ContentClick(Sender: TObject);
    procedure ActualizarEstadoSync;
    procedure FormShowHandler(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure AjustarLayout;
    function CrearBoton(AParent: TPanel; ATop, ALeft, AW, AH: Integer;
      const ACaption: string; AColor: TColor; AFontColor: TColor;
      ATag: Integer; AClick: TNotifyEvent): TPanel;
  end;

var
  frmPesajeIntegrado: TfrmPesajeIntegrado;

implementation

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
// Constructor — toda la UI se crea por código (sin .lfm)
// ══════════════════════════════════════════════════════════════════

constructor TfrmPesajeIntegrado.Create(AOwner: TComponent);
var
  Lbl: TLabel;
  Sep: TPanel;
  YPos: Integer;
  InnerW: Integer;
  pi: TPanel;
begin
  inherited CreateNew(AOwner);

  Randomize;
  FConectado := False;
  FMetodoLectura := 'AUTO';
  FPosInicio := 8;
  FPosLongitud := 5;
  FModoPrueba := False;
  FPesoCapturado := 0;

  Caption := 'Sistema de Pesaje';
  Width := APP_WIDTH;
  Height := APP_HEIGHT;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  Color := CLR_BG;
  Constraints.MinWidth := APP_MIN_WIDTH;
  Constraints.MinHeight := APP_MIN_HEIGHT;

  // ── Barra superior ─────────────────────────────────────────────
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 64;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Color := CLR_CARD;

  with TPanel.Create(pnlTop) do
  begin
    Parent := pnlTop;
    Align := alBottom;
    Height := 1;
    BevelOuter := bvNone;
    Color := CLR_TOPBAR_BORDER;
  end;

  Lbl := TLabel.Create(pnlTop);
  Lbl.Parent := pnlTop;
  Lbl.SetBounds(24, 0, 400, 64);
  Lbl.Layout := tlCenter;
  Lbl.Caption := 'SISTEMA DE PESAJE';
  Lbl.Font.Size := 14;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // ── Botón engranaje (cambio de modo / cerrar sesión) ───────────
  pnlEngranaje := TPanel.Create(pnlTop);
  pnlEngranaje.Parent := pnlTop;
  pnlEngranaje.SetBounds(pnlTop.ClientWidth - 64, 12, 40, 40);
  pnlEngranaje.BevelOuter := bvNone;
  pnlEngranaje.Color := CLR_CARD;
  pnlEngranaje.Cursor := crHandPoint;
  pnlEngranaje.OnClick := @EngranajeClick;
  pnlEngranaje.OnPaint := @PaintRounded;
  pnlEngranaje.Anchors := [akTop, akRight];
  pnlEngranaje.BorderSpacing.Right := 24;

  Lbl := TLabel.Create(pnlEngranaje);
  Lbl.Parent := pnlEngranaje;
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Caption := FAIconoStr(FA_COG, '⚙');
  Lbl.Font.Size := 16;
  Lbl.Font.Name := FA_FONT_NAME;
  Lbl.Font.Color := CLR_PRIMARY;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @EngranajeClick;

  // Menú desplegable del engranaje
  FMenuEngranaje := TPanel.Create(Self);
  FMenuEngranaje.Parent := Self;
  FMenuEngranaje.Visible := False;
  FMenuEngranaje.Color := CLR_CARD;
  FMenuEngranaje.BevelOuter := bvNone;
  FMenuEngranaje.BorderStyle := bsNone;
  FMenuEngranaje.OnPaint := @MenuEngranajePaint;
  FMenuEngranaje.Width := 250;
  FMenuEngranaje.Height := 158;

  pnlSincronizar := CrearBoton(pnlTop, 14, pnlTop.ClientWidth - 242, 170, 36,
    'Sincronizar ahora', CLR_PRIMARY, CLR_WHITE, 0, @SincronizarClick);
  pnlSincronizar.Anchors := [akTop, akRight];
  pnlSincronizar.BorderSpacing.Right := 24 + 40 + 8;

  lblEstado := TLabel.Create(pnlTop);
  lblEstado.Parent := pnlTop;
  lblEstado.Anchors := [akTop, akRight];
  lblEstado.BorderSpacing.Right := 24 + 40 + 8 + 170 + 12;
  lblEstado.SetBounds(pnlTop.ClientWidth - 674, 0, 420, 64);
  lblEstado.Alignment := taRightJustify;
  lblEstado.Layout := tlCenter;
  lblEstado.AutoSize := False;
  lblEstado.Caption := '';
  lblEstado.Font.Size := 10;
  lblEstado.Font.Color := CLR_TEXT_SLATE;

  // ── Contenido ──────────────────────────────────────────────────
  pnlContent := TPanel.Create(Self);
  pnlContent.Parent := Self;
  pnlContent.Align := alClient;
  pnlContent.BevelOuter := bvNone;
  pnlContent.Color := CLR_BG;
  pnlContent.OnClick := @ContentClick;

  pnlMedio := TPanel.Create(pnlContent);
  pnlMedio.Parent := pnlContent;
  pnlMedio.Align := alClient;
  pnlMedio.BevelOuter := bvNone;
  pnlMedio.Color := CLR_BG;
  pnlMedio.BorderSpacing.Around := FRAME_MARGIN;

  // ── Card registro de peso (centrado) ───────────────────────────
  pnlRegistroCard := TPanel.Create(pnlMedio);
  pnlRegistroCard.Parent := pnlMedio;
  pnlRegistroCard.SetBounds(0, 0, CREG_W, 430);
  pnlRegistroCard.BevelOuter := bvNone;
  pnlRegistroCard.Color := CLR_CARD;
  pnlRegistroCard.OnPaint := @PaintRounded;

  pnlRegistro := TPanel.Create(pnlRegistroCard);
  pnlRegistro.Parent := pnlRegistroCard;
  pnlRegistro.Align := alClient;
  pnlRegistro.BevelOuter := bvNone;
  pnlRegistro.Color := CLR_CARD;

  InnerW := CREG_W - CREG_PAD * 2;

  YPos := 12;
  Lbl := TLabel.Create(pnlRegistro);
  Lbl.Parent := pnlRegistro;
  Lbl.SetBounds(CREG_PAD, YPos, InnerW, 18);
  Lbl.Caption := 'Registro de peso';
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_TEXT_HEADING;
  lblRegistroTitle := Lbl;
  YPos := YPos + 26;

  Sep := TPanel.Create(pnlRegistro);
  Sep.Parent := pnlRegistro;
  Sep.SetBounds(CREG_PAD, YPos, InnerW, 1);
  Sep.BevelOuter := bvNone;
  Sep.Color := CLR_BORDER;
  pnlSep1 := Sep;
  YPos := YPos + 10;

  pnlDisplay := TPanel.Create(pnlRegistro);
  pnlDisplay.Parent := pnlRegistro;
  pnlDisplay.SetBounds(CREG_PAD, YPos, InnerW, 110);
  pnlDisplay.BevelOuter := bvNone;
  pnlDisplay.Color := CLR_PRIMARY;
  pi := TPanel.Create(pnlDisplay);
  pi.Parent := pnlDisplay;
  pi.SetBounds(2, 2, InnerW - 4, 106);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  lblPesoDisplay := TLabel.Create(pi);
  lblPesoDisplay.Parent := pi;
  lblPesoDisplay.Align := alClient;
  lblPesoDisplay.Alignment := taCenter;
  lblPesoDisplay.Layout := tlCenter;
  lblPesoDisplay.Caption := '0 kg';
  lblPesoDisplay.Font.Height := -28;
  lblPesoDisplay.Font.Style := [fsBold];
  lblPesoDisplay.Font.Color := CLR_TEXT_HEADING;
  YPos := YPos + 118;

  Sep := TPanel.Create(pnlRegistro);
  Sep.Parent := pnlRegistro;
  Sep.SetBounds(CREG_PAD, YPos, InnerW, 1);
  Sep.BevelOuter := bvNone;
  Sep.Color := CLR_BORDER;
  pnlSep2 := Sep;
  YPos := YPos + 8;

  pnlSwitchConectar := TPanel.Create(pnlRegistro);
  pnlSwitchConectar.Parent := pnlRegistro;
  pnlSwitchConectar.SetBounds(CREG_PAD, YPos, 78, 30);
  pnlSwitchConectar.BevelOuter := bvNone;
  pnlSwitchConectar.Color := CLR_CARD;
  pnlSwitchConectar.Cursor := crHandPoint;
  pnlSwitchConectar.OnPaint := @SwitchConectarPaint;
  pnlSwitchConectar.OnClick := @SwitchConectarClick;

  Lbl := TLabel.Create(pnlRegistro);
  Lbl.Parent := pnlRegistro;
  Lbl.SetBounds(CREG_PAD, YPos + 30, 78, 12);
  Lbl.Caption := 'Conexion';
  Lbl.Font.Size := 9;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.Alignment := taCenter;
  lblConexion := Lbl;

  pnlCapturarPeso := CrearBoton(pnlRegistro, YPos, CREG_PAD + 88,
    InnerW - 88 - 8, 30, 'Capturar peso', CLR_PRIMARY, CLR_WHITE, 0, @CapturarPesoClick);
  pnlCapturarPeso.Enabled := False;

  Lbl := TLabel.Create(pnlRegistro);
  Lbl.Parent := pnlRegistro;
  Lbl.SetBounds(CREG_PAD, YPos + 36, InnerW, 16);
  Lbl.Caption := 'Peso capturado: 0 kg';
  Lbl.Font.Size := 10;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.Alignment := taCenter;
  lblPesoCapturado := Lbl;

  pnlEnviar := CrearBoton(pnlRegistro, YPos + 56, CREG_PAD, InnerW, 36,
    'Enviar a la web', CLR_SUCCESS, CLR_WHITE, 0, @EnviarPesoClick);
  pnlEnviar.Enabled := False;

  // ── Timers ─────────────────────────────────────────────────────
  TimerLectura := TTimer.Create(Self);
  TimerLectura.Interval := 300;
  TimerLectura.Enabled := False;
  TimerLectura.OnTimer := @TimerLecturaTimer;

  TimerEstado := TTimer.Create(Self);
  TimerEstado.Interval := 2000;
  TimerEstado.Enabled := True;
  TimerEstado.OnTimer := @TimerEstadoTimer;

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

function TfrmPesajeIntegrado.CrearBoton(AParent: TPanel; ATop, ALeft, AW, AH: Integer;
  const ACaption: string; AColor: TColor; AFontColor: TColor;
  ATag: Integer; AClick: TNotifyEvent): TPanel;
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
  Lbl.Font.Size := 11;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := AFontColor;
  Lbl.Transparent := True;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := AClick;
end;

procedure TfrmPesajeIntegrado.FormShowHandler(Sender: TObject);
begin
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
  Lbl: TLabel;
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
  if pnlSwitchConectar <> nil then
  begin
    pnlSwitchConectar.SetBounds(P, RowY, 72, ROW_H);
    if lblConexion <> nil then
    begin
      lblConexion.SetBounds(P, RowY + ROW_H, 72, 14);
      lblConexion.Font.Size := 9;
    end;
  end;
  BtnW := InnerW - 72 - Gap;
  if pnlCapturarPeso <> nil then pnlCapturarPeso.SetBounds(P + 72 + Gap, RowY, BtnW, ROW_H);
  Lbl := nil;
  if (pnlCapturarPeso <> nil) and (pnlCapturarPeso.ControlCount > 0) then
    Lbl := TLabel(pnlCapturarPeso.Controls[0]);
  if Lbl <> nil then
    Lbl.Font.Size := 13;
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
  begin
    pnlEnviar.SetBounds(P, YPos, InnerW, 46);
    Lbl := nil;
    if pnlEnviar.ControlCount > 0 then
      Lbl := TLabel(pnlEnviar.Controls[0]);
    if Lbl <> nil then
      Lbl.Font.Size := 13;
  end;
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
  Pnl, Sep: TPanel;
  Lbl: TLabel;
  YPos: Integer;

  function CrearItem(ACaption: string; AIcon: Word; AColor: TColor;
    AClick: TNotifyEvent): TPanel;
  var
    IconLbl: TLabel;
  begin
    Result := TPanel.Create(FMenuEngranaje);
    Result.Parent := FMenuEngranaje;
    Result.SetBounds(8, YPos, FMenuEngranaje.Width - 16, 40);
    Result.BevelOuter := bvNone;
    Result.Color := CLR_CARD;
    Result.Cursor := crHandPoint;
    Result.OnPaint := @MenuItemPaint;
    Result.OnClick := AClick;
    Result.OnMouseEnter := @MenuItemMouseEnter;
    Result.OnMouseLeave := @MenuItemMouseLeave;

    IconLbl := TLabel.Create(Result);
    IconLbl.Parent := Result;
    IconLbl.SetBounds(14, 0, 26, 40);
    IconLbl.Alignment := taCenter;
    IconLbl.Layout := tlCenter;
    IconLbl.Caption := FAIconoStr(AIcon, '•');
    IconLbl.Font.Size := 13;
    IconLbl.Font.Name := FA_FONT_NAME;
    IconLbl.Font.Color := CLR_PRIMARY;
    IconLbl.Transparent := True;
    IconLbl.Cursor := crHandPoint;
    IconLbl.OnClick := AClick;
    IconLbl.OnMouseEnter := @MenuItemMouseEnter;
    IconLbl.OnMouseLeave := @MenuItemMouseLeave;

    Lbl := TLabel.Create(Result);
    Lbl.Parent := Result;
    Lbl.SetBounds(46, 0, Result.Width - 52, 40);
    Lbl.Alignment := taLeftJustify;
    Lbl.Layout := tlCenter;
    Lbl.Caption := ACaption;
    Lbl.Font.Size := 12;
    Lbl.Font.Color := AColor;
    Lbl.Transparent := True;
    Lbl.Cursor := crHandPoint;
    Lbl.OnClick := AClick;
    Lbl.OnMouseEnter := @MenuItemMouseEnter;
    Lbl.OnMouseLeave := @MenuItemMouseLeave;
    YPos := YPos + 44;
  end;

begin
  if FMenuEngranaje.Visible then
  begin
    CerrarMenuEngranaje;
    Exit;
  end;

  FMenuEngranaje.DestroyComponents;

  FMenuEngranaje.Left := pnlEngranaje.Left + pnlEngranaje.Width - FMenuEngranaje.Width;
  FMenuEngranaje.Top := pnlTop.Height + 2;
  YPos := 8;

  CrearItem('Acceder al sistema completo', FA_BUILDING, CLR_TEXT_HEADING, @MenuSistemaCompletoClick);

  Sep := TPanel.Create(FMenuEngranaje);
  Sep.Parent := FMenuEngranaje;
  Sep.SetBounds(16, YPos, FMenuEngranaje.Width - 32, 1);
  Sep.Color := CLR_BORDER;
  Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  CrearItem('Configurar balanza', FA_SCALE, CLR_TEXT_HEADING, @MenuConfigurarBalanzaClick);

  Sep := TPanel.Create(FMenuEngranaje);
  Sep.Parent := FMenuEngranaje;
  Sep.SetBounds(16, YPos, FMenuEngranaje.Width - 32, 1);
  Sep.Color := CLR_BORDER;
  Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  CrearItem('Cerrar sesion', FA_TIMES, CLR_DESTRUCTIVE, @MenuSalirClick);

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

procedure TfrmPesajeIntegrado.MenuItemPaint(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  Pnl.Canvas.Pen.Style := psClear;
  Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
end;

procedure TfrmPesajeIntegrado.MenuItemMouseEnter(Sender: TObject);
var
  Pnl: TPanel;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else if Sender is TLabel then
    Pnl := TPanel(TLabel(Sender).Parent)
  else
    Exit;
  Pnl.Color := CLR_SIDEBAR_HOVER;
end;

procedure TfrmPesajeIntegrado.MenuItemMouseLeave(Sender: TObject);
var
  Pnl: TPanel;
begin
  if Sender is TPanel then
    Pnl := TPanel(Sender)
  else if Sender is TLabel then
    Pnl := TPanel(TLabel(Sender).Parent)
  else
    Exit;
  Pnl.Color := CLR_CARD;
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

procedure TfrmPesajeIntegrado.SwitchConectarPaint(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Font.Height := -(Pnl.Height div 2);
  Pnl.Canvas.Font.Style := [fsBold];
  Ts := Pnl.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  if FConectado then
  begin
    Pnl.Canvas.Font.Color := CLR_SUCCESS;
    Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, FAIconoStr(FA_CHECK, '●') + ' ──', Ts);
  end
  else
  begin
    Pnl.Canvas.Font.Color := CLR_DESTRUCTIVE;
    Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, FAIconoStr(FA_TIMES, '○') + ' ──', Ts);
  end;
end;

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
    if lblConexion <> nil then lblConexion.Caption := 'Conexion';
    pnlSwitchConectar.Invalidate;
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
      if lblConexion <> nil then lblConexion.Caption := 'Prueba';
      pnlSwitchConectar.Invalidate;
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
    if lblConexion <> nil then lblConexion.Caption := 'Prueba';
    MostrarInfoDialogo('Balanza', 'No se pudo conectar al puerto ' + Puerto +
      '. Se activa MODO PRUEBA con pesos simulados.');
  end;
  pnlSwitchConectar.Invalidate;
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
    pnlSwitchConectar.Invalidate;
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
