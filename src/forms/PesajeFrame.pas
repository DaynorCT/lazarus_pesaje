unit PesajeFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme, LoginForm;

type
  { TFramePesaje }

  TFramePesaje = class(TFrame)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    FTara: Integer;
    FPesoBruto: Integer;
    FPesoNeto: Integer;
    FConectado: Boolean;
    FEditMode: Boolean;
    FEditID: Integer;
    FUsarTaraManual: Boolean;
    FTaraManual: string;
    FTaraCapturada: Integer;
    TimerLectura: TTimer;
    pnlRegistroCard, pnlDisplay, pnlCard: TPanel;
    lblPesoDisplay, lblRegistroTitle: TLabel;
    lblValBruto, lblValTara, lblValNeto: TLabel;
    lblFormTitle: TLabel;
    cmbVehiculo, cmbChofer, cmbProveedor: TComboBox;
    cmbProducto, cmbOrigen, cmbDestino: TComboBox;
    edtCosto, edtFlete, edtLicencia, edtTipo: TEdit;
    edtTaraManual: TEdit;
    Grid: TStringGrid;
    pnlSwitchConectar, pnlCapturarPeso, pnlCapturarTara: TPanel;
    pnlSwitchTara, pnlGuardarTara: TPanel;
    pnlGuardar, pnlCancelEdit: TPanel;
    btnVehNuevo, btnChoNuevo, btnPrvNuevo: TPanel;
    btnProNuevo, btnOriNuevo, btnDesNuevo: TPanel;
    procedure RefrescarPesajes(Sender: TObject);
    procedure CargarCombos;
    procedure VehiculoChange(Sender: TObject);
    procedure ChoferChange(Sender: TObject);
    procedure TimerLecturaTimer(Sender: TObject);
    procedure ProcesarTrama(const Trama: string);
    procedure ActualizarResumenPesos;
    procedure SwitchConectarPaint(Sender: TObject);
    procedure SwitchConectarClick(Sender: TObject);
    procedure CapturarPesoClick(Sender: TObject);
    function ExtraerPeso(const Trama: string): string;
    procedure ConectarClick(Sender: TObject);
    procedure TaraClick(Sender: TObject);
    procedure SwitchTaraPaint(Sender: TObject);
    procedure SwitchTaraClick(Sender: TObject);
    procedure TaraManualChange(Sender: TObject);
    procedure GuardarTaraClick(Sender: TObject);
    procedure GuardarClick(Sender: TObject);
    procedure QuickGuardarClick(Sender: TObject);
    procedure QuickCancelarClick(Sender: TObject);
    procedure LimpiarClick(Sender: TObject);
    procedure CancelEditClick(Sender: TObject);
    procedure QuickVehiculoClick(Sender: TObject);
    procedure QuickChoferClick(Sender: TObject);
    procedure QuickProveedorClick(Sender: TObject);
    procedure QuickSimpleClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure CargarPesaje(ID: Integer);
    procedure FinalizarPesaje(ID: Integer);
    procedure AnularPesaje(ID: Integer);
    procedure ToggleEstadoPesaje(ID: Integer; EstadoActual: string);
    procedure PaintRounded(Sender: TObject);
    procedure DialogFinalizarOk(Sender: TObject);
    function MostrarDialogFinalizar(PesajeID, Bruto, Tara, Neto: Integer): Boolean;
    function CrearBoton(AParent: TPanel; ATop, ALeft, AW, AH: Integer; const ACaption: string;
      AColor: TColor; AFontColor: TColor; ATag: Integer; AClick: TNotifyEvent): TPanel;
    function BuscarComboIndex(Cmb: TComboBox; ID: Integer): Integer;
  end;

implementation

{$R *.lfm}

function TFramePesaje.BuscarComboIndex(Cmb: TComboBox; ID: Integer): Integer;
var
  i: Integer;
begin
  for i := 1 to Cmb.Items.Count - 1 do
    if PtrInt(Cmb.Items.Objects[i]) = ID then
      Exit(i);
  Result := 0;
end;

constructor TFramePesaje.Create(AOwner: TComponent);
const
  COL1 = 24;
  COL2 = 310;
  COL3 = 600;
  FIELD_W = 180;
  COMBO_W = 148;
var
  Pnl, pnlForm, pnlRegistro: TPanel;
  Lbl: TLabel;
  YPos, CardW, InnerW: Integer;
  po, pi: TPanel;

  function MakeLabel(ATop, ALeft: Integer; const ACaption: string): TLabel;
  begin
    Result := TLabel.Create(pnlForm);
    Result.Parent := pnlForm;
    Result.SetBounds(ALeft, ATop, 200, 16);
    Result.Caption := ACaption;
    Result.Font.Size := 11;
    Result.Font.Style := [];
    Result.Font.Color := CLR_TEXT_SLATE;
  end;

  function MakeEditConBorde(ATop, ALeft, AWidth: Integer; AReadOnly: Boolean): TEdit;
  var
    po, pi: TPanel;
  begin
    po := TPanel.Create(pnlForm);
    po.Parent := pnlForm;
    po.SetBounds(ALeft, ATop, AWidth, 40);
    po.BevelOuter := bvNone;
    po.Color := CLR_BORDER;

    pi := TPanel.Create(po);
    pi.Parent := po;
    pi.SetBounds(1, 1, AWidth - 2, 38);
    pi.BevelOuter := bvNone;
    pi.Color := CLR_WHITE;
    pi.BorderWidth := 6;

    Result := TEdit.Create(pi);
    Result.Parent := pi;
    Result.Align := alClient;
    Result.BorderStyle := bsNone;
    Result.Font.Size := 11;
    Result.Font.Color := CLR_TEXT;
    Result.Color := CLR_WHITE;
    if AReadOnly then
      Result.ReadOnly := True;
  end;

  procedure ConfigCombo(Cmb: TComboBox; ATop, ALeft, AWidth: Integer);
  begin
    Cmb.Parent := pnlForm;
    Cmb.SetBounds(ALeft, ATop, AWidth, 40);
    Cmb.AutoSize := False;
    Cmb.Style := csDropDownList;
    Cmb.Font.Size := 12;
    Cmb.Color := CLR_WHITE;
    Cmb.Font.Color := CLR_TEXT;
  end;

