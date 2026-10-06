# Apply Theme Colors to Integrated Action Buttons

## Goal
Make the integrated weighing screen's “Conectar” button reliably green and the “Capturar peso” button use `CLR_INFO`, independent of native button background rendering.

## Scope
- Change only the connection and capture controls in `src/forms/PesajeIntegrado.lfm` and `src/forms/PesajeIntegrado.pas`.
- Preserve handlers, captions, enabled/disabled state, layout bounds, and existing connection/capture behavior.
- Preserve unrelated user changes, including `src/forms/MainForm.lfm`.
- Do not commit or publish without the user's explicit instruction.

## Tasks
1. [x] Replace the native connection button with a custom-painted control, preserving interaction and state text.
2. [x] Build and structurally verify the connection control; note widget-set visual limitations if runtime inspection is unavailable.
3. [ ] Replace the native capture button rendering with a `CLR_INFO` custom-painted control, preserving disabled state and behavior.
4. [ ] Build and structurally verify both themed controls; note widget-set visual limitations if runtime inspection is unavailable.

## Verification
- Connection control: `./compilar.sh mac` passed (`COMPILACION EXITOSA`); linker warned that some objects target macOS 11.0 while linking for 10.15. `git diff --check` passed.
- Capture button color change and final combined checks are pending.
- Runtime visual appearance and click behavior were not manually verified in a running GUI.

## Evidence
- Existing worktree contained a pre-existing user modification in `src/forms/MainForm.lfm`; it was left untouched.
- Feature branch: `feat/green-connect-button`.
- Commit identity: pending; do not commit without explicit user request.
