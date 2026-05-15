[Back to README](../README.md) · [DWScript Bridge →](sempare-dws-bridge.md)

# Getting Started

This guide walks through the fastest way to install Sempare Template Engine, point Delphi at the sources, and verify the runtime with the existing DUnitX suite and demos.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Delphi / RAD Studio | Supported from Delphi XE4 onward |
| Source checkout | Repository root with `src/`, `tests/`, and `demo/` |
| Optional package managers | Boss, GetIt, or Delphinus |
| DWScript sources | Needed only for the bridge units and bridge demos |

## Installation Options

### Boss

```bash
boss install sempare/sempare-delphi-template-engine
```

### GetIt

Install "Sempare Template Engine" from the RAD Studio GetIt package manager.

### Manual Setup

1. Open [Sempare.Template.Engine.Group.groupproj](../Sempare.Template.Engine.Group.groupproj).
2. Add [src](../src) to the Delphi search path if you are consuming the units directly.
3. For DWScript bridge work, make sure the local DWScript source tree is available at `D:\projects\externals\DWScript\` or update the project search paths accordingly.

## First Template

```pascal
program FirstTemplate;

uses
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.Util;

var
  Ctx: ITemplateContext;
  Data: TMap;
begin
  Ctx := Template.Context;
  Data := TMap.Create;
  Data.Add('name', 'Ada');
  Data.Add('language', 'Delphi');
  Writeln(Template.Eval(Ctx, 'Hello <% name %> from <% language %>', Data));
end.
```

Expected output:

```text
Hello Ada from Delphi
```

## Build and Test

Delphi CLI builds should initialize the toolchain first:

```bat
call "D:\Embarcadero RAD Studio\23.0\bin\rsvars.bat"
```

Then you can use the existing repo scripts:

```bat
cd scripts
build.bat Debug Win32
```

The standard test runner is [Sempare.Template.Tester.dpr](../Sempare.Template.Tester.dpr). It contains the DUnitX fixtures for both the core template engine and the DWScript bridge.

## Run The Demos

- [Sempare Template Playground](../demo/SempareTemplatePlayground/README.md) for interactive template authoring.
- [DwsBridgeAdvanced](../demo/DwsBridgeAdvanced/README.md) for Chinook/Sakila bridge scenarios and report generation.

## Next Steps

- Read [DWScript Bridge](sempare-dws-bridge.md) if you want `DwsCall`, `DwsText`, or host-service integration.
- Read [Configuration](configuration.md) for encoder, formatting, and template-context behavior.
- Read [Testing](testing.md) for repeatable build and verification commands.

## See Also

- [DWScript Bridge](sempare-dws-bridge.md) - helper-based integration architecture and option semantics.
- [Configuration](configuration.md) - `ITemplateContext` options and formatting defaults.
- [Testing](testing.md) - DUnitX and demo verification workflow.
