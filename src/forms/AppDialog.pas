unit AppDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Theme;

type
  TDialogoTipo = (dtInfo, dtExito, dtError, dtPregunta);

function MostrarInfoDialogo(const Titulo, Mensaje: string;
  ATipo: TDialogoTipo = dtInfo; AExtraButtonSpacing: Integer = 0): Boolean;
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
      AConfirmar: Boolean; AConPass: Boolean; AExtraButtonSpacing: Integer);
  end;

  TDialogoFinalizar = class(TForm)
  private
    FPanelBotones: TPanel;
    FBtnCancelar, FBtnFinalizar: TButton;
    procedure PosicionarBotones(Sender: TObject);
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

procedure TAppDialogo.Construir(const Titulo, Mensaje: string;
  ATipo: TDialogoTipo; AConfirmar: Boolean; AConPass: Boolean;
  AExtraButtonSpacing: Integer);
var
  pnlTop, pnlSep: TPanel;
  lblTitulo, lblIcono, lblMsg: TLabel;
  pO, pI: TPanel;
  H, MsgH, BtnY, MsgW, MsgPrefW: Integer;
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
  lblMsg.AutoSize := False;
  lblMsg.Alignment := taLeftJustify;
  lblMsg.Layout := tlTop;
  lblMsg.SetBounds(58, 62, MsgW, 1);

  // Use the LCL label's wrapped preferred size, so sizing matches actual
  // widget-set font metrics instead of a separate manual line estimate.
  HandleNeeded;
  MsgPrefW := MsgW;
  MsgH := 0;
  lblMsg.GetPreferredSize(MsgPrefW, MsgH);
  // Add vertical slack for wrapped lines; some widget sets under-report the
  // preferred height by a few pixels and clip the final line otherwise.
  MsgH := MsgH + 18;
  if MsgH < 22 then MsgH := 22;
  lblMsg.Height := MsgH;

  BtnY := lblMsg.Top + lblMsg.Height + 12 + AExtraButtonSpacing;

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

  ClientHeight := H;
  Constraints.MinHeight := Height;
  Constraints.MaxHeight := Height;

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
  ATipo: TDialogoTipo; AExtraButtonSpacing: Integer): Boolean;
var
  F: TAppDialogo;
begin
  F := TAppDialogo.CreateNew(nil);
  try
    F.Construir(Titulo, Mensaje, ATipo, False, False, AExtraButtonSpacing);
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
    F.Construir(Titulo, Mensaje, dtPregunta, True, False, 0);
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
    F.Construir(Titulo, 'Para continuar ingrese su contrasena.', dtInfo, False, True, 0);
    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

procedure TDialogoFinalizar.PosicionarBotones(Sender: TObject);
const
  BUTTON_WIDTH = 110;
  BUTTON_GAP = 12;
var
  W, LeftPos, TopPos: Integer;
begin
  if (FPanelBotones = nil) or (FBtnCancelar = nil) or (FBtnFinalizar = nil) then Exit;
  W := FPanelBotones.ClientWidth;
  LeftPos := (W - (2 * BUTTON_WIDTH + BUTTON_GAP)) div 2;
  TopPos := (FPanelBotones.ClientHeight - BTN_H) div 2;
  FBtnCancelar.SetBounds(LeftPos, TopPos, BUTTON_WIDTH, BTN_H);
  FBtnFinalizar.SetBounds(LeftPos + BUTTON_WIDTH + BUTTON_GAP,
    TopPos, BUTTON_WIDTH, BTN_H);
end;

// Hybrid dialog: native Lazarus layout/buttons with the project's custom summary card.
function MostrarDialogoFinalizar(PesajeID, Bruto, Tara, Neto: Integer): Boolean;
var
  F: TDialogoFinalizar;
  pnlWrap, pnlHeader, pnlDatos, pnlConfirm, pnlButtons, Sep: TPanel;
  Lbl: TLabel;
  Btn: TButton;
