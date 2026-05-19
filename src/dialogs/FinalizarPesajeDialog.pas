unit FinalizarPesajeDialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  Theme;

type
  TFinalizarPesajeDialog = class(TForm)
  private
    lblBruto, lblTara, lblNeto: TLabel;
    btnCancelar, btnFinalizar: TPanel;
    lblCancelar, lblFinalizar: TLabel;
    FConfirmed: Boolean;
    procedure btnCancelarClick(Sender: TObject);
    procedure btnFinalizarClick(Sender: TObject);
    procedure PanelMouseEnter(Sender: TObject);
    procedure PanelMouseLeave(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent; PesajeID: Integer;
      Bruto, Tara, Neto: Integer); reintroduce;
    property Confirmed: Boolean read FConfirmed;
  end;

function MostrarFinalizarPesaje(PesajeID, Bruto, Tara, Neto: Integer): Boolean;

implementation

function MostrarFinalizarPesaje(PesajeID, Bruto, Tara, Neto: Integer): Boolean;
begin
  with TFinalizarPesajeDialog.Create(nil, PesajeID, Bruto, Tara, Neto) do
  try
    ShowModal;
    Result := Confirmed;
  finally
    Free;
  end;
end;

constructor TFinalizarPesajeDialog.Create(TheOwner: TComponent;
  PesajeID: Integer; Bruto, Tara, Neto: Integer);
var
  pnlCard, pnlDatos, pnlActions: TPanel;
  lblTitle, lblSubtitle: TLabel;
  Lbl: TLabel;
  W, Y: Integer;
const
  W_DIALOG = 420;
  H_DIALOG = 340;
  PAD = 24;
  GAP = 12;
