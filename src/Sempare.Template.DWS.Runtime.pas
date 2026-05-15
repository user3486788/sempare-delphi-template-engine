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
unit Sempare.Template.DWS.Runtime;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Types,
  dwsComp;

type
  /// <summary>
  /// Allows callers to customize the DWScript engine instance before a script is compiled.
  /// </summary>
  ITemplateDwsRuntimeConfigurator = interface
    ['{37D1721B-9199-4E04-83E5-AE9F3A0E7B86}']
    /// <summary>
    /// Applies additional DWScript units, connectors, or engine options to a fresh `TDelphiWebScript`.
    /// </summary>
    /// <param name="AScript">Engine instance that will compile and execute bridge scripts.</param>
    procedure ConfigureScript(const AScript: TDelphiWebScript);
  end;

/// <summary>
/// Creates the default DWScript runtime used by the bridge.
/// </summary>
/// <returns>A runtime implementation that compiles named scripts and invokes DWScript entries.</returns>
function CreateDefaultDwsRuntime: ITemplateDwsRuntime; overload;

/// <summary>
/// Creates the default DWScript runtime and lets the caller customize each engine instance before compilation.
/// </summary>
/// <param name="AConfigurator">Optional runtime configurator for extra DWScript units or engine settings.</param>
/// <returns>A runtime implementation that uses the supplied configurator for each script engine.</returns>
function CreateDefaultDwsRuntime(const AConfigurator: ITemplateDwsRuntimeConfigurator): ITemplateDwsRuntime; overload;

implementation

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Variants,
  System.Diagnostics,
  System.Generics.Collections,
  Sempare.Template.Context,
  Sempare.Template.Util,
  dwsErrors,
  dwsExprs,
  dwsInfo,
  dwsJSON,
  dwsJSONConnector;