begin
  inherited Create(AOwner);
  Randomize;
  FTara := 0; FPesoBruto := 0; FPesoNeto := 0; FConectado := False;
  FEditMode := False; FEditID := 0;
  FUsarTaraManual := False; FTaraManual := ''; FTaraCapturada := -1;
  Self.Color := CLR_BG;

  // Header
  Pnl := TPanel.Create(Self);
  Pnl.Parent := Self;
  Pnl.Align := alTop;
  Pnl.Height := 64;
  Pnl.BevelOuter := bvNone;
  Pnl.Color := CLR_BG;
  Pnl.BorderSpacing.Top := 15;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(24, 18, 200, 28);
  Lbl.Caption := 'Pesaje';
  Lbl.Font.Height := -24;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // ── CARD: Registro de peso left ──
  CardW := 550;
  InnerW := CardW - 48;
  pnlRegistroCard := TPanel.Create(Self);
  pnlRegistroCard.Parent := Self;
  pnlRegistroCard.SetBounds(
    24, 
    80, 
    CardW, 
    Self.ClientHeight - 330
    );
  pnlRegistroCard.Anchors := [akTop, akLeft, akBottom];
  pnlRegistroCard.BevelOuter := bvLowered;
  pnlRegistroCard.BevelInner := bvNone;
  pnlRegistroCard.BevelWidth := 1;
  pnlRegistroCard.Color := CLR_CARD;

  pnlRegistro := pnlRegistroCard;
  YPos := 20;

  lblRegistroTitle := TLabel.Create(pnlRegistro);
  lblRegistroTitle.Parent := pnlRegistro;
  lblRegistroTitle.SetBounds(24, YPos, InnerW, 20);
  lblRegistroTitle.Caption := 'Registro de peso';
  lblRegistroTitle.Font.Size := 13;
  lblRegistroTitle.Font.Color := CLR_TEXT_HEADING;
  YPos := YPos + 38;

  with TPanel.Create(pnlRegistro) do
  begin
    Parent := pnlRegistro;
    SetBounds(24, YPos, InnerW, 1);
    BevelOuter := bvNone;
    Color := CLR_BORDER;
  end;
  YPos := YPos + 20;

  pnlDisplay := TPanel.Create(pnlRegistro);
  pnlDisplay.Parent := pnlRegistro;
  pnlDisplay.SetBounds(24, YPos, InnerW, 160);
  
  pnlDisplay.BevelOuter := bvNone;
  pnlDisplay.Color := CLR_PRIMARY; // borde azul
  
  // panel interno blanco
  pi := TPanel.Create(pnlDisplay);
  pi.Parent := pnlDisplay;
  pi.SetBounds(2, 2, InnerW - 4, 156);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  
  lblPesoDisplay := TLabel.Create(pi);
  lblPesoDisplay.Parent := pi;
  lblPesoDisplay.Align := alClient;
  lblPesoDisplay.Alignment := taCenter;
  lblPesoDisplay.Layout := tlCenter;
  lblPesoDisplay.Caption := '0 kg';
  lblPesoDisplay.Font.Height := -36;
  lblPesoDisplay.Font.Style := [fsBold];
  lblPesoDisplay.Font.Color := CLR_TEXT_HEADING;
  YPos := YPos + 176;

  with TPanel.Create(pnlRegistro) do
  begin
    Parent := pnlRegistro;
    SetBounds(24, YPos, InnerW, 1);
    BevelOuter := bvNone;
    Color := CLR_BORDER;
  end;
  YPos := YPos + 20;

  // Switch conectar | Capturar peso | Capturar tara
  pnlSwitchConectar := TPanel.Create(pnlRegistro);
  pnlSwitchConectar.Parent := pnlRegistro;
  pnlSwitchConectar.SetBounds(24, YPos, 90, 40);
  pnlSwitchConectar.BevelOuter := bvNone;
  pnlSwitchConectar.Color := CLR_CARD;
  pnlSwitchConectar.Cursor := crHandPoint;
  pnlSwitchConectar.OnPaint := @SwitchConectarPaint;
  pnlSwitchConectar.OnClick := @SwitchConectarClick;

  Lbl := TLabel.Create(pnlRegistro);
  Lbl.Parent := pnlRegistro;
  Lbl.SetBounds(24, YPos + 42, 90, 14);
  Lbl.Caption := 'Conexion';
  Lbl.Font.Size := 10;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  Lbl.Alignment := taCenter;

  // ─────────────────────────────
  // BOTON CAPTURAR PESO
  // ─────────────────────────────
  pnlCapturarPeso := TPanel.Create(pnlRegistro);
  pnlCapturarPeso.Parent := pnlRegistro;
  pnlCapturarPeso.SetBounds(
    130,
    YPos,
    150,
    36
  );
  pnlCapturarPeso.BevelOuter := bvNone;
  pnlCapturarPeso.Color := CLR_PRIMARY;
  pnlCapturarPeso.ParentBackground := False;
  pnlCapturarPeso.ParentColor := False;
  pnlCapturarPeso.Cursor := crHandPoint;
  pnlCapturarPeso.OnPaint := @PaintRounded;
  pnlCapturarPeso.OnClick := @CapturarPesoClick;
  //pnlCapturarPeso.Enabled := False;
  
  // TEXTO BOTON PESO
  Lbl := TLabel.Create(pnlCapturarPeso);
  Lbl.Parent := pnlCapturarPeso;
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Caption := 'Capturar peso';
  Lbl.Font.Size := 12;
  Lbl.Font.Style := [];
  Lbl.Font.Color := CLR_WHITE;
  Lbl.Transparent := True;
  Lbl.ParentColor := False;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @CapturarPesoClick;
  
  // ─────────────────────────────
  // BOTON CAPTURAR TARA
  // ─────────────────────────────
  pnlCapturarTara := TPanel.Create(pnlRegistro);
  pnlCapturarTara.Parent := pnlRegistro;
  pnlCapturarTara.SetBounds(
    295,
    YPos,
    150,
    36
  );
  pnlCapturarTara.BevelOuter := bvNone;
  pnlCapturarTara.Color := CLR_INFO;
  pnlCapturarTara.ParentBackground := False;
  pnlCapturarTara.ParentColor := False;
  pnlCapturarTara.Cursor := crHandPoint;
  pnlCapturarTara.OnPaint := @PaintRounded;
  pnlCapturarTara.OnClick := @TaraClick;
  //pnlCapturarTara.Enabled := False;
  
  // TEXTO BOTON TARA
  Lbl := TLabel.Create(pnlCapturarTara);
  Lbl.Parent := pnlCapturarTara;
  Lbl.Align := alClient;
  Lbl.Alignment := taCenter;
  Lbl.Layout := tlCenter;
  Lbl.Caption := 'Capturar tara';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_WHITE;
  Lbl.Transparent := True;
  Lbl.Cursor := crHandPoint;
  Lbl.OnClick := @TaraClick;
  YPos := YPos + 90;

  // Peso Bruto | Peso tara | Peso Neto
  Lbl := TLabel.Create(pnlRegistro);
  Lbl.Parent := pnlRegistro;
  Lbl.SetBounds(60, YPos, 140, 16);
  Lbl.Caption := 'Peso Bruto';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  
  Lbl := TLabel.Create(pnlRegistro);
  Lbl.Parent := pnlRegistro;
  Lbl.SetBounds(240, YPos, 140, 16);
  Lbl.Caption := 'Peso tara';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  
  Lbl := TLabel.Create(pnlRegistro);
  Lbl.Parent := pnlRegistro;
  Lbl.SetBounds(416, YPos, 140, 16);
  Lbl.Caption := 'Peso Neto';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  
  YPos := YPos + 24;
  
  // ───── Peso Bruto ─────
  po := TPanel.Create(pnlRegistro);
  po.Parent := pnlRegistro;
  po.SetBounds(24, YPos, 150, 40);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, 148, 38);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  pi.BorderWidth := 6;
  
  lblValBruto := TLabel.Create(pi);
  lblValBruto.Parent := pi;
  lblValBruto.Align := alClient;
  lblValBruto.Alignment := taCenter;
  lblValBruto.Layout := tlCenter;
  lblValBruto.Caption := '0';
  lblValBruto.Font.Size := 12;
  lblValBruto.Font.Style := [fsBold];
  lblValBruto.Font.Color := CLR_TEXT_HEADING;
  
  // ───── Peso Tara ─────
  po := TPanel.Create(pnlRegistro);
  po.Parent := pnlRegistro;
  po.SetBounds(200, YPos, 150, 40);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, 148, 38);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  pi.BorderWidth := 6;
  
  lblValTara := TLabel.Create(pi);
  lblValTara.Parent := pi;
  lblValTara.Align := alClient;
  lblValTara.Alignment := taCenter;
  lblValTara.Layout := tlCenter;
  lblValTara.Caption := '0';
  lblValTara.Font.Size := 12;
  lblValTara.Font.Style := [fsBold];
  lblValTara.Font.Color := CLR_TEXT_HEADING;
  
  // ───── Peso Neto ─────
  po := TPanel.Create(pnlRegistro);
  po.Parent := pnlRegistro;
  po.SetBounds(376, YPos, 150, 40);
  po.BevelOuter := bvNone;
  po.Color := CLR_BORDER;
  
  pi := TPanel.Create(po);
  pi.Parent := po;
  pi.SetBounds(1, 1, 148, 38);
  pi.BevelOuter := bvNone;
  pi.Color := CLR_WHITE;
  pi.BorderWidth := 6;
  
  lblValNeto := TLabel.Create(pi);
  lblValNeto.Parent := pi;
  lblValNeto.Align := alClient;
  lblValNeto.Alignment := taCenter;
  lblValNeto.Layout := tlCenter;
  lblValNeto.Caption := '0';
  lblValNeto.Font.Size := 12;
  lblValNeto.Font.Style := [fsBold];
  lblValNeto.Font.Color := CLR_TEXT_HEADING;

  // ── RIGHT PANEL ──
  pnlForm := TPanel.Create(Self);
  pnlForm.Parent := Self;
  pnlForm.SetBounds(
    CardW + 60, 
    80, 
    Self.ClientWidth - 635, 
    Self.ClientHeight - 330
    );
  pnlForm.Anchors := [akTop, akLeft, akRight, akBottom];
  pnlForm.BevelOuter := bvLowered;
  pnlForm.BevelInner := bvNone;
  pnlForm.BevelWidth := 1;
  pnlForm.Color := CLR_CARD;

  YPos := 20;

  lblFormTitle := TLabel.Create(pnlForm);
  lblFormTitle.Parent := pnlForm;
  lblFormTitle.SetBounds(COL1, YPos, 300, 20);
  lblFormTitle.Caption := 'Datos del Pesaje';
  lblFormTitle.Font.Size := 13;
  lblFormTitle.Font.Style := [];
  lblFormTitle.Font.Color := CLR_TEXT_HEADING;
  YPos := YPos + 38;

    // LINEA AQUI
  with TPanel.Create(pnlForm) do
  begin
    Parent := pnlForm;
    SetBounds(COL1, YPos, COL3 + FIELD_W - COL1, 1);
    BevelOuter := bvNone;
    Color := CLR_BORDER;
  end;
  
  YPos := YPos + 28;

  // ════ Fila 1: Chofer | Placa * | Licencia ════
  MakeLabel(YPos, COL1, 'Chofer');
  MakeLabel(YPos, COL2, 'Placa');
  Lbl := TLabel.Create(pnlForm);
  Lbl.Parent := pnlForm;
  Lbl.SetBounds(COL2 + 36, YPos, 20, 16);
  Lbl.Caption := '*';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_DESTRUCTIVE;
  Lbl.Font.Style := [fsBold];
  MakeLabel(YPos, COL3, 'Licencia');
  YPos := YPos + 28;

  cmbChofer := TComboBox.Create(pnlForm);
  ConfigCombo(cmbChofer, YPos, COL1, COMBO_W);
  cmbChofer.OnChange := @ChoferChange;
  btnChoNuevo := CrearBoton(pnlForm, YPos, COL1 + COMBO_W + 4, 24, 40, '+', CLR_WHITE, CLR_SUCCESS, 1, @QuickChoferClick);

  cmbVehiculo := TComboBox.Create(pnlForm);
  ConfigCombo(cmbVehiculo, YPos, COL2, COMBO_W);
  cmbVehiculo.OnChange := @VehiculoChange;
  btnVehNuevo := CrearBoton(pnlForm, YPos, COL2 + COMBO_W + 4, 24, 40, '+', CLR_WHITE, CLR_SUCCESS, 1, @QuickVehiculoClick);

  edtLicencia := MakeEditConBorde(YPos, COL3, FIELD_W, True);
  edtLicencia.Text := '';
  YPos := YPos + 48;

  // ════ Fila 2: Tipo | Proveedor | Producto ════
  MakeLabel(YPos, COL1, 'Tipo vehiculo');
  MakeLabel(YPos, COL2, 'Proveedor');
  MakeLabel(YPos, COL3, 'Producto');
  YPos := YPos + 28;

  edtTipo := MakeEditConBorde(YPos, COL1, FIELD_W, True);
  edtTipo.Text := '';

  cmbProveedor := TComboBox.Create(pnlForm);
  ConfigCombo(cmbProveedor, YPos, COL2, FIELD_W);

  cmbProducto := TComboBox.Create(pnlForm);
  ConfigCombo(cmbProducto, YPos, COL3, FIELD_W);
  YPos := YPos + 48;

  // ════ Fila 3: Origen | Destino | Costo ════
  MakeLabel(YPos, COL1, 'Origen');
  MakeLabel(YPos, COL2, 'Destino');
  MakeLabel(YPos, COL3, 'Costo (Bs)');
  YPos := YPos + 28;

  cmbOrigen := TComboBox.Create(pnlForm);
  ConfigCombo(cmbOrigen, YPos, COL1, FIELD_W);

  cmbDestino := TComboBox.Create(pnlForm);
  ConfigCombo(cmbDestino, YPos, COL2, FIELD_W);

  edtCosto := MakeEditConBorde(YPos, COL3, FIELD_W, False);
  edtCosto.Text := '0';
  YPos := YPos + 48;

  // ════ Fila 4: Flete | Tara ════
  MakeLabel(YPos, COL1, 'Flete pend. (Bs)');
  MakeLabel(YPos, COL2, 'Tara (kg)');
  YPos := YPos + 28;

  edtFlete := MakeEditConBorde(YPos, COL1, FIELD_W, False);
  edtFlete.Text := '0';

  pnlSwitchTara := TPanel.Create(pnlForm);
  pnlSwitchTara.Parent := pnlForm;
  pnlSwitchTara.SetBounds(COL2, YPos, 40, 40);
  pnlSwitchTara.BevelOuter := bvNone;
  pnlSwitchTara.Color := CLR_CARD;
  pnlSwitchTara.Cursor := crHandPoint;
  pnlSwitchTara.OnPaint := @SwitchTaraPaint;
  pnlSwitchTara.OnClick := @SwitchTaraClick;

  edtTaraManual := MakeEditConBorde(YPos, COL2 + 46, 124, True);
  edtTaraManual.Text := '0';
  edtTaraManual.OnChange := @TaraManualChange;

  pnlGuardarTara := TPanel.Create(pnlForm);
  pnlGuardarTara.Parent := pnlForm;
  pnlGuardarTara.SetBounds(COL2 + 176, YPos, 34, 40);
  pnlGuardarTara.BevelOuter := bvNone;
  pnlGuardarTara.Color := CLR_SUCCESS;
  pnlGuardarTara.ParentBackground := False;
  pnlGuardarTara.ParentColor := False;
  pnlGuardarTara.Cursor := crHandPoint;
  pnlGuardarTara.Visible := False;
  pnlGuardarTara.OnPaint := @PaintRounded;
  pnlGuardarTara.OnClick := @GuardarTaraClick;
  with TLabel.Create(pnlGuardarTara) do
  begin
    Parent := pnlGuardarTara;
    Align := alClient;
    Alignment := taCenter;
    Layout := tlCenter;
    Caption := '+';
    Font.Size := 16;
    Font.Style := [];
    Font.Color := CLR_WHITE;
    Cursor := crHandPoint;
    OnClick := @GuardarTaraClick;
  end;

  YPos := YPos + 56;

  with TPanel.Create(pnlForm) do
  begin
    Parent := pnlForm;
    SetBounds(COL1, YPos, COL3 + FIELD_W - COL1, 1);
    BevelOuter := bvNone;
    Color := CLR_BORDER;
  end;
  YPos := YPos + 16;

  pnlCancelEdit := CrearBoton(pnlForm, YPos, COL1, 140, 36, 'Cancelar', CLR_WHITE, CLR_PRIMARY, 1, @CancelEditClick);
  pnlCancelEdit.Visible := False;
  pnlGuardar := CrearBoton(pnlForm, YPos, COL3 + FIELD_W - 180, 180, 36, 'Registrar Pesaje', CLR_PRIMARY, CLR_WHITE, 0, @GuardarClick);

  // ── BOTTOM GRID ──
  pnlCard := TPanel.Create(Self);
  pnlCard.Parent := Self;
  pnlCard.SetBounds(24, Self.ClientHeight - 200, Self.ClientWidth - 48, 310);
  pnlCard.Anchors := [akLeft, akRight, akBottom];
  pnlCard.BevelOuter := bvLowered; pnlCard.BevelInner := bvNone;
  pnlCard.BevelWidth := 1; pnlCard.Color := CLR_CARD;

  Grid := TStringGrid.Create(Self);
  Grid.Parent := pnlCard;
  Grid.SetBounds(2, 2, pnlCard.ClientWidth - 4, pnlCard.ClientHeight - 4);
  Grid.Anchors := [akTop, akLeft, akRight, akBottom];
  Grid.ColCount := 19; Grid.RowCount := 2; Grid.FixedRows := 1; Grid.FixedCols := 0;
  Grid.Options := Grid.Options + [goRowSelect];
  Grid.DefaultRowHeight := 36; Grid.RowHeights[0] := 40;
  Grid.Color := CLR_CARD; Grid.FixedColor := CLR_CARD;
  Grid.Font.Height := -12; Grid.Font.Color := CLR_TEXT_HEADING;
  Grid.TitleFont.Height := -10; Grid.TitleFont.Style := [fsBold]; Grid.TitleFont.Color := CLR_TEXT_SLATE;
  Grid.GridLineWidth := 0; Grid.Flat := True; Grid.FocusRectVisible := False; Grid.BorderStyle := bsNone;

  Grid.Cells[0,0]:='ID'; Grid.Cells[1,0]:='Chofer'; Grid.Cells[2,0]:='Placa';
  Grid.Cells[3,0]:='Licencia'; Grid.Cells[4,0]:='Tipo'; Grid.Cells[5,0]:='Proveedor';
  Grid.Cells[6,0]:='Producto'; Grid.Cells[7,0]:='Origen'; Grid.Cells[8,0]:='Destino';
  Grid.Cells[9,0]:='Costo'; Grid.Cells[10,0]:='Flete'; Grid.Cells[11,0]:='Fecha';
  Grid.Cells[12,0]:='Hora'; Grid.Cells[13,0]:='P.Bruto'; Grid.Cells[14,0]:='P.Tara';
  Grid.Cells[15,0]:='P.Neto'; Grid.Cells[16,0]:='Estado'; Grid.Cells[17,0]:='Est.Pesaje';
  Grid.Cells[18,0]:='Acciones';

  Grid.ColWidths[0]:=50; Grid.ColWidths[1]:=180; Grid.ColWidths[2]:=100;
  Grid.ColWidths[3]:=100; Grid.ColWidths[4]:=100; Grid.ColWidths[5]:=180;
  Grid.ColWidths[6]:=120; Grid.ColWidths[7]:=120; Grid.ColWidths[8]:=120;
  Grid.ColWidths[9]:=70; Grid.ColWidths[10]:=70; Grid.ColWidths[11]:=70;
  Grid.ColWidths[12]:=50; Grid.ColWidths[13]:=70; Grid.ColWidths[14]:=70;
  Grid.ColWidths[15]:=70; Grid.ColWidths[16]:=85; Grid.ColWidths[17]:=90;
  Grid.ColWidths[18]:=180;
  Grid.OnDrawCell := @GridDrawCell;
  Grid.OnMouseDown := @GridMouseDown;

  TimerLectura := TTimer.Create(Self);
  TimerLectura.Interval := 300; TimerLectura.OnTimer := @TimerLecturaTimer;
  TimerLectura.Enabled := False;
  CargarCombos;
  RefrescarPesajes(nil);
