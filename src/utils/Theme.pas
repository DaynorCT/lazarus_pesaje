unit Theme;

{$mode objfpc}{$H+}

interface

const
  // ============================================================
  // Sistema de Pesaje - Tema visual (replicado del sistema web)
  // Colores en formato Lazarus: $BBGGRR (INVERTIDO de HTML #RRGGBB)
  // ============================================================

  // Fondo
  CLR_BG            = $F5F5F5;  // #F5F5F5
  CLR_CARD           = $FFFFFF;  // #FFFFFF
  CLR_WHITE          = $FFFFFF;

  // Sidebar
  CLR_SIDEBAR_BG     = $FFFFFF;
  CLR_SIDEBAR_ACTIVE = $F9F5F1;  // #F1F5F9 - slate-100
  CLR_SIDEBAR_HOVER  = $FCFAF8;  // #F8FAFC - slate-50
  CLR_SIDEBAR_BORDER = $F0E8E2;  // #E2E8F0 - slate-200
  CLR_SIDEBAR_TEXT   = $554133;  // #334155 - slate-700
  CLR_SIDEBAR_ACTIVE_TEXT = $1C1C1C; // #1C1C1C

  // Topbar
  CLR_TOPBAR_BG      = $FFFFFF;
  CLR_TOPBAR_BORDER  = $F0E8E2;  // #E2E8F0

  // Primario
  CLR_PRIMARY        = $A65E25;  // #1A4280 - azul corporativo sistema base
  CLR_PRIMARY_DARK   = $802E12;  // #122E80 - mas oscuro
  CLR_PRIMARY_FG     = $FFFFFF;

  // Secundario
  CLR_SECONDARY      = $715F55;  // #555F71
  CLR_SECONDARY_FG   = $FFFFFF;

  // Estados
  CLR_SUCCESS        = $327D2E;  // #2E7D32 - green
  CLR_SUCCESS_BG     = $EBF5EB;  // #EBF5EB
  CLR_DESTRUCTIVE    = $1B1BBA;  // #BA1B1B - red
  CLR_DESTRUCTIVE_BG = $EDEDFD;  // #FDEDED
  CLR_WARNING        = $026CED;  // #ED6C02 - orange
  CLR_WARNING_BG     = $E0F3FF;  // #FFF3E0
  CLR_INFO           = $D18802;  // #0288D1 - blue
  CLR_INFO_BG        = $FDF2E3;  // #E3F2FD - light blue bg
  CLR_TEAL           = $82B030;  // #30B082 - teal

  // Texto
  CLR_TEXT           = $1C1C1C;  // #1C1C1C
  CLR_TEXT_MUTED     = $7A7171;  // #71717A
  CLR_TEXT_HEADING   = $3B291E;  // #1E293B - slate-800
  CLR_TEXT_SLATE     = $8B7464;  // #64748B - slate-500
  CLR_TEXT_SLATE_LIGHT = $B8A394; // #94A3B8 - slate-400

  // Bordes
  CLR_BORDER         = $DEDEDE;  // #DEDEDE
  CLR_BORDER_LIGHT   = $EEEEEE;  // #E5E7EB
  CLR_TABLE_HEADER   = $F9F5F1;  // #F1F5F9 - slate-100
  CLR_TABLE_ROW_HOVER = $FCFAF8; // #F8FAFC - slate-50

  // Login (replicado del diseno web minimalista)
  CLR_LOGIN_BG         = $F0E8E2;  // #E2E8F0 - slate-200 (fondo pagina)
  CLR_LOGIN_CARD       = $FFFFFF;
  CLR_LOGIN_TITLE      = $554133;  // #334155 - slate-700 (titulos)
  CLR_LOGIN_LABEL      = $2A170F;  // #0F172A - slate-900 (labels de campos)
  CLR_LOGIN_BORDER     = $E1D5CB;  // #CBD5E1 - slate-300 (bordes, divisores)
  CLR_LOGIN_ICON_BG    = $F0E8E2;  // #E2E8F0 - slate-200 (fondo caja icono)
  CLR_LOGIN_ICON_FG    = $F0E8E2;  // #E2E8F0 - slate-200 (color icono)
  CLR_LOGIN_ERROR_BG   = $F2F2FE;  // #FEF2F2 - red-50
  CLR_LOGIN_ERROR_FG   = $2626DC;  // #DC2626 - red-600
  CLR_LOGIN_SALIR      = $8B7464;  // #64748B - slate-500 (texto "Salir")

  // Font Awesome 6 Free Solid — codigos Unicode (Private Use Area)
  // Los iconos son caracteres del U+F000..U+F7FF
  FA_HOME       = $F015;   // casa
  FA_USERS      = $F0C0;   // usuarios
  FA_BUILDING   = $F1AD;   // empresa
  FA_USER       = $F007;   // chofer/persona
  FA_INDUSTRY   = $F275;   // proveedores
  FA_SCALE      = $F24E;   // pesaje (balanza)
  FA_LIST       = $F0CA;   // catalogo
  FA_CHART_BAR  = $F080;   // reportes
  FA_COG        = $F013;   // configuracion
  FA_TRUCK      = $F0D1;   // vehiculos
  FA_BOX        = $F466;   // productos
  FA_MAP_PIN    = $F3C5;   // origenes
  FA_BULLSEYE   = $F140;   // destinos
  FA_FILE       = $F15C;   // boleta/documento
  FA_EDIT       = $F044;   // editar (lapiz)
  FA_CHECK      = $F058;   // activo (check-circle)
  FA_TIMES      = $F057;   // inactivo (times-circle)

  // Nombre de la fuente — debe coincidir con el nombre interno del TTF
  FA_FONT_NAME  = 'Font Awesome 6 Free Solid';

var
  FA_FONT_LOADED: Boolean = False;   // se activa al registrar la fuente

function FAChar(ACodeWide: Word): string;
function FAIconoStr(FACode: Word; const Fallback: string): string; inline;
function FAFuente: string; inline;

implementation

function FAChar(ACodeWide: Word): string;
begin
  if not FA_FONT_LOADED then
    Exit('');
  Result := WideChar(ACodeWide);
end;

function FAIconoStr(FACode: Word; const Fallback: string): string;
begin
  if FA_FONT_LOADED then
    Result := WideChar(FACode)
  else
    Result := Fallback;
end;

function FAFuente: string;
begin
  if FA_FONT_LOADED then
    Result := FA_FONT_NAME
  else
    Result := 'default';
end;

end.