type
  ITemplateDwsCompiledScriptInternal = interface(ITemplateDwsCompiledScript)
    ['{33D36389-3A20-4DFE-B260-0B6AEE669D2D}']
    function GetDwsProgram: IdwsProgram;
    property DwsProgram: IdwsProgram read GetDwsProgram;
  end;

  TTemplateDwsExecutionState = class
  public
    Context: ITemplateContext;
    HostServices: ITemplateDwsHostServices;
    Options: TTemplateDwsBridgeOptions;
    constructor Create(
      const ACtx: ITemplateContext;
      const AHostServices: ITemplateDwsHostServices;
      const AOptions: TTemplateDwsBridgeOptions
    );
  end;

  TTemplateDwsCompiledScript = class(TInterfacedObject, ITemplateDwsCompiledScript, ITemplateDwsCompiledScriptInternal)
  private
    FScriptName: string;
    FVersionTag: string;
    FEngine: TDelphiWebScript;
    FProgram: IdwsProgram;
    function GetDwsProgram: IdwsProgram;
    function GetScriptName: string;
    function GetVersionTag: string;
  public
    constructor Create(const AScriptName, AVersionTag: string; AEngine: TDelphiWebScript; const AProgram: IdwsProgram);
    destructor Destroy; override;
  end;

  TTemplateDwsRuntime = class(TInterfacedObject, ITemplateDwsRuntime)
  private
    FDiagnostics: ITemplateDwsDiagnostics;
    FConfigurator: ITemplateDwsRuntimeConfigurator;
    function CompileDiagnostic(const AProgram: IdwsProgram): string;
    procedure ConfigureHostUnit(const AScript: TDelphiWebScript);
    function RequireExecutionState(const AInfo: TProgramInfo): TTemplateDwsExecutionState;
    procedure NotifyRuntimeEvent(
      const AKind: TTemplateDwsRuntimeEventKind;
      const AScriptName, AEntryName, AVersionTag, ADetail: string
    );
    procedure NotifyProfileEvent(
      const AKind: TTemplateDwsProfileEventKind;
      const AScriptName, AEntryName, AVersionTag: string;
      const AElapsedMs: int64
    );
    function RuntimeDiagnostic(const AExecution: IdwsProgramExecution): string;
    function RequireCompiledScript(const ACompiled: ITemplateDwsCompiledScript): ITemplateDwsCompiledScriptInternal;
    function TemplateValueToDwsVariant(
      const AValue: TValue;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): Variant;
    function TemplateValueToDwsJson(
      const AValue: TValue;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): TdwsJSONValue;
    function JsonValueToTemplateValue(const AValue: TdwsJSONValue): TValue;
    function VariantArrayToTemplateValue(
      const AValue: Variant;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): TValue;
    function VariantToTemplateValue(
      const AValue: Variant;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): TValue;
    function ExecuteEntryValue(
      const ACompiled: ITemplateDwsCompiledScript;
      const AEntryName: string;
      const APayload: TValue;
      const ACtx: ITemplateContext;
      const AHostServices: ITemplateDwsHostServices;
      const AOptions: TTemplateDwsBridgeOptions
    ): TValue;
    function ScalarToString(
      const AValue: TValue;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): string;
    procedure HostTemplateExistsEval(Info: TProgramInfo);
    procedure HostResolveTemplateEval(Info: TProgramInfo);
    procedure HostResolveTemplateWithDataEval(Info: TProgramInfo);
    procedure HostGetVarEval(Info: TProgramInfo);
    procedure HostSetVarEval(Info: TProgramInfo);
  public
    constructor Create(const AConfigurator: ITemplateDwsRuntimeConfigurator);
    function CompileNamed(
      const AName: string;
      const ASource: string;
      const AVersionTag: string;
      const AEntryName: string = ''
    ): ITemplateDwsCompiledScript;
    function CallEntry(
      const ACompiled: ITemplateDwsCompiledScript;
      const AEntryName: string;
      const APayload: TValue;
      const ACtx: ITemplateContext;
      const AHostServices: ITemplateDwsHostServices;
      const AOptions: TTemplateDwsBridgeOptions
    ): TValue;
    function RenderEntry(
      const ACompiled: ITemplateDwsCompiledScript;
      const AEntryName: string;
      const APayload: TValue;
      const ACtx: ITemplateContext;
      const AHostServices: ITemplateDwsHostServices;
      const AOptions: TTemplateDwsBridgeOptions
    ): string;
    procedure SetDiagnostics(const ADiagnostics: ITemplateDwsDiagnostics);
  end;

function CreateDefaultDwsRuntime: ITemplateDwsRuntime;
begin
  result := TTemplateDwsRuntime.Create(nil);
end;

function CreateDefaultDwsRuntime(const AConfigurator: ITemplateDwsRuntimeConfigurator): ITemplateDwsRuntime;
begin
  result := TTemplateDwsRuntime.Create(AConfigurator);
end;

constructor TTemplateDwsRuntime.Create(const AConfigurator: ITemplateDwsRuntimeConfigurator);
begin
  inherited Create;
  FConfigurator := AConfigurator;
end;

constructor TTemplateDwsExecutionState.Create(
  const ACtx: ITemplateContext;
  const AHostServices: ITemplateDwsHostServices;
  const AOptions: TTemplateDwsBridgeOptions
);
begin
  inherited Create;
  Context := ACtx;
  HostServices := AHostServices;
  Options := AOptions;
end;

constructor TTemplateDwsCompiledScript.Create(const AScriptName, AVersionTag: string; AEngine: TDelphiWebScript; const AProgram: IdwsProgram);
begin
  inherited Create;
  FScriptName := AScriptName;
  FVersionTag := AVersionTag;
  FEngine := AEngine;
  FProgram := AProgram;
end;

destructor TTemplateDwsCompiledScript.Destroy;
begin
  FProgram := nil;
  FEngine.Free;
  inherited;
end;

function TTemplateDwsCompiledScript.GetDwsProgram: IdwsProgram;
begin
  exit(FProgram);
end;

function TTemplateDwsCompiledScript.GetScriptName: string;
begin
  exit(FScriptName);
end;

function TTemplateDwsCompiledScript.GetVersionTag: string;
begin
  exit(FVersionTag);
end;

