# Apply Theme Colors and Icons to Weighing Controls

## Goal
Render the integrated weighing controls with their selected theme colors; show the gear as only a success-colored Font Awesome icon, without a colored button surface or outline.

## Scope
- Change only the integrated controls in `src/forms/PesajeIntegrado.lfm` and `src/forms/PesajeIntegrado.pas`.
- Preserve handlers, enabled/disabled state, layout bounds, and existing behavior.
- The gear menu options remain unchanged.
- Preserve unrelated user changes, including `pesaje.lpi` and `src/forms/MainForm.lfm`.
- Do not commit or publish without the user's explicit instruction.

## Tasks
1. [x] Custom-paint the connection control with `CLR_SUCCESS`, preserving interaction and state text.
2. [x] Build and structurally verify the connection control.
3. [x] Custom-paint the capture control with `CLR_INFO`, preserving disabled state and behavior.
4. [x] Build and structurally verify the connection and capture controls.
5. [x] Custom-paint the send-to-web control with `CLR_PRIMARY`, preserving disabled state and behavior.
6. [x] Build and structurally verify the three action controls.
7. [x] Custom-paint only the gear button with `CLR_SUCCESS`, preserving its click behavior and menu.
8. [x] Build and structurally verify all four controls.
9. [x] Replace the gear button's “Menu” text with `FA_COG`, using the bundled font and a Unicode gear fallback.
10. [x] Build and verify the icon rendering configuration.
11. [x] Remove the gear button's colored surface and outline; render only the `FA_COG` icon in `CLR_SUCCESS`.
12. [x] Build and verify the icon-only control.

## Verification
- `./compilar.sh mac` passed (`COMPILACION EXITOSA`, 870 lines compiled, 26 hints); existing objects warned about macOS 11.0 vs 10.15.
- `git diff --check` passed.
- Source wiring and preserved gear menu were structurally verified; only gear painter changes visuals to transparent/no border with success-colored glyph.
- Runtime visual appearance and interaction have not been manually verified in a running GUI.

## Evidence
- Existing worktree contained pre-existing changes in `pesaje.lpi` and `src/forms/MainForm.lfm`; preserve them.
- Feature branch: `feat/green-connect-button`.
- Commit identity: pending; do not commit without explicit user request.
