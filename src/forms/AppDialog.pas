unit AppDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Theme;

type
  TDialogoTipo = (dtInfo, dtExito, dtError, dtPregunta);

function MostrarInfoDialogo(const Titulo, Mensaje: string;
  ATipo: TDialogoTipo = dtInfo): Boolean;
function ConfirmarDialogo(const Titulo, Mensaje: string): Boolean;
function ConfirmarContrasena(const Titulo: string): Boolean;
function MostrarDialogoFinalizar(PesajeID, Bruto, Tara, Neto: Integer): Boolean;

implementation

uses
  AuthService, LoginForm;

const
  D_W   = 380;
  TOP_H = 52;
  BTN_H = 34;

type
  TAppDialogo = class(TForm)
  private
    edtPass: TEdit;
    lblPass: TLabel;
    procedure AceptarClick(Sender: TObject);
    procedure CancelarClick(Sender: TObject);
    procedure Construir(const Titulo, Mensaje: string; ATipo: TDialogoTipo;
      AConfirmar: Boolean; AConPass: Boolean);
  end;

  TDialogoFinalizar = class(TForm)
  private
    procedure OkClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
  end;

procedure CrearBotonC(AParent: TWinControl; ALeft, ATop, AW: Integer;
  const ACaption: string; AColor, AFontColor: TColor; AClick: TNotifyEvent);
var
  P: TPanel;
  Lbl: TLabel;
begin
  P := TPanel.Create(AParent);
  P.Parent := AParent;
  P.SetBounds(ALeft, ATop, AW, BTN_H);
  P.BevelOuter := bvNone;
  P.Color := AColor;
  P.Cursor := crHandPoint;
  P.OnClick := AClick;
  Lbl := TLabel.Create(P);
  Lbl.Parent := P;
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

// Calcula la altura necesaria para mostrar Txt con WordWrap en un
// ancho AW (según la fuente del canvas).
function AlturaMensaje(ACanvas: TCanvas; const Txt: string; AW: Integer): Integer;
var
  I, StartIdx: Integer;
  Linea, Palabra: string;
  LH: Integer;
begin
  LH := ACanvas.TextHeight('Ag');
  Result := LH;
  if AW < 10 then AW := 10;
  Linea := '';
  StartIdx := 1;
  I := 1;
  while I <= Length(Txt) + 1 do
  begin
    if (I > Length(Txt)) or (Txt[I] = ' ') then
    begin
      Palabra := Copy(Txt, StartIdx, I - StartIdx);
      StartIdx := I + 1;
      if Palabra <> '' then
      begin
        if (Linea <> '') and (ACanvas.TextWidth(Linea + ' ' + Palabra) > AW) then
        begin
          Result := Result + LH;
          Linea := Palabra;
        end
        else if Linea = '' then
          Linea := Palabra
        else
          Linea := Linea + ' ' + Palabra;
      end;
    end;
    Inc(I);
  end;
end;

procedure TAppDialogo.Construir(const Titulo, Mensaje: string;
  ATipo: TDialogoTipo; AConfirmar: Boolean; AConPass: Boolean);
var
  pnlTop, pnlSep: TPanel;
  lblTitulo, lblIcono, lblMsg: TLabel;
  pO, pI: TPanel;
  H, MsgH, BtnY, MsgW: Integer;