function TTemplateDwsRuntime.CallEntry(
  const ACompiled: ITemplateDwsCompiledScript;
  const AEntryName: string;
  const APayload: TValue;
  const ACtx: ITemplateContext;
  const AHostServices: ITemplateDwsHostServices;
  const AOptions: TTemplateDwsBridgeOptions
): TValue;
begin
  exit(ExecuteEntryValue(ACompiled, AEntryName, APayload, ACtx, AHostServices, AOptions));
end;

function TTemplateDwsRuntime.CompileDiagnostic(const AProgram: IdwsProgram): string;
begin
  if (AProgram = nil) or (AProgram.Msgs = nil) or (AProgram.Msgs.Count = 0) then
    exit('');
  result := Trim(AProgram.Msgs.AsInfo);
end;

function TTemplateDwsRuntime.CompileNamed(
  const AName: string;
  const ASource: string;
  const AVersionTag: string;
  const AEntryName: string
): ITemplateDwsCompiledScript;
var
  LScript: TDelphiWebScript;
  LJsonModule: TdwsJSONLibModule;
  LProgram: IdwsProgram;
  LDiagnostic: string;
  LStopWatch: TStopWatch;
begin
  NotifyRuntimeEvent(tdrekCompileStart, AName, AEntryName, AVersionTag, '');
  LStopWatch := TStopWatch.StartNew;
  LScript := TDelphiWebScript.Create(nil);
  LProgram := nil;
  try
    LJsonModule := TdwsJSONLibModule.Create(LScript);
    LJsonModule.Script := LScript;
    ConfigureHostUnit(LScript);
    if FConfigurator <> nil then
      FConfigurator.ConfigureScript(LScript);

    LProgram := LScript.Compile(ASource, AName);
    LDiagnostic := CompileDiagnostic(LProgram);
    if (LProgram = nil) or LProgram.Msgs.HasErrors then
    begin
      NotifyRuntimeEvent(tdrekCompileFailure, AName, AEntryName, AVersionTag, LDiagnostic);
      raise ETemplateDwsCompileError.CreateContext(
        'DWScript compilation failed. ' + LDiagnostic,
        AName,
        AEntryName,
        AVersionTag
      );
    end;

    NotifyRuntimeEvent(tdrekCompileSuccess, AName, AEntryName, AVersionTag, '');
    NotifyProfileEvent(tdpekCompile, AName, AEntryName, AVersionTag, LStopWatch.ElapsedMilliseconds);
    Result := TTemplateDwsCompiledScript.Create(AName, AVersionTag, LScript, LProgram);
    LScript := nil;
  finally
    LProgram := nil;
    LScript.Free;
  end;
end;

procedure TTemplateDwsRuntime.ConfigureHostUnit(const AScript: TDelphiWebScript);
var
  LUnit: TdwsUnit;
  LFunction: TdwsFunction;
begin
  LUnit := TdwsUnit.Create(AScript);
  LUnit.UnitName := 'SempareHost';
  LUnit.Script := AScript;

  LFunction := LUnit.Functions.Add('TemplateExists', 'Boolean');
  LFunction.Parameters.Add('Name', 'String');
  LFunction.OnEval := HostTemplateExistsEval;

  LFunction := LUnit.Functions.Add('ResolveTemplate', 'String');
  LFunction.Overloaded := true;
  LFunction.Parameters.Add('Name', 'String');
  LFunction.OnEval := HostResolveTemplateEval;

  LFunction := LUnit.Functions.Add('ResolveTemplate', 'String');
  LFunction.Overloaded := true;
  LFunction.Parameters.Add('Name', 'String');
  LFunction.Parameters.Add('Data', 'Variant');
  LFunction.OnEval := HostResolveTemplateWithDataEval;

  LFunction := LUnit.Functions.Add('GetVar', 'Variant');
  LFunction.Parameters.Add('Name', 'String');
  LFunction.OnEval := HostGetVarEval;

  LFunction := LUnit.Functions.Add('SetVar', 'Boolean');
  LFunction.Parameters.Add('Name', 'String');
  LFunction.Parameters.Add('Value', 'Variant');
  LFunction.OnEval := HostSetVarEval;
