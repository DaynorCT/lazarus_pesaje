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
    edtBuscar: TEdit;
    btnNuevo, btnEliminar: TButton;
    procedure Refrescar(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnEliminarClick(Sender: TObject);
    procedure GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
    function GetSelectedID: Integer;
  end;

implementation

{$R *.lfm}

constructor TFrameUsuarios.Create(AOwner: TComponent);
var Pnl: TPanel; Lbl: TLabel;
begin
  inherited Create(AOwner);
  Self.Color := CLR_BG;
  Pnl := TPanel.Create(Self); Pnl.Parent := Self; Pnl.Align := alTop;
  Pnl.Height := 56; Pnl.BevelOuter := bvNone; Pnl.Color := CLR_CARD;

  Lbl := TLabel.Create(Self); Lbl.Parent := Pnl;
  Lbl.SetBounds(24, 14, 200, 28); Lbl.Caption := 'Usuarios';
  Lbl.Font.Height := -18; Lbl.Font.Style := [fsBold]; Lbl.Font.Color := $333333;

  edtBuscar := TEdit.Create(Self); edtBuscar.Parent := Pnl;
  edtBuscar.SetBounds(240, 14, 250, 28); edtBuscar.Font.Size := 12;
  edtBuscar.TextHint := 'Buscar por nombre o email...';
  edtBuscar.OnChange := @Refrescar;

  btnNuevo := TButton.Create(Self); btnNuevo.Parent := Pnl;
  btnNuevo.SetBounds(500, 12, 100, 32);
  btnNuevo.Caption := '+ Nuevo'; btnNuevo.Font.Style := [fsBold];
  btnNuevo.OnClick := @btnNuevoClick;

  Grid := TStringGrid.Create(Self); Grid.Parent := Self;
  Grid.SetBounds(24, 72, Self.ClientWidth - 48, Self.ClientHeight - 152);
  Grid.Anchors := [akTop,akLeft,akRight,akBottom];
  Grid.ColCount := 5; Grid.RowCount := 2; Grid.FixedRows := 1;
  Grid.FixedCols := 0; Grid.Options := Grid.Options + [goRowSelect];
  Grid.Color := CLR_CARD;
  Grid.FixedColor := CLR_TABLE_HEADER;
  Grid.DefaultRowHeight := 26;
  Grid.Cells[0,0]:='ID'; Grid.Cells[1,0]:='Nombre'; Grid.Cells[2,0]:='Email';
  Grid.Cells[3,0]:='Rol'; Grid.Cells[4,0]:='Estado';
  Grid.ColWidths[0]:=50; Grid.ColWidths[1]:=200; Grid.ColWidths[2]:=220;
  Grid.ColWidths[3]:=120;
  Grid.OnSelectCell := @GridSelectCell;

  btnEliminar := TButton.Create(Self); btnEliminar.Parent := Self;
  btnEliminar.SetBounds(132, Self.ClientHeight - 60, 160, 32);
  btnEliminar.Anchors := [akLeft,akBottom]; btnEliminar.Caption := 'Activar/Desactivar';
  btnEliminar.Enabled := False; btnEliminar.OnClick := @btnEliminarClick;

  Refrescar(nil);
end;

procedure TFrameUsuarios.Refrescar(Sender: TObject);
var Q: TSQLQuery; Filtro: string; Row: Integer;
begin
  if (DM=nil)or(not DM.Conexion.Connected) then Exit;
  Filtro := Trim(edtBuscar.Text);
  if Filtro<>'' then
    Filtro := ' AND (p.nombre LIKE ''%'+StringReplace(Filtro,'''','''''',[rfReplaceAll])+
      '%'' OR u.email LIKE ''%'+StringReplace(Filtro,'''','''''',[rfReplaceAll])+'%'') '
  else Filtro := '';
  Q := DM.AbrirQuery(
    'SELECT u.id, p.nombre||'' ''||COALESCE(p.apellido_paterno,''''), u.email, u.rol, u.estado '+
    'FROM usuarios u INNER JOIN personas p ON p.id=u.persona_id '+
    'WHERE 1=1'+Filtro+' ORDER BY p.nombre');
  Grid.RowCount := Q.RecordCount+1; Row:=1;
  while not Q.EOF do begin
    Grid.Cells[0,Row]:=Q.Fields[0].AsString; Grid.Cells[1,Row]:=Q.Fields[1].AsString;
    Grid.Cells[2,Row]:=Q.Fields[2].AsString; Grid.Cells[3,Row]:=Q.Fields[3].AsString;
    Grid.Cells[4,Row]:=Q.Fields[4].AsString;
    Q.Next; Inc(Row);
  end; Q.Close;
end;

procedure TFrameUsuarios.GridSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  btnEliminar.Enabled:=(aRow>=1)and(Grid.Cells[0,aRow]<>'');
end;

function TFrameUsuarios.GetSelectedID: Integer;
begin Result:=StrToIntDef(Grid.Cells[0,Grid.Row],0); end;

procedure TFrameUsuarios.btnNuevoClick(Sender: TObject);
var
  F: TForm; Lbl: TLabel;
  eNom, ePat, eEmail, ePass: TEdit;
  cmbRol: TComboBox;
  Hash: string;
begin
  F := TForm.Create(nil);
  try
    F.Caption:='Nuevo Usuario'; F.Width:=440; F.Height:=370;
    F.Position:=poOwnerFormCenter; F.BorderStyle:=bsDialog;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,16,200,16);
    Lbl.Caption:='Nombre *'; Lbl.Font.Style:=[fsBold];
    eNom:=TEdit.Create(F); eNom.Parent:=F; eNom.SetBounds(24,36,190,32); eNom.Font.Size:=12;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(226,16,200,16);
    Lbl.Caption:='Apellido'; Lbl.Font.Style:=[fsBold];
    ePat:=TEdit.Create(F); ePat.Parent:=F; ePat.SetBounds(226,36,190,32); ePat.Font.Size:=12;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,76,200,16);
    Lbl.Caption:='Email *'; Lbl.Font.Style:=[fsBold];
    eEmail:=TEdit.Create(F); eEmail.Parent:=F; eEmail.SetBounds(24,96,380,32); eEmail.Font.Size:=12;

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,140,200,16);
    Lbl.Caption:='Password *'; Lbl.Font.Style:=[fsBold];
    ePass:=TEdit.Create(F); ePass.Parent:=F; ePass.SetBounds(24,160,200,32);
    ePass.Font.Size:=12; ePass.PasswordChar:='*';

    Lbl:=TLabel.Create(F); Lbl.Parent:=F; Lbl.SetBounds(24,204,200,16);
    Lbl.Caption:='Rol'; Lbl.Font.Style:=[fsBold];
    cmbRol:=TComboBox.Create(F); cmbRol.Parent:=F;
    cmbRol.SetBounds(24,224,200,32);
    cmbRol.Style:=csDropDownList; cmbRol.Font.Size:=12;
    cmbRol.Items.Add('operador'); cmbRol.Items.Add('usuario');
    if UsuarioActual.Rol='administrador' then cmbRol.Items.Add('administrador');
    cmbRol.ItemIndex:=0;

    with TButton.Create(F) do begin Parent:=F; SetBounds(140,290,100,36);
      Caption:='Guardar'; Font.Style:=[fsBold]; ModalResult:=mrOK; end;
    with TButton.Create(F) do begin Parent:=F; SetBounds(250,290,100,36);
      Caption:='Cancelar'; ModalResult:=mrCancel; end;

    if F.ShowModal=mrOK then begin
      if Trim(eNom.Text)='' then begin ShowMessage('Nombre obligatorio'); Exit; end;
      if Trim(eEmail.Text)='' then begin ShowMessage('Email obligatorio'); Exit; end;
      if Trim(ePass.Text)='' then begin ShowMessage('Password obligatorio'); Exit; end;
      Hash:=TAuthService.HashPassword(Trim(ePass.Text));
      DM.Transaccion.StartTransaction;
      try
        DM.EjecutarSQL('INSERT INTO personas (nombre, apellido_paterno, correo, estado, fecha_creacion, fecha_modificacion) VALUES ('+
          QuotedStr(Trim(eNom.Text))+', '+QuotedStr(Trim(ePat.Text))+', '+
          QuotedStr(Trim(eEmail.Text))+', ''ACTIVO'', '''+
          FechaHoraActual+''', '''+FechaHoraActual+''')');
        DM.EjecutarSQL('INSERT INTO usuarios (persona_id, email, password_hash, rol, estado, fecha_creacion, fecha_modificacion) VALUES ('+
          IntToStr(DM.ObtenerUltimoID)+', '+QuotedStr(Trim(eEmail.Text))+', '+
          QuotedStr(Hash)+', '+QuotedStr(cmbRol.Text)+', ''ACTIVO'', '''+
          FechaHoraActual+''', '''+FechaHoraActual+''')');
        DM.Transaccion.Commit; Refrescar(nil);
      except DM.Transaccion.Rollback; end;
    end;
  finally F.Free; end;
end;

procedure TFrameUsuarios.btnEliminarClick(Sender: TObject);
var ID: Integer; Est: string;
begin
  ID:=GetSelectedID; if ID=0 then Exit;
  Est:=Grid.Cells[4, Grid.Row];
  if Est='ACTIVO' then Est:='INACTIVO' else Est:='ACTIVO';
  DM.EjecutarSQL('UPDATE usuarios SET estado='''+Est+
    ''', fecha_modificacion='''+FechaHoraActual+''' WHERE id='+IntToStr(ID));
  Refrescar(nil);
end;

end.
