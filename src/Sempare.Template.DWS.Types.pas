(*%*************************************************************************************************
 *                 ___                                                                              *
 *                / __|  ___   _ __    _ __   __ _   _ _   ___                                      *
 *                \__ \ / -_) | '  \  | '_ \ / _` | | '_| / -_)                                     *
 *                |___/ \___| |_|_|_| | .__/ \__,_| |_|   \___|                                     *
 *                                    |_|                                                           *
 ****************************************************************************************************
 *                                                                                                  *
 *                          Sempare Template Engine                                                 *
 *                                                                                                  *
 *                                                                                                  *
 *         https://github.com/sempare/sempare-delphi-template-engine                                *
 ****************************************************************************************************
 *                                                                                                  *
 * Copyright (c) 2019-2025 Sempare Limited                                                          *
 *                                                                                                  *
 * Contact: info@sempare.ltd                                                                        *
 *                                                                                                  *
 * Licensed under the Apache Version 2.0 or the Sempare Commercial License                          *
 * You may not use this file except in compliance with one of these Licenses.                       *
 * You may obtain a copy of the Licenses at                                                         *
 *                                                                                                  *
 * https://www.apache.org/licenses/LICENSE-2.0                                                      *
 * https://github.com/sempare/sempare-delphi-template-engine/blob/master/docs/commercial.license.md *
 *                                                                                                  *
 * Unless required by applicable law or agreed to in writing, software                              *
 * distributed under the Licenses is distributed on an "AS IS" BASIS,                               *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.                         *
 * See the License for the specific language governing permissions and                              *
 * limitations under the License.                                                                   *
 *                                                                                                  *
 *************************************************************************************************%*)
unit Sempare.Template.DWS.Types;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Sempare.Template.AST,
  Sempare.Template.Context;

type
  /// <summary>
  /// Describes how the bridge builds the payload passed from Sempare into DWScript.
  /// </summary>
  TTemplateDwsPayloadMode = (
    /// <summary>Only the explicit payload supplied by the caller is forwarded.</summary>
    tdpmExplicitOnly,
    /// <summary>
    /// The explicit payload is forwarded and the current root data may also be exposed through `_` when available.
    /// </summary>
    tdpmExplicitPlusRoot
  );

  /// <summary>
  /// Describes whether a DWScript helper should return a raw value or rendered text.
  /// </summary>
  TTemplateDwsReturnMode = (
    /// <summary>Return the DWScript result as a value.</summary>
    tdrmValue,
    /// <summary>Convert the DWScript result to text.</summary>
    tdrmText
  );

  /// <summary>
  /// Configures optional DWScript bridge behavior.
  /// </summary>
  TTemplateDwsBridgeOption = (
    /// <summary>Allows inline DWScript sources passed through helpers such as `DwsInline`.</summary>
    tdboAllowInlineScripts,
    /// <summary>Enables compiled-script caching keyed by script name and version tag.</summary>
    tdboCacheCompiledScripts,
    /// <summary>
    /// Allows the bridge to pass the current template root data into DWScript. For explicit map payloads the `_` member is injected only when root data exists and `_` is not already present.
    /// </summary>
    tdboPassRootData,
    /// <summary>Prevents DWScript host services from mutating template variables unless a mutation policy explicitly allows it.</summary>
    tdboDisallowContextMutation,
    /// <summary>Converts DWScript JSON-like results into template-friendly values.</summary>
    tdboExpectJsonLikeReturn,
    /// <summary>Allows helpers such as `DwsRaw` to return trusted text without additional template encoding.</summary>
    tdboAllowTrustedText
  );

  /// <summary>
  /// Set of enabled bridge options.
  /// </summary>
  TTemplateDwsBridgeOptions = set of TTemplateDwsBridgeOption;

  /// <summary>
  /// Kinds of compile-cache events emitted by the bridge.
  /// </summary>
  TTemplateDwsCacheEventKind = (
    /// <summary>An existing compiled script was reused.</summary>
    tdcekHit,
    /// <summary>A requested compiled script was not found in cache.</summary>
    tdcekMiss,
    /// <summary>A compiled script was written into cache.</summary>
    tdcekStore,
    /// <summary>A cached entry for one script was invalidated.</summary>
    tdcekInvalidate,
    /// <summary>The entire compile cache was cleared.</summary>
    tdcekClear
  );

  /// <summary>
  /// Kinds of runtime events emitted during DWScript compilation and execution.
  /// </summary>
  TTemplateDwsRuntimeEventKind = (
    /// <summary>Compilation of a DWScript source started.</summary>
    tdrekCompileStart,
    /// <summary>Compilation succeeded.</summary>
    tdrekCompileSuccess,
    /// <summary>Compilation failed.</summary>
    tdrekCompileFailure,
    /// <summary>Execution of a DWScript entry started.</summary>
    tdrekCallStart,
    /// <summary>Execution of a DWScript entry succeeded.</summary>
    tdrekCallSuccess,
    /// <summary>Execution of a DWScript entry failed.</summary>
    tdrekCallFailure
  );

  /// <summary>
  /// Kinds of profile events emitted by the bridge.
  /// </summary>
  TTemplateDwsProfileEventKind = (
    /// <summary>Time spent resolving a named script.</summary>
    tdpekResolve,
    /// <summary>Time spent compiling a DWScript source.</summary>
    tdpekCompile,
    /// <summary>Time spent invoking a DWScript entry point.</summary>
    tdpekCall,
    /// <summary>Time spent rendering a DWScript entry to text.</summary>
    tdpekRender
  );

  /// <summary>
  /// Predicate used by host services to decide whether a template variable may be changed from DWScript.
  /// </summary>
  TTemplateDwsMutationPolicy = reference to function(const AName: string): boolean;

  /// <summary>
  /// Base exception for DWScript bridge errors.
  /// </summary>
  ETemplateDwsBridge = class(ETemplate)
  public
    /// <summary>
    /// Creates a bridge exception enriched with script, entry, version, and option context.
    /// </summary>
    constructor CreateContext(
      const AMessage: string;
      const AScriptName: string = '';
      const AEntryName: string = '';
      const AVersionTag: string = '';
      const AOptions: TTemplateDwsBridgeOptions = []
    );
  end;

  /// <summary>Raised when a named script cannot be resolved from the configured providers.</summary>
  ETemplateDwsScriptNotFound = class(ETemplateDwsBridge);
  /// <summary>Raised when DWScript compilation fails.</summary>
  ETemplateDwsCompileError = class(ETemplateDwsBridge);
  /// <summary>Raised when DWScript runtime execution fails.</summary>
  ETemplateDwsRuntimeError = class(ETemplateDwsBridge);
  /// <summary>Raised when payload or result marshalling fails.</summary>
  ETemplateDwsMarshalError = class(ETemplateDwsBridge);
  /// <summary>Raised when bridge configuration or helper contracts are violated.</summary>
  ETemplateDwsContractError = class(ETemplateDwsBridge);

  /// <summary>
  /// Represents a resolved DWScript source together with its effective version tag.
  /// </summary>
  TTemplateDwsScript = record
  public
    Name: string;
    Source: string;
    VersionTag: string;
    /// <summary>
    /// Creates a DWScript source record.
    /// </summary>
    class function Create(const AName, ASource, AVersionTag: string): TTemplateDwsScript; static;
  end;

  /// <summary>
  /// Represents a bundled or in-memory script definition before it is resolved by a provider.
  /// </summary>
  TTemplateDwsScriptDefinition = record
  public
    Name: string;
    Source: string;
    VersionTag: string;
    /// <summary>
    /// Creates a script definition.
    /// </summary>
    class function Create(const AName, ASource: string; const AVersionTag: string = ''): TTemplateDwsScriptDefinition; static;
  end;

  /// <summary>
  /// Represents a compiled DWScript program together with the script identity used to build it.
  /// </summary>
  ITemplateDwsCompiledScript = interface
    ['{03A0D10E-73A4-43C6-89D5-6426858D459A}']
    function GetScriptName: string;
    function GetVersionTag: string;
    property ScriptName: string read GetScriptName;
    property VersionTag: string read GetVersionTag;
  end;

  /// <summary>
  /// Supplies named DWScript sources to the bridge.
  /// </summary>
  ITemplateDwsScriptProvider = interface
    ['{4A254946-E3F3-4D5A-A903-B5494B39D955}']
    /// <summary>Attempts to resolve a named script.</summary>
    function TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
    /// <summary>Checks whether a named script exists.</summary>
    function Exists(const AName: string): boolean;
    /// <summary>Returns the current version tag for a named script.</summary>
    function VersionTag(const AName: string): string;
  end;

  /// <summary>
  /// Writable DWScript provider used for in-memory bridge scripts.
  /// </summary>
  ITemplateDwsScriptRegistry = interface(ITemplateDwsScriptProvider)
    ['{D574E3E0-09D2-444C-98EA-DAF8BC53912F}']
    /// <summary>Adds a new script or replaces an existing one.</summary>
    procedure AddOrSet(const AName, ASource: string);
    /// <summary>Removes a named script from the registry.</summary>
    procedure Remove(const AName: string);
    /// <summary>Clears all registered scripts.</summary>
    procedure Clear;
  end;

  /// <summary>
  /// Stores compiled DWScript programs by script name and version tag.
  /// </summary>
  ITemplateDwsCompileCache = interface
    ['{9101BD83-ED14-4D95-BE9A-728CCB1E3AF4}']
    /// <summary>Attempts to retrieve a compiled script from cache.</summary>
    function TryGet(const AName, AVersionTag: string; out ACompiled: ITemplateDwsCompiledScript): boolean;
    /// <summary>Stores a compiled script in cache.</summary>
    procedure Put(const AName, AVersionTag: string; const ACompiled: ITemplateDwsCompiledScript);
    /// <summary>Invalidates cached entries for a named script.</summary>
    procedure Invalidate(const AName: string);
    /// <summary>Clears the entire compile cache.</summary>
    procedure Clear;
  end;

  /// <summary>
  /// Converts payloads and return values between Sempare template values and DWScript-friendly values.
  /// </summary>
  ITemplateDwsMarshaller = interface
    ['{D45E4A3E-9460-42CA-A666-04020B14C59F}']
    /// <summary>
    /// Builds the payload that will be passed into a DWScript entry.
    /// </summary>
    function BuildPayload(
      const ACtx: ITemplateContext;
      const AExplicitPayload: TValue;
      const AOptions: TTemplateDwsBridgeOptions;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): TValue;

    /// <summary>
    /// Converts a DWScript result into a template value.
    /// </summary>
    function ConvertResultToTemplateValue(
      const AValue: TValue;
      const AOptions: TTemplateDwsBridgeOptions;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): TValue;

    /// <summary>
    /// Converts a DWScript result into text.
    /// </summary>
    function ConvertResultToText(
      const AValue: TValue;
      const AOptions: TTemplateDwsBridgeOptions;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): string;
  end;

  /// <summary>
  /// Exposes controlled template host operations to DWScript.
  /// </summary>
  ITemplateDwsHostServices = interface
    ['{7E14A77B-CF0F-4B5E-B9CA-AB3A70F95EC4}']
    /// <summary>Checks whether a template can be resolved by name.</summary>
    function TemplateExists(const ACtx: ITemplateContext; const ATemplateName: string): boolean;
    /// <summary>Renders a named Sempare template from DWScript.</summary>
    function ResolveTemplate(const ACtx: ITemplateContext; const ATemplateName: string; const AData: TValue): string;
    /// <summary>Reads a template variable.</summary>
    function TryGetVar(const ACtx: ITemplateContext; const AName: string; out AValue: TValue): boolean;
    /// <summary>Writes a template variable, subject to the configured mutation policy.</summary>
    procedure SetVar(const ACtx: ITemplateContext; const AName: string; const AValue: TValue);
  end;

  /// <summary>
  /// Receives cache, runtime, and profile notifications from the bridge.
  /// </summary>
  ITemplateDwsDiagnostics = interface
    ['{C71B790B-9D08-44F5-A58F-E7F896E063C7}']
    /// <summary>Reports a cache event.</summary>
    procedure CacheEvent(
      const AKind: TTemplateDwsCacheEventKind;
      const AScriptName: string;
      const AVersionTag: string
    );
    /// <summary>Reports a runtime event.</summary>
    procedure RuntimeEvent(
      const AKind: TTemplateDwsRuntimeEventKind;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const ADetail: string
    );
    /// <summary>Reports a profiling event.</summary>
    procedure ProfileEvent(
      const AKind: TTemplateDwsProfileEventKind;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AElapsedMs: int64
    );
  end;

  /// <summary>
  /// Compiles DWScript sources and executes named entries on behalf of the bridge.
  /// </summary>
  ITemplateDwsRuntime = interface
    ['{6C5B3D36-B244-412A-B7A4-55C37F3F0244}']
    /// <summary>Compiles a named DWScript source.</summary>
    function CompileNamed(
      const AName: string;
      const ASource: string;
      const AVersionTag: string;
      const AEntryName: string = ''
    ): ITemplateDwsCompiledScript;

    /// <summary>Calls a DWScript entry and returns its value result.</summary>
    function CallEntry(
      const ACompiled: ITemplateDwsCompiledScript;
      const AEntryName: string;
      const APayload: TValue;
      const ACtx: ITemplateContext;
      const AHostServices: ITemplateDwsHostServices;
      const AOptions: TTemplateDwsBridgeOptions
    ): TValue;

    /// <summary>Calls a DWScript entry and converts the result to text.</summary>
    function RenderEntry(
      const ACompiled: ITemplateDwsCompiledScript;
      const AEntryName: string;
      const APayload: TValue;
      const ACtx: ITemplateContext;
      const AHostServices: ITemplateDwsHostServices;
      const AOptions: TTemplateDwsBridgeOptions
    ): string;

    /// <summary>Sets the diagnostics sink used for cache/runtime/profile events.</summary>
    procedure SetDiagnostics(const ADiagnostics: ITemplateDwsDiagnostics);
  end;

  /// <summary>
  /// Main composition interface for registering DWScript helpers and configuring providers, marshalling, and runtime behavior.
  /// </summary>
  ISempareDwsBridge = interface
    ['{0A9886DB-6D66-47D5-8774-D9859D79F04A}']
    /// <summary>Registers DWScript helper functions into a template context.</summary>
    procedure RegisterInto(const ACtx: ITemplateContext);
    /// <summary>Removes DWScript helper functions from a template context.</summary>
    procedure UnregisterFrom(const ACtx: ITemplateContext);
    /// <summary>Adds or replaces an in-memory named script.</summary>
    procedure AddScript(const AName, ASource: string);
    /// <summary>Removes an in-memory named script.</summary>
    procedure RemoveScript(const AName: string);
    /// <summary>Clears all in-memory named scripts.</summary>
    procedure ClearScripts;
    /// <summary>Invalidates any cached compiled program for a named script.</summary>
    procedure InvalidateScript(const AName: string);
    /// <summary>Clears the compile cache.</summary>
    procedure ClearCompileCache;
    /// <summary>Replaces the named-script provider used for script resolution.</summary>
    procedure SetScriptProvider(const AProvider: ITemplateDwsScriptProvider);
    /// <summary>Replaces the marshaller used for payload and result conversion.</summary>
    procedure SetMarshaller(const AMarshaller: ITemplateDwsMarshaller);
    /// <summary>Replaces the host-services adapter exposed to DWScript.</summary>
    procedure SetHostServices(const AHostServices: ITemplateDwsHostServices);
    /// <summary>Sets the diagnostics sink used by the bridge.</summary>
    procedure SetDiagnostics(const ADiagnostics: ITemplateDwsDiagnostics);
    /// <summary>Replaces the active bridge options.</summary>
    procedure SetOptions(const AOptions: TTemplateDwsBridgeOptions);
    /// <summary>Returns the current bridge options.</summary>
    function GetOptions: TTemplateDwsBridgeOptions;
    property Options: TTemplateDwsBridgeOptions read GetOptions;
  end;

  /// <summary>
  /// Low-level dispatch interface used by helper functions and tests to invoke DWScript directly.
  /// </summary>
  ISempareDwsBridgeDispatch = interface
    ['{77E7D9E0-790E-4D3D-9B8A-45F1FD7F2F1C}']
    /// <summary>Calls a named DWScript entry using an explicit payload.</summary>
    function Call(
      const ACtx: ITemplateContext;
      const AScriptName: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): TValue;

    /// <summary>Renders a named DWScript entry to text using an explicit payload.</summary>
    function Render(
      const ACtx: ITemplateContext;
      const AScriptName: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): string;

    /// <summary>Compiles and calls inline DWScript source using an explicit payload.</summary>
    function CallInline(
      const ACtx: ITemplateContext;
      const ASource: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): TValue;

    /// <summary>Compiles and renders inline DWScript source using an explicit payload.</summary>
    function RenderInline(
      const ACtx: ITemplateContext;
      const ASource: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): string;
  end;

/// <summary>
/// Returns the context variable key used to store the registered DWScript bridge instance.
/// </summary>
function TemplateDwsBridgeContextKey: string;

/// <summary>
/// Calculates the effective payload mode from the current bridge options.
/// </summary>
/// <remarks>
/// `tdboPassRootData` switches the bridge from explicit-only payloads to explicit-plus-root behavior.
/// </remarks>
function TemplateDwsPayloadModeFromOptions(const AOptions: TTemplateDwsBridgeOptions): TTemplateDwsPayloadMode;

/// <summary>
/// Converts the active bridge options to a stable diagnostic string.
/// </summary>
function TemplateDwsOptionsToString(const AOptions: TTemplateDwsBridgeOptions): string;

implementation

type
  TTemplateDwsBridgeOptionHelper = record helper for TTemplateDwsBridgeOption
    function ToDiagnosticText: string;
  end;

function TemplateDwsBridgeContextKey: string;
begin
  exit('__SEMPARE_DWS_BRIDGE__');
end;

function TemplateDwsPayloadModeFromOptions(const AOptions: TTemplateDwsBridgeOptions): TTemplateDwsPayloadMode;
begin
  if tdboPassRootData in AOptions then
    exit(tdpmExplicitPlusRoot);
  exit(tdpmExplicitOnly);
end;

function TemplateDwsOptionsToString(const AOptions: TTemplateDwsBridgeOptions): string;
var
  LOption: TTemplateDwsBridgeOption;
begin
  result := '';
  for LOption in AOptions do
  begin
    if result <> '' then
      result := result + ',';
    result := result + LOption.ToDiagnosticText;
  end;
  if result = '' then
    result := 'none';
end;

constructor ETemplateDwsBridge.CreateContext(
  const AMessage: string;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
);
var
  LContext: string;
begin
  LContext := 'script=' + QuotedStr(AScriptName) +
    ', entry=' + QuotedStr(AEntryName) +
    ', version=' + QuotedStr(AVersionTag) +
    ', payloadMode=' + GetEnumName(TypeInfo(TTemplateDwsPayloadMode), Ord(TemplateDwsPayloadModeFromOptions(AOptions))) +
    ', options=' + TemplateDwsOptionsToString(AOptions);
  inherited Create(AMessage + ' [' + LContext + ']');
end;

class function TTemplateDwsScript.Create(const AName, ASource, AVersionTag: string): TTemplateDwsScript;
begin
  result.Name := AName;
  result.Source := ASource;
  result.VersionTag := AVersionTag;
end;

class function TTemplateDwsScriptDefinition.Create(const AName, ASource: string; const AVersionTag: string): TTemplateDwsScriptDefinition;
begin
  result.Name := AName;
  result.Source := ASource;
  result.VersionTag := AVersionTag;
end;

function TTemplateDwsBridgeOptionHelper.ToDiagnosticText: string;
begin
  case self of
    tdboAllowInlineScripts:
      exit('allowInlineScripts');
    tdboCacheCompiledScripts:
      exit('cacheCompiledScripts');
    tdboPassRootData:
      exit('passRootData');
    tdboDisallowContextMutation:
      exit('disallowContextMutation');
    tdboExpectJsonLikeReturn:
      exit('expectJsonLikeReturn');
    tdboAllowTrustedText:
      exit('allowTrustedText');
  end;
  exit('unknownOption');
end;

end.
