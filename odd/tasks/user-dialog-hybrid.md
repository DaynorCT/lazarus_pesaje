# Hybrid User Create/Edit Dialog

**Goal:** Refactor the shared Usuarios create/edit dialog into a hybrid Lazarus UI: native controls and adaptive layout containers with selective project styling.

## Scope

- `src/forms/UsuariosFrame.pas`
- The same modal serves both creation (`ID = 0`) and editing existing users; preserve both behaviors.
- Do not change database operations, validation rules, user fields, or authentication semantics.

## Tasks

- [x] Replace fixed-position dialog layout and custom button panels with native Lazarus layout containers and standard controls while preserving styling and all save/cancel behavior.
- [x] Independently source-review field, callback, and persistence paths; record findings without expanding scope.
- [ ] Build and inspect the create/edit dialog at the target display scale; revise if runtime issues appear.

## Acceptance criteria

- Personal data and account data remain clearly grouped.
- The layout adapts to dialog width and display scaling instead of relying on fixed absolute field coordinates.
- Native text edits, role combo, and buttons remain usable; password masking and create/edit field behavior are preserved.
- Required-field and minimum-password validation remain unchanged; save and cancel callbacks retain their existing behavior.

## Evidence and status

- User authorized a hybrid redesign after asking whether the create-user dialog exists.
- `src/forms/UsuariosFrame.pas` now uses a resizable form, vertical scrollable field layout, native Lazarus edit/combo/button controls, and selective project styling. Create/edit, role prefill, password masking, save/cancel, and transaction paths were source-checked.
- Independent source review found no layout-specific blocker. It noted validation still happens after modal dismissal and email format is not checked; these behaviors pre-existed and remain unchanged to keep scope on layout.
- No build or runtime visual check was performed; inspect at the target display scale remains pending.
- Current branch: `feat/green-connect-button`.
- Engram mirror attempt failed because the Engram binary is unavailable in this environment.
- The separate finalization-dialog task remains pending the user's runtime visual check.