end;

destructor TFramePesaje.Destroy;
begin
  if FConectado then begin DM.DesconectarSerial; FConectado := False; end;
  inherited Destroy;
end;

// ═══════════════════════════════════════════════
// SERIAL / BASCULA
// ═══════════════════════════════════════════════

procedure TFramePesaje.TimerLecturaTimer(Sender: TObject);
var PesoSimulado: Integer;
begin
  if not FConectado then Exit;

  // Simulación: peso aleatorio 1000-5000 kg
  PesoSimulado := Random(4001) + 1000;
  lblPesoDisplay.Caption := IntToStr(PesoSimulado) + ' kg';

  if FTara > 0 then
  begin
    FPesoBruto := PesoSimulado;
    FPesoNeto := FPesoBruto - FTara;
    ActualizarResumenPesos;
  end;

  // === CÓDIGO REAL (serial) COMENTADO TEMPORALMENTE ===
  // Trama := DM.LeerPuertoSerial;
  // if Trama <> '' then ProcesarTrama(Trama);
end;

procedure TFramePesaje.ActualizarResumenPesos;
begin
  if lblValBruto <> nil then lblValBruto.Caption := IntToStr(FPesoBruto);
  if lblValTara <> nil then lblValTara.Caption := IntToStr(FTara);
  if lblValNeto <> nil then lblValNeto.Caption := IntToStr(FPesoNeto);
  if pnlSwitchConectar <> nil then pnlSwitchConectar.Invalidate;
end;

function PesoDesdeDisplay(const ACaption: string): Integer;
var S: string;
begin
  S := Trim(ACaption);
  if EndsText(' kg', S) then
    Delete(S, Length(S) - 2, 3);
  Result := StrToIntDef(S, 0);
end;

procedure TFramePesaje.SwitchConectarPaint(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Font.Height := -13;
  Pnl.Canvas.Font.Style := [fsBold];
  Ts := Pnl.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  if FConectado then
  begin
    Pnl.Canvas.Font.Color := CLR_SUCCESS;
    Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, '● ──', Ts);
  end
  else
  begin
    Pnl.Canvas.Font.Color := CLR_DESTRUCTIVE;
    Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, '○ ──', Ts);
  end;
end;

procedure TFramePesaje.SwitchConectarClick(Sender: TObject);
begin
  ConectarClick(Sender);
end;

procedure TFramePesaje.CapturarPesoClick(Sender: TObject);
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

procedure TFramePesaje.ProcesarTrama(const Trama: string);
var PesoStr: string; PesoVal: Integer;
begin
  PesoStr := ExtraerPeso(Trama);
  if PesoStr = '' then Exit;
  PesoVal := StrToIntDef(PesoStr, 0);
  lblPesoDisplay.Caption := IntToStr(PesoVal) + ' kg';
  if FTara > 0 then
  begin
    FPesoBruto := PesoVal;
    FPesoNeto := FPesoBruto - FTara;
    ActualizarResumenPesos;
  end;
end;

function TFramePesaje.ExtraerPeso(const Trama: string): string;
var i: Integer; c: Char; EnPeso: Boolean;
begin
  Result := ''; EnPeso := False;
  for i := 1 to Length(Trama) do begin
    c := Trama[i];
    if (c >= '0') and (c <= '9') then begin EnPeso := True; Result := Result + c; end
    else if EnPeso and (c = '.') then Result := Result + c
    else if EnPeso then Break;
  end;
  if Length(Result) < 2 then Result := '';
end;

// ═══════════════════════════════════════════════
// COMBO LOADING
// ═══════════════════════════════════════════════

procedure TFramePesaje.CargarCombos;
var Q: TSQLQuery;
  procedure LlenarCombo(Cmb: TComboBox; const SQL, CampoValor, CampoTexto: string);
  begin
    Cmb.Items.Clear; Cmb.Items.Add('- Seleccione -'); Cmb.ItemIndex := 0;
    Q := DM.AbrirQuery(SQL);
    try
      while not Q.EOF do begin
        Cmb.Items.AddObject(Q.FieldByName(CampoTexto).AsString,
          TObject(PtrInt(Q.FieldByName(CampoValor).AsInteger)));
        Q.Next;
      end;
    finally Q.Close; end;
  end;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;
  LlenarCombo(cmbVehiculo, 'SELECT id, placa FROM vehiculos WHERE estado=''ACTIVO'' ORDER BY placa', 'id', 'placa');
  LlenarCombo(cmbChofer, 'SELECT c.id, p.nombre||'' ''||p.apellido_paterno AS nombre ' +
    'FROM choferes c INNER JOIN personas p ON p.id=c.persona_id WHERE c.estado=''ACTIVO'' AND p.estado=''ACTIVO'' ORDER BY p.nombre', 'id', 'nombre');
  LlenarCombo(cmbProveedor, 'SELECT pr.id, p.nombre||'' ''||COALESCE(p.apellido_paterno,'''')||'' ''||COALESCE(p.apellido_materno,'''') AS nombre ' +
    'FROM proveedores pr INNER JOIN personas p ON p.id=pr.persona_id WHERE pr.estado=''ACTIVO'' AND p.estado=''ACTIVO'' ORDER BY p.nombre', 'id', 'nombre');
  LlenarCombo(cmbProducto, 'SELECT id, nombre FROM productos WHERE estado=''ACTIVO'' ORDER BY nombre', 'id', 'nombre');
  LlenarCombo(cmbOrigen, 'SELECT id, nombre FROM origenes WHERE estado=''ACTIVO'' ORDER BY nombre', 'id', 'nombre');
  LlenarCombo(cmbDestino, 'SELECT id, nombre FROM destinos WHERE estado=''ACTIVO'' ORDER BY nombre', 'id', 'nombre');
end;

procedure TFramePesaje.VehiculoChange(Sender: TObject);
var Q: TSQLQuery; Vid: Integer;
begin
  if cmbVehiculo.ItemIndex < 1 then Exit;
  Vid := PtrInt(cmbVehiculo.Items.Objects[cmbVehiculo.ItemIndex]);
  Q := DM.AbrirQuery('SELECT tara, tipo_vehiculo FROM vehiculos WHERE id=' + IntToStr(Vid));
  try
    if not Q.EOF then
    begin
      FTara := Q.Fields[0].AsInteger;
      edtTipo.Text := UpperCase(Q.Fields[1].AsString);
      edtTaraManual.Text := IntToStr(FTara);
      FTaraManual := IntToStr(FTara);
      ActualizarResumenPesos;
    end;
  finally Q.Close; end;
end;

