[← Getting Started](getting-started.md) · [Back to README](../README.md) · [Configuration →](configuration.md)

# Sempare DWScript Bridge

## Overview

This document describes the current library-level bridge between Sempare Template Engine and DWScript.

The baseline remains unchanged:

- Sempare is still the template engine.
- DWScript remains an external scripting backend.
- Integration happens only through Sempare custom helper functions.
- No Sempare grammar, lexer, parser, AST, or evaluator changes are required.

The original v1 named-script flow is still the production default, but the shipped implementation now also includes opt-in capabilities that were previously roadmap-only:

- structured payload/result conversion
- host callbacks through a dedicated `SempareHost` DWScript unit
- additional script providers
- diagnostics and profiling hooks
- inline script helpers for development scenarios
- optional ergonomic helpers
- explicit trusted/raw and mutation policies
- bundled script packages and optional tooling helpers

Primary usage targets:

```pascal
<% DwsCall('pricing', 'CalcTotal', _) %>
<% DwsCall('pricing', 'CalcTotal', { "order": _, "mode": "net" }) %>
<% DwsText('snippets', 'RenderBadge', { "text": "new" }) %>
<% Dws('pricing', { "value": 4 }) %>
<% DwsRender('snippets', { "html": "<b>safe</b>" }) %>
```

## Architecture Summary

The bridge is split into dedicated units with narrow responsibilities:

- `Sempare.Template.DWS.Types`
  Shared enums, options, diagnostics contracts, provider/runtime/marshaller abstractions, and bridge exceptions.
- `Sempare.Template.DWS.Provider`
  Named script providers: in-memory registry, file-system provider, composite provider chain, and bundled/versioned packages.
- `Sempare.Template.DWS.Cache`
  Thread-safe cache of compiled scripts keyed by script name and version tag.
- `Sempare.Template.DWS.Marshalling`
  Explicit payload creation plus predictable scalar, array, map, `Variant`, and JSON-like result conversion.
- `Sempare.Template.DWS.Runtime`
  The only unit allowed to know about raw DWScript host embedding types and compile/execute details.
- `Sempare.Template.DWS.HostServices`
  Safe host callback layer used by the runtime-backed `SempareHost` DWScript unit.
- `Sempare.Template.DWS.Functions`
  Template helper functions such as `DwsCall`, `DwsText`, `Dws`, `DwsRender`, and the opt-in inline/raw helpers.
- `Sempare.Template.DWS`
  Bridge composition root, helper registration, cache invalidation, provider swaps, and diagnostics wiring.
- `Sempare.Template.DWS.Tooling`
  Optional diagnostics recorder and a fixture-oriented test harness for integration-style tests.

This keeps Sempare core units independent from DWScript and preserves the modular-monolith boundaries documented in `.ai-factory/ARCHITECTURE.md`.

## Integration Rules

### Helper-based only

DWScript is invoked only through Sempare custom helper functions. The bridge uses Sempare's existing RTTI-based custom-function mechanism:

- helper methods are `class` + `static`
- `ITemplateContext` may be the first parameter
- variadic helper arguments use `TArray<TValue>`
- no Sempare parser or evaluator changes are required

### Separate script storage

DWScript source is not loaded through `TemplateResolver` or `TemplateRegistry`.

Sempare template assets and DWScript script assets are separate concerns:

- Sempare template assets continue to use the existing template registry/resolver path
- DWScript source is managed through a dedicated provider/registry/cache layer

### Explicit payload only

Data passed from a template into DWScript must always be explicit.

Supported payload patterns:

- pass `_` explicitly
- pass a literal map/object explicitly
- pass arrays, maps, records, objects, and one-dimensional `Variant` arrays through the marshaller
- enable `tdboPassRootData` when you want the bridge to include the template root automatically

`tdboPassRootData` behaves as follows:

- if there is no explicit payload and root data exists, the root becomes the DWScript payload
- if the explicit payload is a map and root data exists, the bridge injects the root under `_` when `_` is not already defined
- if the explicit payload is not a map, the bridge does not silently reshape it

Still disallowed by default:

- auto-importing all context variables
- auto-importing loop variables
- auto-importing `with` locals or block-local state
- unrestricted `ITemplateContext` access from DWScript

### Escaping and trusted text

Normal Sempare escaping semantics remain the default.

