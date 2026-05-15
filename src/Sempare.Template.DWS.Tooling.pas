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
unit Sempare.Template.DWS.Tooling;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  System.Rtti,
  System.TypInfo,
  Sempare.Template,
  Sempare.Template.DWS.Types;

type
  /// <summary>
  /// Captures a single cache, runtime, or profile event emitted by the DWScript bridge.
  /// </summary>
  TTemplateDwsDiagnosticEvent = record
  public
    Category: string;
    Name: string;
    ScriptName: string;
    EntryName: string;
    VersionTag: string;
    Detail: string;
    ElapsedMs: int64;
  end;

  /// <summary>
  /// In-memory diagnostics sink used by tests and demos to inspect DWScript bridge activity.
  /// </summary>
  TTemplateDwsDiagnosticsRecorder = class(TInterfacedObject, ITemplateDwsDiagnostics)
  private
    FEvents: TArray<TTemplateDwsDiagnosticEvent>;
    procedure AddEvent(const AEvent: TTemplateDwsDiagnosticEvent);
  public
    /// <summary>
    /// Records a compile-cache event.
    /// </summary>
    procedure CacheEvent(const AKind: TTemplateDwsCacheEventKind; const AScriptName: string; const AVersionTag: string);
    /// <summary>
    /// Records a runtime event such as compile or call success/failure.
    /// </summary>
    procedure RuntimeEvent(
      const AKind: TTemplateDwsRuntimeEventKind;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const ADetail: string
    );
    /// <summary>
    /// Records a profiling event with elapsed time.
    /// </summary>
    procedure ProfileEvent(
      const AKind: TTemplateDwsProfileEventKind;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AElapsedMs: int64
    );
    /// <summary>
    /// Returns a snapshot copy of the currently recorded diagnostic events.
    /// </summary>
    function Events: TArray<TTemplateDwsDiagnosticEvent>;
    /// <summary>
    /// Finds the first diagnostic event that matches the supplied category and name.
    /// </summary>
    function FindFirst(const ACategory: string; const AName: string): TTemplateDwsDiagnosticEvent;
    /// <summary>
    /// Returns the total number of recorded diagnostic events.
    /// </summary>
    function Count: integer;
  end;

  /// <summary>
  /// Lightweight fixture helper for exercising DWScript bridge behavior from tests and demos.
  /// </summary>
  TSempareDwsTestHarness = class
  private
    FCtx: ITemplateContext;
    FBridge: ISempareDwsBridge;
    FDiagnostics: ITemplateDwsDiagnostics;
    procedure SetDiagnostics(const AValue: ITemplateDwsDiagnostics);
  public
    /// <summary>
    /// Creates a template context, composes the DWScript bridge, and registers helper functions into the context.
    /// </summary>
    /// <param name="ABridgeOptions">Bridge options to use for the harness.</param>
    /// <param name="ATemplateOptions">Template-evaluation options for the underlying context.</param>
    constructor Create(
      const ABridgeOptions: TTemplateDwsBridgeOptions = [tdboCacheCompiledScripts, tdboDisallowContextMutation];
      const ATemplateOptions: TTemplateEvaluationOptions = [eoNoDefaultFunctions]
    );
    /// <summary>
    /// Adds or replaces a named script in the in-memory bridge registry.
    /// </summary>
    procedure AddScript(const AName, ASource: string);
    /// <summary>
    /// Calls a named DWScript entry with an explicit payload.
    /// </summary>
    function Call(const AScriptName, AEntryName: string; const APayload: TValue): TValue; overload;
    /// <summary>
    /// Calls a named DWScript entry without an explicit payload.
    /// </summary>
    function Call(const AScriptName, AEntryName: string): TValue; overload;
    /// <summary>
    /// Renders a named DWScript entry to text with an explicit payload.
    /// </summary>
    function Render(const AScriptName, AEntryName: string; const APayload: TValue): string; overload;
    /// <summary>
    /// Renders a named DWScript entry to text without an explicit payload.
    /// </summary>
    function Render(const AScriptName, AEntryName: string): string; overload;
    /// <summary>
    /// Evaluates a Sempare template string against the harness context.
    /// </summary>
    function Eval(const ATemplate: string): string; overload;
    /// <summary>
    /// Evaluates a Sempare template string against the harness context with explicit root data.
    /// </summary>
    function Eval(const ATemplate: string; const AData: TValue): string; overload;
    /// <summary>
    /// Gets the underlying template context used by the harness.
    /// </summary>
    property Context: ITemplateContext read FCtx;
    /// <summary>
    /// Gets the composed DWScript bridge used by the harness.
    /// </summary>
    property Bridge: ISempareDwsBridge read FBridge;
    /// <summary>
    /// Gets or sets the active diagnostics sink forwarded into the bridge runtime.
    /// </summary>
    property Diagnostics: ITemplateDwsDiagnostics read FDiagnostics write SetDiagnostics;
  end;

implementation

uses
  System.SysUtils,
  Sempare.Template.Context,
  Sempare.Template.DWS;

procedure TTemplateDwsDiagnosticsRecorder.AddEvent(const AEvent: TTemplateDwsDiagnosticEvent);
var
  LCount: integer;