begin
  Result := False;
  F := TDialogoFinalizar.CreateNew(nil);
  try
    F.Caption := '';
    F.Width := D_W;
    F.Height := 340;
    F.Position := poMainFormCenter;
    F.BorderStyle := bsSizeable;
    F.Color := CLR_BG;
    F.Constraints.MinWidth := D_W;
    F.Constraints.MinHeight := 340;

    pnlWrap := TPanel.Create(F);
    pnlWrap.Parent := F;
    pnlWrap.Align := alClient;
    pnlWrap.BevelOuter := bvNone;
    pnlWrap.Color := CLR_CARD;
    pnlWrap.BorderSpacing.Around := 14;

    pnlHeader := TPanel.Create(F);
    pnlHeader.Parent := pnlWrap;
    pnlHeader.Align := alTop;
    pnlHeader.Height := 58;
    pnlHeader.BorderSpacing.Bottom := 8;
    pnlHeader.BevelOuter := bvNone;
    pnlHeader.Color := CLR_CARD;

    Lbl := TLabel.Create(F);
    Lbl.Parent := pnlHeader;
    Lbl.Align := alTop;
    Lbl.Height := 30;
    Lbl.BorderSpacing.Left := 6;
    Lbl.Caption := 'Finalizar Pesaje #' + IntToStr(PesajeID);
    Lbl.Font.Size := 13;
    Lbl.Font.Style := [fsBold];
    Lbl.Font.Color := CLR_TEXT_HEADING;

    Lbl := TLabel.Create(F);
    Lbl.Parent := pnlHeader;
    Lbl.Align := alTop;
    Lbl.Height := 22;
    Lbl.BorderSpacing.Left := 6;
    Lbl.Caption := 'Verifique los pesos antes de finalizar';
    Lbl.Font.Size := 10;
    Lbl.Font.Color := CLR_TEXT_SLATE;

    pnlDatos := TPanel.Create(F);
    pnlDatos.Parent := pnlWrap;
    pnlDatos.Align := alTop;
    pnlDatos.Height := 112;
    pnlDatos.BorderSpacing.Bottom := 12;
    pnlDatos.BevelOuter := bvNone;
    pnlDatos.Color := CLR_SIDEBAR_ACTIVE;

    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(16, 14, 120, 18); Lbl.Caption := 'Peso Bruto';
    Lbl.Font.Size := 11; Lbl.Font.Color := CLR_TEXT_SLATE;
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(150, 14, D_W - 194, 18);
    Lbl.Anchors := [akTop, akLeft, akRight];
    Lbl.Caption := FormatFloat('#,##0', Bruto) + ' kg';
    Lbl.Font.Size := 12; Lbl.Font.Color := CLR_TEXT; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;

    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(16, 38, 120, 18); Lbl.Caption := 'Tara';
    Lbl.Font.Size := 11; Lbl.Font.Color := CLR_TEXT_SLATE;
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(150, 38, D_W - 194, 18);
    Lbl.Anchors := [akTop, akLeft, akRight];
    Lbl.Caption := FormatFloat('#,##0', Tara) + ' kg';
    Lbl.Font.Size := 12; Lbl.Font.Color := CLR_TEXT; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;

    Sep := TPanel.Create(F);
    Sep.Parent := pnlDatos;
    Sep.SetBounds(16, 66, D_W - 60, 1);
    Sep.Anchors := [akTop, akLeft, akRight];
    Sep.BevelOuter := bvNone;
    Sep.Color := CLR_BORDER;

    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(16, 76, 120, 22); Lbl.Caption := 'Peso Neto';
    Lbl.Font.Size := 11; Lbl.Font.Color := CLR_TEXT_HEADING; Lbl.Font.Style := [fsBold];
    Lbl := TLabel.Create(F); Lbl.Parent := pnlDatos;
    Lbl.SetBounds(150, 72, D_W - 194, 26);
    Lbl.Anchors := [akTop, akLeft, akRight];
    Lbl.Caption := FormatFloat('#,##0', Neto) + ' kg';
    Lbl.Font.Size := 14; Lbl.Font.Color := CLR_PRIMARY; Lbl.Font.Style := [fsBold];
    Lbl.Alignment := taRightJustify;

    pnlConfirm := TPanel.Create(F);
    pnlConfirm.Parent := pnlWrap;
    pnlConfirm.Align := alTop;
    pnlConfirm.Height := 34;
    pnlConfirm.BorderSpacing.Bottom := 8;
    pnlConfirm.BevelOuter := bvNone;
    pnlConfirm.Color := CLR_CARD;

    Lbl := TLabel.Create(F);
    Lbl.Parent := pnlConfirm;
    Lbl.Align := alClient;
    Lbl.BorderSpacing.Left := 6;
    Lbl.Layout := tlCenter;
    Lbl.Caption := 'Confirme la finalizacion del pesaje';
    Lbl.Font.Size := 10;
    Lbl.Font.Color := CLR_TEXT_SLATE;

    pnlButtons := TPanel.Create(F);
    pnlButtons.Parent := pnlWrap;
    pnlButtons.Align := alBottom;
    pnlButtons.Height := 44;
    pnlButtons.BevelOuter := bvNone;
    pnlButtons.Color := CLR_CARD;

    F.FPanelBotones := pnlButtons;
    Btn := TButton.Create(F);
    F.FBtnCancelar := Btn;
    Btn.Parent := pnlButtons;
    Btn.Caption := 'CANCELAR';
    Btn.Font.Size := 10;
    Btn.Font.Color := CLR_TEXT;
    Btn.Cancel := True;
    Btn.OnClick := @F.CancelClick;

    Btn := TButton.Create(F);
    F.FBtnFinalizar := Btn;
    Btn.Parent := pnlButtons;
    Btn.Caption := 'FINALIZAR';
    Btn.Font.Size := 10;
    Btn.Font.Style := [fsBold];
    Btn.Font.Color := CLR_PRIMARY;
    Btn.Default := True;
    Btn.OnClick := @F.OkClick;

    F.OnShow := @F.PosicionarBotones;
    F.OnResize := @F.PosicionarBotones;
    pnlButtons.OnResize := @F.PosicionarBotones;
    F.PosicionarBotones(nil);

    Result := F.ShowModal = mrOk;
  finally
    F.Free;
  end;
end;

end.