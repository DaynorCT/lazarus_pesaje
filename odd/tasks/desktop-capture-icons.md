# Desktop Pesaje Capture Icons

**Goal:** Make the desktop `Cap. peso` and `Cap. tara` controls render the visible scale icon used by the integrated Pesaje screen.

## Scope

- `src/forms/PesajeFrame.pas`
- Preserve capture callbacks, disabled state, colors, rounded panels, and capture behavior.
- Use the existing Font Awesome `FA_SCALE` glyph with its established Unicode fallback.

## Tasks

- [x] Replace the Unicode-in-caption rendering for both capture controls with Font Awesome scale-icon rendering and readable separate text.
- [x] Source-review and build the desktop app.
- [ ] Inspect the icons at runtime on the target desktop display and confirm the appearance.

## Acceptance criteria

- `Cap. peso` and `Cap. tara` display the same scale icon strategy as the integrated Pesaje screen (`FA_SCALE`, fallback `⚖`).
- Their text remains in the regular UI font and centered with the icon.
- Existing click handlers, disabled-state appearance, rounded backgrounds, and colors remain intact.

## Evidence and status

- User requested using the visible system icon for the desktop capture controls after reporting the scale icon was not visible.
- `PesajeFrame.pas` now draws the `FA_SCALE` icon in the Font Awesome font when loaded and uses the Unicode fallback otherwise; button text remains in the regular UI font. Both controls retain their rounded backgrounds and click handlers.
- Independent source review passed and `./compilar.sh mac` completed successfully. It reported 2 warnings, 59 hints, and 4 notes; linker deployment-target warnings remain.
- No runtime visual verification was performed; confirm on the target desktop display.
- Engram mirror attempt failed because the Engram executable is unavailable in this environment.