- `DwsText` and `DwsRender` behave like ordinary helper output and remain subject to the active variable encoder
- `DwsRaw` is opt-in only and requires `tdboAllowTrustedText`
- `DwsRaw` is explicit rather than implicit: if the value is emitted through normal helper output it is still encoded; use it only in an explicitly trusted output path such as `print(DwsRaw(...))`

### Context mutation

Context mutation remains blocked by default.

Two gates are required before `SetVar` can succeed from DWScript:

- `tdboDisallowContextMutation` must be absent from bridge options
- host services must be configured with an explicit mutation policy, typically an allow-list

This keeps the default host surface read-only and audit-friendly.

### Inline scripts

Named scripts remain the production-first path.

Inline DWScript execution exists only for development-oriented or temporary scenarios:

- disabled by default
- enabled with `tdboAllowInlineScripts`
- isolated behind dedicated helpers so the normal named-script flow does not depend on inline mode

## Bridge Options

`TTemplateDwsBridgeOption` currently supports:

- `tdboCacheCompiledScripts`
  Cache compiled DWScript programs by `(script name, version tag)`.
- `tdboPassRootData`
  Allow implicit root-data injection under the documented rules above.
- `tdboDisallowContextMutation`
  Keep host mutation disabled even if host services expose `SetVar`.
- `tdboExpectJsonLikeReturn`
  Parse string results that look like JSON documents into `TMap` / `TArray<TValue>` / scalar template values.
- `tdboAllowInlineScripts`
  Enable `DwsInline` and `DwsInlineText`.
- `tdboAllowTrustedText`
  Enable `DwsRaw` for explicit trusted-output flows.

The default bridge is created with:

```pascal
[tdboCacheCompiledScripts, tdboDisallowContextMutation]
```

## Public API Summary

### Helper functions

`DwsCall(scriptName, entryName, payload?)`

- resolves a named DWScript script
- compiles or reuses a cached compiled script
- invokes the requested entry point
- returns a value-compatible `TValue`

`DwsText(scriptName, entryName, payload?)`

- resolves a named DWScript script
- invokes the requested entry point
- returns text for normal Sempare output

`Dws(scriptName, payload?)`

- shorthand for `DwsCall(scriptName, 'Main', payload?)`

`DwsRender(scriptName, payload?)`

- shorthand for `DwsText(scriptName, 'Render', payload?)`

`DwsInline(source, entryName, payload?)`

- evaluates inline DWScript source
- requires `tdboAllowInlineScripts`

`DwsInlineText(source, entryName, payload?)`

- text variant of inline execution
- requires `tdboAllowInlineScripts`

`DwsRaw(scriptName, entryName, payload?)`

- explicit trusted/raw text helper
- requires `tdboAllowTrustedText`
- does not silently bypass Sempare escaping

### Bridge API

The top-level bridge is responsible for:

- registering and unregistering helper functions into an `ITemplateContext`
- managing named scripts through an in-memory registry by default
- invalidating and clearing compiled-script cache entries
- replacing provider, marshaller, host services, diagnostics sink, and options when needed

Key composition methods:

- `SetScriptProvider`
- `SetMarshaller`
- `SetHostServices`
- `SetDiagnostics`
- `SetOptions`
- `InvalidateScript`
- `ClearCompileCache`

### Provider factories

`Sempare.Template.DWS.Provider` ships these factory helpers:

- `CreateInMemoryDwsScriptRegistry`
- `CreateFileSystemDwsScriptProvider(rootFolder, extension)`
- `CreateCompositeDwsScriptProvider([...])`
- `CreateBundledDwsScriptProvider(bundleVersion, definitions)`

### Host services

`Sempare.Template.DWS.HostServices` ships:

- `CreateDefaultDwsHostServices`
- `CreateAllowListMutationPolicy`

DWScript sees these callbacks through `uses SempareHost;`:

- `TemplateExists(name): Boolean`
- `ResolveTemplate(name): String`
- `ResolveTemplate(name, data): String`
- `GetVar(name): Variant`
- `SetVar(name, value): Boolean`

### Tooling helpers

`Sempare.Template.DWS.Tooling` ships optional helpers:

- `TTemplateDwsDiagnosticsRecorder`
- `TSempareDwsTestHarness`

These helpers are intended for tests, diagnostics capture, and sample-style integration setups. They do not alter bridge behavior.

### Exceptions

The bridge exposes dedicated exception types for:

- missing scripts
- compile failures
- runtime failures
- marshalling errors
- contract validation failures

Error messages include script name, entry name, version tag, and active option context where applicable.

## Verified Usage Examples

### Bootstrap a bridge into a template context

```delphi
uses
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.Util;

var
  Ctx: ITemplateContext;
  Bridge: ISempareDwsBridge;
  OrderData: TMap;
begin
  Ctx := Template.Context([eoNoDefaultFunctions]);
  Bridge := CreateSempareDwsBridge;

  Bridge.AddScript('pricing',
    'function CalcTotal(data : JSONVariant) : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.total + 5;' + sLineBreak +
    'end;');

  Bridge.RegisterInto(Ctx);

  OrderData := TMap.Create;
  OrderData.Add('total', 10);

  Writeln(Template.Eval(Ctx, '<% DwsCall(''pricing'', ''CalcTotal'', _) %>', OrderData));
end;
```

### Call a script with explicit map payload

Template-side explicit payloads remain the safest production path when you only want to expose selected values:

```pascal
<% DwsCall('pricing', 'CalcTotal', { "total": 10, "fee": 5 }) %>
```

Matching DWScript entry:

```pascal
function CalcTotal(data : JSONVariant) : Integer;
begin
  Result := data.total + data.fee;
end;
```

### Use ergonomic default-entry helpers

```pascal
<% Dws('pricing', { "value": 4 }) %>
<% DwsRender('snippets', { "html": "<b>safe</b>" }) %>
```

Matching DWScript entry points:

```pascal
function Main(data : JSONVariant) : Integer;
begin
  Result := data.value + 1;
end;

function Render(data : JSONVariant) : String;
begin
  Result := data.html;
end;
```

### Render text with normal Sempare escaping

If the template context uses an HTML variable encoder, the DWScript result is encoded the same way as other helper output:

```pascal
<% DwsText('snippets', 'RenderBadge', { "html": "<b>unsafe</b>" }) %>
```

With `Ctx.UseHtmlVariableEncoder`, the rendered output is `&lt;b&gt;unsafe&lt;/b&gt;`.

### Explicit trusted/raw output

Trusted output is never implicit. This is the safe pattern:

```pascal
<% print(DwsRaw('snippets', 'RenderBadge', { "html": "<b>trusted</b>" })) %>
```

If `DwsRaw(...)` is emitted through ordinary helper output instead of `print(...)`, Sempare's normal encoding still applies.

### Read-only host services from DWScript

DWScript can call back into the host through the dedicated `SempareHost` unit:

```pascal
uses SempareHost;

function RenderCard(data : JSONVariant) : String;
begin
  if TemplateExists('inner') then
    Result := ResolveTemplate('inner', data)
  else
    Result := String(GetVar('currentUser'));
end;
```

Delphi-side setup:

```delphi
Ctx := Template.Context([eoNoDefaultFunctions]);
Ctx.Variables['currentUser'] := 'ada';
Ctx.SetTemplate('inner', Template.Parse(Ctx, '<% name %>'));

Bridge := CreateSempareDwsBridge;
Bridge.AddScript('card', ScriptSource);
Bridge.RegisterInto(Ctx);
```

### Controlled context mutation

Mutation is opt-in and policy-driven:

```delphi
Bridge := CreateSempareDwsBridge([tdboCacheCompiledScripts]);
Bridge.SetHostServices(
  CreateDefaultDwsHostServices(CreateAllowListMutationPolicy(['stage']))
);
```

With that setup, DWScript may call `SetVar('stage', value)`. Without both the policy and the option change, mutation is rejected.

### Structured payloads and JSON-like results

One-dimensional `Variant` arrays are normalized to `TArray<TValue>` and nested maps/arrays stay predictable:

```delphi
Payload := TMap.Create;
Payload.Add('values', TValue.FromVariant(VarArrayOf([1, 2, 3])));
```

When `tdboExpectJsonLikeReturn` is enabled, DWScript text results such as the following can be parsed back into structured Sempare values:

```pascal
function JsonDoc(data : JSONVariant) : String;
begin
  Result := '{"items":[1,2,3],"meta":{"ok":true}}';
end;
```

### File-system and composite providers

```delphi
Bridge := CreateSempareDwsBridge;
Bridge.SetScriptProvider(
  CreateCompositeDwsScriptProvider([
    CreateInMemoryDwsScriptRegistry,
    CreateFileSystemDwsScriptProvider(ScriptRoot)
  ])
);
```

