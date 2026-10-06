# Apply Theme Colors to Integrated Action Buttons

## Goal
Make the integrated weighing screen's “Conectar” button reliably green, “Capturar peso” use `CLR_INFO`, and “Enviar a la web” use `CLR_PRIMARY`, independent of native button background rendering.

## Scope
- Change only these action controls in `src/forms/PesajeIntegrado.lfm` and `src/forms/PesajeIntegrado.pas`.
- Preserve handlers, captions, enabled/disabled state, layout bounds, and existing behavior.
- Preserve unrelated user changes, including `src/forms/MainForm.lfm`.
- Do not commit or publish without the user's explicit instruction.

## Tasks
1. [x] Replace the native connection button with a custom-painted control, preserving interaction and state text.
2. [x] Build and structurally verify the connection control.
3. [x] Replace the native capture button with a `CLR_INFO` custom-painted control, preserving disabled state and behavior.
4. [x] Build and structurally verify the connection and capture controls.
5. [x] Replace the native “Enviar a la web” button with a `CLR_PRIMARY` custom-painted control, preserving its initial disabled state and behavior.
6. [x] Build and structurally verify all three themed controls.

## Verification
- `./compilar.sh mac` passed (`COMPILACION EXITOSA`); linker warned that existing objects target macOS 11.0 while linking for 10.15, and compiler emitted hints.
- `git diff --check` passed.
- LFM click/paint handlers, initial disabled state, and runtime enablement were structurally verified.
- Runtime visual appearance and click behavior have not been manually verified in a running GUI.

## Evidence
- Existing worktree contained a pre-existing user modification in `src/forms/MainForm.lfm`; it was left untouched.
- Feature branch: `feat/green-connect-button`.
- Commit identity: pending; do not commit without explicit user request.
