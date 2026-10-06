# Prevent Clipped Text in the Custom Connect Dialog

## Goal
Keep the app's custom themed dialog while using native Lazarus/LCL label word-wrap and client-area sizing so longer connection messages remain fully visible across widget sets.

## Scope
- Modify only `src/forms/AppDialog.pas`.
- Preserve dialog titles, colors, icons, buttons, modal results, password flow, and connection messages.
- Replace manual line-count estimation with the label's native LCL wrapped preferred height, and size the form from its client area.
- Do not commit or publish without explicit user instruction.

## Tasks
1. [x] Use LCL `TLabel` word-wrap sizing as the source of truth for message height and calculate dialog layout from actual label dimensions/client height.
2. [x] Build and structurally verify standard info, confirmation, and password dialog layouts; document any unavailable visual check.

## Verification
- `./compilar.sh mac` passed (`COMPILACION EXITOSA`; 505 lines compiled, 15 hints); linker warned that objects target macOS 11.0 while linking for 10.15.
- `git diff --check` passed.
- Source inspection confirmed wrapped LCL preferred sizing at fixed label width, downstream button position derived from actual label bounds, and form client-height sizing; info, confirmation, and password paths remain present.
- Runtime visual appearance has not been checked in a running GUI.

## Evidence
- The connect handler calls `MostrarInfoDialogo` for missing balanza configuration or serial failure (`src/forms/PesajeIntegrado.pas:578,611`).
- The dialog now uses `TLabel.WordWrap` plus LCL `GetPreferredSize` instead of the `AlturaMensaje` heuristic; it sizes `ClientHeight` from content layout.
- Feature branch: `feat/green-connect-button`.
- Commit identity: pending; do not commit without explicit user request.