Provider order defines fallback order. Named-script usage from templates stays unchanged.

### Bundled/versioned providers

```delphi
Bridge.SetScriptProvider(
  CreateBundledDwsScriptProvider(
    'bundle-v2',
    [TTemplateDwsScriptDefinition.Create('pricing', PricingScript)]
  )
);
```

Bundle version prefixes the effective version tag, so cache invalidation cooperates with bundle upgrades.

### Cache reuse and invalidation

Compiled scripts are cached by `(script name, version tag)` when `tdboCacheCompiledScripts` is enabled:

```delphi
Bridge.AddScript('pricing', PricingScriptV1);
Template.Eval(Ctx, '<% DwsCall(''pricing'', ''CalcTotal'', { "total": 10 }) %>');

Bridge.AddScript('pricing', PricingScriptV2);
Bridge.InvalidateScript('pricing');
Bridge.ClearCompileCache;
```

### Inline development mode

Inline execution is available, but it is intentionally opt-in:

```delphi
Bridge := CreateSempareDwsBridge([
  tdboCacheCompiledScripts,
  tdboDisallowContextMutation,
  tdboAllowInlineScripts
]);
Bridge.RegisterInto(Ctx);
```

Template-side usage:

```pascal
<% DwsInlineText('function Render(data : JSONVariant) : String; begin Result := data.name; end;', 'Render', { "name": "Ada" }) %>
```

## Diagnostics and Tooling

Diagnostics are optional and non-invasive.

`ITemplateDwsDiagnostics` receives:

- cache events: hit, miss, store, invalidate, clear
- runtime events: compile start/success/failure, call start/success/failure
- profile events: resolve, compile, call, render

Example:

```delphi
var
  Recorder: TTemplateDwsDiagnosticsRecorder;
begin
  Recorder := TTemplateDwsDiagnosticsRecorder.Create;
  Bridge.SetDiagnostics(Recorder);
end;
```

`TSempareDwsTestHarness` is a lightweight helper for fixture-style tests and samples:

```delphi
var
  Harness: TSempareDwsTestHarness;
begin
  Harness := TSempareDwsTestHarness.Create;
  Harness.AddScript('calc', ScriptSource);
  Writeln(Harness.Call('calc', 'Value').AsInt64);
end;
```

## Dependency and Build Assumptions

The repository vendors DUnitX but not DWScript binaries. Integration builds against the local DWScript source tree:

- `D:\projects\externals\DWScript\`

Build/test implications:

- Sempare package and test projects resolve DWScript source units through project search paths
- machine-specific paths do not leak into the public bridge API
- build/test commands must initialize `D:\Embarcadero RAD Studio\23.0\bin\rsvars.bat` first

## Security and Behavioral Notes

- named scripts remain the primary production path
- inline scripts are development-oriented and disabled by default
- raw output is explicit and never implicit
- context mutation is explicit, whitelisted, and disabled by default
- host access is routed through a dedicated service abstraction instead of direct `ITemplateContext` exposure
- Sempare escaping stays the baseline behavior unless the template author explicitly opens a trusted-output path

## Unsupported or Deferred Areas

The current implementation intentionally does not do the following:

- change Sempare syntax or replace Sempare expression evaluation with DWScript
- auto-import arbitrary context variables or loop locals
- expose raw DWScript host internals outside `Sempare.Template.DWS.Runtime`
- make raw output implicit
- make mutation unrestricted
- ship database-backed or resource-backed providers yet
- persist precompiled DWScript programs outside the process yet

## Design Seams Preserved For Further Evolution

Even with the added v2/v3-style capabilities, the implementation still preserves the original extension seams:

- provider abstraction stays separate from Sempare template loading
- runtime embedding details remain isolated in one unit
- marshalling stays replaceable
- diagnostics and tooling stay optional
- ergonomic helpers are additive and do not break `DwsCall` / `DwsText`

Those choices keep the original v1 contract stable while allowing the bridge to grow without revisiting Sempare core internals.

## See Also

- [Getting Started](getting-started.md) - install and first bridge setup.
- [Configuration](configuration.md) - `ITemplateContext` behavior, encoders, and formatting defaults.
- [Testing](testing.md) - build and verification workflow for bridge changes.

