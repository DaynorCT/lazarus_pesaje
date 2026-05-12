unit Theme;

{$mode objfpc}{$H+}

interface

const
  // ============================================================
  // Sistema de Pesaje - Tema visual (replicado del sistema web)
  // Colores en formato Lazarus: $BBGGRR (invertido de #RRGGBB)
  // ============================================================

  // Fondo
  CLR_BG            = $F5F5F5;  // #F5F5F5 - page background
  CLR_CARD           = $FFFFFF;  // #FFFFFF - cards, surfaces
  CLR_WHITE          = $FFFFFF;

  // Sidebar (estilo web: blanco con borde)
  CLR_SIDEBAR_BG     = $FFFFFF;  // white
  CLR_SIDEBAR_ACTIVE = $F1F5F9;  // #F1F5F9 - slate-100 (active bg)
  CLR_SIDEBAR_HOVER  = $F8FAFC;  // #F8FAFC - slate-50 (hover bg)
  CLR_SIDEBAR_BORDER = $E2E8F0;  // #E2E8F0 - slate-200
  CLR_SIDEBAR_TEXT   = $334155;  // #334155 - slate-700
  CLR_SIDEBAR_ACTIVE_TEXT = $1C1C1C; // #1C1C1C - foreground (active text)

  // Topbar
  CLR_TOPBAR_BG      = $FFFFFF;
  CLR_TOPBAR_BORDER  = $E2E8F0;  // border-b border-slate-200

  // Primario
  CLR_PRIMARY        = $255EA6;  // #255EA6 - primary blue
  CLR_PRIMARY_LIGHT  = $4A7BC7;  // #4A7BC7
  CLR_PRIMARY_DARK   = $1A4280;  // #1A4280
  CLR_PRIMARY_FG     = $FFFFFF;  // foreground on primary

  // Secundario
  CLR_SECONDARY      = $555F71;  // #555F71
  CLR_SECONDARY_FG   = $FFFFFF;

  // Estados
  CLR_SUCCESS        = $2E7D32;  // #2E7D32 - success green
  CLR_SUCCESS_BG     = $EBF5EB;  // success/10
  CLR_DESTRUCTIVE    = $BA1B1B;  // #BA1B1B - destructive red
  CLR_DESTRUCTIVE_BG = $FDEDED;  // destructive/10
  CLR_WARNING        = $ED6C02;  // #ED6C02 - warning orange
  CLR_WARNING_BG     = $FFF3E0;  // warning/10
  CLR_INFO           = $0288D1;  // #0288D1 - info blue
  CLR_TEAL           = $30B082;  // #30B082 - teal (display peso)

  // Texto
  CLR_TEXT           = $1C1C1C;  // foreground
  CLR_TEXT_MUTED     = $71717A;  // #71717A - muted-foreground
  CLR_TEXT_HEADING   = $1E293B;  // #1E293B - slate-800
  CLR_TEXT_SLATE     = $64748B;  // #64748B - slate-500
  CLR_TEXT_SLATE_LIGHT = $94A3B8; // #94A3B8 - slate-400

  // Bordes
  CLR_BORDER         = $DEDEDE;  // #DEDEDE (~oklch 0.922)
  CLR_BORDER_LIGHT   = $EEEEEE;  // ~#E5E7EB - gray-200
  CLR_TABLE_HEADER   = $F1F5F9;  // #F1F5F9 - slate-100
  CLR_TABLE_ROW_HOVER = $F8FAFC; // #F8FAFC - slate-50

  // Login page specific
  CLR_LOGIN_BG       = $F5F5F5;  // bg-[#F5F5F5]
  CLR_LOGIN_CARD     = $FFFFFF;

implementation

end.
