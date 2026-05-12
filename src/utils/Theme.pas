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
  CLR_PRIMARY        = $80421A;  // #1A4280 - azul corporativo sistema base
  CLR_PRIMARY_DARK   = $802E12;  // #122E80 - más oscuro
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

  // Login
  CLR_LOGIN_BG       = $F5F5F5;
  CLR_LOGIN_CARD     = $FFFFFF;

implementation

end.
