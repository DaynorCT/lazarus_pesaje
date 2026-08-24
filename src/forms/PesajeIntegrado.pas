unit PesajeIntegrado;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, sqldb, DataModule, Utils, Theme, LoginForm, SyncService;

type
  { TfrmPesajeIntegrado }

  TfrmPesajeIntegrado = class(TForm)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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
    pnlForm: TPanel;

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
    pnlGuardar: TPanel;

    pnlSincronizar: TPanel;
    pnlEngranaje: TPanel;
    FMenuEngranaje: TPanel;
    lblEstado: TLabel;

    cmbVehiculo: TComboBox;
    cmbChofer: TComboBox;
    cmbProveedor: TComboBox;
    cmbProducto: TComboBox;
    cmbOrigen: TComboBox;
    cmbDestino: TComboBox;
    edtCosto: TEdit;
    edtFlete: TEdit;

    pnlSepForm: TPanel;

    procedure PaintRounded(Sender: TObject);
    procedure SwitchConectarPaint(Sender: TObject);
    procedure SwitchConectarClick(Sender: TObject);
    procedure CapturarPesoClick(Sender: TObject);
    procedure CapturarTaraClick(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
    procedure TimerEstadoTimer(Sender: TObject);
    procedure ProcesarTrama(const Trama: string);
    function ExtraerPeso(const Trama: string): string;
    procedure GuardarClick(Sender: TObject);
    procedure SincronizarClick(Sender: TObject);
    procedure EngranajeClick(Sender: TObject);
    procedure MenuSistemaCompletoClick(Sender: TObject);
    procedure MenuSalirClick(Sender: TObject);
    procedure CerrarMenuEngranaje;
    procedure ContentClick(Sender: TObject);
    procedure VehiculoChange(Sender: TObject);
    procedure CargarCombos;
    procedure ActualizarResumenPesos;
    procedure ActualizarEstadoSync;
    procedure Limpiar;
    procedure FormShowHandler(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure AjustarFormLayout;
    function CrearBoton(AParent: TPanel; ATop, ALeft, AW, AH: Integer;
      const ACaption: string; AColor: TColor; AFontColor: TColor;
      ATag: Integer; AClick: TNotifyEvent): TPanel;
  end;

var
  frmPesajeIntegrado: TfrmPesajeIntegrado;

implementation

const
  CREG_W   = 380;
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

function NuevoEventID: string;
const
  Hex = '0123456789abcdef';
var
  I: Integer;
begin
  Result := '';
  for I := 1 to 32 do
    Result := Result + Hex[Random(16) + 1];
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

  procedure MakeLabel(ATop, ALeft, AWidth: Integer; const ACaption: string);
  begin
    Lbl := TLabel.Create(pnlForm);
    Lbl.Parent := pnlForm;
    Lbl.SetBounds(ALeft, ATop, AWidth, 14);
    Lbl.Caption := ACaption;
    Lbl.Font.Size := 10;
    Lbl.Font.Style := [];
    Lbl.Font.Color := CLR_TEXT_SLATE;
  end;

  function MakeEdit(ATop, ALeft, AWidth: Integer): TEdit;
  var
    ep, ip: TPanel;
  begin
    ep := TPanel.Create(pnlForm);
    ep.Parent := pnlForm;
    ep.SetBounds(ALeft, ATop, AWidth, 34);
    ep.BevelOuter := bvNone;
    ep.Color := CLR_BORDER;
    ip := TPanel.Create(ep);
    ip.Parent := ep;
    ip.SetBounds(1, 1, AWidth - 2, 32);
    ip.BevelOuter := bvNone;
    ip.Color := CLR_WHITE;
    ip.BorderWidth := 4;
    Result := TEdit.Create(ip);
    Result.Parent := ip;
    Result.Align := alClient;
    Result.BorderStyle := bsNone;
    Result.Font.Size := 10;
    Result.Font.Color := CLR_TEXT;
    Result.Color := CLR_WHITE;
  end;

  procedure ConfigCombo(Cmb: TComboBox; ATop, ALeft, AWidth: Integer);
  begin
    Cmb.Parent := pnlForm;
    Cmb.SetBounds(ALeft, ATop, AWidth, 34);
    Cmb.AutoSize := False;
    Cmb.Style := csDropDownList;
    Cmb.Font.Size := 10;
    Cmb.Color := CLR_WHITE;
    Cmb.Font.Color := CLR_TEXT;
  end;

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
  pnlEngranaje.SetBounds(0, 12, 40, 40);
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
  FMenuEngranaje.Height := 60;

  pnlSincronizar := CrearBoton(pnlTop, 14, 0, 170, 36,
    'Sincronizar ahora', CLR_PRIMARY, CLR_WHITE, 0, @SincronizarClick);
  pnlSincronizar.Anchors := [akTop, akRight];
  pnlSincronizar.BorderSpacing.Right := 24 + 40 + 8;

  lblEstado := TLabel.Create(pnlTop);
  lblEstado.Parent := pnlTop;
  lblEstado.Anchors := [akTop, akRight];
  lblEstado.BorderSpacing.Right := 24 + 40 + 8 + 170 + 12;
  lblEstado.SetBounds(0, 0, 420, 64);
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
  pnlMedio.Height := 400;
  pnlMedio.BevelOuter := bvNone;
  pnlMedio.Color := CLR_BG;
  pnlMedio.BorderSpacing.Left := FRAME_MARGIN;
  pnlMedio.BorderSpacing.Right := FRAME_MARGIN;
  pnlMedio.BorderSpacing.Top := FRAME_MARGIN;

  // ── Card izquierdo: registro de peso ───────────────────────────
  pnlRegistroCard := TPanel.Create(pnlMedio);
  pnlRegistroCard.Parent := pnlMedio;
  pnlRegistroCard.Align := alLeft;
  pnlRegistroCard.Width := CREG_W;
  pnlRegistroCard.BorderSpacing.Right := 16;
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
  pnlDisplay.SetBounds(CREG_PAD, YPos, InnerW, 100);
  pnlDisplay.BevelOuter := bvNone;
  pnlDisplay.Color := CLR_PRIMARY;
  pi := TPanel.Create(pnlDisplay);
  pi.Parent := pnlDisplay;
  pi.SetBounds(2, 2, InnerW - 4, 96);
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
  YPos := YPos + 108;

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
  lblTaraTit.SetBounds(CREG_PAD + 120, YPos, 90, 13);
  lblTaraTit.Caption := 'Peso tara';
  lblTaraTit.Font.Size := 9;
  lblTaraTit.Font.Color := CLR_TEXT_SLATE;

  lblNetoTit := TLabel.Create(pnlRegistro);
  lblNetoTit.Parent := pnlRegistro;
  lblNetoTit.SetBounds(CREG_PAD + 236, YPos, 90, 13);
  lblNetoTit.Caption := 'Peso Neto';
  lblNetoTit.Font.Size := 9;
  lblNetoTit.Font.Color := CLR_TEXT_SLATE;
  YPos := YPos + 16;

  po := TPanel.Create(pnlRegistro);
  po.Parent := pnlRegistro;
  po.SetBounds(CREG_PAD, YPos, 108, 32);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  pnlValBruto := po;
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, 106, 30);
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
  po.SetBounds(CREG_PAD + 114, YPos, 108, 32);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  pnlValTara := po;
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, 106, 30);
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
  po.SetBounds(CREG_PAD + 228, YPos, InnerW - 228, 32);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  pnlValNeto := po;
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, InnerW - 230, 30);
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
  YPos := YPos + 32 + 14;

  pnlGuardar := CrearBoton(pnlRegistro, YPos, CREG_PAD, InnerW, 40,
    'GUARDAR Y ENVIAR', CLR_PRIMARY, CLR_WHITE, 0, @GuardarClick);

  // ── Card derecho: datos del pesaje ─────────────────────────────
  pnlForm := TPanel.Create(pnlMedio);
  pnlForm.Parent := pnlMedio;
  pnlForm.Align := alClient;
  pnlForm.BevelOuter := bvNone;
  pnlForm.Color := CLR_CARD;
  pnlForm.OnPaint := @PaintRounded;

  YPos := 12;
  Lbl := TLabel.Create(pnlForm);
  Lbl.Parent := pnlForm;
  Lbl.SetBounds(CREG_PAD, YPos, 300, 18);
  Lbl.Caption := 'Datos del Pesaje';
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_TEXT_HEADING;
  YPos := YPos + 26;

  pnlSepForm := TPanel.Create(pnlForm);
  pnlSepForm.Parent := pnlForm;
  pnlSepForm.SetBounds(CREG_PAD, YPos, 600, 1);
  pnlSepForm.BevelOuter := bvNone;
  pnlSepForm.Color := CLR_BORDER;
  YPos := YPos + 10;

  MakeLabel(YPos, CREG_PAD, 200, 'Vehiculo *');
  MakeLabel(YPos, 360, 200, 'Chofer');
  YPos := YPos + 16;
  cmbVehiculo := TComboBox.Create(pnlForm);
  ConfigCombo(cmbVehiculo, YPos, CREG_PAD, 300);
  cmbVehiculo.OnChange := @VehiculoChange;
  cmbChofer := TComboBox.Create(pnlForm);
  ConfigCombo(cmbChofer, YPos, 360, 300);
  YPos := YPos + 34 + 12;

  MakeLabel(YPos, CREG_PAD, 200, 'Proveedor');
  MakeLabel(YPos, 360, 200, 'Producto');
  YPos := YPos + 16;
  cmbProveedor := TComboBox.Create(pnlForm);
  ConfigCombo(cmbProveedor, YPos, CREG_PAD, 300);
  cmbProducto := TComboBox.Create(pnlForm);
  ConfigCombo(cmbProducto, YPos, 360, 300);
  YPos := YPos + 34 + 12;

  MakeLabel(YPos, CREG_PAD, 200, 'Origen');
  MakeLabel(YPos, 360, 200, 'Destino');
  YPos := YPos + 16;
  cmbOrigen := TComboBox.Create(pnlForm);
  ConfigCombo(cmbOrigen, YPos, CREG_PAD, 300);
  cmbDestino := TComboBox.Create(pnlForm);
  ConfigCombo(cmbDestino, YPos, 360, 300);
  YPos := YPos + 34 + 12;

  MakeLabel(YPos, CREG_PAD, 200, 'Costo (Bs)');
  MakeLabel(YPos, 360, 200, 'Flete pend. (Bs)');
  YPos := YPos + 16;
  edtCosto := MakeEdit(YPos, CREG_PAD, 300);
  edtCosto.Text := '0';
  edtFlete := MakeEdit(YPos, 360, 300);
  edtFlete.Text := '0';

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

  CargarCombos;
  ActualizarResumenPesos;
  ActualizarEstadoSync;
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
  if (Pnl = pnlRegistroCard) or (Pnl = pnlForm) then
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
  Lbl.Font.Size := 10;
  Lbl.Font.Style := [];
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
    CargarCombos;
  end;
  ActualizarEstadoSync;
