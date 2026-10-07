# Hybrid Finalization Dialog Layout

**Goal:** Rebuild the Pesaje finalization dialog as a hybrid Lazarus UI: native controls and responsive layout containers, with the project's custom color/style treatment, preserving the current information and actions.

## Tasks

- [x] Use native Lazarus layout containers for the summary and custom panel-and-label buttons matching the Usuarios dialog, preserving button callbacks and visual hierarchy.
- [x] Correct section order and make gross/tare/net value labels fit the actual summary panel at runtime scale.
- [x] Build and source-review the corrected dialog.
- [ ] Inspect the dialog visually at the target display scale; revise if clipping or spacing issues remain.

## Acceptance criteria

- Cancel and Finalizar are equally sized, aligned together below the confirmation text, and stay within the dialog at different widths/scales.
- The title, weight summary, and confirmation text appear in the intended top-to-bottom order.
- Gross, tare, and net captions and values remain visible in the custom-styled summary card at the target scale.
- Native Lazarus controls/layout drive sizing; custom styling remains selective.
- Both buttons retain their original modal results and actions.

## Evidence

- User authorized an experimental hybrid redesign after the prior dialog still showed button clipping.
- `src/forms/AppDialog.pas` uses aligned Lazarus panels and a custom weight-summary card. The Cancelar/Finalizar controls now use rounded panel-and-label styling matching Usuarios and re-center on show/resize.
- The user-provided screenshot showed the aligned top sections reversed and no weight values. `src/forms/AppDialog.pas` now positions header, weight summary, confirmation, and buttons explicitly; value labels and separator size from the live summary-panel client width on resize/show.
- The first attempted child-order API did not compile; it was replaced with explicit bounds. `./compilar.sh mac` now passes (16 hints; linker deployment-target warnings remain). Source review confirms Bruto/Tara/Neto captions, `kg`, button modal results, and Enter/Esc callbacks are preserved.
- Native review for this candidate was approved and acknowledged; one non-blocking reliability warning remains at `src/forms/AppDialog.pas:365–367`. Review authority is consumed for this candidate; delivery remains under normal repository policy.
- Runtime visual confirmation remains pending.
- Current branch: `feat/green-connect-button`.
- Engram task mirror attempt failed because the Engram binary is unavailable in this environment.