procedure TFramePesaje.ChoferChange(Sender: TObject);
var Q: TSQLQuery; Cid: Integer;
begin
  if cmbChofer.ItemIndex < 1 then begin edtLicencia.Text := ''; Exit; end;
  Cid := PtrInt(cmbChofer.Items.Objects[cmbChofer.ItemIndex]);
  Q := DM.AbrirQuery('SELECT licencia FROM choferes WHERE id=' + IntToStr(Cid));
  try
    if not Q.EOF then edtLicencia.Text := UpperCase(Q.Fields[0].AsString);
  finally Q.Close; end;
end;

// ═══════════════════════════════════════════════
// PESAJES GRID
// ═══════════════════════════════════════════════

procedure TFramePesaje.RefrescarPesajes(Sender: TObject);
var Q: TSQLQuery; Row, ID: Integer; FechaStr: string;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;
  Q := DM.AbrirQuery(
    'SELECT p.id, ' +
    'COALESCE(pe.nombre||'' ''||pe.apellido_paterno,'''') as chofer, v.placa, ' +
    'COALESCE(c.licencia,'''') as licencia, COALESCE(v.tipo_vehiculo,'''') as tipo, ' +
    'COALESCE(pp.nombre||'' ''||pp.apellido_paterno,'''') as proveedor, ' +
    'COALESCE(pr.nombre,'''') as producto, COALESCE(o.nombre,'''') as origen, ' +
    'COALESCE(d.nombre,'''') as destino, p.costo_bs, p.flete_bs_pendiente, ' +
    'p.fecha_creacion, p.peso_bruto, p.tara, p.peso_neto, ' +
    'COALESCE(ps.nombre,'''') as pesador, p.estado, p.estado_balanza ' +
    'FROM pesajes p ' +
    'LEFT JOIN vehiculos v ON v.id=p.vehiculo_id ' +
    'LEFT JOIN choferes c ON c.id=p.chofer_id LEFT JOIN personas pe ON pe.id=c.persona_id ' +
    'LEFT JOIN proveedores ppv ON ppv.id=p.proveedor_id LEFT JOIN personas pp ON pp.id=ppv.persona_id ' +
    'LEFT JOIN productos pr ON pr.id=p.producto_id ' +
    'LEFT JOIN origenes o ON o.id=p.id_origen ' +
    'LEFT JOIN destinos d ON d.id=p.id_destino ' +
    'LEFT JOIN personas ps ON ps.id=p.pesador_id ' +
    'WHERE p.estado IN (''ACTIVO'',''INACTIVO'') ORDER BY p.id DESC LIMIT 50');
  Grid.RowCount := Q.RecordCount + 1; Row := 1;
  while not Q.EOF do begin
    ID := Q.Fields[0].AsInteger;
    Grid.Objects[0, Row] := TObject(PtrInt(ID));
    FechaStr := Q.Fields[11].AsString;
    if Length(FechaStr) >= 16 then
    begin
      Grid.Cells[11,Row] := Copy(FechaStr,9,2)+'/'+Copy(FechaStr,6,2)+'/'+Copy(FechaStr,1,4);
      Grid.Cells[12,Row] := Copy(FechaStr,12,5);
    end else begin
      Grid.Cells[11,Row] := Copy(FechaStr,1,10);
      Grid.Cells[12,Row] := '';
    end;
    Grid.Cells[0,Row] := IntToStr(ID);
    Grid.Cells[1,Row]:=UpperCase(Q.Fields[1].AsString);
    Grid.Cells[2,Row]:=UpperCase(Q.Fields[2].AsString);
    Grid.Cells[3,Row]:=UpperCase(Q.Fields[3].AsString);
    Grid.Cells[4,Row]:=UpperCase(Q.Fields[4].AsString);
    Grid.Cells[5,Row]:=UpperCase(Q.Fields[5].AsString);
    Grid.Cells[6,Row]:=UpperCase(Q.Fields[6].AsString);
    Grid.Cells[7,Row]:=UpperCase(Q.Fields[7].AsString);
    Grid.Cells[8,Row]:=UpperCase(Q.Fields[8].AsString);
    Grid.Cells[9,Row]:=Q.Fields[9].AsString;
    Grid.Cells[10,Row]:=Q.Fields[10].AsString;
    Grid.Cells[13,Row]:=Q.Fields[12].AsString;
    Grid.Cells[14,Row]:=Q.Fields[13].AsString;
    Grid.Cells[15,Row]:=Q.Fields[14].AsString;
    Grid.Cells[16,Row]:=UpperCase(Q.Fields[16].AsString);
    Grid.Cells[17,Row]:=UpperCase(Q.Fields[17].AsString);
    Grid.Cells[18,Row]:='';
    Q.Next; Inc(Row);
  end;
  Q.Close;
end;

procedure TFramePesaje.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var Ts: TTextStyle; IsSelected: Boolean;
begin
  if aRow = 0 then begin
    Grid.Canvas.Brush.Color := CLR_CARD; Grid.Canvas.FillRect(aRect);
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
    Ts := Grid.Canvas.TextStyle; Ts.Alignment := taCenter; Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);
    Exit;
  end;
  IsSelected := gdSelected in aState;

  // Columna Estado: badge
  if aCol = 16 then begin
    if IsSelected then Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);
    if Grid.Cells[16, aRow] = 'ACTIVO' then
    begin Grid.Canvas.Brush.Color := CLR_SUCCESS_BG; Grid.Canvas.Font.Color := CLR_TEAL; end
    else begin Grid.Canvas.Brush.Color := CLR_DESTRUCTIVE_BG; Grid.Canvas.Font.Color := CLR_DESTRUCTIVE; end;
    Grid.Canvas.Pen.Style := psClear;
    Grid.Canvas.RoundRect(aRect.Left + 2, aRect.Top + 6, aRect.Left + (aRect.Right - aRect.Left) - 2, aRect.Top + 30, 12, 12);
    Grid.Canvas.Font.Height := -11; Grid.Canvas.Font.Style := [fsBold];
    Ts := Grid.Canvas.TextStyle; Ts.Alignment := taCenter; Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top, Grid.Cells[16, aRow], Ts);
    Exit;
  end;

  // Columna EstPesaje: badge
  if aCol = 17 then begin
    if IsSelected then Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);
    if Grid.Cells[17, aRow] = 'FINALIZADO' then
    begin Grid.Canvas.Brush.Color := CLR_INFO_BG; Grid.Canvas.Font.Color := CLR_INFO; end
    else begin Grid.Canvas.Brush.Color := CLR_WARNING_BG; Grid.Canvas.Font.Color := CLR_WARNING; end;
    Grid.Canvas.Pen.Style := psClear;
    Grid.Canvas.RoundRect(aRect.Left + 2, aRect.Top + 6, aRect.Left + (aRect.Right - aRect.Left) - 2, aRect.Top + 30, 12, 12);
    Grid.Canvas.Font.Height := -10; Grid.Canvas.Font.Style := [fsBold];
    Ts := Grid.Canvas.TextStyle; Ts.Alignment := taCenter; Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top, Grid.Cells[17, aRow], Ts);
    Exit;
  end;

  // Columna Acciones
  if aCol = 18 then begin
    if IsSelected then Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);
    Grid.Canvas.Font.Height := -11; Grid.Canvas.Font.Style := [fsBold];
    Ts := Grid.Canvas.TextStyle; Ts.Layout := tlCenter;

    if Grid.Cells[16, aRow] = 'ACTIVO' then
    begin
      if Grid.Cells[17, aRow] = 'EN_PROCESO' then
      begin
        // Toggle ●/○
        Grid.Canvas.Font.Color := CLR_SUCCESS;
        Ts.Alignment := taCenter;
        Grid.Canvas.TextRect(Rect(aRect.Left + 20, aRect.Top, aRect.Left + 55, aRect.Bottom),
          aRect.Left + 20, aRect.Top + 2, '● ──', Ts);
        // Edit
        Grid.Canvas.Font.Color := CLR_PRIMARY;
        Grid.Canvas.TextRect(Rect(aRect.Left + 55, aRect.Top, aRect.Left + 110, aRect.Bottom),
          aRect.Left + 55, aRect.Top + 2, '✏️', Ts);
        // Finalizar
        Grid.Canvas.Font.Color := CLR_INFO;
        Grid.Canvas.TextRect(Rect(aRect.Left + 110, aRect.Top, aRect.Left + 160, aRect.Bottom),
          aRect.Left + 110, aRect.Top + 2, '✅', Ts);
      end
      else // FINALIZADO
      begin
        // Toggle ●/○
        Grid.Canvas.Font.Color := CLR_SUCCESS;
        Ts.Alignment := taCenter;
        Grid.Canvas.TextRect(Rect(aRect.Left + 20, aRect.Top, aRect.Left + 90, aRect.Bottom),
          aRect.Left + 20, aRect.Top + 2, '● ──', Ts);
        // Boleta
        Grid.Canvas.Font.Color := CLR_PRIMARY;
        Grid.Canvas.TextRect(Rect(aRect.Left + 90, aRect.Top, aRect.Left + 160, aRect.Bottom),
          aRect.Left + 90, aRect.Top + 2, '📄', Ts);
      end;
    end
    else // INACTIVO
    begin
      Grid.Canvas.Font.Color := CLR_DESTRUCTIVE;
      Ts.Alignment := taCenter;
      Grid.Canvas.TextRect(Rect(aRect.Left + 20, aRect.Top, aRect.Left + 55, aRect.Bottom),
        aRect.Left + 20, aRect.Top + 2, '○ ──', Ts);
    end;
    Exit;
  end;

  if IsSelected then Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
  else Grid.Canvas.Brush.Color := CLR_CARD;
  Grid.Canvas.FillRect(aRect);
  Ts := Grid.Canvas.TextStyle; Ts.Alignment := taCenter; Ts.Layout := tlCenter;
  Grid.Canvas.Font.Height := -12; Grid.Canvas.Font.Color := CLR_TEXT_HEADING; Grid.Canvas.Font.Style := [];
  Grid.Canvas.TextRect(aRect, aRect.Left + 6, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);
  if aCol = 0 then begin
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
  end;
end;

procedure TFramePesaje.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var Col, Row: Integer; ID, TotalH, I: Integer; CellW: Integer;
begin
  if Button <> mbLeft then Exit;
  Grid.MouseToCell(X, Y, Col, Row);
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;
  TotalH := 0;
  for I := 0 to Grid.RowCount - 1 do TotalH := TotalH + Grid.RowHeights[I];
  if Y > TotalH then Exit;
  if Col <> 18 then Exit;
  ID := PtrInt(Grid.Objects[0, Row]);
  CellW := Grid.CellRect(Col, Row).Right - Grid.CellRect(Col, Row).Left;

  if Grid.Cells[16, Row] = 'ACTIVO' then
  begin
    if Grid.Cells[17, Row] = 'EN_PROCESO' then
    begin
      if X < Grid.CellRect(Col, Row).Left + CellW div 3 then
        ToggleEstadoPesaje(ID, Grid.Cells[16, Row])
      else if X < Grid.CellRect(Col, Row).Left + 2 * CellW div 3 then
        CargarPesaje(ID)
      else
        FinalizarPesaje(ID);
    end
    else // FINALIZADO
    begin
      if X < Grid.CellRect(Col, Row).Left + CellW div 2 then
        ToggleEstadoPesaje(ID, Grid.Cells[16, Row])
      else
        ShowMessage('Boleta PDF - Fase 3');
    end;
  end
  else // INACTIVO
  begin
    if X < Grid.CellRect(Col, Row).Left + CellW div 3 then
      ToggleEstadoPesaje(ID, Grid.Cells[16, Row]);
  end;