begin
  MsgW := D_W - 78;

  Caption := '';
  Width := D_W;
  Position := poMainFormCenter;
  BorderStyle := bsDialog;
  Color := CLR_BG;
  Constraints.MinWidth := D_W;
  Constraints.MaxWidth := D_W;

  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := TOP_H;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Color := CLR_CARD;

  lblTitulo := TLabel.Create(pnlTop);
  lblTitulo.Parent := pnlTop;
  lblTitulo.SetBounds(20, 14, D_W - 40, 24);
  lblTitulo.Caption := Titulo;
  lblTitulo.Font.Size := 13;
  lblTitulo.Font.Style := [fsBold];
  lblTitulo.Font.Color := CLR_TEXT_HEADING;

  pnlSep := TPanel.Create(pnlTop);
  pnlSep.Parent := pnlTop;
  pnlSep.Align := alBottom;
  pnlSep.Height := 1;
  pnlSep.BevelOuter := bvNone;
  pnlSep.Color := CLR_BORDER;

  lblIcono := TLabel.Create(Self);
  lblIcono.Parent := Self;
  lblIcono.SetBounds(20, 66, 30, 30);
  lblIcono.Alignment := taCenter;
  lblIcono.Layout := tlCenter;
  lblIcono.Font.Size := 15;
  lblIcono.Font.Name := FA_FONT_NAME;
  case ATipo of
    dtExito:     begin lblIcono.Font.Color := CLR_SUCCESS;    lblIcono.Caption := FAIconoStr(FA_CHECK, '✓'); end;
    dtError:     begin lblIcono.Font.Color := CLR_DESTRUCTIVE; lblIcono.Caption := FAIconoStr(FA_TIMES, '✕'); end;
    dtPregunta:  begin lblIcono.Font.Color := CLR_WARNING;    lblIcono.Caption := FAIconoStr(FA_CHECK, '?'); end;
  else
    begin lblIcono.Font.Color := CLR_INFO;    lblIcono.Caption := FAIconoStr(FA_CHECK, 'i'); end;
  end;

  lblMsg := TLabel.Create(Self);
  lblMsg.Parent := Self;
  lblMsg.Caption := Mensaje;
  lblMsg.Font.Size := 10;
  lblMsg.Font.Color := CLR_TEXT;
  lblMsg.WordWrap := True;
  lblMsg.Alignment := taLeftJustify;
  lblMsg.Layout := tlTop;

  // Altura del mensaje según su largo (el texto nunca se corta)
  lblMsg.Canvas.Font := lblMsg.Font;
  MsgH := AlturaMensaje(lblMsg.Canvas, Mensaje, MsgW) + 6;
  if MsgH < 22 then MsgH := 22;
  lblMsg.SetBounds(58, 62, MsgW, MsgH);

  BtnY := 62 + MsgH + 12;

  if AConPass then
  begin
    lblPass := TLabel.Create(Self);
    lblPass.Parent := Self;
    lblPass.SetBounds(58, BtnY + 2, MsgW, 14);
    lblPass.Caption := 'Ingrese la contrasena de ' + UsuarioActual.Email;
    lblPass.Font.Size := 9;
    lblPass.Font.Color := CLR_TEXT_SLATE;

    pO := TPanel.Create(Self);
    pO.Parent := Self;
    pO.SetBounds(58, BtnY + 20, MsgW, 38);
    pO.BevelOuter := bvNone;
    pO.Color := CLR_BORDER;
    pI := TPanel.Create(pO);
    pI.Parent := pO;
    pI.SetBounds(1, 1, MsgW - 2, 36);
    pI.BevelOuter := bvNone;
    pI.Color := CLR_WHITE;
    pI.BorderWidth := 6;
    edtPass := TEdit.Create(pI);
    edtPass.Parent := pI;
    edtPass.Align := alClient;
    edtPass.BorderStyle := bsNone;
    edtPass.Font.Size := 11;
    edtPass.Font.Color := CLR_TEXT;
    edtPass.Color := CLR_WHITE;
    edtPass.PasswordChar := '*';

    BtnY := BtnY + 20 + 38 + 10;
  end;

  H := BtnY + BTN_H + 12;
  if H < 150 then H := 150;

  Self.Height := H;
  Self.Constraints.MinHeight := H;
  Self.Constraints.MaxHeight := H;

  if AConfirmar or AConPass then
  begin
    CrearBotonC(Self, D_W - 2 * 122, BtnY, 110, 'CANCELAR', CLR_CARD, CLR_PRIMARY, @CancelarClick);
    CrearBotonC(Self, D_W - 122 - 12, BtnY, 110, 'ACEPTAR', CLR_PRIMARY, CLR_WHITE, @AceptarClick);
  end
  else
    CrearBotonC(Self, (D_W - 110) div 2, BtnY, 110, 'ACEPTAR', CLR_PRIMARY, CLR_WHITE, @AceptarClick);
end;

procedure TAppDialogo.AceptarClick(Sender: TObject);
begin
  if edtPass <> nil then
  begin
    if Trim(edtPass.Text) = '' then
    begin
      edtPass.SetFocus;
      Exit;
    end;
    if not TAuthService.VerificarContrasena(UsuarioActual.Email, Trim(edtPass.Text)) then
    begin
      lblPass.Font.Color := CLR_DESTRUCTIVE;
      edtPass.Text := '';
      edtPass.SetFocus;
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

procedure TAppDialogo.CancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TDialogoFinalizar.OkClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TDialogoFinalizar.CancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

function MostrarInfoDialogo(const Titulo, Mensaje: string;
  ATipo: TDialogoTipo): Boolean;
var
  F: TAppDialogo;
begin
  F := TAppDialogo.CreateNew(nil);
  try
    F.Construir(Titulo, Mensaje, ATipo, False, False);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

function ConfirmarDialogo(const Titulo, Mensaje: string): Boolean;
var
  F: TAppDialogo;
begin
  F := TAppDialogo.CreateNew(nil);
  try
    F.Construir(Titulo, Mensaje, dtPregunta, True, False);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

