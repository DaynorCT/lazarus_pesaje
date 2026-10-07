# Hybrid Finalization Dialog Layout

**Goal:** Rebuild the Pesaje finalization dialog as a hybrid Lazarus UI: native controls and responsive layout containers, with the project's custom color/style treatment, preserving the current information and actions.

## Tasks

- [x] Use native Lazarus layout containers for the summary and custom panel-and-label buttons matching the Usuarios dialog, preserving button callbacks and visual hierarchy.
- [ ] Build and inspect the dialog visually at the target display scale; revise if clipping or spacing issues remain.

## Acceptance criteria

- Cancel and Finalizar are equally sized, aligned together below the confirmation text, and stay within the dialog at different widths/scales.
- Weight details remain legible and grouped in the custom-styled summary card.
- Native Lazarus controls/layout drive sizing; custom styling remains selective.
- Both buttons retain their original modal results and actions.

## Evidence

- User authorized an experimental hybrid redesign after the prior dialog still showed button clipping.
- `src/forms/AppDialog.pas` uses aligned Lazarus panels and a custom weight-summary card. The Cancelar/Finalizar controls now use rounded panel-and-label styling matching Usuarios and re-center on show/resize.
- `./compilar.sh mac` passed after fixing the panel paint callback to use a method. Source review confirmed modal results remain `mrCancel`/`mrOk` and Esc/Enter still invoke Cancelar/Finalizar. Runtime visual inspection remains pending.
- Current branch: `feat/green-connect-button`.
- Engram task mirror attempt failed because the Engram binary is unavailable in this environment.