end;

function TTemplateDwsRuntime.ExecuteEntryValue(
  const ACompiled: ITemplateDwsCompiledScript;
  const AEntryName: string;
  const APayload: TValue;
  const ACtx: ITemplateContext;
  const AHostServices: ITemplateDwsHostServices;
  const AOptions: TTemplateDwsBridgeOptions
): TValue;
var
  LCompiled: ITemplateDwsCompiledScriptInternal;
  LExecution: IdwsProgramExecution;
  LEntryInfo: IInfo;
  LResultInfo: IInfo;
  LParams: array of Variant;
  LVersionTag: string;
  LPayloadVariant: Variant;
  LDiagnostic: string;
  LExecutionState: TTemplateDwsExecutionState;
  LStopWatch: TStopWatch;
begin
  LCompiled := RequireCompiledScript(ACompiled);
  LVersionTag := LCompiled.VersionTag;
  NotifyRuntimeEvent(tdrekCallStart, LCompiled.ScriptName, AEntryName, LVersionTag, '');
  LStopWatch := TStopWatch.StartNew;

  LExecution := LCompiled.DwsProgram.BeginNewExecution;
  LExecutionState := TTemplateDwsExecutionState.Create(ACtx, AHostServices, AOptions);
  try
    LExecution.UserObject := LExecutionState;
    if LExecution.Msgs.HasErrors then
      raise ETemplateDwsRuntimeError.CreateContext(
        'DWScript runtime setup failed. ' + RuntimeDiagnostic(LExecution),
        LCompiled.ScriptName,
        AEntryName,
        LVersionTag
      );

    try
      LEntryInfo := LExecution.Info.Func[AEntryName];
      if LEntryInfo = nil then
        raise ETemplateDwsContractError.CreateContext(
          'DWScript entry was not found.',
          LCompiled.ScriptName,
          AEntryName,
          LVersionTag
        );
    except
      on E: Exception do
        raise ETemplateDwsContractError.CreateContext(
          'DWScript entry lookup failed. ' + E.Message,
          LCompiled.ScriptName,
          AEntryName,
          LVersionTag
        );
    end;

    try
      if APayload.IsEmpty then
      begin
        LResultInfo := LEntryInfo.Call;
      end
      else
      begin
        SetLength(LParams, 1);
        LPayloadVariant := TemplateValueToDwsVariant(APayload, LCompiled.ScriptName, AEntryName, LVersionTag);
        LParams[0] := LPayloadVariant;
        LResultInfo := LEntryInfo.Call(LParams);
      end;
    except
      on E: Exception do
      begin
        LDiagnostic := RuntimeDiagnostic(LExecution);
        if LDiagnostic = '' then
          LDiagnostic := E.Message;
        NotifyRuntimeEvent(tdrekCallFailure, LCompiled.ScriptName, AEntryName, LVersionTag, LDiagnostic);
        raise ETemplateDwsRuntimeError.CreateContext(
          'DWScript entry execution failed. ' + LDiagnostic,
          LCompiled.ScriptName,
          AEntryName,
          LVersionTag
        );
      end;
    end;

    if LExecution.Msgs.HasErrors then
    begin
      LDiagnostic := RuntimeDiagnostic(LExecution);
      NotifyRuntimeEvent(tdrekCallFailure, LCompiled.ScriptName, AEntryName, LVersionTag, LDiagnostic);
      raise ETemplateDwsRuntimeError.CreateContext(
        'DWScript entry execution failed. ' + LDiagnostic,
        LCompiled.ScriptName,
        AEntryName,
        LVersionTag
      );
    end;

    if LResultInfo = nil then
    begin
      NotifyRuntimeEvent(tdrekCallSuccess, LCompiled.ScriptName, AEntryName, LVersionTag, '');
      NotifyProfileEvent(tdpekCall, LCompiled.ScriptName, AEntryName, LVersionTag, LStopWatch.ElapsedMilliseconds);
      exit(TValue.Empty);
    end;

    try
      result := VariantToTemplateValue(LResultInfo.Value, LCompiled.ScriptName, AEntryName, LVersionTag);
    except
      on E: Exception do
      begin
        LDiagnostic := Format(
          'DWScript result conversion failed (VarType=%d). %s',
          [VarType(LResultInfo.Value), E.Message]
        );
        NotifyRuntimeEvent(tdrekCallFailure, LCompiled.ScriptName, AEntryName, LVersionTag, LDiagnostic);
        raise ETemplateDwsMarshalError.CreateContext(
          LDiagnostic,
          LCompiled.ScriptName,
          AEntryName,
          LVersionTag,
          AOptions
        );
      end;
    end;
    NotifyRuntimeEvent(tdrekCallSuccess, LCompiled.ScriptName, AEntryName, LVersionTag, '');
    NotifyProfileEvent(tdpekCall, LCompiled.ScriptName, AEntryName, LVersionTag, LStopWatch.ElapsedMilliseconds);
  finally
    LExecution.UserObject := nil;
    LExecution.EndProgram;
    LExecution := nil;
    LExecutionState.Free;
  end;
