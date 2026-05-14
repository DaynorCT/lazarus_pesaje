unit UsuariosFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, sqldb, DataModule, Utils, Theme, LoginForm, AuthService;

type
  { TFrameUsuarios }

  TFrameUsuarios = class(TFrame)
    constructor Create(AOwner: TComponent); override;
  private
    Grid: TStringGrid;
    edtBuscarNombre, edtBuscarCI: TEdit;
    btnNuevo, btnRefresh: TButton;
    FEditingID: Integer;
    procedure Refrescar(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ToggleEstado(ID: Integer; EstadoActual: string);
    function GetColByName(const ColName: string): Integer;
    procedure ShowUserForm(ID: Integer);
  end;

implementation

{$R *.lfm}

constructor TFrameUsuarios.Create(AOwner: TComponent);
var
  Pnl: TPanel;
  Lbl: TLabel;
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
  Pnl.Color := CLR_CARD;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := Pnl;
  Lbl.SetBounds(24, 18, 200, 28);
  Lbl.Caption := 'Usuarios';
  Lbl.Font.Height := -24;
  Lbl.Font.Style := [fsBold];
  Lbl.Font.Color := CLR_TEXT_HEADING;

  // Búsqueda por nombre
  edtBuscarNombre := TEdit.Create(Self);
  edtBuscarNombre.Parent := Pnl;
  edtBuscarNombre.SetBounds(240, 11, 220, 30);
  edtBuscarNombre.Font.Size := 14;
  edtBuscarNombre.Font.Color := CLR_TEXT;
  edtBuscarNombre.TextHint := 'Buscar por nombre...';
  edtBuscarNombre.OnChange := @Refrescar;

  // Búsqueda por CI
  edtBuscarCI := TEdit.Create(Self);
  edtBuscarCI.Parent := Pnl;
  edtBuscarCI.SetBounds(468, 11, 160, 30);
  edtBuscarCI.Font.Size := 14;
  edtBuscarCI.Font.Color := CLR_TEXT;
  edtBuscarCI.TextHint := 'Buscar por CI...';
  edtBuscarCI.OnChange := @Refrescar;

  // Botón refrescar
  btnRefresh := TButton.Create(Self);
  btnRefresh.Parent := Pnl;
  btnRefresh.SetBounds(636, 10, 44, 44);
  btnRefresh.Caption := '↻';
  btnRefresh.Font.Size := 18;
  btnRefresh.OnClick := @Refrescar;

  // Botón nuevo
  btnNuevo := TButton.Create(Self);
  btnNuevo.Parent := Pnl;
  btnNuevo.Width := 120;
  btnNuevo.Height := 36;
  btnNuevo.Left := Self.ClientWidth - btnNuevo.Width - 24;
  btnNuevo.Top := 14;
  btnNuevo.Anchors := [akTop, akRight];
  btnNuevo.Caption := '+ Agregar';
  btnNuevo.Font.Size := 14;
  btnNuevo.Font.Style := [fsBold];
  btnNuevo.Font.Color := CLR_PRIMARY;
  btnNuevo.OnClick := @btnNuevoClick;

  // Grid
  Grid := TStringGrid.Create(Self);
  Grid.Parent := Self;
  Grid.SetBounds(24, 80, Self.ClientWidth - 48, Self.ClientHeight - 100);
  Grid.Anchors := [akTop, akLeft, akRight, akBottom];
  Grid.ColCount := 8;
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
  Grid.GridLineWidth := 1;
  Grid.GridLineColor := CLR_BORDER_LIGHT;
  Grid.Flat := True;
  Grid.FocusRectVisible := False;

  Grid.Cells[0, 0] := 'Nro. Documento';
  Grid.Cells[1, 0] := 'Nombres';
  Grid.Cells[2, 0] := 'Correo electrónico';
  Grid.Cells[3, 0] := 'Teléfono';
  Grid.Cells[4, 0] := 'Rol';
  Grid.Cells[5, 0] := 'Estado';
  Grid.Cells[6, 0] := 'Acciones';
  Grid.Cells[7, 0] := 'ID';

  Grid.ColWidths[0] := 120;
  Grid.ColWidths[1] := 260;
  Grid.ColWidths[2] := 220;
  Grid.ColWidths[3] := 120;
  Grid.ColWidths[4] := 120;
  Grid.ColWidths[5] := 90;
  Grid.ColWidths[6] := 80;
  Grid.ColWidths[7] := 0; // ID oculto

  Grid.OnDblClick := @GridDblClick;
  Grid.OnDrawCell := @GridDrawCell;
  Grid.OnMouseDown := @GridMouseDown;

  Refrescar(nil);
end;

procedure TFrameUsuarios.Refrescar(Sender: TObject);
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
    'SELECT u.id, p.ci, p.nombre, p.apellido_paterno, p.apellido_materno, ' +
    'p.telefono, u.email, u.rol, u.estado ' +
    'FROM usuarios u INNER JOIN personas p ON p.id = u.persona_id ' +
    'WHERE 1=1 ' + Filtro + ' ORDER BY p.nombre');

  Grid.RowCount := Q.RecordCount + 1;
  Row := 1;
  while not Q.EOF do
  begin
    ID := Q.Fields[0].AsInteger;
    Grid.Objects[0, Row] := TObject(PtrInt(ID));
    Grid.Cells[0, Row] := UpperCase(Q.Fields[1].AsString);
    Grid.Cells[1, Row] := UpperCase(Trim(
      Q.Fields[2].AsString + ' ' +
      Q.Fields[3].AsString + ' ' +
      Q.Fields[4].AsString));
    Grid.Cells[2, Row] := UpperCase(Q.Fields[6].AsString);
    Grid.Cells[3, Row] := UpperCase(Q.Fields[5].AsString);
    Grid.Cells[4, Row] := UpperCase(Q.Fields[7].AsString);
    Grid.Cells[5, Row] := UpperCase(Q.Fields[8].AsString);
    Grid.Cells[6, Row] := '✏️';
    Grid.Cells[7, Row] := IntToStr(ID);
    Q.Next;
    Inc(Row);
  end;
  Q.Close;
