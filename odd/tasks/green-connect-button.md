# Paint the Integrated Connection Button Green

## Goal
Make the integrated weighing screen's “Conectar” button visibly green across Lazarus widget sets by replacing its native button rendering with a project-consistent custom-painted clickable control.

## Scope
- Change only the connection button in `src/forms/PesajeIntegrado.lfm` and `src/forms/PesajeIntegrado.pas`.
- Preserve the `SwitchConectarClick` behavior, captions, layout bounds, and connection state transitions.
- Preserve unrelated user changes, including `src/forms/MainForm.lfm`.
- Do not commit or publish without the user's explicit instruction.

## Tasks
1. [x] Replace the native connection button with a custom-painted control, preserving interaction and state text.
2. [x] Build and structurally verify the change; note widget-set visual limitations if runtime inspection is unavailable.

## Verification
- `./compilar.sh mac` passed (`COMPILACION EXITOSA`); linker warned that some objects target macOS 11.0 while linking for 10.15.
- `git diff --check` passed.
- Runtime visual appearance and click behavior were not manually verified in a running GUI.

## Evidence
- Existing worktree contained a pre-existing user modification in `src/forms/MainForm.lfm`; it was left untouched.
- Feature branch: `feat/green-connect-button`.
- Commit identity: pending; do not commit without explicit user request.