end;

procedure TTemplateDwsRuntime.HostGetVarEval(Info: TProgramInfo);
var
  LState: TTemplateDwsExecutionState;
  LValue: TValue;
begin
  LState := RequireExecutionState(Info);
  if not Assigned(LState.HostServices) then
    raise ETemplateDwsContractError.CreateContext('DWScript host services are not configured.');

  if LState.HostServices.TryGetVar(LState.Context, Info.ParamAsString[0], LValue) then
    Info.ResultAsVariant := TemplateValueToDwsVariant(LValue, '[host]', 'GetVar', '')
  else
    Info.ResultAsVariant := Unassigned;
end;

procedure TTemplateDwsRuntime.HostResolveTemplateEval(Info: TProgramInfo);
var
  LState: TTemplateDwsExecutionState;
begin
  LState := RequireExecutionState(Info);
  if not Assigned(LState.HostServices) then
    raise ETemplateDwsContractError.CreateContext('DWScript host services are not configured.');

  Info.ResultAsString := LState.HostServices.ResolveTemplate(LState.Context, Info.ParamAsString[0], TValue.Empty);
end;

procedure TTemplateDwsRuntime.HostResolveTemplateWithDataEval(Info: TProgramInfo);
var
  LState: TTemplateDwsExecutionState;
  LData: TValue;
begin
  LState := RequireExecutionState(Info);
  if not Assigned(LState.HostServices) then
    raise ETemplateDwsContractError.CreateContext('DWScript host services are not configured.');

  LData := VariantToTemplateValue(Info.ParamAsVariant[1], '[host]', 'ResolveTemplate', '');
  Info.ResultAsString := LState.HostServices.ResolveTemplate(LState.Context, Info.ParamAsString[0], LData);
end;

procedure TTemplateDwsRuntime.HostSetVarEval(Info: TProgramInfo);
var
  LState: TTemplateDwsExecutionState;
  LValue: TValue;
begin
  LState := RequireExecutionState(Info);
  if not Assigned(LState.HostServices) then
    raise ETemplateDwsContractError.CreateContext('DWScript host services are not configured.');
  if tdboDisallowContextMutation in LState.Options then
    raise ETemplateDwsContractError.CreateContext('DWScript host-service mutation is disabled by bridge options.');

  LValue := VariantToTemplateValue(Info.ParamAsVariant[1], '[host]', 'SetVar', '');
  LState.HostServices.SetVar(LState.Context, Info.ParamAsString[0], LValue);
  Info.ResultAsBoolean := true;
end;

procedure TTemplateDwsRuntime.HostTemplateExistsEval(Info: TProgramInfo);
var
  LState: TTemplateDwsExecutionState;
begin
  LState := RequireExecutionState(Info);
  if not Assigned(LState.HostServices) then
    raise ETemplateDwsContractError.CreateContext('DWScript host services are not configured.');

  Info.ResultAsBoolean := LState.HostServices.TemplateExists(LState.Context, Info.ParamAsString[0]);