begin
  inherited CreateNew(TheOwner);
  Width := W_DIALOG;
  Height := H_DIALOG;
  BorderStyle := bsDialog;
  Position := poMainFormCenter;
  Color := CLR_BG;
  Font.Name := 'SF Pro';
  Font.Size := 11;

  // Card panel (white)
  pnlCard := TPanel.Create(Self);
  pnlCard.Parent := Self;
  pnlCard.Align := alClient;
  pnlCard.BevelOuter := bvNone;
  pnlCard.Color := CLR_CARD;
  pnlCard.BorderSpacing.Around := 0;

  // Title
  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlCard;
  lblTitle.SetBounds(PAD, PAD, W_DIALOG - PAD * 2, 28);
  lblTitle.Caption := 'Finalizar Pesaje #' + IntToStr(PesajeID);
  lblTitle.Font.Size := 15;
  lblTitle.Font.Color := CLR_TEXT_HEADING;
  lblTitle.Font.Style := [fsBold];

  // Subtitle
  Y := PAD + 32;
  lblSubtitle := TLabel.Create(Self);
  lblSubtitle.Parent := pnlCard;
  lblSubtitle.SetBounds(PAD, Y, W_DIALOG - PAD * 2, 18);
  lblSubtitle.Caption := 'Verifique los pesos antes de finalizar';
  lblSubtitle.Font.Size := 11;
  lblSubtitle.Font.Color := CLR_TEXT_SLATE;

  // Datos panel
  Y := PAD + 58;
  pnlDatos := TPanel.Create(Self);
  pnlDatos.Parent := pnlCard;
  pnlDatos.SetBounds(PAD, Y, W_DIALOG - PAD * 2, 112);
  pnlDatos.BevelOuter := bvNone;
  pnlDatos.Color := CLR_SIDEBAR_ACTIVE;
  pnlDatos.BorderSpacing.Around := 0;

  // Bruto
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlDatos;
  Lbl.SetBounds(16, 14, 100, 18);
  Lbl.Caption := 'Peso Bruto';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  lblBruto := TLabel.Create(Self);
  lblBruto.Parent := pnlDatos;
  lblBruto.SetBounds(W_DIALOG - PAD * 2 - 50 - 120, 14, 120, 18);
  lblBruto.Caption := IntToStr(Bruto) + ' kg';
  lblBruto.Font.Size := 12;
  lblBruto.Font.Color := CLR_TEXT;
  lblBruto.Font.Style := [fsBold];
  lblBruto.Alignment := taRightJustify;

  // Tara
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlDatos;
  Lbl.SetBounds(16, 38, 100, 18);
  Lbl.Caption := 'Tara';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;
  lblTara := TLabel.Create(Self);
  lblTara.Parent := pnlDatos;
  lblTara.SetBounds(W_DIALOG - PAD * 2 - 50 - 120, 38, 120, 18);
  lblTara.Caption := IntToStr(Tara) + ' kg';
  lblTara.Font.Size := 12;
  lblTara.Font.Color := CLR_TEXT;
  lblTara.Font.Style := [fsBold];
  lblTara.Alignment := taRightJustify;

  // Divider
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlDatos;
  Lbl.SetBounds(16, 62, W_DIALOG - PAD * 2 - 32, 1);
  Lbl.Caption := '';
  Lbl.AutoSize := False;
  Lbl.Color := CLR_BORDER;
  Lbl.Transparent := False;

  // Neto
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlDatos;
  Lbl.SetBounds(16, 72, 100, 22);
  Lbl.Caption := 'Peso Neto';
  Lbl.Font.Size := 12;
  Lbl.Font.Color := CLR_TEXT_HEADING;
  Lbl.Font.Style := [fsBold];
  lblNeto := TLabel.Create(Self);
  lblNeto.Parent := pnlDatos;
  lblNeto.SetBounds(W_DIALOG - PAD * 2 - 50 - 120, 72, 120, 22);
  lblNeto.Caption := IntToStr(Neto) + ' kg';
  lblNeto.Font.Size := 16;
  lblNeto.Font.Color := CLR_PRIMARY;
  lblNeto.Font.Style := [fsBold];
  lblNeto.Alignment := taRightJustify;

  // Confirm message
  Y := PAD + 178;
  Lbl := TLabel.Create(Self);
  Lbl.Parent := pnlCard;
  Lbl.SetBounds(PAD, Y, W_DIALOG - PAD * 2, 18);
  Lbl.Caption := 'Confirme la finalizacion del pesaje';
  Lbl.Font.Size := 11;
  Lbl.Font.Color := CLR_TEXT_SLATE;

  // Actions
  Y := H_DIALOG - 60;
  W := W_DIALOG - PAD * 2;

  btnCancelar := TPanel.Create(Self);
  btnCancelar.Parent := pnlCard;
  btnCancelar.SetBounds(W - 210, Y, 95, 36);
  btnCancelar.Color := CLR_CARD;
  btnCancelar.BevelOuter := bvNone;
  btnCancelar.BorderStyle := bsSingle;
  btnCancelar.BorderWidth := 1;
  btnCancelar.Cursor := crHandPoint;
  btnCancelar.OnClick := @btnCancelarClick;
  btnCancelar.OnMouseEnter := @PanelMouseEnter;
  btnCancelar.OnMouseLeave := @PanelMouseLeave;

  lblCancelar := TLabel.Create(Self);
  lblCancelar.Parent := btnCancelar;
  lblCancelar.Align := alClient;
  lblCancelar.Alignment := taCenter;
  lblCancelar.Layout := tlCenter;
  lblCancelar.Caption := 'Cancelar';
  lblCancelar.Font.Size := 11;
  lblCancelar.Font.Color := CLR_TEXT;
  lblCancelar.Font.Style := [];

  btnFinalizar := TPanel.Create(Self);
  btnFinalizar.Parent := pnlCard;
  btnFinalizar.SetBounds(W - 105, Y, 100, 36);
  btnFinalizar.Color := CLR_PRIMARY;
  btnFinalizar.BevelOuter := bvNone;
  btnFinalizar.Cursor := crHandPoint;
  btnFinalizar.OnClick := @btnFinalizarClick;

  lblFinalizar := TLabel.Create(Self);
  lblFinalizar.Parent := btnFinalizar;
  lblFinalizar.Align := alClient;
  lblFinalizar.Alignment := taCenter;
  lblFinalizar.Layout := tlCenter;
  lblFinalizar.Caption := 'Finalizar';
  lblFinalizar.Font.Size := 11;
  lblFinalizar.Font.Color := CLR_PRIMARY_FG;
  lblFinalizar.Font.Style := [fsBold];
end;

procedure TFinalizarPesajeDialog.btnCancelarClick(Sender: TObject);
begin
  FConfirmed := False;
  ModalResult := mrCancel;
end;

procedure TFinalizarPesajeDialog.btnFinalizarClick(Sender: TObject);
begin
  FConfirmed := True;
  ModalResult := mrOk;
end;

procedure TFinalizarPesajeDialog.PanelMouseEnter(Sender: TObject);
begin
  if Sender = btnCancelar then
    btnCancelar.Color := CLR_SIDEBAR_ACTIVE;
end;

procedure TFinalizarPesajeDialog.PanelMouseLeave(Sender: TObject);
begin
  if Sender = btnCancelar then
    btnCancelar.Color := CLR_CARD;
end;

end.