end;

// ═══════════════════════════════════════════════
// LOAD PESAJE FOR EDIT
// ═══════════════════════════════════════════════

procedure TFramePesaje.CargarPesaje(ID: Integer);
var Q: TSQLQuery;
begin
  if ID = 0 then Exit;
  Q := DM.AbrirQuery(
    'SELECT vehiculo_id, chofer_id, proveedor_id, producto_id, id_origen, id_destino, ' +
    'peso_bruto, tara, costo_bs, flete_bs_pendiente FROM pesajes WHERE id=' + IntToStr(ID));
  try
    if Q.EOF then Exit;
    FEditMode := True; FEditID := ID;
    cmbVehiculo.ItemIndex := BuscarComboIndex(cmbVehiculo, Q.Fields[0].AsInteger);
    cmbChofer.ItemIndex := BuscarComboIndex(cmbChofer, Q.Fields[1].AsInteger);
    cmbProveedor.ItemIndex := BuscarComboIndex(cmbProveedor, Q.Fields[2].AsInteger);
    cmbProducto.ItemIndex := BuscarComboIndex(cmbProducto, Q.Fields[3].AsInteger);
    cmbOrigen.ItemIndex := BuscarComboIndex(cmbOrigen, Q.Fields[4].AsInteger);
    cmbDestino.ItemIndex := BuscarComboIndex(cmbDestino, Q.Fields[5].AsInteger);
    FPesoBruto := Q.Fields[6].AsInteger; FTara := Q.Fields[7].AsInteger;
    FPesoNeto := FPesoBruto - FTara;
    lblPesoDisplay.Caption := IntToStr(FPesoBruto) + ' kg';
    ActualizarResumenPesos;
    edtCosto.Text := Q.Fields[8].AsString;
    edtFlete.Text := Q.Fields[9].AsString;
    lblFormTitle.Caption := 'Editar Pesaje #' + IntToStr(ID);
    TLabel(pnlGuardar.Controls[0]).Caption := 'Actualizar Pesaje';
    pnlCancelEdit.Visible := True;
  finally Q.Close; end;
end;

// ═══════════════════════════════════════════════
// PESAJE ACTIONS
// ═══════════════════════════════════════════════

procedure TFramePesaje.FinalizarPesaje(ID: Integer);
var
  Q: TSQLQuery;
  Bruto, Tara, Neto: Integer;
begin
  Q := DM.AbrirQuery('SELECT peso_bruto, tara, peso_neto FROM pesajes WHERE id=' + IntToStr(ID));
  try
    Bruto := Q.FieldByName('peso_bruto').AsInteger;
    Tara := Q.FieldByName('tara').AsInteger;
    Neto := Q.FieldByName('peso_neto').AsInteger;
  finally
    Q.Close;
  end;

  if (Bruto <= 0) or (Tara <= 0) then
  begin
    ShowMessage('No se puede finalizar. Falta registrar el peso bruto o la tara.');
    Exit;
  end;

  if not MostrarDialogFinalizar(ID, Bruto, Tara, Neto) then Exit;

  if DM.Transaccion.Active then DM.Transaccion.Rollback;
  DM.Transaccion.StartTransaction;
  try
    DM.EjecutarSQL('UPDATE pesajes SET estado_balanza=''FINALIZADO'',' +
      ' usuario_modificacion=' + IntToStr(UsuarioActual.ID) +
      ', fecha_modificacion=''' + FechaHoraActual +
      ''' WHERE id=' + IntToStr(ID) + ' AND estado_balanza=''EN_PROCESO''');
    DM.Transaccion.Commit;
    RefrescarPesajes(nil);
  except
    DM.Transaccion.Rollback;
    ShowMessage('Error al finalizar el pesaje');
  end;
end;