end;

function TTemplateDwsRuntime.JsonValueToTemplateValue(const AValue: TdwsJSONValue): TValue;
var
  LIdx: integer;
  LMap: TMap;
  LArray: TArray<TValue>;
begin
  if AValue = nil then
    exit(TValue.Empty);

  case AValue.ValueType of
    jvtUndefined:
      exit(TValue.Empty);

    jvtNull:
      exit(TValue.From<Pointer>(nil));

    jvtObject:
      begin
        LMap := TMap.Create;
        for LIdx := 0 to AValue.ElementCount - 1 do
          LMap.Add(AValue.Names[LIdx], JsonValueToTemplateValue(AValue.Elements[LIdx]));
        exit(TValue.From<TMap>(LMap));
      end;

    jvtArray:
      begin
        SetLength(LArray, AValue.ElementCount);
        for LIdx := 0 to AValue.ElementCount - 1 do
          LArray[LIdx] := JsonValueToTemplateValue(AValue.Elements[LIdx]);
        exit(TValue.From<TArray<TValue>>(LArray));
      end;

    jvtString:
      exit(AValue.AsString);

    jvtNumber:
      exit(FloatToTValue(AValue.AsNumber));

    jvtInt64:
      exit(AValue.AsInteger);

    jvtBoolean:
      exit(AValue.AsBoolean);
  end;

  exit(TValue.Empty);
end;

procedure TTemplateDwsRuntime.NotifyProfileEvent(
  const AKind: TTemplateDwsProfileEventKind;
  const AScriptName, AEntryName, AVersionTag: string;
  const AElapsedMs: int64
);
begin
  if FDiagnostics <> nil then
    FDiagnostics.ProfileEvent(AKind, AScriptName, AEntryName, AVersionTag, AElapsedMs);
end;

procedure TTemplateDwsRuntime.NotifyRuntimeEvent(
  const AKind: TTemplateDwsRuntimeEventKind;
  const AScriptName, AEntryName, AVersionTag, ADetail: string
);
begin
  if FDiagnostics <> nil then
    FDiagnostics.RuntimeEvent(AKind, AScriptName, AEntryName, AVersionTag, ADetail);
end;

function TTemplateDwsRuntime.RenderEntry(
  const ACompiled: ITemplateDwsCompiledScript;
  const AEntryName: string;
  const APayload: TValue;
  const ACtx: ITemplateContext;
  const AHostServices: ITemplateDwsHostServices;
  const AOptions: TTemplateDwsBridgeOptions
): string;
var
  LValue: TValue;
  LStopWatch: TStopWatch;
begin
  LStopWatch := TStopWatch.StartNew;
  LValue := ExecuteEntryValue(ACompiled, AEntryName, APayload, ACtx, AHostServices, AOptions);
  result := ScalarToString(LValue, ACompiled.ScriptName, AEntryName, ACompiled.VersionTag);
  NotifyProfileEvent(tdpekRender, ACompiled.ScriptName, AEntryName, ACompiled.VersionTag, LStopWatch.ElapsedMilliseconds);
end;

function TTemplateDwsRuntime.RequireCompiledScript(const ACompiled: ITemplateDwsCompiledScript): ITemplateDwsCompiledScriptInternal;
begin
  if not Supports(ACompiled, ITemplateDwsCompiledScriptInternal, result) then
    raise ETemplateDwsContractError.CreateContext('Compiled DWScript artifact is invalid.');
end;

function TTemplateDwsRuntime.RequireExecutionState(const AInfo: TProgramInfo): TTemplateDwsExecutionState;
begin
  result := nil;
  if (AInfo = nil) or (AInfo.Execution = nil) then
    raise ETemplateDwsContractError.CreateContext('DWScript host execution context is unavailable.');
  if not (AInfo.Execution.UserObject is TTemplateDwsExecutionState) then
    raise ETemplateDwsContractError.CreateContext('DWScript host execution state is invalid.');
  result := TTemplateDwsExecutionState(AInfo.Execution.UserObject);
