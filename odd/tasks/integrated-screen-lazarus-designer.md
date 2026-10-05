# Integrated Weighing Screen in Lazarus Designer

## Goal
Move the integrated weigh/capture/send screen from runtime-created Pascal controls into Lazarus visual designer resources (`.lfm`), preserving its existing appearance and behavior.

## Scope
- Convert `TfrmPesajeIntegrado` main visual tree to designer-owned LCL controls.
- Keep serial connection/read, test-mode fallback, capture validation, sync status/send, modal results, close handling, and gear-menu actions.
- Preserve existing AppDialog and service behavior; do not redesign login or the desktop system.
- Preserve the user-modified `src/forms/MainForm.lfm` without editing it.

## Tasks
1. [x] Move the integrated form's static UI into `src/forms/PesajeIntegrado.lfm` and adapt `PesajeIntegrado.pas` to resource-backed construction without duplicate control creation.
2. [x] Build and structurally review the conversion; record warnings and manual runtime checks still needed.

## Decisions
- Keep the current integrated screen's visual arrangement; change its authoring method to the Lazarus visual designer rather than introducing a new visual redesign.
- Runtime behavior remains in Pascal and existing services.

## Verification
- No deterministic UI automation was identified. Full `lazbuild --build-all pesaje.lpi` passed (exit 0; 13 warnings, 196 hints, 13 notes). Linker warnings mention objects built for macOS 11.0 linked for 10.15.
- Manual checks remain for visual designer preview and runtime resize, connect/disconnect, simulated mode, capture, web send, synchronization, gear menu, and modal-result transitions.

## Evidence
- Current branch: `feat/integrated-screen-lfm` (created from `main`).
- Pre-existing user change: `src/forms/MainForm.lfm`; do not modify.
- `TimerEstado.Enabled = True` is now explicit in the LFM to preserve periodic sync-status updates; `TimerLectura` remains disabled until connection.
- Pre-existing `src/forms/MainForm.lfm` modification was left unchanged.
- Engram mirror: unavailable (Engram binary missing).
- Commit identity: pending; no commit requested.