procedure TFramePesaje.AnularPesaje(ID: Integer);
begin
  if MessageDlg('Anular pesaje', 'Se cambiara el estado a INACTIVO. Continuar?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  if DM.Transaccion.Active then DM.Transaccion.Rollback;
  DM.Transaccion.StartTransaction;
  try
    DM.EjecutarSQL('UPDATE pesajes SET estado=''INACTIVO'',' +
      ' usuario_modificacion=' + IntToStr(UsuarioActual.ID) +
      ', fecha_modificacion=''' + FechaHoraActual +
      ''' WHERE id=' + IntToStr(ID));
    DM.Transaccion.Commit;
    RefrescarPesajes(nil);
  except
    DM.Transaccion.Rollback;
  end;
end;

procedure TFramePesaje.ToggleEstadoPesaje(ID: Integer; EstadoActual: string);
var NuevoEstado: string;
begin
  if EstadoActual = 'ACTIVO' then NuevoEstado := 'INACTIVO' else NuevoEstado := 'ACTIVO';
  if DM.Transaccion.Active then DM.Transaccion.Rollback;
  DM.Transaccion.StartTransaction;
  try
    DM.EjecutarSQL('UPDATE pesajes SET estado=''' + NuevoEstado +
      ''', usuario_modificacion=' + IntToStr(UsuarioActual.ID) +
      ', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(ID));
    DM.Transaccion.Commit;
    RefrescarPesajes(nil);
  except
    DM.Transaccion.Rollback;
  end;
end;

// ═══════════════════════════════════════════════
// BUTTON EVENTS
// ═══════════════════════════════════════════════

procedure TFramePesaje.ConectarClick(Sender: TObject);
begin
  if FConectado then
  begin
    // DM.DesconectarSerial;
    TimerLectura.Enabled := False;
    FConectado := False;
    pnlCapturarPeso.Enabled := False;
    pnlCapturarTara.Enabled := False;
    ActualizarResumenPesos;
  end
  else
  begin
    // Simulación: conexión directa sin puerto serial
    // if DM.ConectarSerial('COM4', 9600, 8, 'N', 1) then
    TimerLectura.Enabled := True;
    FConectado := True;
    pnlCapturarPeso.Enabled := True;
    pnlCapturarTara.Enabled := True;
    ActualizarResumenPesos;
    // else ShowMessage('No se pudo conectar al puerto COM4');
  end;
end;

procedure TFramePesaje.TaraClick(Sender: TObject);
begin
  if not FConectado then
  begin
    ShowMessage('Conecte la balanza primero');
    Exit;
  end;
  if not FUsarTaraManual then
  begin
    ShowMessage('Active el modo manual de tara para capturar');
    Exit;
  end;
  FTara := PesoDesdeDisplay(lblPesoDisplay.Caption);
  if FTara <= 0 then
  begin
    ShowMessage('Peso invalido');
    Exit;
  end;
  FTaraCapturada := FTara;
  FTaraManual := IntToStr(FTara);
  edtTaraManual.Text := FTaraManual;
  edtTaraManual.ReadOnly := True;
  FPesoBruto := 0;
  FPesoNeto := 0;
  ActualizarResumenPesos;
end;

procedure TFramePesaje.SwitchTaraPaint(Sender: TObject);
var
  Pnl: TPanel;
  Ts: TTextStyle;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_CARD;
  Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Font.Height := -11;
  Pnl.Canvas.Font.Style := [fsBold];
  Ts := Pnl.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  if FUsarTaraManual then
  begin
    Pnl.Canvas.Font.Color := CLR_SUCCESS;
    Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, '● ──', Ts);
  end
  else
  begin
    Pnl.Canvas.Font.Color := CLR_DESTRUCTIVE;
    Pnl.Canvas.TextRect(Pnl.ClientRect, 0, 0, '○ ──', Ts);
  end;
end;

procedure TFramePesaje.SwitchTaraClick(Sender: TObject);
begin
  FUsarTaraManual := not FUsarTaraManual;

  if not FUsarTaraManual then
  begin
    FTaraManual := '';
    FTaraCapturada := -1;
    pnlGuardarTara.Visible := False;
    edtTaraManual.ReadOnly := True;
    edtTaraManual.Text := IntToStr(FTara);
  end
  else
  begin
    edtTaraManual.ReadOnly := False;
    pnlGuardarTara.Visible := True;
    if FTara > 0 then
    begin
      FTaraManual := IntToStr(FTara);
      edtTaraManual.Text := FTaraManual;
    end
    else
    begin
      FTaraManual := '';
      edtTaraManual.Text := '0';
    end;
    FTaraCapturada := -1;
  end;

  pnlSwitchTara.Invalidate;
end;

procedure TFramePesaje.TaraManualChange(Sender: TObject);
begin
  if not FUsarTaraManual then Exit;
  FTaraCapturada := -1;
  FTaraManual := edtTaraManual.Text;
  FTara := StrToIntDef(FTaraManual, 0);
  FPesoNeto := FPesoBruto - FTara;
  lblValTara.Caption := IntToStr(FTara);
  lblValNeto.Caption := IntToStr(FPesoNeto);
end;

procedure TFramePesaje.GuardarTaraClick(Sender: TObject);
var
  VehiculoID: Integer;
  NuevaTara: Integer;
begin
  if cmbVehiculo.ItemIndex < 1 then
  begin
    ShowMessage('Seleccione un vehiculo primero');
    Exit;
  end;
  NuevaTara := StrToIntDef(FTaraManual, 0);
  VehiculoID := PtrInt(cmbVehiculo.Items.Objects[cmbVehiculo.ItemIndex]);

  if DM.Transaccion.Active then DM.Transaccion.Rollback;
  DM.Transaccion.StartTransaction;
  try
    DM.EjecutarSQL('UPDATE vehiculos SET tara=' + IntToStr(NuevaTara) +
      ', usuario_modificacion=' + IntToStr(UsuarioActual.ID) +
      ', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(VehiculoID));
    DM.Transaccion.Commit;
    FTara := NuevaTara;
    FPesoNeto := FPesoBruto - FTara;
    ActualizarResumenPesos;
  except
    DM.Transaccion.Rollback;
    ShowMessage('Error al guardar tara');
  end;
end;

procedure TFramePesaje.GuardarClick(Sender: TObject);
var VehiculoID, ChoferID, ProveedorID, ProductoID, OrigenID, DestinoID: Integer;
  Costo, Flete: Integer;
  Guia, Anio: string;
  ProximoID: Integer;
  Q: TSQLQuery;
begin
  if cmbVehiculo.ItemIndex < 1 then begin ShowMessage('Seleccione un vehiculo'); Exit; end;
  if FPesoBruto < FTara then begin ShowMessage('El peso bruto no puede ser menor que la tara'); Exit; end;

  VehiculoID := PtrInt(cmbVehiculo.Items.Objects[cmbVehiculo.ItemIndex]);
  ChoferID:=0; ProveedorID:=0; ProductoID:=0; OrigenID:=0; DestinoID:=0;
  if cmbChofer.ItemIndex > 0 then ChoferID := PtrInt(cmbChofer.Items.Objects[cmbChofer.ItemIndex]);
  if cmbProveedor.ItemIndex > 0 then ProveedorID := PtrInt(cmbProveedor.Items.Objects[cmbProveedor.ItemIndex]);
  if cmbProducto.ItemIndex > 0 then ProductoID := PtrInt(cmbProducto.Items.Objects[cmbProducto.ItemIndex]);
  if cmbOrigen.ItemIndex > 0 then OrigenID := PtrInt(cmbOrigen.Items.Objects[cmbOrigen.ItemIndex]);
  if cmbDestino.ItemIndex > 0 then DestinoID := PtrInt(cmbDestino.Items.Objects[cmbDestino.ItemIndex]);
  Costo := StrToIntDef(edtCosto.Text, 0); Flete := StrToIntDef(edtFlete.Text, 0);

  // Duplicate check: same vehicle already has an active pesaje in process
  if not FEditMode then
  begin
    Q := DM.AbrirQuery('SELECT id FROM pesajes WHERE vehiculo_id=' + IntToStr(VehiculoID) +
      ' AND estado_balanza=''EN_PROCESO'' AND estado=''ACTIVO''');
    try
      if not Q.EOF then
      begin
        ShowMessage('Ya existe un pesaje en proceso para este vehiculo (#' + Q.Fields[0].AsString + ')');
        Exit;
      end;
    finally
      Q.Close;
    end;
  end;

  if not FEditMode then
  begin
    if MessageDlg('Guardar pesaje', Format('Bruto: %d kg | Tara: %d kg | Neto: %d kg. Confirmar?',
      [FPesoBruto, FTara, FPesoNeto]), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  end;

  if DM.Transaccion.Active then DM.Transaccion.Rollback;
  DM.Transaccion.StartTransaction;
  try
    if FEditMode then
    begin
      DM.EjecutarSQL('UPDATE pesajes SET vehiculo_id=' + IntToStr(VehiculoID) +
        ', chofer_id=' + IfThen(ChoferID > 0, IntToStr(ChoferID), 'NULL') +
        ', proveedor_id=' + IfThen(ProveedorID > 0, IntToStr(ProveedorID), 'NULL') +
        ', producto_id=' + IfThen(ProductoID > 0, IntToStr(ProductoID), 'NULL') +
        ', id_origen=' + IfThen(OrigenID > 0, IntToStr(OrigenID), 'NULL') +
        ', id_destino=' + IfThen(DestinoID > 0, IntToStr(DestinoID), 'NULL') +
        ', peso_bruto=' + IntToStr(FPesoBruto) + ', tara=' + IntToStr(FTara) +
        ', peso_neto=' + IntToStr(FPesoNeto) +
        ', costo_bs=' + IntToStr(Costo) + ', flete_bs_pendiente=' + IntToStr(Flete) +
        ', usuario_modificacion=' + IntToStr(UsuarioActual.ID) +
        ', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(FEditID));
    end
    else
    begin
      // Generate guia: PESO-{YEAR}-{6-digit ID}
      Q := DM.AbrirQuery('SELECT MAX(id) AS max_id FROM pesajes');
      try
        if Q.FieldByName('max_id').IsNull then
          ProximoID := 1
        else
          ProximoID := Q.FieldByName('max_id').AsInteger + 1;
      finally
        Q.Close;
      end;
      Anio := FormatDateTime('yyyy', Now);
      Guia := 'PESO-' + Anio + '-' + Format('%.6d', [ProximoID]);

      DM.EjecutarSQL('INSERT INTO pesajes (guia, lote, vehiculo_id, chofer_id, proveedor_id, producto_id, ' +
        'id_origen, id_destino, peso_bruto, tara, peso_neto, costo_bs, flete_bs_pendiente, ' +
        'pesador_id, estado, estado_balanza, usuario_creacion, usuario_modificacion, ' +
        'fecha_creacion, fecha_modificacion) VALUES (' +
        QuotedStr(Guia) + ', '''', ' +
        IntToStr(VehiculoID) + ', ' +
        IfThen(ChoferID > 0, IntToStr(ChoferID), 'NULL') + ', ' +
        IfThen(ProveedorID > 0, IntToStr(ProveedorID), 'NULL') + ', ' +
        IfThen(ProductoID > 0, IntToStr(ProductoID), 'NULL') + ', ' +
        IfThen(OrigenID > 0, IntToStr(OrigenID), 'NULL') + ', ' +
        IfThen(DestinoID > 0, IntToStr(DestinoID), 'NULL') + ', ' +
        IntToStr(FPesoBruto) + ', ' + IntToStr(FTara) + ', ' + IntToStr(FPesoNeto) + ', ' +
        IntToStr(Costo) + ', ' + IntToStr(Flete) + ', ' +
        IntToStr(UsuarioActual.PersonaID) + ', ' +
        '''ACTIVO'', ''EN_PROCESO'', ' +
        IntToStr(UsuarioActual.ID) + ', ' +
        IntToStr(UsuarioActual.ID) + ', ''' +
        FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
    end;
    DM.Transaccion.Commit;
    RefrescarPesajes(nil);
    ShowMessage(IfThen(FEditMode, 'Pesaje actualizado', 'Pesaje guardado correctamente'));
    CancelEditClick(nil);
  except
    DM.Transaccion.Rollback;
    ShowMessage('Error al guardar pesaje');
  end;
end;

procedure TFramePesaje.CancelEditClick(Sender: TObject);
begin
  FEditMode := False; FEditID := 0;
  LimpiarClick(nil);
  lblFormTitle.Caption := 'Datos del Pesaje';
  TLabel(pnlGuardar.Controls[0]).Caption := 'Registrar Pesaje';
  pnlCancelEdit.Visible := False;
end;

procedure TFramePesaje.LimpiarClick(Sender: TObject);
begin
  FTara := 0; FPesoBruto := 0; FPesoNeto := 0;
  FUsarTaraManual := False; FTaraManual := ''; FTaraCapturada := -1;
  lblPesoDisplay.Caption := '0 kg';
  ActualizarResumenPesos;
  cmbVehiculo.ItemIndex := 0; cmbChofer.ItemIndex := 0; cmbProveedor.ItemIndex := 0;
  cmbProducto.ItemIndex := 0; cmbOrigen.ItemIndex := 0; cmbDestino.ItemIndex := 0;
  edtCosto.Text := '0'; edtFlete.Text := '0';
  edtLicencia.Text := ''; edtTipo.Text := '';
  edtTaraManual.Text := '0';
  edtTaraManual.ReadOnly := True;
  pnlGuardarTara.Visible := False;
  pnlSwitchTara.Invalidate;
end;

// ═══════════════════════════════════════════════
// QUICK CREATE DIALOGS
// ═══════════════════════════════════════════════

procedure TFramePesaje.QuickVehiculoClick(Sender: TObject);
var
  F: TForm; ePlaca, eTipo, eTara: TEdit; Lbl, LblSection: TLabel; YPos: Integer;
  pnlOuter, pnlInner: TPanel;
begin
  F := TForm.Create(nil);
  try
    F.Caption := ''; F.Width := 600; F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog; F.Color := CLR_WHITE;
    with TPanel.Create(F) do begin Parent:=F; Align:=alTop; Height:=60; BevelOuter:=bvNone; Color:=CLR_WHITE;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        SetBounds(24,14,400,24); Caption:='Nuevo vehículo'; Font.Size:=14; Font.Style:=[]; Font.Color:=CLR_TEXT_HEADING; end;
      with TPanel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        Align:=alBottom; Height:=1; BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    end; YPos:=80;

    LblSection:=TLabel.Create(F); LblSection.Parent:=F; LblSection.SetBounds(24,YPos,300,20);
    LblSection.Caption:='Datos del Vehículo'; LblSection.Font.Size:=11; LblSection.Font.Style:=[]; LblSection.Font.Color:=CLR_TEXT_HEADING;
    YPos:=YPos+33;

    // Fila 1: Placa * (izquierda) | Tipo (derecha)
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,YPos,300,16);
    Lbl.Caption:='Placa *'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(314,YPos,300,16);
    Lbl.Caption:='Tipo de vehículo'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING; YPos:=YPos+28;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(24,YPos,280,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,278,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    ePlaca:=TEdit.Create(pnlInner); ePlaca.Parent:=pnlInner; ePlaca.Align:=alClient; ePlaca.BorderStyle:=bsNone;
    ePlaca.Font.Size:=11; ePlaca.Font.Color:=CLR_TEXT; ePlaca.Color:=CLR_WHITE; ePlaca.CharCase:=ecUpperCase;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(314,YPos,260,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,258,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eTipo:=TEdit.Create(pnlInner); eTipo.Parent:=pnlInner; eTipo.Align:=alClient; eTipo.BorderStyle:=bsNone;
    eTipo.Font.Size:=11; eTipo.Font.Color:=CLR_TEXT; eTipo.Color:=CLR_WHITE; eTipo.CharCase:=ecUpperCase;
    YPos:=YPos+48;

    // Fila 2: Tara (kg)
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,YPos,300,16);
    Lbl.Caption:='Tara (kg)'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING; YPos:=YPos+28;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(24,YPos,160,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,158,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eTara:=TEdit.Create(pnlInner); eTara.Parent:=pnlInner; eTara.Align:=alClient; eTara.BorderStyle:=bsNone;
    eTara.Font.Size:=11; eTara.Font.Color:=CLR_TEXT; eTara.Color:=CLR_WHITE; eTara.Text:='0';
    YPos:=YPos+56;

    with TPanel.Create(F) do begin Parent:=F; SetBounds(24,YPos,556,1); BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    YPos:=YPos+16;

    F.Height:=YPos+70;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(310,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_WHITE; Tag:=1; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickCancelarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='CANCELAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_PRIMARY; OnClick:=@QuickCancelarClick; end; end;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(450,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_PRIMARY; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickGuardarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='GUARDAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_WHITE; OnClick:=@QuickGuardarClick; end; end;

    if F.ShowModal = mrOK then begin
      if Trim(ePlaca.Text) = '' then begin ShowMessage('Placa obligatoria'); Exit; end;
      if DM.Transaccion.Active then DM.Transaccion.Rollback;
      DM.Transaccion.StartTransaction;
      try
        DM.EjecutarSQL('INSERT INTO vehiculos (placa, tipo_vehiculo, tara, estado, ' +
          'usuario_creacion, usuario_modificacion, fecha_creacion, fecha_modificacion) VALUES (' +
          QuotedStr(UpperCase(Trim(ePlaca.Text))) + ', ' +
          QuotedStr(Trim(eTipo.Text)) + ', ' +
          IntToStr(StrToIntDef(Trim(eTara.Text), 0)) + ', ''ACTIVO'', ' +
          IntToStr(UsuarioActual.ID) + ', ' + IntToStr(UsuarioActual.ID) + ', ''' +
          FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        DM.Transaccion.Commit;
        CargarCombos;
        ShowMessage('Vehículo creado correctamente');
      except
        DM.Transaccion.Rollback;
        ShowMessage('Error al guardar vehículo');
      end;
    end;
  finally F.Free; end;
end;

procedure TFramePesaje.QuickChoferClick(Sender: TObject);
var
  F: TForm; eNom, ePat, eMat, eCI, eLic, eTel: TEdit; Lbl, LblSection: TLabel; YPos: Integer;
  pnlOuter, pnlInner: TPanel;
begin
  F := TForm.Create(nil);
  try
    F.Caption := ''; F.Width := 600; F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog; F.Color := CLR_WHITE;
    with TPanel.Create(F) do begin Parent:=F; Align:=alTop; Height:=60; BevelOuter:=bvNone; Color:=CLR_WHITE;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        SetBounds(24,14,400,24); Caption:='Nuevo chofer'; Font.Size:=14; Font.Style:=[]; Font.Color:=CLR_TEXT_HEADING; end;
      with TPanel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        Align:=alBottom; Height:=1; BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    end; YPos:=80;

    LblSection:=TLabel.Create(F); LblSection.Parent:=F; LblSection.SetBounds(24,YPos,300,20);
    LblSection.Caption:='Datos del Chofer'; LblSection.Font.Size:=11; LblSection.Font.Style:=[]; LblSection.Font.Color:=CLR_TEXT_HEADING;
    YPos:=YPos+33;

    // Fila 1: Nombre * | Apellido paterno | Apellido materno
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,YPos,200,16);
    Lbl.Caption:='Nombre *'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(212,YPos,200,16);
    Lbl.Caption:='Apellido paterno'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(400,YPos,200,16);
    Lbl.Caption:='Apellido materno'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    YPos:=YPos+28;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(24,YPos,180,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,178,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eNom:=TEdit.Create(pnlInner); eNom.Parent:=pnlInner; eNom.Align:=alClient; eNom.BorderStyle:=bsNone;
    eNom.Font.Size:=11; eNom.Font.Color:=CLR_TEXT; eNom.Color:=CLR_WHITE; eNom.CharCase:=ecUpperCase;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(212,YPos,180,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,178,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    ePat:=TEdit.Create(pnlInner); ePat.Parent:=pnlInner; ePat.Align:=alClient; ePat.BorderStyle:=bsNone;
    ePat.Font.Size:=11; ePat.Font.Color:=CLR_TEXT; ePat.Color:=CLR_WHITE; ePat.CharCase:=ecUpperCase;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(400,YPos,180,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,178,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eMat:=TEdit.Create(pnlInner); eMat.Parent:=pnlInner; eMat.Align:=alClient; eMat.BorderStyle:=bsNone;
    eMat.Font.Size:=11; eMat.Font.Color:=CLR_TEXT; eMat.Color:=CLR_WHITE; eMat.CharCase:=ecUpperCase;
    YPos:=YPos+48;

    // Fila 2: Nro. Documento | Teléfono | Licencia
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,YPos,200,16);
    Lbl.Caption:='Nro. Documento'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(212,YPos,200,16);
    Lbl.Caption:='Teléfono'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(400,YPos,200,16);
    Lbl.Caption:='Licencia'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    YPos:=YPos+28;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(24,YPos,180,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,178,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eCI:=TEdit.Create(pnlInner); eCI.Parent:=pnlInner; eCI.Align:=alClient; eCI.BorderStyle:=bsNone;
    eCI.Font.Size:=11; eCI.Font.Color:=CLR_TEXT; eCI.Color:=CLR_WHITE; eCI.CharCase:=ecUpperCase;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(212,YPos,180,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,178,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eTel:=TEdit.Create(pnlInner); eTel.Parent:=pnlInner; eTel.Align:=alClient; eTel.BorderStyle:=bsNone;
    eTel.Font.Size:=11; eTel.Font.Color:=CLR_TEXT; eTel.Color:=CLR_WHITE; eTel.CharCase:=ecUpperCase;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(400,YPos,180,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,178,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eLic:=TEdit.Create(pnlInner); eLic.Parent:=pnlInner; eLic.Align:=alClient; eLic.BorderStyle:=bsNone;
    eLic.Font.Size:=11; eLic.Font.Color:=CLR_TEXT; eLic.Color:=CLR_WHITE;
    YPos:=YPos+56;

    with TPanel.Create(F) do begin Parent:=F; SetBounds(24,YPos,556,1); BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    YPos:=YPos+16;

    F.Height:=YPos+70;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(310,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_WHITE; Tag:=1; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickCancelarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='CANCELAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_PRIMARY; OnClick:=@QuickCancelarClick; end; end;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(450,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_PRIMARY; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickGuardarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='GUARDAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_WHITE; OnClick:=@QuickGuardarClick; end; end;

    if F.ShowModal = mrOK then begin
      if Trim(eNom.Text) = '' then begin ShowMessage('Nombre obligatorio'); Exit; end;
      if DM.Transaccion.Active then DM.Transaccion.Rollback;
      DM.Transaccion.StartTransaction;
      try
        DM.EjecutarSQL('INSERT INTO personas (nombre, apellido_paterno, apellido_materno, ci, telefono, estado, fecha_creacion, fecha_modificacion) VALUES (' +
          QuotedStr(Trim(eNom.Text)) + ', ' +
          QuotedStr(Trim(ePat.Text)) + ', ' +
          QuotedStr(Trim(eMat.Text)) + ', ' +
          QuotedStr(Trim(eCI.Text)) + ', ' +
          QuotedStr(Trim(eTel.Text)) +
          ', ''ACTIVO'', ''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        DM.EjecutarSQL('INSERT INTO choferes (persona_id, licencia, estado, fecha_creacion, fecha_modificacion) VALUES (' +
          IntToStr(DM.ObtenerUltimoID) + ', ' + QuotedStr(Trim(eLic.Text)) +
          ', ''ACTIVO'', ''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        DM.Transaccion.Commit; CargarCombos;
      except DM.Transaccion.Rollback; ShowMessage('Error al crear chofer'); end;
    end;
  finally F.Free; end;
end;

procedure TFramePesaje.QuickProveedorClick(Sender: TObject);
var
  F: TForm; eNom, eEmp, eTel: TEdit; Lbl, LblSection: TLabel; YPos: Integer;
  pnlOuter, pnlInner: TPanel;
begin
  F := TForm.Create(nil);
  try
    F.Caption := ''; F.Width := 600; F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog; F.Color := CLR_WHITE;
    with TPanel.Create(F) do begin Parent:=F; Align:=alTop; Height:=60; BevelOuter:=bvNone; Color:=CLR_WHITE;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        SetBounds(24,14,400,24); Caption:='Nuevo proveedor'; Font.Size:=14; Font.Style:=[]; Font.Color:=CLR_TEXT_HEADING; end;
      with TPanel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        Align:=alBottom; Height:=1; BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    end; YPos:=80;

    LblSection:=TLabel.Create(F); LblSection.Parent:=F; LblSection.SetBounds(24,YPos,300,20);
    LblSection.Caption:='Datos del Proveedor'; LblSection.Font.Size:=11; LblSection.Font.Style:=[]; LblSection.Font.Color:=CLR_TEXT_HEADING;
    YPos:=YPos+33;

    // Fila 1: Nombre * (izquierda) | Empresa (derecha)
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,YPos,300,16);
    Lbl.Caption:='Nombre *'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(314,YPos,300,16);
    Lbl.Caption:='Empresa'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING; YPos:=YPos+28;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(24,YPos,280,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,278,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eNom:=TEdit.Create(pnlInner); eNom.Parent:=pnlInner; eNom.Align:=alClient; eNom.BorderStyle:=bsNone;
    eNom.Font.Size:=11; eNom.Font.Color:=CLR_TEXT; eNom.Color:=CLR_WHITE; eNom.CharCase:=ecUpperCase;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(314,YPos,260,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,258,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eEmp:=TEdit.Create(pnlInner); eEmp.Parent:=pnlInner; eEmp.Align:=alClient; eEmp.BorderStyle:=bsNone;
    eEmp.Font.Size:=11; eEmp.Font.Color:=CLR_TEXT; eEmp.Color:=CLR_WHITE; eEmp.CharCase:=ecUpperCase;
    YPos:=YPos+48;

    // Fila 2: Teléfono (izquierda)
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,YPos,300,16);
    Lbl.Caption:='Teléfono'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING; YPos:=YPos+28;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(24,YPos,280,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,278,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eTel:=TEdit.Create(pnlInner); eTel.Parent:=pnlInner; eTel.Align:=alClient; eTel.BorderStyle:=bsNone;
    eTel.Font.Size:=11; eTel.Font.Color:=CLR_TEXT; eTel.Color:=CLR_WHITE; eTel.CharCase:=ecUpperCase;
    YPos:=YPos+56;

    with TPanel.Create(F) do begin Parent:=F; SetBounds(24,YPos,556,1); BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    YPos:=YPos+16;

    F.Height:=YPos+70;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(310,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_WHITE; Tag:=1; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickCancelarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='CANCELAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_PRIMARY; OnClick:=@QuickCancelarClick; end; end;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(450,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_PRIMARY; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickGuardarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='GUARDAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_WHITE; OnClick:=@QuickGuardarClick; end; end;

    if F.ShowModal = mrOK then begin
      if Trim(eNom.Text) = '' then begin ShowMessage('Nombre obligatorio'); Exit; end;
      if DM.Transaccion.Active then DM.Transaccion.Rollback;
      DM.Transaccion.StartTransaction;
      try
        DM.EjecutarSQL('INSERT INTO personas (nombre, telefono, estado, fecha_creacion, fecha_modificacion) VALUES (' +
          QuotedStr(Trim(eNom.Text)) + ', ' + QuotedStr(Trim(eTel.Text)) +
          ', ''ACTIVO'', ''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        DM.EjecutarSQL('INSERT INTO proveedores (persona_id, nombre_empresa, estado, fecha_creacion, fecha_modificacion) VALUES (' +
          IntToStr(DM.ObtenerUltimoID) + ', ' + QuotedStr(Trim(eEmp.Text)) +
          ', ''ACTIVO'', ''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        DM.Transaccion.Commit; CargarCombos;
      except DM.Transaccion.Rollback; ShowMessage('Error al crear proveedor'); end;
    end;
  finally F.Free; end;
end;

procedure TFramePesaje.QuickSimpleClick(Sender: TObject);
var
  F: TForm; eNom, eDes: TEdit; TagVal: Integer; Tabla, Titulo: string;
  Lbl, LblSection: TLabel; YPos: Integer;
  pnlOuter, pnlInner: TPanel;
begin
  TagVal := TPanel(Sender).Tag;
  case TagVal of 4: begin Tabla:='productos'; Titulo:='Nuevo producto'; end;
    5: begin Tabla:='origenes'; Titulo:='Nuevo origen'; end;
    6: begin Tabla:='destinos'; Titulo:='Nuevo destino'; end;
    else Exit; end;
  F := TForm.Create(nil);
  try
    F.Caption := ''; F.Width := 600; F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog; F.Color := CLR_WHITE;
    with TPanel.Create(F) do begin Parent:=F; Align:=alTop; Height:=60; BevelOuter:=bvNone; Color:=CLR_WHITE;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        SetBounds(24,14,400,24); Caption:=Titulo; Font.Size:=14; Font.Style:=[]; Font.Color:=CLR_TEXT_HEADING; end;
      with TPanel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]);
        Align:=alBottom; Height:=1; BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    end; YPos:=80;

    LblSection:=TLabel.Create(F); LblSection.Parent:=F; LblSection.SetBounds(24,YPos,300,20);
    LblSection.Caption:='Datos del registro'; LblSection.Font.Size:=11; LblSection.Font.Style:=[]; LblSection.Font.Color:=CLR_TEXT_HEADING;
    YPos:=YPos+33;

    // Fila 1: Nombre * (izquierda) | Descripción (derecha)
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,YPos,300,16);
    Lbl.Caption:='Nombre *'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING;
    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(314,YPos,300,16);
    Lbl.Caption:='Descripción'; Lbl.Font.Size:=11; Lbl.Font.Style:=[]; Lbl.Font.Color:=CLR_TEXT_HEADING; YPos:=YPos+28;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(24,YPos,280,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,278,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eNom:=TEdit.Create(pnlInner); eNom.Parent:=pnlInner; eNom.Align:=alClient; eNom.BorderStyle:=bsNone;
    eNom.Font.Size:=11; eNom.Font.Color:=CLR_TEXT; eNom.Color:=CLR_WHITE; eNom.CharCase:=ecUpperCase;

    pnlOuter:=TPanel.Create(F); pnlOuter.Parent:=F; pnlOuter.SetBounds(314,YPos,260,40); pnlOuter.BevelOuter:=bvNone; pnlOuter.Color:=CLR_BORDER;
    pnlInner:=TPanel.Create(pnlOuter); pnlInner.Parent:=pnlOuter; pnlInner.SetBounds(1,1,258,38); pnlInner.BevelOuter:=bvNone; pnlInner.Color:=CLR_WHITE; pnlInner.BorderWidth:=6;
    eDes:=TEdit.Create(pnlInner); eDes.Parent:=pnlInner; eDes.Align:=alClient; eDes.BorderStyle:=bsNone;
    eDes.Font.Size:=11; eDes.Font.Color:=CLR_TEXT; eDes.Color:=CLR_WHITE; eDes.CharCase:=ecUpperCase;
    YPos:=YPos+56;

    with TPanel.Create(F) do begin Parent:=F; SetBounds(24,YPos,556,1); BevelOuter:=bvNone; Color:=CLR_BORDER; end;
    YPos:=YPos+16;

    F.Height:=YPos+70;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(310,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_WHITE; Tag:=1; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickCancelarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='CANCELAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_PRIMARY; OnClick:=@QuickCancelarClick; end; end;
    with TPanel.Create(F) do begin Parent:=F; SetBounds(450,YPos,130,36);
      BevelOuter:=bvNone; Color:=CLR_PRIMARY; Cursor:=crHandPoint; OnPaint:=@PaintRounded; OnClick:=@QuickGuardarClick;
      with TLabel.Create(F) do begin Parent:=TPanel(F.Controls[F.ControlCount-1]); Align:=alClient;
        Alignment:=taCenter; Layout:=tlCenter; Caption:='GUARDAR'; Font.Size:=12; Font.Style:=[]; Font.Color:=CLR_WHITE; OnClick:=@QuickGuardarClick; end; end;

    if F.ShowModal = mrOK then begin
      if Trim(eNom.Text) = '' then begin ShowMessage('Nombre obligatorio'); Exit; end;
      DM.EjecutarSQL('INSERT INTO ' + Tabla + ' (nombre, descripcion, estado, fecha_creacion, fecha_modificacion) VALUES (' +
        QuotedStr(Trim(eNom.Text)) + ', ' + QuotedStr(Trim(eDes.Text)) +
        ', ''ACTIVO'', ''' + FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
      CargarCombos;
    end;
  finally F.Free; end;
end;

// ═══════════════════════════════════════════════
// UI HELPERS
// ═══════════════════════════════════════════════

function TFramePesaje.CrearBoton(AParent: TPanel; ATop, ALeft, AW, AH: Integer;
  const ACaption: string; AColor: TColor; AFontColor: TColor; ATag: Integer;
  AClick: TNotifyEvent): TPanel;
var Lbl: TLabel;
begin
  Result := TPanel.Create(AParent);
  Result.Parent := AParent; Result.SetBounds(ALeft, ATop, AW, AH);
  Result.BevelOuter := bvNone; Result.Color := AColor; Result.Tag := ATag;
  Result.Cursor := crHandPoint; Result.OnClick := AClick;
  Result.OnPaint := @PaintRounded;
  Result.ParentBackground := False; Result.ParentColor := False;
  Lbl := TLabel.Create(Result); Lbl.Parent := Result;
  Lbl.Align := alClient; Lbl.Alignment := taCenter; Lbl.Layout := tlCenter;
  Lbl.Caption := ACaption; Lbl.Font.Size := 12; Lbl.Font.Style := [];
  Lbl.Font.Color := AFontColor; Lbl.OnClick := AClick;
end;

procedure TFramePesaje.QuickCancelarClick(Sender: TObject);
var Frm: TCustomForm; Pnl: TWinControl;
begin
  if Sender is TLabel then Pnl := TLabel(Sender).Parent
  else if Sender is TPanel then Pnl := TPanel(Sender)
  else Exit;
  Frm := GetParentForm(Pnl);
  if Frm <> nil then Frm.ModalResult := mrCancel;
end;

procedure TFramePesaje.QuickGuardarClick(Sender: TObject);
var Frm: TCustomForm; Pnl: TWinControl;
begin
  if Sender is TLabel then Pnl := TLabel(Sender).Parent
  else if Sender is TPanel then Pnl := TPanel(Sender)
  else Exit;
  Frm := GetParentForm(Pnl);
  if Frm <> nil then Frm.ModalResult := mrOK;
end;

procedure TFramePesaje.PaintRounded(Sender: TObject);
var Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_BG; Pnl.Canvas.FillRect(0, 0, Pnl.Width, Pnl.Height);
  Pnl.Canvas.Brush.Color := Pnl.Color;
  if Pnl.Tag = 1 then begin
    Pnl.Canvas.Pen.Color := CLR_INFO; Pnl.Canvas.Pen.Width := 1;
    Pnl.Canvas.RoundRect(1, 1, Pnl.Width - 1, Pnl.Height - 1, 8, 8);
  end else begin
    Pnl.Canvas.Pen.Style := psClear;
    Pnl.Canvas.RoundRect(0, 0, Pnl.Width, Pnl.Height, 8, 8);
  end;
end;

// ═══════════════════════════════════════════════
// DIALOG FINALIZAR PESAJE
// ═══════════════════════════════════════════════

function TFramePesaje.MostrarDialogFinalizar(PesajeID, Bruto, Tara, Neto: Integer): Boolean;
var
  F: TForm;
  pnlWrap, pnlDatos: TPanel;
  Lbl: TLabel;
  YPos, W: Integer;
const
  DIALOG_W = 440;
begin
  Result := False;
  F := TForm.Create(nil);
  try
    F.Caption := ''; F.Width := DIALOG_W; F.Position := poMainFormCenter;
    F.BorderStyle := bsDialog; F.Color := CLR_BG;
    F.Constraints.MinWidth := DIALOG_W; F.Constraints.MaxWidth := DIALOG_W;
    F.Constraints.MinHeight := 320; F.Constraints.MaxHeight := 320;

    // Card panel (blanco, centrado)
    pnlWrap := TPanel.Create(F);
    pnlWrap.Parent := F; pnlWrap.Align := alClient; pnlWrap.BevelOuter := bvNone;
    pnlWrap.Color := CLR_CARD; pnlWrap.BorderSpacing.Around := 16;
    // Title
    with TLabel.Create(F) do begin Parent := pnlWrap;
      SetBounds(24, 24, DIALOG_W - 48, 28);
      Caption := 'Finalizar Pesaje #' + IntToStr(PesajeID);
      Font.Size := 15; Font.Style := [fsBold]; Font.Color := CLR_TEXT_HEADING;
    end;
    // Subtitle
    with TLabel.Create(F) do begin Parent := pnlWrap;
      SetBounds(24, 54, DIALOG_W - 48, 18);
      Caption := 'Verifique los pesos antes de finalizar';
      Font.Size := 11; Font.Color := CLR_TEXT_SLATE;
    end;
    // Datos panel (slate-100)
    pnlDatos := TPanel.Create(F); pnlDatos.Parent := pnlWrap;
    pnlDatos.SetBounds(24, 84, DIALOG_W - 48, 120);
    pnlDatos.BevelOuter := bvNone; pnlDatos.Color := CLR_SIDEBAR_ACTIVE;
    // Bruto
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(20, 16, 100, 20); Lbl.Caption := 'Peso Bruto';
    Lbl.Font.Size := 12; Lbl.Font.Color := CLR_TEXT_SLATE;
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(200, 16, 150, 20); Lbl.Caption := FormatFloat('#,##0', Bruto) + ' kg';
    Lbl.Font.Size := 13; Lbl.Font.Color := CLR_TEXT; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;
    // Tara
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(20, 42, 100, 20); Lbl.Caption := 'Tara';
    Lbl.Font.Size := 12; Lbl.Font.Color := CLR_TEXT_SLATE;
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(200, 42, 150, 20); Lbl.Caption := FormatFloat('#,##0', Tara) + ' kg';
    Lbl.Font.Size := 13; Lbl.Font.Color := CLR_TEXT; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;
    // Divider
    with TPanel.Create(F) do begin Parent := pnlDatos;
      SetBounds(20, 74, pnlDatos.Width - 40, 1); BevelOuter := bvNone;
      Color := CLR_BORDER;
    end;
    // Neto
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(20, 84, 100, 24); Lbl.Caption := 'Peso Neto';
    Lbl.Font.Size := 12; Lbl.Font.Color := CLR_TEXT_HEADING; Lbl.Font.Style := [fsBold];
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(200, 84, 150, 24); Lbl.Caption := FormatFloat('#,##0', Neto) + ' kg';
    Lbl.Font.Size := 16; Lbl.Font.Color := CLR_PRIMARY; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;
    // Confirm message
    YPos := 216;
    with TLabel.Create(F) do begin Parent := pnlWrap;
      SetBounds(24, YPos, DIALOG_W - 48, 18);
      Caption := 'Confirme la finalizacion del pesaje';
      Font.Size := 11; Font.Color := CLR_TEXT_SLATE;
    end;
    // Buttons
    YPos := 248;
    W := DIALOG_W - 32;
    CrearBoton(pnlWrap, YPos, W - 220, 100, 36,
      'Cancelar', CLR_CARD, CLR_TEXT, 1, @QuickCancelarClick);
    CrearBoton(pnlWrap, YPos, W - 108, 100, 36,
      'Finalizar', CLR_PRIMARY, CLR_PRIMARY_FG, 0, @DialogFinalizarOk);

    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TFramePesaje.DialogFinalizarOk(Sender: TObject);
var Pnl: TWinControl; Frm: TCustomForm;
begin
  if Sender is TLabel then Pnl := TLabel(Sender).Parent
  else if Sender is TPanel then Pnl := TPanel(Sender)
  else Exit;
  Frm := GetParentForm(Pnl);
  if Frm <> nil then Frm.ModalResult := mrOk;
end;

end.