end;

function TTemplateDwsRuntime.RuntimeDiagnostic(const AExecution: IdwsProgramExecution): string;
begin
  if (AExecution = nil) or (AExecution.Msgs = nil) or (AExecution.Msgs.Count = 0) then
    exit('');
  result := Trim(AExecution.Msgs.AsInfo);
end;

function TTemplateDwsRuntime.ScalarToString(
  const AValue: TValue;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): string;
var
  LFormatSettings: TFormatSettings;
begin
  if AValue.IsEmpty then
    exit('');

  case AValue.Kind of
    tkString, tkLString, tkWString, tkUString, tkChar, tkWChar:
      exit(AValue.AsString);
    tkInteger, tkInt64:
      exit(IntToStr(AValue.AsInt64));
    tkFloat:
      begin
        LFormatSettings := TFormatSettings.Create;
        LFormatSettings.DecimalSeparator := '.';
        exit(FloatToStr(AValue.AsExtended, LFormatSettings));
      end;
    tkEnumeration:
      begin
        if AValue.TypeInfo = TypeInfo(boolean) then
        begin
          if AValue.AsBoolean then
            exit('true')
          else
            exit('false');
        end;
        exit(IntToStr(AValue.AsInt64));
      end;
    tkPointer:
      if AValue.AsType<Pointer> = nil then
        exit('');
  end;

  raise ETemplateDwsMarshalError.CreateContext(
    'DWScript render entry returned a non-text-compatible result.',
    AScriptName,
    AEntryName,
    AVersionTag
  );
end;

procedure TTemplateDwsRuntime.SetDiagnostics(const ADiagnostics: ITemplateDwsDiagnostics);
begin
  FDiagnostics := ADiagnostics;
end;

function TTemplateDwsRuntime.TemplateValueToDwsJson(
  const AValue: TValue;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): TdwsJSONValue;
var
  LMap: TMap;
  LArray: TArray<TValue>;
  LItems: TArray<TPair<string, TValue>>;
  LIdx: integer;
  LJsonObject: TdwsJSONObject;
  LJsonArray: TdwsJSONArray;
  LVariant: Variant;
begin
  if AValue.IsType<TMap> then
  begin
    LMap := AValue.AsType<TMap>;
    LJsonObject := TdwsJSONObject.Create;
    LItems := LMap.GetItems;
    for LIdx := 0 to High(LItems) do
      LJsonObject.Add(LItems[LIdx].Key, TemplateValueToDwsJson(LItems[LIdx].Value, AScriptName, AEntryName, AVersionTag));
    exit(LJsonObject);
  end;

  if AValue.Kind in [tkDynArray, tkArray] then
  begin
    LArray := AValue.AsType<TArray<TValue>>;
    LJsonArray := TdwsJSONArray.Create;
    for LIdx := 0 to High(LArray) do
      LJsonArray.Add(TemplateValueToDwsJson(LArray[LIdx], AScriptName, AEntryName, AVersionTag));
    exit(LJsonArray);
  end;

  if AValue.Kind = tkVariant then
  begin
    LVariant := AValue.AsVariant;
    if VarIsArray(LVariant) then
      exit(TemplateValueToDwsJson(VariantArrayToTemplateValue(LVariant, AScriptName, AEntryName, AVersionTag), AScriptName, AEntryName, AVersionTag));
    exit(TemplateValueToDwsJson(TValue.FromVariant(LVariant), AScriptName, AEntryName, AVersionTag));
  end;

  case AValue.Kind of
    tkString, tkLString, tkWString, tkUString, tkChar, tkWChar:
      begin
        result := TdwsJSONImmediate.Create;
        result.AsString := AValue.AsString;
        exit;
      end;

    tkInteger, tkInt64:
      begin
        result := TdwsJSONImmediate.Create;
        result.AsInteger := AValue.AsInt64;
        exit;
      end;

    tkFloat:
      begin
        result := TdwsJSONImmediate.Create;
        result.AsNumber := AValue.AsExtended;
        exit;
      end;

    tkEnumeration:
      begin
        result := TdwsJSONImmediate.Create;
        if AValue.TypeInfo = TypeInfo(boolean) then
          result.AsBoolean := AValue.AsBoolean
        else
          result.AsInteger := AValue.AsInt64;
        exit;
      end;

    tkPointer:
      begin
        if AValue.AsType<Pointer> = nil then
          exit(TdwsJSONImmediate.CreateNull);
      end;

    tkClass:
      begin
        if AValue.AsObject = nil then
          exit(TdwsJSONImmediate.CreateNull);
      end;
  end;

  raise ETemplateDwsMarshalError.CreateContext(
    'Runtime JSON conversion received an unsupported payload kind.',
    AScriptName,
    AEntryName,
    AVersionTag
  );
