unit ProveedoresFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme;

type
  { TFrameProveedores }

  TFrameProveedores = class(TFrame)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    Grid: TStringGrid;
    pnlCard: TPanel;
    pnlNuevo: TPanel;
    lblNuevo: TLabel;
    edtBuscarNombre, edtBuscarCI: TEdit;
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
    procedure ShowProveedorForm(ID: Integer);
  end;

implementation

{$R *.lfm}

constructor TFrameProveedores.Create(AOwner: TComponent);
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
  Lbl.SetBounds(24, 18, 250, 28);
  Lbl.Caption := 'Proveedores';
  Lbl.Font.Height := -24;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // Busqueda por nombre
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(240, 28, 70, 16);
  Lbl.Caption := 'Nombre';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_MUTED;

  pnlOuter := TPanel.Create(Pnl);
  pnlOuter.Parent := Pnl;
  pnlOuter.SetBounds(310, 19, 230, 40);
  pnlOuter.BevelOuter := bvNone;
  pnlOuter.Color := CLR_BORDER;

  pnlInner := TPanel.Create(pnlOuter);
  pnlInner.Parent := pnlOuter;
  pnlInner.SetBounds(1, 1, 228, 38);
  pnlInner.BevelOuter := bvNone;
  pnlInner.Color := CLR_WHITE;
  pnlInner.BorderWidth := 8;

  edtBuscarNombre := TEdit.Create(pnlInner);
  edtBuscarNombre.Parent := pnlInner;
  edtBuscarNombre.Align := alClient;
  edtBuscarNombre.BorderStyle := bsNone;
  edtBuscarNombre.Font.Size := 11;
  edtBuscarNombre.Font.Color := CLR_TEXT;
  edtBuscarNombre.Color := CLR_WHITE;
  edtBuscarNombre.OnChange := @Refrescar;

  // Busqueda por CI
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(554, 28, 30, 16);
  Lbl.Caption := 'CI';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_MUTED;

  pnlOuter := TPanel.Create(Pnl);
  pnlOuter.Parent := Pnl;
  pnlOuter.SetBounds(590, 19, 264, 40);
  pnlOuter.BevelOuter := bvNone;
  pnlOuter.Color := CLR_BORDER;

  pnlInner := TPanel.Create(pnlOuter);
  pnlInner.Parent := pnlOuter;
  pnlInner.SetBounds(1, 1, 262, 38);
  pnlInner.BevelOuter := bvNone;
  pnlInner.Color := CLR_WHITE;
  pnlInner.BorderWidth := 8;

  edtBuscarCI := TEdit.Create(pnlInner);
  edtBuscarCI.Parent := pnlInner;
  edtBuscarCI.Align := alClient;
  edtBuscarCI.BorderStyle := bsNone;
  edtBuscarCI.Font.Size := 11;
  edtBuscarCI.Font.Color := CLR_TEXT;
  edtBuscarCI.Color := CLR_WHITE;
  edtBuscarCI.OnChange := @Refrescar;

  // Boton + AGREGAR (panel azul + label blanco)
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
  Grid.ColCount := 7;
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

  Grid.Cells[0, 0] := 'Nombres';
  Grid.Cells[1, 0] := 'Nro. Documento';
  Grid.Cells[2, 0] := 'Telefono';
  Grid.Cells[3, 0] := 'Empresa';
  Grid.Cells[4, 0] := 'Estado';
  Grid.Cells[5, 0] := 'Acciones';
  Grid.Cells[6, 0] := 'ID';

  Grid.ColWidths[0] := 200;
  Grid.ColWidths[1] := 200;
  Grid.ColWidths[2] := 200;
  Grid.ColWidths[3] := 200;
  Grid.ColWidths[4] := 200;
  Grid.ColWidths[5] := 200;
  Grid.ColWidths[6] := 0;

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