end;

function TFrameUsuarios.GetColByName(const ColName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Grid.ColCount - 1 do
    if Grid.Cells[I, 0] = ColName then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TFrameUsuarios.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
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

  // Columna Estado: badge coloreado
  if aCol = 5 then
  begin
    Ts := Grid.Canvas.TextStyle;
    Ts.Alignment := taCenter;
    Ts.Layout := tlCenter;
    Grid.Canvas.Font.Height := -11;
    Grid.Canvas.Font.Style := [fsBold];

    if Grid.Cells[5, aRow] = 'ACTIVO' then
    begin
      Grid.Canvas.Brush.Color := CLR_SUCCESS_BG;
      Grid.Canvas.Font.Color := CLR_TEAL;
    end
    else
    begin
      Grid.Canvas.Brush.Color := CLR_DESTRUCTIVE_BG;
      Grid.Canvas.Font.Color := CLR_DESTRUCTIVE;
    end;
    Grid.Canvas.FillRect(aRect);
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top, Grid.Cells[5, aRow], Ts);
    Exit;
  end;

  // Fondo de fila seleccionada (gris sutil, sin azul)
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
end;

procedure TFrameUsuarios.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;
  ID: Integer;
begin
  if Button <> mbLeft then Exit;
  Grid.MouseToCell(X, Y, Col, Row);
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;

  // Columna Acciones
  if Col = 6 then
  begin
    if Grid.Cells[5, Row] = 'ACTIVO' then
      ShowUserForm(PtrInt(Grid.Objects[0, Row]));
  end;

  // Toggle estado click en la columna estado
  if Col = 5 then
  begin
    ID := PtrInt(Grid.Objects[0, Row]);
    ToggleEstado(ID, Grid.Cells[5, Row]);
  end;
