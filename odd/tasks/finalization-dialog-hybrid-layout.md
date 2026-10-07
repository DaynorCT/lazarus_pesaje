# Hybrid Finalization Dialog Layout

**Goal:** Rebuild the Pesaje finalization dialog as a hybrid Lazarus UI: native controls and responsive layout containers, with the project's custom color/style treatment, preserving the current information and actions.

## Tasks

- [x] Replace fixed-position summary content and custom button panels with native Lazarus layout containers and standard buttons, preserving button callbacks and visual hierarchy.
- [ ] Build and inspect the dialog visually at the target display scale; revise if clipping or spacing issues remain.

## Acceptance criteria

- Cancel and Finalizar are equally sized, aligned together below the confirmation text, and stay within the dialog at different widths/scales.
- Weight details remain legible and grouped in the custom-styled summary card.
- Native Lazarus controls/layout drive sizing; custom styling remains selective.
- Both buttons retain their original modal results and actions.

## Evidence

- User authorized an experimental hybrid redesign after the prior dialog still showed button clipping.
- `src/forms/AppDialog.pas` now uses aligned Lazarus panels, a custom weight-summary card, and native `TButton` controls. The button group re-centers using footer client width on show/resize.
- Read-only source review confirmed native button callbacks and footer recentering; no blocking issue found. Width is constrained to a safe minimum, while runtime/build behavior remains unverified.
- Current branch: `feat/green-connect-button`.
- Engram task mirror attempt failed because the Engram binary is unavailable in this environment.