procedure TFrameProveedores.Refrescar(Sender: TObject);
var
  Q: TSQLQuery;
  Filtro: string;
  Row, ID: Integer;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Filtro := '';
  if Trim(edtBuscarNombre.Text) <> '' then
    Filtro := Filtro + ' AND (p.nombre LIKE ''%' +
      StringReplace(Trim(edtBuscarNombre.Text), '''', '''''', [rfReplaceAll]) + '%'' ' +
      'OR p.apellido_paterno LIKE ''%' +
      StringReplace(Trim(edtBuscarNombre.Text), '''', '''''', [rfReplaceAll]) + '%'') ';
  if Trim(edtBuscarCI.Text) <> '' then
    Filtro := Filtro + ' AND p.ci LIKE ''%' +
      StringReplace(Trim(edtBuscarCI.Text), '''', '''''', [rfReplaceAll]) + '%'' ';

  Q := DM.AbrirQuery(
    'SELECT pr.id, p.nombre, p.apellido_paterno, p.apellido_materno, ' +
    'p.ci, p.telefono, pr.nombre_empresa, pr.estado ' +
    'FROM proveedores pr INNER JOIN personas p ON p.id = pr.persona_id ' +
    'WHERE 1=1 ' + Filtro + ' ORDER BY p.nombre');

  Grid.RowCount := Q.RecordCount + 1;
  Row := 1;
  while not Q.EOF do
  begin
    ID := Q.Fields[0].AsInteger;
    Grid.Objects[0, Row] := TObject(PtrInt(ID));
    Grid.Cells[0, Row] := UpperCase(Trim(
      Q.Fields[1].AsString + ' ' +
      Q.Fields[2].AsString + ' ' +
      Q.Fields[3].AsString));
    Grid.Cells[1, Row] := UpperCase(Q.Fields[4].AsString);
    Grid.Cells[2, Row] := UpperCase(Q.Fields[5].AsString);
    Grid.Cells[3, Row] := UpperCase(Q.Fields[6].AsString);
    Grid.Cells[4, Row] := UpperCase(Q.Fields[7].AsString);
    Grid.Cells[5, Row] := '';
    Grid.Cells[6, Row] := IntToStr(ID);
    Q.Next;
    Inc(Row);
  end;
  Q.Close;
end;

procedure TFrameProveedores.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Ts: TTextStyle;
  IsSelected: Boolean;
begin
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

  // Columna Acciones: switch (izquierda) + lapiz (derecha)
  if aCol = 5 then
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

    Grid.Canvas.Font.Height := -13;
    Grid.Canvas.Font.Style := [fsBold];
    if Grid.Cells[4, aRow] = 'ACTIVO' then
    begin
      Grid.Canvas.Font.Color := CLR_SUCCESS;
      Ts.Alignment := taCenter;
      Grid.Canvas.TextRect(Rect(aRect.Left + 45, aRect.Top, aRect.Left + 105, aRect.Bottom),
        aRect.Left + 45, aRect.Top + 2, '● ──', Ts);
    end
    else
    begin
      Grid.Canvas.Font.Color := CLR_DESTRUCTIVE;
      Ts.Alignment := taCenter;
      Grid.Canvas.TextRect(Rect(aRect.Left + 45, aRect.Top, aRect.Left + 105, aRect.Bottom),
        aRect.Left + 45, aRect.Top + 2, '○ ──', Ts);
    end;

    Grid.Canvas.Font.Height := -13;
    Grid.Canvas.Font.Color := CLR_PRIMARY;
    Grid.Canvas.Font.Style := [fsBold];
    Ts.Alignment := taCenter;
    Grid.Canvas.TextRect(Rect(aRect.Left + 105, aRect.Top, aRect.Left + 155, aRect.Bottom),
      aRect.Left + 105, aRect.Top + 2, '✏️', Ts);
    Exit;
  end;

  // Columna Estado: badge coloreado centrado
  if aCol = 4 then
  begin
    if IsSelected then
      Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
    else
      Grid.Canvas.Brush.Color := CLR_CARD;
    Grid.Canvas.FillRect(aRect);

    if Grid.Cells[4, aRow] = 'ACTIVO' then
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
      Grid.Cells[4, aRow], Ts);
    Exit;
  end;

  if IsSelected then
    Grid.Canvas.Brush.Color := CLR_TABLE_ROW_HOVER
  else
    Grid.Canvas.Brush.Color := CLR_CARD;

  Grid.Canvas.FillRect(aRect);

  Ts := Grid.Canvas.TextStyle;
  Ts.Alignment := taCenter;
  Ts.Layout := tlCenter;
  Grid.Canvas.Font.Height := -12;
  Grid.Canvas.Font.Color := CLR_TEXT_HEADING;
  Grid.Canvas.Font.Style := [];
  Grid.Canvas.TextRect(aRect, aRect.Left + 6, aRect.Top + 2, Grid.Cells[aCol, aRow], Ts);

  if aCol = 0 then
  begin
    Grid.Canvas.Pen.Color := CLR_SIDEBAR_BORDER;
    Grid.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
  end;
end;

procedure TFrameProveedores.GridMouseDown(Sender: TObject; Button: TMouseButton;
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

  if Col = 5 then
  begin
    ID := PtrInt(Grid.Objects[0, Row]);
    if X < Grid.CellRect(Col, Row).Left + 105 then
      ToggleEstado(ID, Grid.Cells[4, Row])
    else
      ShowProveedorForm(ID);
  end;
end;

procedure TFrameProveedores.GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var Col, Row: Integer; Zona: Integer; NewZone: Integer;
begin
  Grid.MouseToCell(X, Y, Col, Row);
  if (Col <> 5) or (Row < 1) or (Row >= Grid.RowCount) then begin NewZone := 0; Row := 0; end
  else begin
    if X < Grid.CellRect(Col, Row).Left + 105 then Zona := 1 else Zona := 2;
    NewZone := Zona;
  end;
  if (FHoverRow <> Row) or (FHoverZone <> NewZone) then begin
    if (FHoverRow > 0) and (FHoverRow < Grid.RowCount) then Grid.InvalidateCell(5, FHoverRow);
    FHoverRow := Row; FHoverZone := NewZone;
    if (Row > 0) and (Row < Grid.RowCount) then Grid.InvalidateCell(5, Row);
    if FHintActive then begin FHintWindow.Hide; FHintActive := False; end;
    FHintTimer.Enabled := NewZone > 0;
  end;
end;

procedure TFrameProveedores.HintTimerTick(Sender: TObject);
var Texto: string; P: TPoint;
begin
  FHintTimer.Enabled := False;
  if FHoverZone = 0 then Exit;
  case FHoverZone of
    1: if Grid.Cells[4, FHoverRow] = 'ACTIVO' then Texto := 'Desactivar' else Texto := 'Activar';
    2: Texto := 'Editar proveedor';
  else Exit; end;
  P := Mouse.CursorPos;
  MostrarHintAccion(Texto);
  FHintWindow.Top := P.Y + 20; FHintWindow.Left := P.X + 12;
  FHintWindow.Show; FHintActive := True;
end;

procedure TFrameProveedores.MostrarHintAccion(const Texto: string);
var R: TRect;
begin
  if FHintWindow = nil then begin
    FHintWindow := THintWindow.Create(Self);
    FHintWindow.Color := CLR_TEXT; FHintWindow.Font.Size := 11; FHintWindow.Font.Color := CLR_WHITE;
  end;
  R := FHintWindow.CalcHintRect(250, Texto, nil);
  FHintWindow.ActivateHint(R, Texto);
end;

procedure TFrameProveedores.GridDblClick(Sender: TObject);
var
  Row: Integer;
  ID: Integer;
begin
  Row := Grid.Row;
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;
  ID := PtrInt(Grid.Objects[0, Row]);
  if ID > 0 then ShowProveedorForm(ID);
end;

procedure TFrameProveedores.btnNuevoClick(Sender: TObject);
begin
  ShowProveedorForm(0);
end;

procedure TFrameProveedores.GuardarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrOK;
end;

procedure TFrameProveedores.CancelarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrCancel;
end;

procedure TFrameProveedores.ToggleEstado(ID: Integer; EstadoActual: string);
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
    DM.EjecutarSQL('UPDATE proveedores SET estado=''' + NuevoEstado +
      ''', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(ID));
    DM.EjecutarSQL('UPDATE personas SET estado=''' + NuevoEstado +
      ''', fecha_modificacion=''' + FechaHoraActual +
      ''' WHERE id=(SELECT persona_id FROM proveedores WHERE id=' + IntToStr(ID) + ')');
    DM.Transaccion.Commit;
    for Row := 1 to Grid.RowCount - 1 do
      if PtrInt(Grid.Objects[0, Row]) = ID then
      begin
        Grid.Cells[4, Row] := NuevoEstado;
        Grid.InvalidateCell(4, Row);
        Grid.InvalidateCell(5, Row);
        Break;
      end;
  except
    DM.Transaccion.Rollback;
  end;
end;

procedure TFrameProveedores.PaintRounded(Sender: TObject);
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

procedure TFrameProveedores.ShowProveedorForm(ID: Integer);
var
  F: TForm;
  Lbl, LblSection: TLabel;
  eNom, ePat, eMat, eCI, eTel, eEmp, eDesc: TEdit;
  Nombre, ApPat, ApMat, CIStr, Tel, Emp, Desc: string;
  Q: TSQLQuery;
  IsNew: Boolean;
  YPos: Integer;

  function MakeLabel(ATop, ALeft: Integer; ACaption: string): TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := F;
    Result.SetBounds(ALeft, ATop, 200, 16);
    Result.Caption := ACaption;
    Result.Font.Size := 11;
    Result.Font.Style := [];
    Result.Font.Color := CLR_TEXT_HEADING;
  end;

  function MakeEditConBorde(ATop, ALeft, AWidth: Integer): TEdit;
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
    Result.CharCase := ecUpperCase;
    Result.Color := CLR_WHITE;
  end;

begin
  IsNew := ID = 0;
  Nombre := ''; ApPat := ''; ApMat := ''; CIStr := ''; Tel := ''; Emp := ''; Desc := '';

  // Cargar datos si editar
  if not IsNew then
  begin
    Q := DM.AbrirQuery(
      'SELECT p.nombre, p.apellido_paterno, p.apellido_materno, p.ci, p.telefono, ' +
      'pr.nombre_empresa, pr.descripcion FROM proveedores pr ' +
      'INNER JOIN personas p ON p.id = pr.persona_id WHERE pr.id = ' + IntToStr(ID));
    try
      if not Q.EOF then
      begin
        Nombre := UpperCase(Q.FieldByName('nombre').AsString);
        ApPat := UpperCase(Q.FieldByName('apellido_paterno').AsString);
        ApMat := UpperCase(Q.FieldByName('apellido_materno').AsString);
        CIStr := UpperCase(Q.FieldByName('ci').AsString);
        Tel := UpperCase(Q.FieldByName('telefono').AsString);
        Emp := UpperCase(Q.FieldByName('nombre_empresa').AsString);
        Desc := UpperCase(Q.FieldByName('descripcion').AsString);
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
        if IsNew then Caption := 'Nuevo proveedor'
        else Caption := 'Editar proveedor';
        Font.Size := 14;
        Font.Style := [];
        Font.Color := CLR_TEXT_HEADING;
      end;
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

    // Seccion: Datos personales
    LblSection := TLabel.Create(F);
    LblSection.Parent := F;
    LblSection.SetBounds(24, YPos, 300, 20);
    LblSection.Caption := 'Datos personales';
    LblSection.Font.Size := 11;
    LblSection.Font.Style := [];
    LblSection.Font.Color := CLR_TEXT_HEADING;

    YPos := YPos + 33;

    // Fila 1: Nombre | Apellido paterno | Apellido materno
    MakeLabel(YPos, 24, 'Nombre *');
    MakeLabel(YPos, 212, 'Apellido paterno');
    MakeLabel(YPos, 400, 'Apellido materno');
    YPos := YPos + 28;

    eNom := MakeEditConBorde(YPos, 24, 180);
    eNom.Text := Nombre;
    ePat := MakeEditConBorde(YPos, 212, 180);
    ePat.Text := ApPat;
    eMat := MakeEditConBorde(YPos, 400, 180);
    eMat.Text := ApMat;
    YPos := YPos + 48;

    // Fila 2: CI | Telefono
    MakeLabel(YPos, 24, 'Nro. Documento');
    MakeLabel(YPos, 212, 'Telefono');
    YPos := YPos + 28;

    eCI := MakeEditConBorde(YPos, 24, 180);
    eCI.Text := CIStr;
    eTel := MakeEditConBorde(YPos, 212, 180);
    eTel.Text := Tel;
    YPos := YPos + 56;

    // Seccion: Datos de empresa
    LblSection := TLabel.Create(F);
    LblSection.Parent := F;
    LblSection.SetBounds(24, YPos, 300, 20);
    LblSection.Caption := 'Datos de empresa';
    LblSection.Font.Size := 11;
    LblSection.Font.Style := [];
    LblSection.Font.Color := CLR_TEXT_HEADING;

    YPos := YPos + 33;

    MakeLabel(YPos, 24, 'Nombre empresa');
    MakeLabel(YPos, 314, 'Descripcion');
    YPos := YPos + 28;

    eEmp := MakeEditConBorde(YPos, 24, 280);
    eEmp.Text := Emp;
    eDesc := MakeEditConBorde(YPos, 314, 260);
    eDesc.Text := Desc;
    YPos := YPos + 56;

    // Linea divisora
    with TPanel.Create(F) do
    begin
      Parent := F;
      SetBounds(24, YPos, 556, 1);
      BevelOuter := bvNone;
      Color := CLR_BORDER;
    end;
    YPos := YPos + 16;

    F.Height := YPos + 70;

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
      if Trim(eNom.Text) = '' then
      begin
        ShowMessage('Nombre obligatorio');
        Exit;
      end;

      if DM.Transaccion.Active then
        DM.Transaccion.Rollback;
      DM.Transaccion.StartTransaction;
      try
        if IsNew then
        begin
          DM.EjecutarSQL('INSERT INTO personas (nombre, apellido_paterno, apellido_materno, ci, telefono, estado, fecha_creacion, fecha_modificacion) VALUES (' +
            QuotedStr(Trim(eNom.Text)) + ', ' +
            QuotedStr(Trim(ePat.Text)) + ', ' +
            QuotedStr(Trim(eMat.Text)) + ', ' +
            QuotedStr(Trim(eCI.Text)) + ', ' +
            QuotedStr(Trim(eTel.Text)) + ', ''ACTIVO'', ''' +
            FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
          DM.EjecutarSQL('INSERT INTO proveedores (persona_id, nombre_empresa, descripcion, estado, fecha_creacion, fecha_modificacion) VALUES (' +
            IntToStr(DM.ObtenerUltimoID) + ', ' +
            QuotedStr(Trim(eEmp.Text)) + ', ' +
            QuotedStr(Trim(eDesc.Text)) + ', ''ACTIVO'', ''' +
            FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        end
        else
        begin
          DM.EjecutarSQL('UPDATE personas SET nombre=' + QuotedStr(Trim(eNom.Text)) +
            ', apellido_paterno=' + QuotedStr(Trim(ePat.Text)) +
            ', apellido_materno=' + QuotedStr(Trim(eMat.Text)) +
            ', ci=' + QuotedStr(Trim(eCI.Text)) +
            ', telefono=' + QuotedStr(Trim(eTel.Text)) +
            ', fecha_modificacion=''' + FechaHoraActual +
            ''' WHERE id=(SELECT persona_id FROM proveedores WHERE id=' + IntToStr(ID) + ')');

          DM.EjecutarSQL('UPDATE proveedores SET nombre_empresa=' + QuotedStr(Trim(eEmp.Text)) +
            ', descripcion=' + QuotedStr(Trim(eDesc.Text)) +
            ', fecha_modificacion=''' + FechaHoraActual +
            ''' WHERE id=' + IntToStr(ID));
        end;
        DM.Transaccion.Commit;
        Refrescar(nil);
      except
        DM.Transaccion.Rollback;
        ShowMessage('Error al guardar proveedor');
      end;
    end;
  finally
    F.Free;
  end;
end;

destructor TFrameProveedores.Destroy;
begin
  if FHintWindow <> nil then FreeAndNil(FHintWindow);
  inherited Destroy;
end;

end.
