# Use Default Lazarus Buttons Across the Integrated Screen

## Goal
Remove custom-painted button-like controls from the integrated weighing screen and use standard Lazarus `TButton` controls with their native default appearance.

## Scope
- Replace the custom capture/send controls, synchronization button, gear button, connection switch, and clickable gear-menu entries with standard `TButton` controls.
- Preserve every operation, caption/meaning, enablement state, and layout where feasible; adapt the connection switch to clear native button text indicating its current action/state.
- Remove custom button/label paint and font/color styling for these actions.
- Preserve unrelated UI, service behavior, panels, read-only labels, and the background-click behavior that dismisses the gear menu.
- Do not edit unrelated `pesaje.lpi` or `src/forms/MainForm.lfm` changes.

## Tasks
1. [x] Convert capture and send controls to default `TButton`s while preserving handlers, disabled states, and layout.
2. [x] Convert all remaining visible clickable actions (sync, gear, connection, and gear-menu entries) to default `TButton`s and preserve their operations.
3. [x] Set a readable dark caption color on native buttons to address invisible text on macOS while retaining native button shapes.
4. [ ] Structurally verify and build; test caption visibility on macOS and Windows when available.

## Verification
- Capture/send conversion structural checks passed: controls are `TButton`s with default font/color styling, correct captions and handlers, initial disabled state, state updates, and responsive bounds.
- Independent structural verification passed: sync, gear, connection, capture/send, and the dynamically generated gear-menu actions are `TButton`s with preserved handlers/state changes. Background-click menu dismissal and non-action containers remain intact. `git diff --check` passed.
- User reports on macOS that all button text is invisible while Windows displays it. Applied explicit `CLR_TEXT` with parent font inheritance disabled on all static buttons and dynamic gear-menu buttons, leaving native backgrounds/borders/shapes intact.
- Independent structural verification and `git diff --check` passed. Documented macOS build `./compilar.sh` succeeded (exit 0; executable `pesaje` generated). Linker warned that existing objects target macOS 11.0 while linking for 10.15; 11 FPC hints. Visual macOS and Windows runtime behavior remain unconfirmed.
- Native reviewer capture was rejected for the current slot as missing/stale binding; no verdict was obtained.

## Evidence
- Existing worktree has user edits. Preserve unrelated portions, particularly `pesaje.lpi` and `src/forms/MainForm.lfm`.
- Current feature branch: `feat/native-lazarus-capture-buttons`.
- Engram mirror unavailable: provider binary is not installed.
- Commit identity: pending; do not commit without explicit user request.
