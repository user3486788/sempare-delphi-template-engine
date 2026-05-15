# ![](../../images/sempare-logo-45px.png) Sempare Template Engine

Copyright (c) 2019-2024 [Sempare Limited](http://www.sempare.ltd)

# Sempare Template Engine Playpen Demo

This demo was originally developed with Delphi 10.3.3 and later refreshed for Delphi 11.3.

The playground is meant to be the single place where you can explore the engine, inspect pretty-printed AST output, preview HTML, and now exercise the DWScript bridge without jumping between sibling demos.

## Bundled local assets

`Load Example` now uses only the local [templates](./templates) folder that ships with `SempareTemplatePlayground`. The shared selector stays at the top of the window and switches between normal Playground samples and DWScript demos based on the active editor tab.

That folder now contains:

- the original Playground samples such as `sample1.tpl`, `sample2.tpl`, and `international.tpl`
- a local copy of the reporting pair `index.tpl` + `layout.tpl`
- the HTML invoice demo in `invoice.tpl`
- DWScript scenario templates: `dws-explicit-call.tpl`, `dws-host-render.tpl`, `dws-trusted-raw.tpl`, `dws-inline.tpl`, and `dws-invoice-summary.tpl`
- DWScript source files in `templates\dws\scripts\`
- the host-side bridge template `templates\dws\templates\badge.tpl`

This keeps the demo self-contained: the Playground no longer needs to load templates from `demo\WebReporting` or `demo\HtmlInvoice` just to show the reporting, invoice, and bridge scenarios.

## DWScript bridge coverage

The `DWScript` tab is wired to the same local assets and demonstrates:

- `DwsCall` with an explicit entry point and payload map
- `DwsRender` resolving the local `badge` host template through `card.dws`
- `DwsRaw` for trusted-output flows
- `DwsInline` for temporary inline scripts
- `Dws()` over SQLite-seeded invoice data with an explicit `Invoice` payload and `JSON-like return`

The SQLite-backed invoice scenario is also available through `Load Example`, so the main editor can show the same bridge flow the dedicated tab configures.

## Notes

- The Playground still depends on the local `..\..\..\DWScript\Source` tree in the same way as the rest of the bridge work.
- Switch to the `DWScript` tab before using the shared example selector if you want the list to show only DWScript demos.
- The example loader now registers only the local Playground template folder, so cross-template samples such as `index.tpl`, `layout.tpl`, and `badge.tpl` stay in sync with what ships in this demo.
- To build from the command line, run `build.bat Debug Win32` from the [`scripts`](../../scripts) folder; it initializes `rsvars.bat` before calling MSBuild.

