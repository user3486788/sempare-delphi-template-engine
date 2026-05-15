# DwsBridgeAdvanced

This console demo supports two CLI showcase modes backed by local SQLite databases inside `demo\DwsBridgeAdvanced\templates`:

- `chinook` keeps the Sempare <-> DWScript showcase against `chinook.db`
- `sakila` adds an analogous showcase against `sakila.db`, with database reads initiated from DWScript scripts through the demo-local `SakilaDb` unit

Both modes demonstrate the same bridge surface in a repeatable console run:

- a generated HTML report under `demo\DwsBridgeAdvanced\output\*.html`
- poster-cache generation under `output\poster-cache\...`, with a download attempt first and local SVG fallback when the poster is not yet cached
- `DwsCall` with explicit payloads
- `Dws` with `tdboPassRootData`
- `DwsText`, `DwsRender`, and `DwsRaw`
- `DwsInline` and `DwsInlineText`
- host callbacks through `TemplateExists`, `ResolveTemplate`, `GetVar`, and `SetVar`
- controlled mutation via `CreateAllowListMutationPolicy`
- JSON-like structured return values with `tdboExpectJsonLikeReturn`
- diagnostics and cache reuse through `TTemplateDwsDiagnosticsRecorder`

Mode-specific output:

- `chinook` writes `demo\DwsBridgeAdvanced\output\chinook-report.html` plus linked album detail pages
- `sakila` writes `demo\DwsBridgeAdvanced\output\sakila-report.html` as a single-page gallery of film cards sourced from `sakila.db`

## Files

- `DwsBridgeAdvanced.dpr`
  Thin console entry point that runs either the Chinook or Sakila showcase and saves the HTML report.
- `Sempare.Template.DwsBridgeAdvanced.Scenarios.pas`
  Chinook scenario runner used by the CLI and DUnitX regressions. It emits the main report, linked album pages, and poster-cache assets.
- `Sempare.Template.DwsBridgeAdvanced.SakilaDemo.pas`
  Sakila scenario runner and HTML report orchestrator. It keeps the database reads inside DWS scripts and renders a single HTML page of film cards.
- `Sempare.Template.DwsBridgeAdvanced.SakilaRuntime.pas`
  Demo-local runtime extension that registers the `SakilaDb` DWScript unit with `QueryJson(...)` and `ValueText(...)` helpers.
- `Sempare.Template.DwsBridgeAdvanced.PosterSupport.pas`
  Shared poster-cache runtime helper used by both demos to populate poster assets.
- `scripts\*.dws`
  Chinook scripts and `scripts\sakila\*.dws` for the Sakila showcase.
- `templates\host\*.tpl` and `templates\sakila\host\*.tpl`
  Host templates resolved from DWScript through `SempareHost`.
- `templates\report\chinook-report.tpl`
  Main Sempare template for the Chinook HTML report.
- `templates\sakila\scenarios\*.tpl`
  Sempare templates that trigger the Sakila DWS scenarios.

## Run

Build the demo with the same RAD Studio CLI environment used by the repo:

1. initialize `D:\Embarcadero RAD Studio\23.0\bin\rsvars.bat`
2. build `demo\DwsBridgeAdvanced\DwsBridgeAdvanced.dproj`
3. run one of:
   - `demo\DwsBridgeAdvanced\Win32\Debug\DwsBridgeAdvanced.exe`
   - `demo\DwsBridgeAdvanced\Win32\Debug\DwsBridgeAdvanced.exe sakila`

The default mode is `chinook`. Chinook writes `demo\DwsBridgeAdvanced\output\chinook-report.html` and a linked album micro-site, while `sakila` writes `demo\DwsBridgeAdvanced\output\sakila-report.html` as one page with film cards. Both modes populate `demo\DwsBridgeAdvanced\output\poster-cache\...`; if a live poster download is unavailable, the cache falls back to generated SVG artwork so the reports stay self-contained.
