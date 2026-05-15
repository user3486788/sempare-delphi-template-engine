(*%*************************************************************************************************
 *                 ___                                                                              *
 *                / __|  ___   _ __    _ __   __ _   _ _   ___                                      *
 *                \__ \ / -_) | ''  \  | ''_ \ / _` | | ''_| / -_)                                     *
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
unit Sempare.Template.DWS.Functions;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  System.Generics.Collections,
  System.Rtti,
  Sempare.Template.Context,
  Sempare.Template.StackFrame;

type
  /// <summary>
  /// DWScript helper functions that can be registered into a template context and called directly from Delphi-driven evaluations.
  /// </summary>
  TSempareDwsFunctions = class
  public
    /// <summary>
    /// Calls a named DWScript entry point and returns its value result.
    /// </summary>
    /// <param name="ACtx">Template context that owns the registered DWScript bridge.</param>
    /// <param name="AArgs">Arguments in the form `scriptName`, `entryName`, and optional payload.</param>
    class function DwsCall(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): TValue; static;
    /// <summary>
    /// Renders a named DWScript entry point to text.
    /// </summary>
    /// <param name="ACtx">Template context that owns the registered DWScript bridge.</param>
    /// <param name="AArgs">Arguments in the form `scriptName`, `entryName`, and optional payload.</param>
    class function DwsText(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string; static;
    /// <summary>
    /// Executes inline DWScript source and returns its value result.
    /// </summary>
    /// <param name="ACtx">Template context that owns the registered DWScript bridge.</param>
    /// <param name="AArgs">Arguments in the form `source`, `entryName`, and optional payload.</param>
    /// <remarks>Inline execution requires the `tdboAllowInlineScripts` option.</remarks>
    class function DwsInline(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): TValue; static;
    /// <summary>
    /// Executes inline DWScript source and converts the result to text.
    /// </summary>
    /// <param name="ACtx">Template context that owns the registered DWScript bridge.</param>
    /// <param name="AArgs">Arguments in the form `source`, `entryName`, and optional payload.</param>
    /// <remarks>Inline execution requires the `tdboAllowInlineScripts` option.</remarks>
    class function DwsInlineText(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string; static;
    /// <summary>
    /// Calls the default `Main` entry point in a named DWScript script.
    /// </summary>
    /// <param name="ACtx">Template context that owns the registered DWScript bridge.</param>
    /// <param name="AArgs">Arguments in the form `scriptName` and optional payload.</param>
    class function Dws(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): TValue; static;
    /// <summary>
    /// Renders the default `Render` entry point in a named DWScript script.
    /// </summary>
    /// <param name="ACtx">Template context that owns the registered DWScript bridge.</param>
    /// <param name="AArgs">Arguments in the form `scriptName` and optional payload.</param>
    class function DwsRender(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string; static;
    /// <summary>
    /// Renders the default `Render` entry point and returns trusted text without additional template encoding.
    /// </summary>
    /// <param name="ACtx">Template context that owns the registered DWScript bridge.</param>
    /// <param name="AArgs">Arguments in the form `scriptName` and optional payload.</param>
    /// <remarks>Trusted text output requires the `tdboAllowTrustedText` option.</remarks>
    class function DwsRaw(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string; static;
  end;

  /// <summary>
  /// Template-aware DWScript helper functions that can resolve the current root data from the Sempare stack frame.
  /// </summary>
  TSempareDwsTemplateFunctions = class
  public
    /// <summary>
    /// Calls a named DWScript entry point and preserves template root-data injection semantics.
    /// </summary>
    class function DwsCall(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue; static;
    /// <summary>
    /// Renders a named DWScript entry point to text while preserving template root-data injection semantics.
    /// </summary>
    class function DwsText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; static;
    /// <summary>
    /// Executes inline DWScript source with access to the current template root data when `tdboPassRootData` is enabled.
    /// </summary>
    class function DwsInline(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue; static;
    /// <summary>
    /// Executes inline DWScript source and converts the result to text with template root-data injection support.
    /// </summary>
    class function DwsInlineText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; static;
    /// <summary>
    /// Calls the default `Main` entry point in a named DWScript script with template-aware payload resolution.
    /// </summary>
    class function Dws(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue; static;
    /// <summary>
    /// Renders the default `Render` entry point in a named DWScript script with template-aware payload resolution.
    /// </summary>
    class function DwsRender(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; static;
    /// <summary>
    /// Renders trusted text from the default `Render` entry point with template-aware payload resolution.
    /// </summary>
    class function DwsRaw(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.TypInfo,
  Sempare.Template.DWS.Types;

const
  CDwsDefaultValueEntry = 'Main';
  CDwsDefaultTextEntry = 'Render';

type
  TDwsBridgeState = record
    Bridge: ISempareDwsBridge;
    Dispatch: ISempareDwsBridgeDispatch;
  end;

  TDwsNamedHelperArgs = record
    ScriptName: string;
    EntryName: string;
    Payload: TValue;
  end;

  TDwsInlineHelperArgs = record
    Source: string;
    EntryName: string;
    Payload: TValue;
  end;

  TDwsDefaultEntryArgs = record
    ScriptName: string;
    Payload: TValue;
  end;

function RequireBridgeState(const ACtx: ITemplateContext): TDwsBridgeState; forward;
function UnwrapValue(const AValue: TValue): TValue; forward;
function RequireStringArg(const AArgs: TArray<TValue>; const AIndex: integer; const ALabel: string): string; forward;
function ValidateNamedArgs(const AArgs: TArray<TValue>): TDwsNamedHelperArgs; forward;
function ValidateInlineArgs(const AArgs: TArray<TValue>): TDwsInlineHelperArgs; forward;
function ValidateDefaultEntryArgs(const AArgs: TArray<TValue>): TDwsDefaultEntryArgs; forward;
procedure RequireInlineEnabled(const AState: TDwsBridgeState); forward;
procedure RequireTrustedTextEnabled(const AState: TDwsBridgeState); forward;
function ResolveImplicitRoot(const AStackFrames: TObjectStack<TStackFrame>): TValue; forward;
function ResolveHelperPayload(const APayload: TValue; const AStackFrames: TObjectStack<TStackFrame>; const AOptions: TTemplateDwsBridgeOptions): TValue; forward;
function ExecuteDwsCall(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue; forward;
function ExecuteDwsText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; forward;
function ExecuteDwsInline(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue; forward;
function ExecuteDwsInlineText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; forward;
function ExecuteDwsDefault(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue; forward;
function ExecuteDwsRender(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; forward;
function ExecuteDwsRaw(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string; forward;

class function TSempareDwsFunctions.Dws(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): TValue;
begin
  Result := ExecuteDwsDefault(ACtx, nil, AArgs);
end;

class function TSempareDwsFunctions.DwsCall(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): TValue;
begin
  Result := ExecuteDwsCall(ACtx, nil, AArgs);
end;

class function TSempareDwsFunctions.DwsInline(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): TValue;
begin
  Result := ExecuteDwsInline(ACtx, nil, AArgs);
end;

class function TSempareDwsFunctions.DwsInlineText(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsInlineText(ACtx, nil, AArgs);
end;

class function TSempareDwsFunctions.DwsRaw(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsRaw(ACtx, nil, AArgs);
end;

class function TSempareDwsFunctions.DwsRender(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsRender(ACtx, nil, AArgs);
end;

class function TSempareDwsFunctions.DwsText(const ACtx: ITemplateContext; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsText(ACtx, nil, AArgs);
end;

class function TSempareDwsTemplateFunctions.Dws(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue;
begin
  Result := ExecuteDwsDefault(ACtx, AStackFrames, AArgs);
end;

class function TSempareDwsTemplateFunctions.DwsCall(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue;
begin
  Result := ExecuteDwsCall(ACtx, AStackFrames, AArgs);
end;

class function TSempareDwsTemplateFunctions.DwsInline(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue;
begin
  Result := ExecuteDwsInline(ACtx, AStackFrames, AArgs);
end;

class function TSempareDwsTemplateFunctions.DwsInlineText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsInlineText(ACtx, AStackFrames, AArgs);
end;

class function TSempareDwsTemplateFunctions.DwsRaw(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsRaw(ACtx, AStackFrames, AArgs);
end;

class function TSempareDwsTemplateFunctions.DwsRender(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsRender(ACtx, AStackFrames, AArgs);
end;

class function TSempareDwsTemplateFunctions.DwsText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
begin
  Result := ExecuteDwsText(ACtx, AStackFrames, AArgs);
end;

function ExecuteDwsCall(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue;
var
  LState: TDwsBridgeState;
  LArgs: TDwsNamedHelperArgs;
begin
  LState := RequireBridgeState(ACtx);
  LArgs := ValidateNamedArgs(AArgs);
  LArgs.Payload := ResolveHelperPayload(LArgs.Payload, AStackFrames, LState.Bridge.Options);
  Exit(LState.Dispatch.Call(ACtx, LArgs.ScriptName, LArgs.EntryName, LArgs.Payload));
end;

function ExecuteDwsDefault(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue;
var
  LArgs: TDwsDefaultEntryArgs;
  LState: TDwsBridgeState;
begin
  LState := RequireBridgeState(ACtx);
  LArgs := ValidateDefaultEntryArgs(AArgs);
  LArgs.Payload := ResolveHelperPayload(LArgs.Payload, AStackFrames, LState.Bridge.Options);
  Exit(LState.Dispatch.Call(ACtx, LArgs.ScriptName, CDwsDefaultValueEntry, LArgs.Payload));
end;

function ExecuteDwsInline(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): TValue;
var
  LArgs: TDwsInlineHelperArgs;
  LState: TDwsBridgeState;
begin
  LState := RequireBridgeState(ACtx);
  RequireInlineEnabled(LState);
  LArgs := ValidateInlineArgs(AArgs);
  LArgs.Payload := ResolveHelperPayload(LArgs.Payload, AStackFrames, LState.Bridge.Options);
  Exit(LState.Dispatch.CallInline(ACtx, LArgs.Source, LArgs.EntryName, LArgs.Payload));
end;

function ExecuteDwsInlineText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
var
  LArgs: TDwsInlineHelperArgs;
  LState: TDwsBridgeState;
begin
  LState := RequireBridgeState(ACtx);
  RequireInlineEnabled(LState);
  LArgs := ValidateInlineArgs(AArgs);
  LArgs.Payload := ResolveHelperPayload(LArgs.Payload, AStackFrames, LState.Bridge.Options);
  Exit(LState.Dispatch.RenderInline(ACtx, LArgs.Source, LArgs.EntryName, LArgs.Payload));
end;

function ExecuteDwsRaw(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
var
  LArgs: TDwsNamedHelperArgs;
  LState: TDwsBridgeState;
begin
  LState := RequireBridgeState(ACtx);
  RequireTrustedTextEnabled(LState);
  LArgs := ValidateNamedArgs(AArgs);
  LArgs.Payload := ResolveHelperPayload(LArgs.Payload, AStackFrames, LState.Bridge.Options);
  Exit(LState.Dispatch.Render(ACtx, LArgs.ScriptName, LArgs.EntryName, LArgs.Payload));
end;

function ExecuteDwsRender(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
var
  LArgs: TDwsDefaultEntryArgs;
  LState: TDwsBridgeState;
begin
  LState := RequireBridgeState(ACtx);
  LArgs := ValidateDefaultEntryArgs(AArgs);
  LArgs.Payload := ResolveHelperPayload(LArgs.Payload, AStackFrames, LState.Bridge.Options);
  Exit(LState.Dispatch.Render(ACtx, LArgs.ScriptName, CDwsDefaultTextEntry, LArgs.Payload));
end;

function ExecuteDwsText(const ACtx: ITemplateContext; const AStackFrames: TObjectStack<TStackFrame>; const AArgs: TArray<TValue>): string;
var
  LState: TDwsBridgeState;
  LArgs: TDwsNamedHelperArgs;
begin
  LState := RequireBridgeState(ACtx);
  LArgs := ValidateNamedArgs(AArgs);
  LArgs.Payload := ResolveHelperPayload(LArgs.Payload, AStackFrames, LState.Bridge.Options);
  Exit(LState.Dispatch.Render(ACtx, LArgs.ScriptName, LArgs.EntryName, LArgs.Payload));
end;

function RequireBridgeState(const ACtx: ITemplateContext): TDwsBridgeState;
var
  LValue: TValue;
begin
  if (ACtx = nil) or not ACtx.TryGetVariable(TemplateDwsBridgeContextKey, LValue) then
    raise ETemplateDwsContractError.CreateContext('No DWScript bridge is registered in the current template context.');

  if not LValue.IsType<ISempareDwsBridge> then
    raise ETemplateDwsContractError.CreateContext('The registered DWScript bridge context value is invalid.');
  Result.Bridge := LValue.AsType<ISempareDwsBridge>;

  if not Supports(Result.Bridge, ISempareDwsBridgeDispatch, Result.Dispatch) then
    raise ETemplateDwsContractError.CreateContext('The registered DWScript bridge does not expose dispatch operations.');
end;

function ResolveHelperPayload(const APayload: TValue; const AStackFrames: TObjectStack<TStackFrame>; const AOptions: TTemplateDwsBridgeOptions): TValue;
begin
  if not APayload.IsEmpty then
    Exit(APayload);
  if not (tdboPassRootData in AOptions) then
    Exit(TValue.Empty);
  Exit(ResolveImplicitRoot(AStackFrames));
end;

function ResolveImplicitRoot(const AStackFrames: TObjectStack<TStackFrame>): TValue;
var
  LFrame: TStackFrame;
begin
  Result := TValue.Empty;
  if (AStackFrames = nil) or (AStackFrames.Count = 0) then
    Exit;
  LFrame := AStackFrames.Peek;
  if LFrame = nil then
    Exit;
  Result := LFrame.Root;
end;

procedure RequireInlineEnabled(const AState: TDwsBridgeState);
begin
  if not (tdboAllowInlineScripts in AState.Bridge.Options) then
    raise ETemplateDwsContractError.CreateContext('Inline DWScript helpers are disabled. Enable tdboAllowInlineScripts for development mode.');
end;

procedure RequireTrustedTextEnabled(const AState: TDwsBridgeState);
begin
  if not (tdboAllowTrustedText in AState.Bridge.Options) then
    raise ETemplateDwsContractError.CreateContext('Trusted/raw DWScript text is disabled. Enable tdboAllowTrustedText explicitly.');
end;

function RequireStringArg(const AArgs: TArray<TValue>; const AIndex: integer; const ALabel: string): string;
var
  LTypeName: string;
  LValue: TValue;
begin
  LValue := UnwrapValue(AArgs[AIndex]);
  case LValue.Kind of
    tkString, tkLString, tkWString, tkUString, tkChar, tkWChar:
      begin
        Result := LValue.AsString;
        if Result = '' then
          raise ETemplateDwsContractError.CreateContext(
            Format('DWScript helper argument %d (%s) must not be empty.', [AIndex, ALabel])
          );
        Exit;
      end;
  end;

  if LValue.TypeInfo <> nil then
    LTypeName := GetTypeName(LValue.TypeInfo)
  else
    LTypeName := 'unknown';

  raise ETemplateDwsContractError.CreateContext(
    Format('DWScript helper argument %d (%s) must be a string, got %s.', [AIndex, ALabel, LTypeName])
  );
end;

function UnwrapValue(const AValue: TValue): TValue;
begin
  if AValue.TypeInfo = TypeInfo(TValue) then
    Exit(UnwrapValue(AValue.AsType<TValue>));
  Exit(AValue);
end;

function ValidateDefaultEntryArgs(const AArgs: TArray<TValue>): TDwsDefaultEntryArgs;
begin
  if not (Length(AArgs) in [1, 2]) then
    raise ETemplateDwsContractError.CreateContext(
      Format('DWScript default-entry helpers expect 1 or 2 arguments, got %d.', [Length(AArgs)])
    );

  Result.ScriptName := RequireStringArg(AArgs, 0, 'script name');
  if Length(AArgs) > 1 then
    Result.Payload := UnwrapValue(AArgs[1])
  else
    Result.Payload := TValue.Empty;
end;

function ValidateInlineArgs(const AArgs: TArray<TValue>): TDwsInlineHelperArgs;
begin
  if not (Length(AArgs) in [2, 3]) then
    raise ETemplateDwsContractError.CreateContext(
      Format('DWScript inline helpers expect 2 or 3 arguments, got %d.', [Length(AArgs)])
    );

  Result.Source := RequireStringArg(AArgs, 0, 'inline source');
  Result.EntryName := RequireStringArg(AArgs, 1, 'entry name');
  if Length(AArgs) > 2 then
    Result.Payload := UnwrapValue(AArgs[2])
  else
    Result.Payload := TValue.Empty;
end;

function ValidateNamedArgs(const AArgs: TArray<TValue>): TDwsNamedHelperArgs;
begin
  if not (Length(AArgs) in [2, 3]) then
    raise ETemplateDwsContractError.CreateContext(
      Format('DWScript helpers expect 2 or 3 arguments, got %d.', [Length(AArgs)])
    );

  Result.ScriptName := RequireStringArg(AArgs, 0, 'script name');
  Result.EntryName := RequireStringArg(AArgs, 1, 'entry name');
  if Length(AArgs) > 2 then
    Result.Payload := UnwrapValue(AArgs[2])
  else
    Result.Payload := TValue.Empty;
end;

end.
