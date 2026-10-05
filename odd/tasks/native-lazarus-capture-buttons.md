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
3. [ ] Structurally verify the screen and build/visually verify when Lazarus tooling is available.

## Verification
- Capture/send conversion structural checks passed: controls are `TButton`s with default font/color styling, correct captions and handlers, initial disabled state, state updates, and responsive bounds.
- Independent structural verification passed: sync, gear, connection, capture/send, and the dynamically generated gear-menu actions are `TButton`s with native styling and preserved handlers/state changes. Background-click menu dismissal and non-action containers remain intact. `git diff --check` passed.
- Build/runtime verification remains unavailable: FPC is installed, but `lazbuild` and Lazarus are unavailable; no GUI behavior was exercised.
- Native assessment remains unassessable due untracked-file declaration handling. The reviewer capture transition did not produce a verdict; do not treat it as approval.

## Evidence
- Existing worktree has user edits. Preserve unrelated portions, particularly `pesaje.lpi` and `src/forms/MainForm.lfm`.
- Current feature branch: `feat/native-lazarus-capture-buttons`.
- Engram mirror unavailable: provider binary is not installed.
- Commit identity: pending; do not commit without explicit user request.