end;

procedure TfrmPesajeIntegrado.FormResize(Sender: TObject);
begin
  AjustarFormLayout;
end;

procedure TfrmPesajeIntegrado.AjustarFormLayout;
var
  W, ColW, Col2: Integer;

  procedure AjustarEdit(AEdit: TEdit; ALeft, AWidth: Integer);
  var
    PnlOuter, PnlInner: TPanel;
  begin
    if AEdit = nil then Exit;
    PnlInner := TPanel(AEdit.Parent);
    PnlOuter := TPanel(PnlInner.Parent);
    PnlOuter.Left := ALeft;
    PnlOuter.Width := AWidth;
    PnlInner.Width := AWidth - 2;
  end;

begin
  if pnlForm = nil then Exit;
  W := pnlForm.ClientWidth;
  if W < 400 then Exit;

  ColW := (W - CREG_PAD * 2 - 8) div 2;
  if ColW < 150 then ColW := 150;
  Col2 := CREG_PAD + ColW + 8;

  if pnlSepForm <> nil then
    pnlSepForm.Width := W - CREG_PAD * 2;

  if cmbVehiculo <> nil then
  begin
    cmbVehiculo.Left := CREG_PAD;
    cmbVehiculo.Width := ColW;
    cmbChofer.Left := Col2;
    cmbChofer.Width := ColW;
    cmbProveedor.Left := CREG_PAD;
    cmbProveedor.Width := ColW;
    cmbProducto.Left := Col2;
    cmbProducto.Width := ColW;
    cmbOrigen.Left := CREG_PAD;
    cmbOrigen.Width := ColW;
    cmbDestino.Left := Col2;
    cmbDestino.Width := ColW;
  end;
  AjustarEdit(edtCosto, CREG_PAD, ColW);
  AjustarEdit(edtFlete, Col2, ColW);

  pnlForm.Invalidate;
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
    CargarCombos;
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
    Close;
  end;