begin
  LCount := Length(FEvents);
  SetLength(FEvents, LCount + 1);
  FEvents[LCount] := AEvent;
end;

procedure TTemplateDwsDiagnosticsRecorder.CacheEvent(
  const AKind: TTemplateDwsCacheEventKind;
  const AScriptName: string;
  const AVersionTag: string
);
var
  LEvent: TTemplateDwsDiagnosticEvent;
begin
  LEvent.Category := 'cache';
  LEvent.Name := GetEnumName(TypeInfo(TTemplateDwsCacheEventKind), Ord(AKind));
  LEvent.ScriptName := AScriptName;
  LEvent.VersionTag := AVersionTag;
  AddEvent(LEvent);
end;

function TTemplateDwsDiagnosticsRecorder.Count: integer;
begin
  result := Length(FEvents);
end;

function TTemplateDwsDiagnosticsRecorder.Events: TArray<TTemplateDwsDiagnosticEvent>;
begin
  result := Copy(FEvents);
end;

function TTemplateDwsDiagnosticsRecorder.FindFirst(const ACategory: string; const AName: string): TTemplateDwsDiagnosticEvent;
var
  LEvent: TTemplateDwsDiagnosticEvent;
begin
  for LEvent in FEvents do
    if SameText(LEvent.Category, ACategory) and SameText(LEvent.Name, AName) then
      exit(LEvent);
  FillChar(result, SizeOf(result), 0);
end;

procedure TTemplateDwsDiagnosticsRecorder.ProfileEvent(
  const AKind: TTemplateDwsProfileEventKind;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AElapsedMs: int64
);
var
  LEvent: TTemplateDwsDiagnosticEvent;
begin
  LEvent.Category := 'profile';
  LEvent.Name := GetEnumName(TypeInfo(TTemplateDwsProfileEventKind), Ord(AKind));
  LEvent.ScriptName := AScriptName;
  LEvent.EntryName := AEntryName;
  LEvent.VersionTag := AVersionTag;
  LEvent.ElapsedMs := AElapsedMs;
  AddEvent(LEvent);
end;

procedure TTemplateDwsDiagnosticsRecorder.RuntimeEvent(
  const AKind: TTemplateDwsRuntimeEventKind;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const ADetail: string
);
var
  LEvent: TTemplateDwsDiagnosticEvent;
begin
  LEvent.Category := 'runtime';
  LEvent.Name := GetEnumName(TypeInfo(TTemplateDwsRuntimeEventKind), Ord(AKind));
  LEvent.ScriptName := AScriptName;
  LEvent.EntryName := AEntryName;
  LEvent.VersionTag := AVersionTag;
  LEvent.Detail := ADetail;
  AddEvent(LEvent);
end;

procedure TSempareDwsTestHarness.AddScript(const AName, ASource: string);
begin
  FBridge.AddScript(AName, ASource);
end;

function TSempareDwsTestHarness.Call(const AScriptName, AEntryName: string): TValue;
begin
  result := Call(AScriptName, AEntryName, TValue.Empty);
end;

function TSempareDwsTestHarness.Call(const AScriptName, AEntryName: string; const APayload: TValue): TValue;
var
  LDispatch: ISempareDwsBridgeDispatch;
begin
  if not Supports(FBridge, ISempareDwsBridgeDispatch, LDispatch) then
    raise ETemplateDwsContractError.CreateContext('DWScript bridge dispatch is unavailable in the test harness.');
  result := LDispatch.Call(FCtx, AScriptName, AEntryName, APayload);
end;

constructor TSempareDwsTestHarness.Create(
  const ABridgeOptions: TTemplateDwsBridgeOptions;
  const ATemplateOptions: TTemplateEvaluationOptions
);
begin
  inherited Create;
  FCtx := Template.Context(ATemplateOptions);
  FBridge := CreateSempareDwsBridge(ABridgeOptions);
  FBridge.RegisterInto(FCtx);
end;

function TSempareDwsTestHarness.Eval(const ATemplate: string): string;
begin
  result := Template.Eval(FCtx, ATemplate);
end;

function TSempareDwsTestHarness.Eval(const ATemplate: string; const AData: TValue): string;
begin
  result := Template.Eval<TValue>(FCtx, ATemplate, AData);
end;

function TSempareDwsTestHarness.Render(const AScriptName, AEntryName: string): string;
begin
  result := Render(AScriptName, AEntryName, TValue.Empty);
end;

function TSempareDwsTestHarness.Render(const AScriptName, AEntryName: string; const APayload: TValue): string;
var
  LDispatch: ISempareDwsBridgeDispatch;
begin
  if not Supports(FBridge, ISempareDwsBridgeDispatch, LDispatch) then
    raise ETemplateDwsContractError.CreateContext('DWScript bridge dispatch is unavailable in the test harness.');
  result := LDispatch.Render(FCtx, AScriptName, AEntryName, APayload);
end;

procedure TSempareDwsTestHarness.SetDiagnostics(const AValue: ITemplateDwsDiagnostics);
begin
  FDiagnostics := AValue;
  if FBridge <> nil then
    FBridge.SetDiagnostics(AValue);
end;

end.
