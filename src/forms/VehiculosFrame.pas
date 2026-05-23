unit VehiculosFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme;

type
  { TFrameVehiculos }

  TFrameVehiculos = class(TFrame)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    Grid: TStringGrid;
    pnlCard: TPanel;
    pnlNuevo: TPanel;
    lblNuevo: TLabel;
    edtBuscar: TEdit;
    FEditingID: Integer;
    FModalForm: TForm;
    FHoverRow: Integer;
    FHoverZone: Integer;
    FHintWindow: THintWindow;
    FHintTimer: TTimer;
    FHintActive: Boolean;
    procedure Refrescar(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure GuardarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HintTimerTick(Sender: TObject);
    procedure MostrarHintAccion(const Texto: string);
    procedure ToggleEstado(ID: Integer; EstadoActual: string);
    procedure PaintRounded(Sender: TObject);
    procedure ShowVehicleForm(ID: Integer);
  end;

implementation

{$R *.lfm}

constructor TFrameVehiculos.Create(AOwner: TComponent);
var
  Pnl: TPanel;
  Lbl: TLabel;
  pnlOuter, pnlInner: TPanel;
begin
  inherited Create(AOwner);
  FEditingID := 0;
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
  Lbl.Caption := 'Vehículos';
  Lbl.Font.Height := -24;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // Búsqueda por placa
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(240, 28, 60, 16);
  Lbl.Caption := 'Placa';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_MUTED;

  pnlOuter := TPanel.Create(Pnl);
  pnlOuter.Parent := Pnl;
  pnlOuter.SetBounds(300, 19, 240, 40);
  pnlOuter.BevelOuter := bvNone;
  pnlOuter.Color := CLR_BORDER;

  pnlInner := TPanel.Create(pnlOuter);
  pnlInner.Parent := pnlOuter;
  pnlInner.SetBounds(1, 1, 238, 38);
  pnlInner.BevelOuter := bvNone;
  pnlInner.Color := CLR_WHITE;
  pnlInner.BorderWidth := 8;

  edtBuscar := TEdit.Create(pnlInner);
  edtBuscar.Parent := pnlInner;
  edtBuscar.Align := alClient;
  edtBuscar.BorderStyle := bsNone;
  edtBuscar.Font.Size := 11;
  edtBuscar.Font.Color := CLR_TEXT;
  edtBuscar.Color := CLR_WHITE;
  edtBuscar.CharCase := ecUpperCase;
  edtBuscar.OnChange := @Refrescar;

  // Botón + AGREGAR (panel azul + label blanco)
  pnlNuevo := TPanel.Create(Self);
  pnlNuevo.Parent := Pnl;
  pnlNuevo.Width := 120;
  pnlNuevo.Height := 36;
  pnlNuevo.Top := 14;
  pnlNuevo.Anchors := [akTop, akRight];
  pnlNuevo.BorderSpacing.Right := 8;
  pnlNuevo.BevelOuter := bvNone;
  pnlNuevo.Color := CLR_PRIMARY;
  pnlNuevo.ParentBackground := False;
  pnlNuevo.ParentColor := False;
  pnlNuevo.Cursor := crHandPoint;
  pnlNuevo.OnClick := @btnNuevoClick;
  pnlNuevo.OnPaint := @PaintRounded;

  lblNuevo := TLabel.Create(Self);
  lblNuevo.Parent := pnlNuevo;
  lblNuevo.Align := alClient;
  lblNuevo.Alignment := taCenter;
  lblNuevo.Layout := tlCenter;
  lblNuevo.Caption := '+ Agregar';
  lblNuevo.Font.Size := 12;
  lblNuevo.Font.Style := [];
  lblNuevo.Font.Color := CLR_WHITE;
  lblNuevo.Transparent := True;
  lblNuevo.ParentColor := False;
  lblNuevo.OnClick := @btnNuevoClick;

  // Card contenedor de la tabla
  pnlCard := TPanel.Create(Self);
  pnlCard.Parent := Self;
  pnlCard.Align := alClient;
  pnlCard.BorderSpacing.Top := 30;
  pnlCard.BorderSpacing.Left := 24;
  pnlCard.BorderSpacing.Right := 24;
  pnlCard.BorderSpacing.Bottom := 24;
  pnlCard.BevelOuter := bvLowered;
  pnlCard.BevelInner := bvNone;
  pnlCard.BevelWidth := 1;
  pnlCard.Color := CLR_CARD;

  // Grid
  Grid := TStringGrid.Create(Self);
  Grid.Parent := pnlCard;
  Grid.Align := alClient;
  Grid.BorderSpacing.Around := 2;
  Grid.ScrollBars := ssAutoBoth;
  Grid.ColCount := 6;
  Grid.RowCount := 2;
  Grid.FixedRows := 1;
  Grid.FixedCols := 0;
  Grid.Options := Grid.Options + [goRowSelect];
  Grid.DefaultRowHeight := 36;
  Grid.RowHeights[0] := 40;
  Grid.Color := CLR_CARD;
  Grid.FixedColor := CLR_CARD;
  Grid.Font.Height := -12;
  Grid.Font.Color := CLR_TEXT_HEADING;
  Grid.TitleFont.Height := -10;
  Grid.TitleFont.Style := [fsBold];
  Grid.TitleFont.Color := CLR_TEXT_SLATE;
  Grid.GridLineWidth := 0;
  Grid.GridLineColor := CLR_BORDER_LIGHT;
  Grid.Flat := True;
  Grid.FocusRectVisible := False;
  Grid.BorderStyle := bsNone;

  Grid.Cells[0, 0] := 'Placa';
  Grid.Cells[1, 0] := 'Tipo de Vehículo';
  Grid.Cells[2, 0] := 'Tara (kg)';
  Grid.Cells[3, 0] := 'Estado';
  Grid.Cells[4, 0] := 'Acciones';
  Grid.Cells[5, 0] := 'ID';

  Grid.ColWidths[0] := 180;
  Grid.ColWidths[1] := 240;
  Grid.ColWidths[2] := 140;
  Grid.ColWidths[3] := 200;
  Grid.ColWidths[4] := 200;
  Grid.ColWidths[5] := 0; // ID oculto

  Grid.OnDblClick := @GridDblClick;
  Grid.OnDrawCell := @GridDrawCell;
  Grid.OnMouseDown := @GridMouseDown;
  Grid.OnMouseMove := @GridMouseMove;
  FHintTimer := TTimer.Create(Self);
  FHintTimer.Interval := 400; FHintTimer.OnTimer := @HintTimerTick;
  FHintTimer.Enabled := False;
  FHintActive := False;

  Refrescar(nil);
end;

procedure TFrameVehiculos.Refrescar(Sender: TObject);
var
  Q: TSQLQuery;
  Filtro: string;
  Row, ID: Integer;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Filtro := '';
  if Trim(edtBuscar.Text) <> '' then
    Filtro := ' WHERE placa LIKE ''%' +
      StringReplace(Trim(edtBuscar.Text), '''', '''''', [rfReplaceAll]) + '%'' ';

  Q := DM.AbrirQuery(
    'SELECT id, placa, tipo_vehiculo, tara, estado ' +
    'FROM vehiculos ' + Filtro + ' ORDER BY id DESC');

  Grid.RowCount := Q.RecordCount + 1;
  Row := 1;
  while not Q.EOF do
  begin
    ID := Q.Fields[0].AsInteger;
    Grid.Objects[0, Row] := TObject(PtrInt(ID));
    Grid.Cells[0, Row] := UpperCase(Q.Fields[1].AsString);
    Grid.Cells[1, Row] := UpperCase(Q.Fields[2].AsString);
    Grid.Cells[2, Row] := Q.Fields[3].AsString;
    Grid.Cells[3, Row] := UpperCase(Q.Fields[4].AsString);
    Grid.Cells[4, Row] := FAIconoStr(FA_EDIT, '✎');
    Grid.Cells[5, Row] := IntToStr(ID);
    Q.Next;
    Inc(Row);
  end;
  Q.Close;
end;

procedure TFrameVehiculos.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Ts: TTextStyle;
  IsSelected: Boolean;
begin
  // Header row: fondo blanco + borde inferior
  if aRow = 0 then
  begin
    Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
    Ts := Grid.Canvas.TextStyle;
    Ts.Alignment := taCenter;
    Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);
    Exit;
  end;

  IsSelected := gdSelected in aState;

  // Columna Acciones: switch (izquierda) + lápiz (derecha)
  if aCol = 4 then
  begin
    if IsSelected then
      Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else
      Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);

    if (aRow = FHoverRow) and (FHoverZone > 0) then
    begin
      Grid.Canvas.Brush.Color := CLR_SIDEBAR_ACTIVE;
      Grid.Canvas.Pen.Style := psClear;
      case FHoverZone of
        1: Grid.Canvas.RoundRect(aRect.Left + 41, aRect.Top + 4, aRect.Left + 109, aRect.Bottom - 4, 6, 6);
        2: Grid.Canvas.RoundRect(aRect.Left + 101, aRect.Top + 4, aRect.Left + 159, aRect.Bottom - 4, 6, 6);
      end;
    end;

    Ts := Grid.Canvas.TextStyle;
    Ts.Layout := tlCenter;

    // Switch toggle (izquierda del grupo centrado)
    Grid.Canvas.Font.Height := -13;
    Grid.Canvas.Font.Style := [fsBold];
    if Grid.Cells[3, aRow] = 'ACTIVO' then
    begin
      Grid.Canvas.Font.Color := CLR_SUCCESS;
      Ts.Alignment := taCenter;
      Grid.Canvas.Font.Name := FAFuente; Grid.Canvas.TextRect(Rect(aRect.Left + 45, aRect.Top, aRect.Left + 105, aRect.Bottom),
        aRect.Left + 45, aRect.Top + 2, FAIconoStr(FA_CHECK, '●') + ' ──', Ts);
    end
    else
    begin
      Grid.Canvas.Font.Color := CLR_DESTRUCTIVE;
      Ts.Alignment := taCenter;
      Grid.Canvas.Font.Name := FAFuente; Grid.Canvas.TextRect(Rect(aRect.Left + 45, aRect.Top, aRect.Left + 105, aRect.Bottom),
        aRect.Left + 45, aRect.Top + 2, FAIconoStr(FA_TIMES, '○') + ' ──', Ts);
    end;

    // Lápiz editar (derecha del grupo centrado)
    Grid.Canvas.Font.Height := -13;
    Grid.Canvas.Font.Color := CLR_PRIMARY;
    Grid.Canvas.Font.Style := [fsBold];
    Ts.Alignment := taCenter;
    Grid.Canvas.Font.Name := FAFuente; Grid.Canvas.TextRect(Rect(aRect.Left + 105, aRect.Top, aRect.Left + 155, aRect.Bottom),
      aRect.Left + 105, aRect.Top + 2, FAIconoStr(FA_EDIT, '✎'), Ts);
    Exit;
  end;

  // Columna Estado: badge coloreado centrado
  if aCol = 3 then
  begin
    if IsSelected then
      Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else
      Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);

    if Grid.Cells[3, aRow] = 'ACTIVO' then
    begin
      Grid.Canvas.Brush.Color := CLR_SUCCESS_BG;
      Grid.Canvas.Font.Color := CLR_TEAL;
    end
    else
    begin
      Grid.Canvas.Brush.Color := CLR_DESTRUCTIVE_BG;
      Grid.Canvas.Font.Color := CLR_DESTRUCTIVE;
    end;

    Grid.Canvas.Pen.Style := psClear;
    Grid.Canvas.RoundRect(
      aRect.Left + 55, aRect.Top + 6,
      aRect.Left + 145, aRect.Top + 30,
      12, 12);

    Grid.Canvas.Font.Height := -11;
    Grid.Canvas.Font.Style := [fsBold];
    Ts := Grid.Canvas.TextStyle;
    Ts.Alignment := taCenter;
    Ts.Layout := tlCenter;
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top,
      Grid.Cells[3, aRow], Ts);
    Exit;
  end;

  // Fondo de fila seleccionada
  if IsSelected then
    Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
  else
    Grid.Canvas.Brush.Color := CLR_CARD;

  Grid.Canvas.FillRect(aRect);

  // Texto normal de celda
  Ts := Grid.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  Grid.Canvas.Font.Height := -12;
  Grid.Canvas.Font.Color := CLR_TEXT_HEADING;
  Grid.Canvas.Font.Style := [];
  Grid.Canvas.TextRect(aRect, aRect.Left + 6, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);

  // Línea divisora horizontal suave (solo en col 0)
  if aCol = 0 then
  begin
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
  end;
end;

procedure TFrameVehiculos.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;
  ID, TotalH, I: Integer;
begin
  if Button <> mbLeft then Exit;
  Grid.MouseToCell(X, Y, Col, Row);
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;

  TotalH := 0;
  for I := 0 to Grid.RowCount - 1 do
    TotalH := TotalH + Grid.RowHeights[I];
  if Y > TotalH then Exit;

  // Columna Acciones
  if Col = 4 then
  begin
    ID := PtrInt(Grid.Objects[0, Row]);
    if X < Grid.CellRect(Col, Row).Left + 105 then
      ToggleEstado(ID, Grid.Cells[3, Row])
    else
      ShowVehicleForm(ID);
  end;
end;

procedure TFrameVehiculos.GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var Col, Row: Integer; Zona: Integer; NewZone: Integer;
begin
  Grid.MouseToCell(X, Y, Col, Row);
  if (Col <> 4) or (Row < 1) or (Row >= Grid.RowCount) then begin NewZone := 0; Row := 0; end
  else begin
    if X < Grid.CellRect(Col, Row).Left + 105 then Zona := 1 else Zona := 2;
    NewZone := Zona;
  end;
  if (FHoverRow <> Row) or (FHoverZone <> NewZone) then begin
    if (FHoverRow > 0) and (FHoverRow < Grid.RowCount) then Grid.InvalidateCell(4, FHoverRow);
    FHoverRow := Row; FHoverZone := NewZone;
    if (Row > 0) and (Row < Grid.RowCount) then Grid.InvalidateCell(4, Row);
    if FHintActive then begin FHintWindow.Hide; FHintActive := False; end;
    FHintTimer.Enabled := NewZone > 0;
  end;
end;

procedure TFrameVehiculos.HintTimerTick(Sender: TObject);
var Texto: string; P: TPoint;
begin
  FHintTimer.Enabled := False;
  if FHoverZone = 0 then Exit;
  case FHoverZone of
    1: if Grid.Cells[3, FHoverRow] = 'ACTIVO' then Texto := 'Desactivar' else Texto := 'Activar';
    2: Texto := 'Editar vehículo';
  else Exit; end;
  P := Mouse.CursorPos;
  MostrarHintAccion(Texto);
  FHintWindow.Top := P.Y + 20; FHintWindow.Left := P.X + 12;
  FHintWindow.Show; FHintActive := True;
end;

procedure TFrameVehiculos.MostrarHintAccion(const Texto: string);
var R: TRect;
begin
  if FHintWindow = nil then begin
    FHintWindow := THintWindow.Create(Self);
    FHintWindow.Color := CLR_TEXT; FHintWindow.Font.Size := 11; FHintWindow.Font.Color := CLR_WHITE;
  end;
  R := FHintWindow.CalcHintRect(250, Texto, nil);
  FHintWindow.ActivateHint(R, Texto);
end;

procedure TFrameVehiculos.GridDblClick(Sender: TObject);
var
  Row: Integer;
  ID: Integer;
begin
  Row := Grid.Row;
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;
  ID := PtrInt(Grid.Objects[0, Row]);
  if ID > 0 then ShowVehicleForm(ID);
end;

procedure TFrameVehiculos.btnNuevoClick(Sender: TObject);
begin
  ShowVehicleForm(0);
end;

procedure TFrameVehiculos.GuardarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrOK;
end;

procedure TFrameVehiculos.CancelarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrCancel;
end;

procedure TFrameVehiculos.ToggleEstado(ID: Integer; EstadoActual: string);
var
  NuevoEstado: string; Row: Integer;
begin
  if ID = 0 then Exit;
  if EstadoActual = 'ACTIVO' then
    NuevoEstado := 'INACTIVO'
  else
    NuevoEstado := 'ACTIVO';

  if DM.Transaccion.Active then DM.Transaccion.Rollback;
  DM.Transaccion.StartTransaction;
  try
    DM.EjecutarSQL('UPDATE vehiculos SET estado=''' + NuevoEstado +
      ''', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(ID));
    DM.Transaccion.Commit;
    for Row := 1 to Grid.RowCount - 1 do
      if PtrInt(Grid.Objects[0, Row]) = ID then
      begin
        Grid.Cells[3, Row] := NuevoEstado;
        Grid.InvalidateCell(3, Row);
        Grid.InvalidateCell(4, Row);
        Break;
      end;
  except
    DM.Transaccion.Rollback;
  end;
end;

procedure TFrameVehiculos.PaintRounded(Sender: TObject);
var
  Pnl: TPanel;
begin
  Pnl := TPanel(Sender);
  Pnl.Canvas.Brush.Color := CLR_BG;
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

procedure TFrameVehiculos.ShowVehicleForm(ID: Integer);
var
  F: TForm;
  LblSection: TLabel;
  ePlaca, eTipo, eTara: TEdit;
  Placa, Tipo, TaraStr: string;
  Q: TSQLQuery;
  IsNew: Boolean;
  YPos: Integer;

  function MakeLabel(ATop, ALeft: Integer; ACaption: string): TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := F;
    Result.SetBounds(ALeft, ATop, 300, 16);
    Result.Caption := ACaption;
    Result.Font.Size := 11;
    Result.Font.Style := [];
    Result.Font.Color := CLR_TEXT_HEADING;
  end;

  function MakeEditConBorde(ATop, ALeft, AWidth: Integer; ANumerico: Boolean = False): TEdit;
  var
    pnlOuter, pnlInner: TPanel;
  begin
    pnlOuter := TPanel.Create(F);
    pnlOuter.Parent := F;
    pnlOuter.SetBounds(ALeft, ATop, AWidth, 40);
    pnlOuter.BevelOuter := bvNone;
    pnlOuter.Color := CLR_BORDER;

    pnlInner := TPanel.Create(pnlOuter);
    pnlInner.Parent := pnlOuter;
    pnlInner.SetBounds(1, 1, AWidth - 2, 38);
    pnlInner.BevelOuter := bvNone;
    pnlInner.Color := CLR_WHITE;
    pnlInner.BorderWidth := 6;

    Result := TEdit.Create(pnlInner);
    Result.Parent := pnlInner;
    Result.Align := alClient;
    Result.BorderStyle := bsNone;
    Result.Font.Size := 11;
    Result.Font.Color := CLR_TEXT;
    Result.Color := CLR_WHITE;
    if ANumerico then
      Result.CharCase := ecNormal
    else
      Result.CharCase := ecUpperCase;
  end;

begin
  IsNew := ID = 0;
  Placa := ''; Tipo := ''; TaraStr := '0';

  // Cargar datos si editar
  if not IsNew then
  begin
    Q := DM.AbrirQuery(
      'SELECT placa, tipo_vehiculo, tara FROM vehiculos WHERE id=' + IntToStr(ID));
    try
      if not Q.EOF then
      begin
        Placa := UpperCase(Q.FieldByName('placa').AsString);
        Tipo := UpperCase(Q.FieldByName('tipo_vehiculo').AsString);
        TaraStr := Q.FieldByName('tara').AsString;
      end;
    finally
      Q.Close;
    end;
  end;

  F := TForm.Create(nil);
  FModalForm := F;
  try
    F.Caption := '';
    F.Width := 600;
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.Color := CLR_WHITE;

    // Header del modal
    with TPanel.Create(F) do
    begin
      Parent := F;
      Align := alTop;
      Height := 60;
      BevelOuter := bvNone;
      Color := CLR_WHITE;
      with TLabel.Create(F) do
      begin
        Parent := TPanel(F.Controls[F.ControlCount - 1]);
        SetBounds(24, 14, 400, 24);
        if IsNew then Caption := 'Nuevo vehículo'
        else Caption := 'Editar vehículo';
        Font.Size := 14;
        Font.Style := [];
        Font.Color := CLR_TEXT_HEADING;
      end;
      // Línea separadora
      with TPanel.Create(F) do
      begin
        Parent := TPanel(F.Controls[F.ControlCount - 1]);
        Align := alBottom;
        Height := 1;
        BevelOuter := bvNone;
        Color := CLR_BORDER;
      end;
    end;

    YPos := 80;

    // Sección: Datos del Vehículo
    LblSection := TLabel.Create(F);
    LblSection.Parent := F;
    LblSection.SetBounds(24, YPos, 300, 20);
    LblSection.Caption := 'Datos del Vehículo';
    LblSection.Font.Size := 11;
    LblSection.Font.Style := [];
    LblSection.Font.Color := CLR_TEXT_HEADING;

    YPos := YPos + 33;

    // Fila 1: Placa * (izquierda) | Tipo de vehículo (derecha)
    MakeLabel(YPos, 24, 'Placa *');
    MakeLabel(YPos, 314, 'Tipo de vehículo');
    YPos := YPos + 28;

    ePlaca := MakeEditConBorde(YPos, 24, 280);
    ePlaca.Text := Placa;

    eTipo := MakeEditConBorde(YPos, 314, 260);
    eTipo.Text := Tipo;

    YPos := YPos + 48;

    // Fila 2: Tara (kg) (izquierda)
    MakeLabel(YPos, 24, 'Tara (kg)');
    YPos := YPos + 28;

    eTara := MakeEditConBorde(YPos, 24, 160, True);
    eTara.Text := TaraStr;

    YPos := YPos + 56;

    // Línea divisora
    with TPanel.Create(F) do
    begin
      Parent := F;
      SetBounds(24, YPos, 556, 1);
      BevelOuter := bvNone;
      Color := CLR_BORDER;
    end;
    YPos := YPos + 16;

    F.Height := YPos + 70;

    // Botones
    // CANCELAR: panel blanco con borde info
    with TPanel.Create(F) do
    begin
      Parent := F;
      SetBounds(310, YPos, 130, 36);
      BevelOuter := bvNone;
      Color := CLR_WHITE;
      Tag := 1;
      Cursor := crHandPoint;
      OnPaint := @PaintRounded;
      OnClick := @CancelarClick;
      with TLabel.Create(F) do
      begin
        Parent := TPanel(F.Controls[F.ControlCount - 1]);
        Align := alClient;
        Alignment := taCenter;
        Layout := tlCenter;
        Caption := 'CANCELAR';
        Font.Size := 12;
        Font.Style := [];
        Font.Color := CLR_PRIMARY;
        OnClick := @CancelarClick;
      end;
    end;

    // GUARDAR: panel azul con letra blanca
    with TPanel.Create(F) do
    begin
      Parent := F;
      SetBounds(450, YPos, 130, 36);
      BevelOuter := bvNone;
      Color := CLR_PRIMARY;
      Cursor := crHandPoint;
      OnPaint := @PaintRounded;
      OnClick := @GuardarClick;
      with TLabel.Create(F) do
      begin
        Parent := TPanel(F.Controls[F.ControlCount - 1]);
        Align := alClient;
        Alignment := taCenter;
        Layout := tlCenter;
        Caption := 'GUARDAR';
        Font.Size := 12;
        Font.Style := [];
        Font.Color := CLR_WHITE;
        OnClick := @GuardarClick;
      end;
    end;

    if F.ShowModal = mrOK then
    begin
      if Trim(ePlaca.Text) = '' then
      begin
        ShowMessage('La placa es obligatoria');
        Exit;
      end;

      if DM.Transaccion.Active then
        DM.Transaccion.Rollback;
      DM.Transaccion.StartTransaction;
      try
        if IsNew then
        begin
          DM.EjecutarSQL('INSERT INTO vehiculos (placa, tipo_vehiculo, tara, estado, ' +
            'fecha_creacion, fecha_modificacion) VALUES (' +
            QuotedStr(UpperCase(Trim(ePlaca.Text))) + ', ' +
            QuotedStr(UpperCase(Trim(eTipo.Text))) + ', ' +
            eTara.Text + ', ''ACTIVO'', ''' +
            FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        end
        else
        begin
          DM.EjecutarSQL('UPDATE vehiculos SET placa=' +
            QuotedStr(UpperCase(Trim(ePlaca.Text))) +
            ', tipo_vehiculo=' + QuotedStr(UpperCase(Trim(eTipo.Text))) +
            ', tara=' + eTara.Text +
            ', fecha_modificacion=''' + FechaHoraActual +
            ''' WHERE id=' + IntToStr(ID));
        end;
        DM.Transaccion.Commit;
        Refrescar(nil);
      except
        DM.Transaccion.Rollback;
        ShowMessage('Error al guardar vehículo');
      end;
    end;
  finally
    F.Free;
    FModalForm := nil;
  end;
end;

destructor TFrameVehiculos.Destroy;
begin
  if FHintWindow <> nil then FreeAndNil(FHintWindow);
  inherited Destroy;
end;

end.
