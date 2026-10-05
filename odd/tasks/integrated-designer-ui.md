# Integrated designer UI

## Objective
Convert the entire integrated capture/send screen to a Lazarus designer-backed form using standard LCL components, preserving current behavior and leaving autonomous desktop mode unchanged.

## Authorization and scope
User authorized a full-screen visual trial. Allowed source surfaces: `src/forms/PesajeIntegrado.pas`, new `src/forms/PesajeIntegrado.lfm`. UI copy remains Spanish following project convention. No service, database, authentication, autonomous-mode, hardware behavior, deployment artifact or installer changes. No installs or production application/data operations. Commits, push and PR creation are not explicitly authorized; no commits will be made under the safety rule.

## Route and forecast
One delegated writer: required by two non-trivial files and unfamiliar resource migration. Independent delegated verification for resource/build/behavior checks. Estimated 350–650 authored diff lines, possibly more for complete LFM serialization; this is one coherent form migration, not a reason to omit controls or tests. Delivery strategy: ask-on-risk; delivery/PR is not requested, any oversized delivery choice remains pending before a future authorized commit. Branch: `feat/integrated-designer-ui`. Mirror pending: Engram is unavailable (binary missing).

## Tasks
- [ ] T1 — Convert all integrated visual controls and events to a streamed `.lfm` resource. Status: implemented, pending compilation/visual acceptance (not checked off). Preserve modal results, password-protected desktop switch, scale settings, disconnect, simulated fallback, capture/send, sync status and timers. Remove runtime visual construction/owner-drawn interaction. Keep behavior handlers and native component state updates. Route: gentle-ai-worker. Commit: not authorized.
- [ ] T2 — Independently verify component/event consistency, behavior preservation, compilation when tooling permits, and record unavailable visual/runtime checks. Status: blocked/in_progress. Structural and native review checks passed; compile and visual checks pending. Route: gentle-ai-verify. Commit: not authorized.

## Acceptance criteria
- The integrated form opens in Lazarus Form Designer with editable standard controls and menus.
- No persistent integrated-screen visual widgets are constructed manually at runtime.
- Existing serial parsing, sync contracts, capture/send validation and modal return semantics remain unchanged.
- Capture/send enabling and connection/status text still reflect current state.
- Resizing and keyboard access remain usable; no changes to autonomous mode.
- Build/functional results are observed or explicitly marked unavailable, never inferred from static checks.

## Verification plan
No existing deterministic UI test runner was found. Behavior-preserving form/resource migration has no meaningful RED without a runnable harness; perform structural event/resource checks and an isolated Lazarus build if tools permit. A full visual test (resize, keyboard, connect, capture, send, menu, logout) needs a disposable data environment; never launch against live business data. Verifier may compile a copy outside the repository, without installs or dependency downloads. `git diff --check` required. Native RDD enabled: inspect candidate after normalized source changes, respecting candidate consent and provider routes. RDD does not replace functional checks.

## Evidence
- Before changes: clean `main`; user-owned RDD switch reads on.
- Explorer: form currently uses `CreateNew`, has no `.lfm`, and creates UI at runtime; modal results are owned by `pesaje.lpr`.
- Writer implemented `PesajeIntegrado.pas` and new `.lfm`; tracked Pascal diff: 111 additions / 804 deletions, plus new resource lines. Larger than forecast because all hand-drawn UI was removed; one coherent migration, no delivery requested.
- Writer `git diff --check`: passed. Structural checks: 11 unique resource event handlers declared, top-level fields/types match, no runtime screen visual construction remains.
- Writer initially found FPC only on PATH. Independent verifier located installed lazbuild and corrected migration defects via writer: missing constructor declaration and native connect/disconnect captions.
- Independent resource scan: 24 component objects with matching fields/types and 11 declared event bindings; `git diff --check` passed, including parent spot check.
- Isolated candidate and unchanged HEAD builds both failed before source compilation with `Broken dependency: laz_synapse` (exit 3). Bounded retry linked a temp copy of existing Synapse, then timed out after 300 seconds building FCL; candidate source/resource compilation not reached.
- Verification incident: even with temp --pcp, Lazarus attempted an installed-package output path outside temp. Verifier stopped; checked no recently modified files in that output directory and no remaining lazbuild/fpc processes. No cleanup or toolchain setup performed. No app launched or business data accessed.
- Native review approved with one informational advisory R3-001 at `src/forms/PesajeIntegrado.pas:212`; no correction route. Exact acknowledgement completed; authority burned for review-9716b183a96f841c, candidate sha256:9d4e5e2c4298f5bdcaa8f87d1374ed5e5a1e7ba6400be1c58fe95e96381c0af0. This is code-review evidence only, not compilation or UI proof.
- User reported a destructor compile error. Inline bounded fix added public `destructor Destroy; override;` and nil guards for both timers (`PesajeIntegrado.pas:51,98-101`). Deterministic source RED failed missing destructor declaration; GREEN passed for all 17 implementation declarations, unique destructor and nil guards. Independent and parent diff checks passed. Full compilation still pending; user changes to `pesaje.lpi` preserved.
- New native snapshot review-3f2e3accf1419e91 approved with informational R3-001/R3-002 only. Before acknowledgement, bound status reported a different current target. Diagnosed drift: only `pesaje.lpi` changed relative to frozen tree (6 additions/7 deletions); source fix unchanged. No acknowledgement, replay, reset or fresh START issued after drift; native closure is not acknowledged for the current ambient candidate.
- Resource loading, opening in designer, native visual appearance/resize/keyboard and live capture/send remain unverified. No Windows or dist artifacts regenerated. No commits made.

## Next step
Use a working Lazarus environment with the project's existing Synapse/FCL dependencies to open the form in Designer and build; then visually exercise the full integrated screen using disposable data. Do not call this trial complete or regenerate dist before these checks pass. Commit and delivery remain pending explicit authorization. Engram full mirror remains pending (missing binary).