end;

function TTemplateDwsRuntime.TemplateValueToDwsVariant(
  const AValue: TValue;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): Variant;
var
  LJsonValue: TdwsJSONValue;
  LVariant: Variant;
begin
  if AValue.IsEmpty then
    exit(Unassigned);

  case AValue.Kind of
    tkString, tkLString, tkWString, tkUString, tkChar, tkWChar:
      exit(AValue.AsString);
    tkInteger, tkInt64:
      exit(AValue.AsInt64);
    tkFloat:
      exit(AValue.AsExtended);
    tkEnumeration:
      begin
        if AValue.TypeInfo = TypeInfo(boolean) then
          exit(AValue.AsBoolean)
        else
          exit(AValue.AsInt64);
      end;
    tkVariant:
      begin
        LVariant := AValue.AsVariant;
        if not VarIsArray(LVariant) then
          exit(LVariant);
      end;
  end;

  LJsonValue := TemplateValueToDwsJson(AValue, AScriptName, AEntryName, AVersionTag);
  exit(BoxedJSONValue(LJsonValue));
end;

function TTemplateDwsRuntime.VariantArrayToTemplateValue(
  const AValue: Variant;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): TValue;
var
  LLow: integer;
  LHigh: integer;
  LIdx: integer;
  LItems: TArray<TValue>;
begin
  if VarArrayDimCount(AValue) <> 1 then
    raise ETemplateDwsMarshalError.CreateContext(
      'Only one-dimensional Variant arrays are supported by the DWScript runtime bridge.',
      AScriptName,
      AEntryName,
      AVersionTag
    );

  LLow := VarArrayLowBound(AValue, 1);
  LHigh := VarArrayHighBound(AValue, 1);
  SetLength(LItems, LHigh - LLow + 1);
  for LIdx := LLow to LHigh do
    LItems[LIdx - LLow] := VariantToTemplateValue(AValue[LIdx], AScriptName, AEntryName, AVersionTag);
  exit(TValue.From<TArray<TValue>>(LItems));
end;

function TTemplateDwsRuntime.VariantToTemplateValue(
  const AValue: Variant;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): TValue;
var
  LVarType: integer;
  LBoxed: IBoxedJSONValue;
begin
  LVarType := VarType(AValue);

  if VarIsEmpty(AValue) or VarIsClear(AValue) then
    exit(TValue.Empty);

  if VarIsNull(AValue) then
    exit(TValue.From<Pointer>(nil));

  if VarIsArray(AValue) then
    exit(VariantArrayToTemplateValue(AValue, AScriptName, AEntryName, AVersionTag));

  if (LVarType = varUnknown) and not VarIsClear(AValue) then
  begin
    if Supports(IUnknown(TVarData(AValue).VUnknown), IBoxedJSONValue, LBoxed) then
      exit(JsonValueToTemplateValue(LBoxed.Value));
  end;

  case LVarType of
    varBoolean:
      exit(boolean(AValue));
    varByte, varSmallint, varInteger, varShortInt, varWord, varLongWord, varInt64:
      exit(int64(AValue));
    varSingle, varDouble, varCurrency:
      exit(FloatToTValue(AValue));
    varOleStr, varStrArg, varString, varUString:
      exit(string(AValue));
  end;

  exit(TValue.FromVariant(AValue));
end;

end.







