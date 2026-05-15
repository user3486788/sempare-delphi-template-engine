[← Components](components.md) · [Back to README](../README.md)

# Testing

This project uses the existing DUnitX test runner and Delphi build scripts. The bridge work extends the same test project instead of introducing a second framework.

## Toolchain Setup

Initialize the RAD Studio CLI before builds or test runs:

```bat
call "D:\Embarcadero RAD Studio\23.0\bin\rsvars.bat"
```

## Main Test Project

| Project | Purpose |
|---------|---------|
| `Sempare.Template.Tester.dpr` | DUnitX entry point |
| `Sempare.Template.Tester.dproj` | Buildable test project |
| `tests\*.pas` | Core engine, bridge, demo, and regression fixtures |

## Standard Build Command

From [scripts](../scripts):

```bat
build.bat Debug Win32
```

This compiles the main DUnitX runner and all currently registered test fixtures.

## Running DUnitX

From the repository root:

```bat
Win32\Debug\Sempare.Template.Tester.exe
```

The runner covers:

- core parser, evaluator, and helper behavior
- DWScript providers, runtime, marshalling, and host services
- demo regressions for the playground and `DwsBridgeAdvanced`

## Demo Verification

### Playground

Use [scripts/rs23-build.cmd](../scripts/rs23-build.cmd) to rebuild the playground with the RS23 toolchain:

```bat
cd scripts
rs23-build.cmd
```

### DwsBridgeAdvanced

Build [DwsBridgeAdvanced.dproj](../demo/DwsBridgeAdvanced/DwsBridgeAdvanced.dproj) after `rsvars.bat`, then run:

```bat
demo\DwsBridgeAdvanced\Win32\Debug\DwsBridgeAdvanced.exe chinook
demo\DwsBridgeAdvanced\Win32\Debug\DwsBridgeAdvanced.exe sakila
```

Both modes generate reports under [demo/DwsBridgeAdvanced/output](../demo/DwsBridgeAdvanced/output).

## Documentation-Specific Checks

When you change bridge behavior, verify these together in the same patch:

- docs stay aligned with runtime defaults and helper semantics
- focused DUnitX regressions exist for locale-sensitive, re-entrant, or environment-sensitive changes
- bridge payload docs describe `_` injection precisely
- formatter docs separate invariant wire formats from context-driven formatting

## See Also

- [Getting Started](getting-started.md) - install and first-run workflow.
- [DWScript Bridge](sempare-dws-bridge.md) - bridge contracts and public helper behavior.
- [Template Registry](template-registry.md) - lazy loading and file-backed refresh behavior.