end;

procedure TFrameUsuarios.GridDblClick(Sender: TObject);
var
  Row: Integer;
  ID: Integer;
begin
  Row := Grid.Row;
  if (Row < 1) or (Row >= Grid.RowCount) then Exit;
  ID := PtrInt(Grid.Objects[0, Row]);
  if ID > 0 then ShowUserForm(ID);
end;

procedure TFrameUsuarios.btnNuevoClick(Sender: TObject);
begin
  ShowUserForm(0);
end;

procedure TFrameUsuarios.ToggleEstado(ID: Integer; EstadoActual: string);
var
  NuevoEstado: string;
begin
  if ID = 0 then Exit;
  if EstadoActual = 'ACTIVO' then
    NuevoEstado := 'INACTIVO'
  else
    NuevoEstado := 'ACTIVO';

  DM.EjecutarSQL('UPDATE usuarios SET estado=''' + NuevoEstado +
    ''', fecha_modificacion=''' + FechaHoraActual + ''' WHERE id=' + IntToStr(ID));
  DM.EjecutarSQL('UPDATE personas SET estado=''' + NuevoEstado +
    ''', fecha_modificacion=''' + FechaHoraActual +
    ''' WHERE id=(SELECT persona_id FROM usuarios WHERE id=' + IntToStr(ID) + ')');
  Refrescar(nil);
end;

procedure TFrameUsuarios.ShowUserForm(ID: Integer);
var
  F: TForm;
  Lbl, LblSection: TLabel;
  eNom, ePat, eMat, eCI, eTel, eEmail, ePass: TEdit;
  cmbRol: TComboBox;
  Hash, Nombre, ApPat, ApMat, CIStr, Tel, Email, Rol, PassStr: string;
  Q: TSQLQuery;
  IsNew: Boolean;
  YPos: Integer;

  function MakeLabel(ATop, ALeft: Integer; ACaption: string): TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := F;
    Result.SetBounds(ALeft, ATop, 200, 16);
    Result.Caption := ACaption;
    Result.Font.Size := 14;
    Result.Font.Style := [fsBold];
    Result.Font.Color := CLR_TEXT_HEADING;
  end;

  function MakeEdit(ATop, ALeft, AWidth: Integer; APassword: Boolean = False): TEdit;
  begin
    Result := TEdit.Create(F);
    Result.Parent := F;
    Result.SetBounds(ALeft, ATop, AWidth, 36);
    Result.Font.Size := 14;
    Result.Font.Color := CLR_TEXT;
    Result.CharCase := ecUpperCase;
    if APassword then
    begin
      Result.PasswordChar := '*';
      Result.CharCase := ecNormal;
    end;
  end;

begin
  IsNew := ID = 0;
  Nombre := ''; ApPat := ''; ApMat := ''; CIStr := ''; Tel := ''; Email := ''; Rol := 'operador'; PassStr := '';

  // Cargar datos si editar
  if not IsNew then
  begin
    Q := DM.AbrirQuery(
      'SELECT p.nombre, p.apellido_paterno, p.apellido_materno, p.ci, p.telefono, ' +
      'u.email, u.rol FROM usuarios u ' +
      'INNER JOIN personas p ON p.id = u.persona_id WHERE u.id = ' + IntToStr(ID));
    try
      if not Q.EOF then
      begin
        Nombre := UpperCase(Q.FieldByName('nombre').AsString);
        ApPat := UpperCase(Q.FieldByName('apellido_paterno').AsString);
        ApMat := UpperCase(Q.FieldByName('apellido_materno').AsString);
        CIStr := UpperCase(Q.FieldByName('ci').AsString);
        Tel := UpperCase(Q.FieldByName('telefono').AsString);
        Email := Q.FieldByName('email').AsString;
        Rol := Q.FieldByName('rol').AsString;
      end;
    finally
      Q.Close;
    end;
  end;

  F := TForm.Create(nil);
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
      Height := 52;
      BevelOuter := bvNone;
      Color := CLR_WHITE;
      with TLabel.Create(F) do
      begin
        Parent := TPanel(F.Controls[F.ControlCount - 1]);
        SetBounds(24, 14, 400, 24);
        if IsNew then Caption := 'Nuevo usuario'
        else Caption := 'Editar usuario';
        Font.Size := 18;
        Font.Style := [fsBold];
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

    YPos := 68;

    // Sección: Datos personales
    LblSection := TLabel.Create(F);
    LblSection.Parent := F;
    LblSection.SetBounds(24, YPos, 300, 20);
    LblSection.Caption := 'Datos personales';
    LblSection.Font.Size := 14;
    LblSection.Font.Style := [fsBold];
    LblSection.Font.Color := CLR_TEXT_HEADING;

    YPos := YPos + 28;

    // Fila 1: Nombre | Apellido paterno | Apellido materno
    MakeLabel(YPos, 24, 'Nombre *');
    MakeLabel(YPos, 212, 'Apellido paterno');
    MakeLabel(YPos, 400, 'Apellido materno');
    YPos := YPos + 20;

    eNom := MakeEdit(YPos, 24, 180);
    eNom.Text := Nombre;
    ePat := MakeEdit(YPos, 212, 180);
    ePat.Text := ApPat;
    eMat := MakeEdit(YPos, 400, 180);
    eMat.Text := ApMat;
    YPos := YPos + 48;

    // Fila 2: CI | Teléfono | Rol
    MakeLabel(YPos, 24, 'Nro. Documento');
    MakeLabel(YPos, 212, 'Teléfono');
    MakeLabel(YPos, 400, 'Rol');
    YPos := YPos + 20;

    eCI := MakeEdit(YPos, 24, 180);
    eCI.Text := CIStr;
    eTel := MakeEdit(YPos, 212, 180);
    eTel.Text := Tel;

    cmbRol := TComboBox.Create(F);
    cmbRol.Parent := F;
    cmbRol.SetBounds(400, YPos, 180, 36);
    cmbRol.Style := csDropDownList;
    cmbRol.Font.Size := 14;
    cmbRol.Items.Add('administrador');
    cmbRol.Items.Add('coordinador');
    cmbRol.Items.Add('operador');
    cmbRol.Items.Add('usuario');
    cmbRol.ItemIndex := cmbRol.Items.IndexOf(Rol);
    if cmbRol.ItemIndex < 0 then cmbRol.ItemIndex := 2;

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

    // Sección: Datos de usuario
    LblSection := TLabel.Create(F);
    LblSection.Parent := F;
    LblSection.SetBounds(24, YPos, 300, 20);
    LblSection.Caption := 'Datos de usuario';
    LblSection.Font.Size := 14;
    LblSection.Font.Style := [fsBold];
    LblSection.Font.Color := CLR_TEXT_HEADING;
    YPos := YPos + 28;

    // Email
    MakeLabel(YPos, 24, 'Correo electrónico *');
    YPos := YPos + 20;
    eEmail := MakeEdit(YPos, 24, 290);
    eEmail.Text := Email;
    eEmail.CharCase := ecNormal;
    YPos := YPos + 48;

    // Contraseña
    Lbl := MakeLabel(YPos, 24, 'Contraseña');
    if not IsNew then
      Lbl.Caption := 'Contraseña (dejar en blanco para mantener)';
    YPos := YPos + 20;
    ePass := MakeEdit(YPos, 24, 290, True);
    ePass.CharCase := ecNormal;
    YPos := YPos + 56;

    F.Height := YPos + 70;

    // Botones
    with TButton.Create(F) do
    begin
      Parent := F;
      SetBounds(310, YPos, 130, 40);
      Caption := 'CANCELAR';
      Font.Size := 14;
      Font.Style := [];
      ModalResult := mrCancel;
    end;

    with TButton.Create(F) do
    begin
      Parent := F;
      SetBounds(450, YPos, 130, 40);
      Caption := 'GUARDAR';
      Font.Size := 14;
      Font.Style := [fsBold];
      ModalResult := mrOK;
    end;

    if F.ShowModal = mrOK then
    begin
      if Trim(eNom.Text) = '' then
      begin
        ShowMessage('Nombre obligatorio');
        Exit;
      end;
      if Trim(eEmail.Text) = '' then
      begin
        ShowMessage('Email obligatorio');
        Exit;
      end;

      PassStr := Trim(ePass.Text);
      if IsNew and (PassStr = '') then
      begin
        ShowMessage('Contraseña obligatoria (mínimo 8 caracteres)');
        Exit;
      end;
      if (PassStr <> '') and (Length(PassStr) < 8) then
      begin
        ShowMessage('La contraseña debe tener al menos 8 caracteres');
        Exit;
      end;

      DM.Transaccion.StartTransaction;
      try
        if IsNew then
        begin
          Hash := TAuthService.HashPassword(PassStr);
          DM.EjecutarSQL('INSERT INTO personas (nombre, apellido_paterno, apellido_materno, ci, telefono, correo, estado, fecha_creacion, fecha_modificacion) VALUES (' +
            QuotedStr(Trim(eNom.Text)) + ', ' +
            QuotedStr(Trim(ePat.Text)) + ', ' +
            QuotedStr(Trim(eMat.Text)) + ', ' +
            QuotedStr(Trim(eCI.Text)) + ', ' +
            QuotedStr(Trim(eTel.Text)) + ', ' +
            QuotedStr(Trim(eEmail.Text)) + ', ''ACTIVO'', ''' +
            FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
          DM.EjecutarSQL('INSERT INTO usuarios (persona_id, email, password_hash, rol, estado, fecha_creacion, fecha_modificacion) VALUES (' +
            IntToStr(DM.ObtenerUltimoID) + ', ' +
            QuotedStr(Trim(eEmail.Text)) + ', ' +
            QuotedStr(Hash) + ', ' +
            QuotedStr(cmbRol.Text) + ', ''ACTIVO'', ''' +
            FechaHoraActual + ''', ''' + FechaHoraActual + ''')');
        end
        else
        begin
          DM.EjecutarSQL('UPDATE personas SET nombre=' + QuotedStr(Trim(eNom.Text)) +
            ', apellido_paterno=' + QuotedStr(Trim(ePat.Text)) +
            ', apellido_materno=' + QuotedStr(Trim(eMat.Text)) +
            ', ci=' + QuotedStr(Trim(eCI.Text)) +
            ', telefono=' + QuotedStr(Trim(eTel.Text)) +
            ', correo=' + QuotedStr(Trim(eEmail.Text)) +
            ', fecha_modificacion=''' + FechaHoraActual +
            ''' WHERE id=(SELECT persona_id FROM usuarios WHERE id=' + IntToStr(ID) + ')');

          if PassStr <> '' then
          begin
            Hash := TAuthService.HashPassword(PassStr);
            DM.EjecutarSQL('UPDATE usuarios SET email=' + QuotedStr(Trim(eEmail.Text)) +
              ', password_hash=' + QuotedStr(Hash) +
              ', rol=' + QuotedStr(cmbRol.Text) +
              ', fecha_modificacion=''' + FechaHoraActual +
              ''' WHERE id=' + IntToStr(ID));
          end
          else
            DM.EjecutarSQL('UPDATE usuarios SET email=' + QuotedStr(Trim(eEmail.Text)) +
              ', rol=' + QuotedStr(cmbRol.Text) +
              ', fecha_modificacion=''' + FechaHoraActual +
              ''' WHERE id=' + IntToStr(ID));
        end;
        DM.Transaccion.Commit;
        Refrescar(nil);
      except
        DM.Transaccion.Rollback;
        ShowMessage('Error al guardar usuario');
      end;
    end;
  finally
    F.Free;
  end;
end;

end.