function ConfirmarContrasena(const Titulo: string): Boolean;
var
  F: TAppDialogo;
begin
  F := TAppDialogo.CreateNew(nil);
  try
    F.Construir(Titulo, 'Para continuar ingrese su contrasena.', dtInfo, False, True);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

// Diálogo "Finalizar pesaje" con el mismo estilo uniforme.
function MostrarDialogoFinalizar(PesajeID, Bruto, Tara, Neto: Integer): Boolean;
var
  F: TDialogoFinalizar;
  pnlWrap, pnlDatos: TPanel;
  Lbl: TLabel;
  YPos, W: Integer;
begin
  Result := False;
  F := TDialogoFinalizar.CreateNew(nil);
  try
    F.Caption := '';
    F.Width := D_W;
    F.Height := 300;
    F.Position := poMainFormCenter;
    F.BorderStyle := bsDialog;
    F.Color := CLR_BG;
    F.Constraints.MinWidth := D_W;
    F.Constraints.MaxWidth := D_W;
    F.Constraints.MinHeight := 300;
    F.Constraints.MaxHeight := 300;

    pnlWrap := TPanel.Create(F);
    pnlWrap.Parent := F;
    pnlWrap.Align := alClient;
    pnlWrap.BevelOuter := bvNone;
    pnlWrap.Color := CLR_CARD;
    pnlWrap.BorderSpacing.Around := 14;

    Lbl := TLabel.Create(F);
    Lbl.Parent := pnlWrap;
    Lbl.SetBounds(6, 6, D_W - 40, 24);
    Lbl.Caption := 'Finalizar Pesaje #' + IntToStr(PesajeID);
    Lbl.Font.Size := 13;
    Lbl.Font.Style := [fsBold];
    Lbl.Font.Color := CLR_TEXT_HEADING;

    Lbl := TLabel.Create(F);
    Lbl.Parent := pnlWrap;
    Lbl.SetBounds(6, 34, D_W - 40, 16);
    Lbl.Caption := 'Verifique los pesos antes de finalizar';
    Lbl.Font.Size := 10;
    Lbl.Font.Color := CLR_TEXT_SLATE;

    pnlDatos := TPanel.Create(F);
    pnlDatos.Parent := pnlWrap;
    pnlDatos.SetBounds(6, 58, D_W - 40, 112);
    pnlDatos.BevelOuter := bvNone;
    pnlDatos.Color := CLR_SIDEBAR_ACTIVE;

    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(16, 14, 100, 18); Lbl.Caption := 'Peso Bruto';
    Lbl.Font.Size := 11; Lbl.Font.Color := CLR_TEXT_SLATE;
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(190, 14, pnlDatos.Width - 206, 18);
    Lbl.Caption := FormatFloat('#,##0', Bruto) + ' kg';
    Lbl.Font.Size := 12; Lbl.Font.Color := CLR_TEXT; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;

    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(16, 38, 100, 18); Lbl.Caption := 'Tara';
    Lbl.Font.Size := 11; Lbl.Font.Color := CLR_TEXT_SLATE;
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(190, 38, pnlDatos.Width - 206, 18);
    Lbl.Caption := FormatFloat('#,##0', Tara) + ' kg';
    Lbl.Font.Size := 12; Lbl.Font.Color := CLR_TEXT; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;

    with TPanel.Create(F) do
    begin
      Parent := pnlDatos;
      SetBounds(16, 66, pnlDatos.Width - 32, 1);
      BevelOuter := bvNone;
      Color := CLR_BORDER;
    end;

    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(16, 76, 100, 22); Lbl.Caption := 'Peso Neto';
    Lbl.Font.Size := 11; Lbl.Font.Color := CLR_TEXT_HEADING; Lbl.Font.Style := [fsBold];
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(190, 72, pnlDatos.Width - 206, 26);
    Lbl.Caption := FormatFloat('#,##0', Neto) + ' kg';
    Lbl.Font.Size := 14; Lbl.Font.Color := CLR_PRIMARY; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;

    YPos := 186;
    Lbl := TLabel.Create(F);
    Lbl.Parent := pnlWrap;
    Lbl.SetBounds(6, YPos, D_W - 40, 16);
    Lbl.Caption := 'Confirme la finalizacion del pesaje';
    Lbl.Font.Size := 10;
    Lbl.Font.Color := CLR_TEXT_SLATE;

    YPos := 214;
    W := D_W - 28;
    CrearBotonC(pnlWrap, YPos, W - 210, 96, 'CANCELAR', CLR_CARD, CLR_TEXT, @F.CancelClick);
    CrearBotonC(pnlWrap, YPos, W - 106, 96, 'FINALIZAR', CLR_PRIMARY, CLR_PRIMARY_FG, @F.OkClick);

    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

end.