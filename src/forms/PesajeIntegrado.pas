unit PesajeIntegrado;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, sqldb, DataModule, Utils, Theme, LoginForm, SyncService, LMessages,
  ConfigBalanzaFrame;

type
  { TfrmPesajeIntegrado }

  TfrmPesajeIntegrado = class(TForm)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  protected
    procedure WMCloseQuery(var Message: TLMessage); message LM_CLOSEQUERY;
  private
    FTara: Integer;
    FPesoBruto: Integer;
    FPesoNeto: Integer;
    FConectado: Boolean;
    FMetodoLectura: string;
    FPosInicio: Integer;
    FPosLongitud: Integer;

    TimerLectura: TTimer;
    TimerEstado: TTimer;

    pnlTop: TPanel;
    pnlContent: TPanel;
    pnlMedio: TPanel;
    pnlRegistroCard: TPanel;
    pnlRegistro: TPanel;

    pnlDisplay: TPanel;
    lblPesoDisplay: TLabel;
    lblValBruto: TLabel;
    lblValTara: TLabel;
    lblValNeto: TLabel;
    lblBrutoTit: TLabel;
    lblTaraTit: TLabel;
    lblNetoTit: TLabel;
    pnlValBruto: TPanel;
    pnlValTara: TPanel;
    pnlValNeto: TPanel;

    pnlSwitchConectar: TPanel;
    pnlCapturarPeso: TPanel;
    pnlCapturarTara: TPanel;
    pnlEnviar: TPanel;

    pnlSincronizar: TPanel;
    pnlEngranaje: TPanel;
    FMenuEngranaje: TPanel;
    lblEstado: TLabel;

    procedure PaintRounded(Sender: TObject);
    procedure SwitchConectarPaint(Sender: TObject);
    procedure SwitchConectarClick(Sender: TObject);
    procedure CapturarPesoClick(Sender: TObject);
    procedure CapturarTaraClick(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
    procedure TimerEstadoTimer(Sender: TObject);
    procedure ProcesarTrama(const Trama: string);
    function ExtraerPeso(const Trama: string): string;
    procedure EnviarPesoClick(Sender: TObject);
    procedure SincronizarClick(Sender: TObject);
    procedure EngranajeClick(Sender: TObject);
    procedure MenuSistemaCompletoClick(Sender: TObject);
    procedure MenuConfigurarBalanzaClick(Sender: TObject);
    procedure MenuSalirClick(Sender: TObject);
    procedure CerrarMenuEngranaje;
    procedure ContentClick(Sender: TObject);
    procedure ActualizarResumenPesos;
    procedure ActualizarEstadoSync;
    procedure Limpiar;
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
  po, pi: TPanel;
begin
  inherited CreateNew(AOwner);

  Randomize;
  FTara := 0;
  FPesoBruto := 0;
  FPesoNeto := 0;
  FConectado := False;
  FMetodoLectura := 'AUTO';
  FPosInicio := 8;
  FPosLongitud := 5;

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
  FMenuEngranaje.BorderStyle := bsSingle;
  FMenuEngranaje.Width := 230;
  FMenuEngranaje.Height := 96;

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
  pnlMedio.Align := alTop;
  pnlMedio.Height := 430;
  pnlMedio.BevelOuter := bvNone;
  pnlMedio.Color := CLR_BG;
  pnlMedio.BorderSpacing.Top := FRAME_MARGIN;

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
  YPos := YPos + 26;

  Sep := TPanel.Create(pnlRegistro);
  Sep.Parent := pnlRegistro;
  Sep.SetBounds(CREG_PAD, YPos, InnerW, 1);
  Sep.BevelOuter := bvNone;
  Sep.Color := CLR_BORDER;
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

  pnlCapturarPeso := CrearBoton(pnlRegistro, YPos, CREG_PAD + 84,
    (InnerW - 84 - 6) div 2, 30, 'Cap. peso', CLR_PRIMARY, CLR_WHITE, 0, @CapturarPesoClick);
  pnlCapturarPeso.Enabled := False;

  pnlCapturarTara := CrearBoton(pnlRegistro, YPos, CREG_PAD + 84 + (InnerW - 84 - 6) div 2 + 6,
    (InnerW - 84 - 6) div 2, 30, 'Cap. tara', CLR_INFO, CLR_WHITE, 0, @CapturarTaraClick);
  pnlCapturarTara.Enabled := False;
  YPos := YPos + 30 + 18;

  lblBrutoTit := TLabel.Create(pnlRegistro);
  lblBrutoTit.Parent := pnlRegistro;
  lblBrutoTit.SetBounds(CREG_PAD + 4, YPos, 100, 13);
  lblBrutoTit.Caption := 'Peso Bruto';
  lblBrutoTit.Font.Size := 9;
  lblBrutoTit.Font.Color := CLR_TEXT_SLATE;

  lblTaraTit := TLabel.Create(pnlRegistro);
  lblTaraTit.Parent := pnlRegistro;
  lblTaraTit.SetBounds(CREG_PAD + 140, YPos, 90, 13);
  lblTaraTit.Caption := 'Peso tara';
  lblTaraTit.Font.Size := 9;
  lblTaraTit.Font.Color := CLR_TEXT_SLATE;

  lblNetoTit := TLabel.Create(pnlRegistro);
  lblNetoTit.Parent := pnlRegistro;
  lblNetoTit.SetBounds(CREG_PAD + 276, YPos, 90, 13);
  lblNetoTit.Caption := 'Peso Neto';
  lblNetoTit.Font.Size := 9;
  lblNetoTit.Font.Color := CLR_TEXT_SLATE;
  YPos := YPos + 16;

  po := TPanel.Create(pnlRegistro);
  po.Parent := pnlRegistro;
  po.SetBounds(CREG_PAD, YPos, 120, 32);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  pnlValBruto := po;
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, 118, 30);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  pi.BorderWidth := 4;
  lblValBruto := TLabel.Create(pi);
  lblValBruto.Parent := pi;
  lblValBruto.Align := alClient;
  lblValBruto.Alignment := taCenter;
  lblValBruto.Layout := tlCenter;
  lblValBruto.Caption := '0';
  lblValBruto.Font.Size := 11;
  lblValBruto.Font.Style := [fsBold];
  lblValBruto.Font.Color := CLR_TEXT_HEADING;

  po := TPanel.Create(pnlRegistro);
  po.Parent := pnlRegistro;
  po.SetBounds(CREG_PAD + 126, YPos, 120, 32);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  pnlValTara := po;
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, 118, 30);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  pi.BorderWidth := 4;
  lblValTara := TLabel.Create(pi);
  lblValTara.Parent := pi;
  lblValTara.Align := alClient;
  lblValTara.Alignment := taCenter;
  lblValTara.Layout := tlCenter;
  lblValTara.Caption := '0';
  lblValTara.Font.Size := 11;
  lblValTara.Font.Style := [fsBold];
  lblValTara.Font.Color := CLR_TEXT_HEADING;

  po := TPanel.Create(pnlRegistro);
  po.Parent := pnlRegistro;
  po.SetBounds(CREG_PAD + 252, YPos, InnerW - 252, 32);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  pnlValNeto := po;
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, InnerW - 254, 30);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  pi.BorderWidth := 4;
  lblValNeto := TLabel.Create(pi);
  lblValNeto.Parent := pi;
  lblValNeto.Align := alClient;
  lblValNeto.Alignment := taCenter;
  lblValNeto.Layout := tlCenter;
  lblValNeto.Caption := '0';
  lblValNeto.Font.Size := 11;
  lblValNeto.Font.Style := [fsBold];
  lblValNeto.Font.Color := CLR_TEXT_HEADING;
  YPos := YPos + 32 + 16;

  pnlEnviar := CrearBoton(pnlRegistro, YPos, CREG_PAD, InnerW, 44,
    'ENVIAR PESO', CLR_PRIMARY, CLR_WHITE, 0, @EnviarPesoClick);

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

  ActualizarResumenPesos;
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
begin
  if (pnlMedio = nil) or (pnlRegistroCard = nil) then Exit;
  pnlRegistroCard.Left := (pnlMedio.ClientWidth - CREG_W) div 2;
  if pnlRegistroCard.Left < 0 then pnlRegistroCard.Left := 0;
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
  Lbl: TLabel;
  Sep: TPanel;
  YPos: Integer;
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

  Lbl := TLabel.Create(FMenuEngranaje);
  Lbl.Parent := FMenuEngranaje;
  Lbl.SetBounds(12, YPos, 206, 16);
  Lbl.Caption := 'Acceder al sistema completo';
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @MenuSistemaCompletoClick;
  YPos := YPos + 22;

  Sep := TPanel.Create(FMenuEngranaje);
  Sep.Parent := FMenuEngranaje;
  Sep.SetBounds(8, YPos, 214, 1);
  Sep.Color := CLR_BORDER;
  Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  Lbl := TLabel.Create(FMenuEngranaje);
  Lbl.Parent := FMenuEngranaje;
  Lbl.SetBounds(12, YPos, 206, 16);
  Lbl.Caption := 'Configurar balanza';
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @MenuConfigurarBalanzaClick;
  YPos := YPos + 22;

  Sep := TPanel.Create(FMenuEngranaje);
  Sep.Parent := FMenuEngranaje;
  Sep.SetBounds(8, YPos, 214, 1);
  Sep.Color := CLR_BORDER;
  Sep.BevelOuter := bvNone;
  YPos := YPos + 8;

  Lbl := TLabel.Create(FMenuEngranaje);
  Lbl.Parent := FMenuEngranaje;
  Lbl.SetBounds(12, YPos, 206, 16);
  Lbl.Caption := 'Cerrar sesion';
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_DESTRUCTIVE;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @MenuSalirClick;

  FMenuEngranaje.Visible := True;
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
  if MessageDlg('Cerrar sesion', 'Seguro que desea cerrar sesion?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
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
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.SwitchConectarPaint(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Font.Height := -12;
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
    pnlCapturarPeso.Enabled := False;
    pnlCapturarTara.Enabled := False;
    pnlSwitchConectar.Invalidate;
    Exit;
  end;

  Q := DM.AbrirQuery(
    'SELECT puerto_com, baudrate, databits, paridad, stopbits, metodo_lectura, posicion_inicio, posicion_longitud ' +
    'FROM config_balanza ORDER BY id DESC LIMIT 1');
  try
    if Q.EOF then
    begin
      ShowMessage('No hay configuracion de balanza. Configurela en el sistema completo.');
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
    pnlCapturarPeso.Enabled := True;
    pnlCapturarTara.Enabled := True;
    TimerLectura.Enabled := True;
  end
  else
  begin
    FConectado := False;
    ShowMessage('No se pudo conectar al puerto ' + Puerto);
  end;
  pnlSwitchConectar.Invalidate;
end;

procedure TfrmPesajeIntegrado.TimerLecturaTimer(Sender: TObject);
var
  Trama: string;
begin
  if not FConectado then Exit;
  if not DM.PuertoConectado then
  begin
    FConectado := False;
    TimerLectura.Enabled := False;
    pnlCapturarPeso.Enabled := False;
    pnlCapturarTara.Enabled := False;
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
// Captura de pesos
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.ActualizarResumenPesos;
begin
  if lblValBruto <> nil then lblValBruto.Caption := IntToStr(FPesoBruto);
  if lblValTara <> nil then lblValTara.Caption := IntToStr(FTara);
  if lblValNeto <> nil then lblValNeto.Caption := IntToStr(FPesoNeto);
end;

procedure TfrmPesajeIntegrado.CapturarPesoClick(Sender: TObject);
begin
  if not FConectado then
  begin
    ShowMessage('Conecte la balanza primero');
    Exit;
  end;
  FPesoBruto := PesoDesdeDisplay(lblPesoDisplay.Caption);
  if FPesoBruto <= 0 then
  begin
    ShowMessage('Peso invalido');
    Exit;
  end;
  FPesoNeto := FPesoBruto - FTara;
  ActualizarResumenPesos;
end;

procedure TfrmPesajeIntegrado.CapturarTaraClick(Sender: TObject);
begin
  if not FConectado then
  begin
    ShowMessage('Conecte la balanza primero');
    Exit;
  end;
  FTara := PesoDesdeDisplay(lblPesoDisplay.Caption);
  if FTara <= 0 then
  begin
    ShowMessage('Peso invalido');
    Exit;
  end;
  FPesoNeto := FPesoBruto - FTara;
  ActualizarResumenPesos;
end;

// ══════════════════════════════════════════════════════════════════
// Enviar peso — envía únicamente el peso captado a la web
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.Limpiar;
begin
  FTara := 0;
  FPesoBruto := 0;
  FPesoNeto := 0;
  lblPesoDisplay.Caption := '0 kg';
  ActualizarResumenPesos;
end;

procedure TfrmPesajeIntegrado.EnviarPesoClick(Sender: TObject);
begin
  if FPesoBruto <= 0 then
  begin
    ShowMessage('Capture el peso bruto primero');
    Exit;
  end;
  if FTara <= 0 then
  begin
    ShowMessage('Capture la tara primero');
    Exit;
  end;
  if FPesoBruto < FTara then
  begin
    ShowMessage('El peso bruto no puede ser menor que la tara');
    Exit;
  end;

  FPesoNeto := FPesoBruto - FTara;
  ActualizarResumenPesos;

  if MessageDlg('Enviar peso',
    Format('Bruto: %d kg | Tara: %d kg | Neto: %d kg. Enviar a la web?',
    [FPesoBruto, FTara, FPesoNeto]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  if SyncSvc = nil then
  begin
    ShowMessage('Servicio de sincronizacion no disponible');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    if SyncSvc.EnviarPeso(FPesoBruto, FTara) then
    begin
      ShowMessage('Peso enviado correctamente.');
      Limpiar;
    end
    else
      ShowMessage('No se pudo enviar el peso. Revise la conexion con el sistema web.');
  finally
    Screen.Cursor := crDefault;
  end;
  ActualizarEstadoSync;
end;

end.