end;

procedure TfrmPesajeIntegrado.MenuSalirClick(Sender: TObject);
begin
  CerrarMenuEngranaje;
  if MessageDlg('Cerrar sesion', 'Seguro que desea cerrar sesion?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ModalResult := mrCancel;
    Close;
  end;
end;

// ══════════════════════════════════════════════════════════════════
// Catálogos
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.CargarCombos;
var
  Q: TSQLQuery;

  procedure LlenarCombo(Cmb: TComboBox; const SQL, CV, CT: string);
  begin
    Cmb.Items.Clear;
    Cmb.Items.Add('- Seleccione -');
    Cmb.ItemIndex := 0;
    Q := DM.AbrirQuery(SQL);
    try
      while not Q.EOF do
      begin
        Cmb.Items.AddObject(Q.FieldByName(CT).AsString,
          TObject(PtrInt(Q.FieldByName(CV).AsInteger)));
        Q.Next;
      end;
    finally
      Q.Close;
    end;
  end;

begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;
  LlenarCombo(cmbVehiculo, 'SELECT id,placa FROM vehiculos WHERE estado=''ACTIVO'' ORDER BY placa', 'id', 'placa');
  LlenarCombo(cmbChofer, 'SELECT c.id,p.nombre||'' ''||p.apellido_paterno AS nombre FROM choferes c INNER JOIN personas p ON p.id=c.persona_id WHERE c.estado=''ACTIVO'' AND p.estado=''ACTIVO'' ORDER BY p.nombre', 'id', 'nombre');
  LlenarCombo(cmbProveedor, 'SELECT pr.id,p.nombre||'' ''||COALESCE(p.apellido_paterno,'''')||'' ''||COALESCE(p.apellido_materno,'''') AS nombre FROM proveedores pr INNER JOIN personas p ON p.id=pr.persona_id WHERE pr.estado=''ACTIVO'' AND p.estado=''ACTIVO'' ORDER BY p.nombre', 'id', 'nombre');
  LlenarCombo(cmbProducto, 'SELECT id,nombre FROM productos WHERE estado=''ACTIVO'' ORDER BY nombre', 'id', 'nombre');
  LlenarCombo(cmbOrigen, 'SELECT id,nombre FROM origenes WHERE estado=''ACTIVO'' ORDER BY nombre', 'id', 'nombre');
  LlenarCombo(cmbDestino, 'SELECT id,nombre FROM destinos WHERE estado=''ACTIVO'' ORDER BY nombre', 'id', 'nombre');
end;

procedure TfrmPesajeIntegrado.VehiculoChange(Sender: TObject);
var
  Q: TSQLQuery;
  Vid: Integer;
begin
  if cmbVehiculo.ItemIndex < 1 then
  begin
    FTara := 0;
    ActualizarResumenPesos;
    Exit;
  end;
  Vid := PtrInt(cmbVehiculo.Items.Objects[cmbVehiculo.ItemIndex]);
  Q := DM.AbrirQuery('SELECT tara FROM vehiculos WHERE id=' + IntToStr(Vid));
  try
    if not Q.EOF then
    begin
      FTara := Q.Fields[0].AsInteger;
      ActualizarResumenPesos;
    end;
  finally
    Q.Close;
  end;
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
// Guardar y enviar
// ══════════════════════════════════════════════════════════════════

procedure TfrmPesajeIntegrado.Limpiar;
begin
  FTara := 0;
  FPesoBruto := 0;
  FPesoNeto := 0;
  lblPesoDisplay.Caption := '0 kg';
  ActualizarResumenPesos;
  cmbVehiculo.ItemIndex := 0;
  cmbChofer.ItemIndex := 0;
  cmbProveedor.ItemIndex := 0;
  cmbProducto.ItemIndex := 0;
  cmbOrigen.ItemIndex := 0;
  cmbDestino.ItemIndex := 0;
  edtCosto.Text := '0';
  edtFlete.Text := '0';
end;

procedure TfrmPesajeIntegrado.GuardarClick(Sender: TObject);
var
  VehiculoID, ChoferID, ProveedorID, ProductoID, OrigenID, DestinoID: Integer;
  Costo, Flete, ProximoID: Integer;
  Guia, Anio, EventID: string;
  Q: TSQLQuery;
begin
  if cmbVehiculo.ItemIndex < 1 then
  begin
    ShowMessage('Seleccione un vehiculo');
    Exit;
  end;
  if FPesoBruto <= 0 then
  begin
    ShowMessage('Capture el peso bruto primero');
    Exit;
  end;
  if FTara <= 0 then
  begin
    ShowMessage('Falta la tara. Seleccione un vehiculo con tara o capture la tara.');
    Exit;
  end;
  if FPesoBruto < FTara then
  begin
    ShowMessage('El peso bruto no puede ser menor que la tara');
    Exit;
  end;

  FPesoNeto := FPesoBruto - FTara;
  ActualizarResumenPesos;

  if MessageDlg('Guardar pesaje',
    Format('Bruto: %d kg | Tara: %d kg | Neto: %d kg. Confirmar?',
    [FPesoBruto, FTara, FPesoNeto]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  VehiculoID := PtrInt(cmbVehiculo.Items.Objects[cmbVehiculo.ItemIndex]);
  ChoferID := 0;
  ProveedorID := 0;
  ProductoID := 0;
  OrigenID := 0;
  DestinoID := 0;
  if cmbChofer.ItemIndex > 0 then ChoferID := PtrInt(cmbChofer.Items.Objects[cmbChofer.ItemIndex]);
  if cmbProveedor.ItemIndex > 0 then ProveedorID := PtrInt(cmbProveedor.Items.Objects[cmbProveedor.ItemIndex]);
  if cmbProducto.ItemIndex > 0 then ProductoID := PtrInt(cmbProducto.Items.Objects[cmbProducto.ItemIndex]);
  if cmbOrigen.ItemIndex > 0 then OrigenID := PtrInt(cmbOrigen.Items.Objects[cmbOrigen.ItemIndex]);
  if cmbDestino.ItemIndex > 0 then DestinoID := PtrInt(cmbDestino.Items.Objects[cmbDestino.ItemIndex]);
  Costo := StrToIntDef(edtCosto.Text, 0);
  Flete := StrToIntDef(edtFlete.Text, 0);

  Q := DM.AbrirQuery('SELECT MAX(id) AS max_id FROM pesajes');
  try
    if Q.FieldByName('max_id').IsNull then ProximoID := 1
    else ProximoID := Q.FieldByName('max_id').AsInteger + 1;
  finally
    Q.Close;
  end;

  Anio := FormatDateTime('yyyy', Now);
  Guia := 'PESO-' + Anio + '-' + Format('%.6d', [ProximoID]);
  EventID := NuevoEventID;

  if DM.Transaccion.Active then DM.Transaccion.Rollback;
  DM.Transaccion.StartTransaction;
  try
    DM.EjecutarSQL(
      'INSERT INTO pesajes (guia, lote, vehiculo_id, chofer_id, proveedor_id, producto_id, ' +
      'id_origen, id_destino, peso_bruto, tara, peso_neto, costo_bs, flete_bs_pendiente, ' +
      'pesador_id, estado, estado_balanza, sincronizado, sync_event_id, ' +
      'usuario_creacion, usuario_modificacion, fecha_creacion, fecha_modificacion) VALUES (' +
      QuotedStr(Guia) + ','''',' + IntToStr(VehiculoID) + ',' +
      IfThen(ChoferID > 0, IntToStr(ChoferID), 'NULL') + ',' +
      IfThen(ProveedorID > 0, IntToStr(ProveedorID), 'NULL') + ',' +
      IfThen(ProductoID > 0, IntToStr(ProductoID), 'NULL') + ',' +
      IfThen(OrigenID > 0, IntToStr(OrigenID), 'NULL') + ',' +
      IfThen(DestinoID > 0, IntToStr(DestinoID), 'NULL') + ',' +
      IntToStr(FPesoBruto) + ',' + IntToStr(FTara) + ',' + IntToStr(FPesoNeto) + ',' +
      IntToStr(Costo) + ',' + IntToStr(Flete) + ',' + IntToStr(UsuarioActual.PersonaID) + ',' +
      '''ACTIVO'',''FINALIZADO'',0,' + QuotedStr(EventID) + ',' +
      IntToStr(UsuarioActual.ID) + ',' + IntToStr(UsuarioActual.ID) + ',''' +
      FechaHoraActual + ''',''' + FechaHoraActual + ''')');
    DM.Transaccion.Commit;
  except
    DM.Transaccion.Rollback;
    ShowMessage('Error al guardar pesaje');
    Exit;
  end;

  Limpiar;

  if SyncSvc <> nil then
  begin
    Screen.Cursor := crHourGlass;
    try
      SyncSvc.PushPesajesPendientes;
    finally
      Screen.Cursor := crDefault;
    end;
    ActualizarEstadoSync;
  end;

  if SyncSvc.Conectado then
    ShowMessage('Pesaje guardado y enviado correctamente.')
  else
    ShowMessage('Pesaje guardado localmente. Se enviara automaticamente cuando haya conexion.');
end;

end.
