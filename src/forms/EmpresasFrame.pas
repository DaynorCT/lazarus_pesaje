unit EmpresasFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme, base64;

type
  { TFrameEmpresas }

  TFrameEmpresas = class(TFrame)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    Grid: TStringGrid;
    pnlCard: TPanel;
    pnlNuevo: TPanel;
    lblNuevo: TLabel;
    edtBuscarNombre: TEdit;
    FEditingID: Integer;
    FLogoBase64: string;
    FModalForm: TForm;
    FModalImgPreview: TImage;
    FModalPnlLogo: TPanel;
    FModalBtnLogo: TPanel;
    FHoverRow: Integer;
    FHoverZone: Integer;
    FHintWindow: THintWindow;
    FHintTimer: TTimer;
    FHintActive: Boolean;
    procedure Refrescar(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure GuardarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure CargarLogoClick(Sender: TObject);
    procedure RemoveLogoClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HintTimerTick(Sender: TObject);
    procedure MostrarHintAccion(const Texto: string);
    procedure ToggleEstado(ID: Integer; EstadoActual: string);
    procedure PaintRounded(Sender: TObject);
    procedure ShowEmpresaForm(ID: Integer);
  end;

implementation

uses
  MainForm;

{$R *.lfm}

constructor TFrameEmpresas.Create(AOwner: TComponent);
var
  Pnl: TPanel;
  Lbl: TLabel;
  pnlOuter, pnlInner: TPanel;
begin
  inherited Create(AOwner);
  FEditingID := 0;
  FLogoBase64 := '';
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
  Lbl.Caption := 'Empresas';
  Lbl.Font.Height := -24;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // Busqueda por nombre
  pnlOuter := TPanel.Create(Pnl);
  pnlOuter.Parent := Pnl;
  pnlOuter.SetBounds(240, 19, 300, 40);
  pnlOuter.BevelOuter := bvNone;
  pnlOuter.Color := CLR_BORDER;

  pnlInner := TPanel.Create(pnlOuter);
  pnlInner.Parent := pnlOuter;
  pnlInner.SetBounds(1, 1, 298, 38);
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
  edtBuscarNombre.TextHint := 'Buscar por nombre...';
  edtBuscarNombre.OnChange := @Refrescar;

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
  pnlCard.SetBounds(24, 90, Self.ClientWidth - 48, Self.ClientHeight - 116);
  pnlCard.Anchors := [akTop, akLeft, akRight, akBottom];
  pnlCard.BevelOuter := bvLowered;
  pnlCard.BevelInner := bvNone;
  pnlCard.BevelWidth := 1;
  pnlCard.Color := CLR_CARD;

  // Grid
  Grid := TStringGrid.Create(Self);
  Grid.Parent := pnlCard;
  Grid.SetBounds(2, 2, pnlCard.ClientWidth - 4, pnlCard.ClientHeight - 4);
  Grid.Anchors := [akTop, akLeft, akRight, akBottom];
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

  Grid.Cells[0, 0] := 'Empresa';
  Grid.Cells[1, 0] := 'Actividad';
  Grid.Cells[2, 0] := 'Correo';
  Grid.Cells[3, 0] := 'Telefono';
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

procedure TFrameEmpresas.Refrescar(Sender: TObject);
var
  Q: TSQLQuery;
  Filtro: string;
  Row, ID: Integer;
begin
  if (DM = nil) or (not DM.Conexion.Connected) then Exit;

  Filtro := '';
  if Trim(edtBuscarNombre.Text) <> '' then
    Filtro := ' AND nombre_empresa LIKE ''%' +
      StringReplace(Trim(edtBuscarNombre.Text), '''', '''''', [rfReplaceAll]) + '%'' ';

  Q := DM.AbrirQuery(
    'SELECT id, nombre_empresa, actividad_economica, correo_electronico, ' +
    'telefono, estado FROM empresas WHERE 1=1 ' + Filtro + ' ORDER BY id DESC');

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
    Grid.Cells[4, Row] := UpperCase(Q.Fields[5].AsString);
    Grid.Cells[5, Row] := '';
    Grid.Cells[6, Row] := IntToStr(ID);
    Q.Next;
    Inc(Row);
  end;
  Q.Close;
end;

procedure TFrameEmpresas.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
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

procedure TFrameEmpresas.GridMouseDown(Sender: TObject; Button: TMouseButton;
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
      ShowEmpresaForm(ID);
  end;
end;

procedure TFrameEmpresas.GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
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

procedure TFrameEmpresas.HintTimerTick(Sender: TObject);
var Texto: string; P: TPoint;
begin
  FHintTimer.Enabled := False;
  if FHoverZone = 0 then Exit;
  case FHoverZone of
    1: if Grid.Cells[4, FHoverRow] = 'ACTIVO' then Texto := 'Desactivar' else Texto := 'Activar';
    2: Texto := 'Editar empresa';
  else Exit; end;
  P := Mouse.CursorPos;
  MostrarHintAccion(Texto);
  FHintWindow.Top := P.Y + 20; FHintWindow.Left := P.X + 12;
  FHintWindow.Show; FHintActive := True;
end;

procedure TFrameEmpresas.MostrarHintAccion(const Texto: string);
var R: TRect;
begin
  if FHintWindow = nil then begin
    FHintWindow := THintWindow.Create(Self);
    FHintWindow.Color := CLR_TEXT; FHintWindow.Font.Size := 11; FHintWindow.Font.Color := CLR_WHITE;
  end;
  R := FHintWindow.CalcHintRect(250, Texto, nil);
  FHintWindow.ActivateHint(R, Texto);
end;

procedure TFrameEmpresas.GridDblClick(Sender: TObject);
var
  Row: Integer;
  ID: Integer;
begin
  Row := Grid.Row;
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;
  ID := PtrInt(Grid.Objects[0, Row]);
  if ID > 0 then ShowEmpresaForm(ID);
end;

procedure TFrameEmpresas.btnNuevoClick(Sender: TObject);
begin
  ShowEmpresaForm(0);
end;

procedure TFrameEmpresas.GuardarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrOK;
end;

procedure TFrameEmpresas.CancelarClick(Sender: TObject);
begin
  FModalForm.ModalResult := mrCancel;
end;

procedure TFrameEmpresas.ToggleEstado(ID: Integer; EstadoActual: string);
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
    DM.EjecutarSQL('UPDATE empresas SET estado=''' + NuevoEstado +
      ''', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(ID));
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

procedure TFrameEmpresas.PaintRounded(Sender: TObject);
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

procedure TFrameEmpresas.CargarLogoClick(Sender: TObject);
var
  dlgLogo: TOpenDialog;
  Stream: TMemoryStream;
  RawBytes: RawByteString;
  FileExt: string;
  MimeType: string;
begin
  dlgLogo := TOpenDialog.Create(FModalForm);
  try
    dlgLogo.Filter := 'Imagenes (*.jpg;*.png;*.webp)|*.jpg;*.png;*.webp';
    dlgLogo.Options := [ofFileMustExist];
    if dlgLogo.Execute then
    begin
      Stream := TMemoryStream.Create;
      try
        Stream.LoadFromFile(dlgLogo.FileName);
        if Stream.Size > 2 * 1024 * 1024 then
        begin
          ShowMessage('El archivo debe ser menor a 2MB');
          Exit;
        end;

        SetLength(RawBytes, Stream.Size);
        Stream.Position := 0;
        Stream.Read(RawBytes[1], Stream.Size);
        FLogoBase64 := EncodeStringBase64(RawBytes);

        FileExt := LowerCase(ExtractFileExt(dlgLogo.FileName));
        if FileExt = '.jpg' then MimeType := 'image/jpeg'
        else if FileExt = '.webp' then MimeType := 'image/webp'
        else MimeType := 'image/png';

        FLogoBase64 := 'data:' + MimeType + ';base64,' + FLogoBase64;

        SetLength(RawBytes, 0);
        RawBytes := DecodeStringBase64(Copy(FLogoBase64, Pos('base64,', FLogoBase64) + 7, MaxInt));
        Stream.Clear;
        Stream.Write(RawBytes[1], Length(RawBytes));
        Stream.Position := 0;
        FModalImgPreview.Picture.LoadFromStream(Stream);

        FModalPnlLogo.Visible := True;
        FModalBtnLogo.Visible := False;
      finally
        Stream.Free;
      end;
    end;
  finally
    dlgLogo.Free;
  end;
end;

procedure TFrameEmpresas.RemoveLogoClick(Sender: TObject);
begin
  FLogoBase64 := '';
  FModalPnlLogo.Visible := False;
  FModalBtnLogo.Visible := True;
end;

procedure TFrameEmpresas.ShowEmpresaForm(ID: Integer);
var
  F: TForm;
  Lbl, LblSection: TLabel;
  eNom, eAct, eCorreo, eTel: TEdit;
  Nombre, Actividad, Correo, Telefono, LogoStr: string;
  Q: TSQLQuery;
  IsNew: Boolean;
  YPos: Integer;
  lblRemoveLogo: TLabel;
  LblCargarLogo: TLabel;
  Stream: TMemoryStream;
  RawBytes: RawByteString;

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
  Nombre := ''; Actividad := ''; Correo := ''; Telefono := ''; LogoStr := ''; FLogoBase64 := '';

  if not IsNew then
  begin
    Q := DM.AbrirQuery(
      'SELECT nombre_empresa, actividad_economica, correo_electronico, ' +
      'telefono, logo FROM empresas WHERE id = ' + IntToStr(ID));
    try
      if not Q.EOF then
      begin
        Nombre := UpperCase(Q.FieldByName('nombre_empresa').AsString);
        Actividad := UpperCase(Q.FieldByName('actividad_economica').AsString);
        Correo := Q.FieldByName('correo_electronico').AsString;
        Telefono := UpperCase(Q.FieldByName('telefono').AsString);
        LogoStr := Q.FieldByName('logo').AsString;
        FLogoBase64 := LogoStr;
      end;
    finally
      Q.Close;
    end;
  end;

  F := TForm.Create(nil);
  FModalForm := F;
  FModalImgPreview := nil;
  FModalPnlLogo := nil;
  FModalBtnLogo := nil;
  try
    F.Caption := '';
    F.Width := 600;
    F.Position := poOwnerFormCenter;
    F.BorderStyle := bsDialog;
    F.Color := CLR_WHITE;

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
        if IsNew then Caption := 'Nueva empresa'
        else Caption := 'Editar empresa';
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

    LblSection := TLabel.Create(F);
    LblSection.Parent := F;
    LblSection.SetBounds(24, YPos, 300, 20);
    LblSection.Caption := 'Datos de la Empresa';
    LblSection.Font.Size := 11;
    LblSection.Font.Style := [];
    LblSection.Font.Color := CLR_TEXT_HEADING;

    YPos := YPos + 33;

    MakeLabel(YPos, 24, 'Nombre de empresa *');
    MakeLabel(YPos, 314, 'Actividad economica *');
    YPos := YPos + 28;

    eNom := MakeEditConBorde(YPos, 24, 280);
    eNom.Text := Nombre;
    eAct := MakeEditConBorde(YPos, 314, 260);
    eAct.Text := Actividad;
    YPos := YPos + 48;

    MakeLabel(YPos, 24, 'Correo electronico');
    MakeLabel(YPos, 314, 'Telefono');
    YPos := YPos + 28;

    eCorreo := MakeEditConBorde(YPos, 24, 280);
    eCorreo.CharCase := ecNormal;
    eCorreo.Text := Correo;
    eTel := MakeEditConBorde(YPos, 314, 260);
    eTel.Text := Telefono;
    YPos := YPos + 48;

    MakeLabel(YPos, 24, 'Logo');
    YPos := YPos + 28;

    FModalPnlLogo := TPanel.Create(F);
    FModalPnlLogo.Parent := F;
    FModalPnlLogo.SetBounds(24, YPos, 56, 56);
    FModalPnlLogo.BevelOuter := bvNone;
    FModalPnlLogo.Color := CLR_WHITE;
    FModalPnlLogo.Visible := FLogoBase64 <> '';

    FModalImgPreview := TImage.Create(FModalPnlLogo);
    FModalImgPreview.Parent := FModalPnlLogo;
    FModalImgPreview.Align := alClient;
    FModalImgPreview.Stretch := True;
    FModalImgPreview.Proportional := True;
    FModalImgPreview.Center := True;

    if FLogoBase64 <> '' then
    begin
      try
        RawBytes := DecodeStringBase64(Copy(FLogoBase64, Pos('base64,', FLogoBase64) + 7, MaxInt));
        Stream := TMemoryStream.Create;
        try
          Stream.Write(RawBytes[1], Length(RawBytes));
          Stream.Position := 0;
          FModalImgPreview.Picture.LoadFromStream(Stream);
        finally
          Stream.Free;
        end;
      except
        FModalPnlLogo.Visible := False;
      end;
    end;

    lblRemoveLogo := TLabel.Create(F);
    lblRemoveLogo.Parent := FModalPnlLogo;
    lblRemoveLogo.SetBounds(FModalPnlLogo.Width - 16, -4, 16, 14);
    lblRemoveLogo.Caption := '✕';
    lblRemoveLogo.Font.Size := 10;
    lblRemoveLogo.Font.Color := CLR_DESTRUCTIVE;
    lblRemoveLogo.Cursor := crHandPoint;
    lblRemoveLogo.OnClick := @RemoveLogoClick;

    FModalBtnLogo := TPanel.Create(F);
    FModalBtnLogo.Parent := F;
    FModalBtnLogo.SetBounds(90, YPos + 10, 130, 36);
    FModalBtnLogo.BevelOuter := bvNone;
    FModalBtnLogo.Color := CLR_WHITE;
    FModalBtnLogo.Tag := 1;
    FModalBtnLogo.Cursor := crHandPoint;
    FModalBtnLogo.OnPaint := @PaintRounded;
    FModalBtnLogo.Visible := FLogoBase64 = '';

    LblCargarLogo := TLabel.Create(FModalBtnLogo);
    LblCargarLogo.Parent := FModalBtnLogo;
    LblCargarLogo.Align := alClient;
    LblCargarLogo.Alignment := taCenter;
    LblCargarLogo.Layout := tlCenter;
    LblCargarLogo.Caption := 'Cargar logo';
    LblCargarLogo.Font.Size := 12;
    LblCargarLogo.Font.Style := [];
    LblCargarLogo.Font.Color := CLR_PRIMARY;
    LblCargarLogo.OnClick := @CargarLogoClick;

    YPos := YPos + 56;

    Lbl := TLabel.Create(F);
    Lbl.Parent := F;
    Lbl.SetBounds(24, YPos, 400, 14);
    Lbl.Caption := 'JPG, PNG o WEBP. Tamano maximo: 2MB.';
    Lbl.Font.Size := 10;
    Lbl.Font.Color := CLR_TEXT_SLATE;
    YPos := YPos + 28;

    with TPanel.Create(F) do
    begin
      Parent := F;
      SetBounds(24, YPos, 556, 1);
      BevelOuter := bvNone;
      Color := CLR_BORDER;
    end;
    YPos := YPos + 16;

    F.Height := YPos + 70;

    // CANCELAR
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

    // GUARDAR
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
        ShowMessage('Nombre de empresa obligatorio');
        Exit;
      end;
      if Trim(eAct.Text) = '' then
      begin
        ShowMessage('Actividad economica obligatoria');
        Exit;
      end;

      if DM.Transaccion.Active then
        DM.Transaccion.Rollback;
      DM.Transaccion.StartTransaction;
      try
        if IsNew then
        begin
          DM.EjecutarSQL('INSERT INTO empresas (nombre_empresa, actividad_economica, ' +
            'correo_electronico, telefono, logo, estado, fecha_creacion, fecha_modificacion) VALUES (' +
            QuotedStr(Trim(eNom.Text)) + ', ' +
            QuotedStr(Trim(eAct.Text)) + ', ' +
            QuotedStr(Trim(eCorreo.Text)) + ', ' +
            QuotedStr(Trim(eTel.Text)) + ', ' +
            QuotedStr(FLogoBase64) + ', ''ACTIVO'', ''' +
            FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        end
        else
        begin
          DM.EjecutarSQL('UPDATE empresas SET nombre_empresa=' + QuotedStr(Trim(eNom.Text)) +
            ', actividad_economica=' + QuotedStr(Trim(eAct.Text)) +
            ', correo_electronico=' + QuotedStr(Trim(eCorreo.Text)) +
            ', telefono=' + QuotedStr(Trim(eTel.Text)) +
            ', logo=' + QuotedStr(FLogoBase64) +
            ', fecha_modificacion=''' + FechaHoraActual +
            ''' WHERE id=' + IntToStr(ID));
        end;
        DM.Transaccion.Commit;
        Refrescar(nil);
        if Assigned(frmMain) then
          frmMain.CargarLogo;
      except
        DM.Transaccion.Rollback;
        ShowMessage('Error al guardar empresa');
      end;
    end;
  finally
    F.Free;
    FModalForm := nil;
  end;
end;

destructor TFrameEmpresas.Destroy;
begin
  if FHintWindow <> nil then FreeAndNil(FHintWindow);
  inherited Destroy;
end;

end.
