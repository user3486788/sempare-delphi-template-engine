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
unit Sempare.Template.DWS;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Types;

/// <summary>
/// Creates the default DWScript bridge composition root.
/// </summary>
/// <param name="AOptions">Bridge behavior flags such as compile-cache reuse, root-data injection, and mutation policy gates.</param>
/// <returns>A bridge ready to register helper functions into an `ITemplateContext`.</returns>
function CreateSempareDwsBridge(
  const AOptions: TTemplateDwsBridgeOptions = [tdboCacheCompiledScripts, tdboDisallowContextMutation]
): ISempareDwsBridge; overload;

/// <summary>
/// Creates the DWScript bridge with a caller-supplied runtime implementation.
/// </summary>
/// <param name="ARuntime">Runtime implementation that owns DWScript compile and execute details.</param>
/// <param name="AOptions">Bridge behavior flags such as compile-cache reuse, root-data injection, and mutation policy gates.</param>
/// <returns>A bridge using the supplied runtime.</returns>
function CreateSempareDwsBridge(
  const ARuntime: ITemplateDwsRuntime;
  const AOptions: TTemplateDwsBridgeOptions = [tdboCacheCompiledScripts, tdboDisallowContextMutation]
): ISempareDwsBridge; overload;

implementation

uses
  System.SysUtils,
  System.Rtti,
  System.Diagnostics,
{$IFDEF SUPPORT_HASH}
  System.Hash,
{$ENDIF}
  Sempare.Template.Context,
  Sempare.Template.DWS.Provider,
  Sempare.Template.DWS.Cache,
  Sempare.Template.DWS.HostServices,
  Sempare.Template.DWS.Marshalling,
  Sempare.Template.DWS.Runtime,
  Sempare.Template.DWS.Functions;

type
  TSempareDwsBridge = class(TInterfacedObject, ISempareDwsBridge, ISempareDwsBridgeDispatch)
  private
    FProvider: ITemplateDwsScriptProvider;
    FRegistry: ITemplateDwsScriptRegistry;
    FMarshaller: ITemplateDwsMarshaller;
    FRuntime: ITemplateDwsRuntime;
    FCache: ITemplateDwsCompileCache;
    FHostServices: ITemplateDwsHostServices;
    FDiagnostics: ITemplateDwsDiagnostics;
    FOptions: TTemplateDwsBridgeOptions;
    function GetOptions: TTemplateDwsBridgeOptions;
    procedure NotifyCacheEvent(
      const AKind: TTemplateDwsCacheEventKind;
      const AScriptName: string;
      const AVersionTag: string
    );
    procedure NotifyProfileEvent(
      const AKind: TTemplateDwsProfileEventKind;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AElapsedMs: int64
    );
    function RequireProvider: ITemplateDwsScriptProvider;
    function RequireRegistry: ITemplateDwsScriptRegistry;
    function RequireMarshaller: ITemplateDwsMarshaller;
    function RequireRuntime: ITemplateDwsRuntime;
    function ResolveScript(const AScriptName: string; const AEntryName: string): TTemplateDwsScript;
    function CreateInlineScript(const ASource: string): TTemplateDwsScript;
    function GetCompiledScript(const AScript: TTemplateDwsScript; const AEntryName: string): ITemplateDwsCompiledScript;
  public
    constructor Create(const AOptions: TTemplateDwsBridgeOptions; const ARuntime: ITemplateDwsRuntime = nil);
    procedure RegisterInto(const ACtx: ITemplateContext);
    procedure UnregisterFrom(const ACtx: ITemplateContext);
    procedure AddScript(const AName, ASource: string);
    procedure RemoveScript(const AName: string);
    procedure ClearScripts;
    procedure InvalidateScript(const AName: string);
    procedure ClearCompileCache;
    procedure SetScriptProvider(const AProvider: ITemplateDwsScriptProvider);
    procedure SetMarshaller(const AMarshaller: ITemplateDwsMarshaller);
    procedure SetHostServices(const AHostServices: ITemplateDwsHostServices);
    procedure SetDiagnostics(const ADiagnostics: ITemplateDwsDiagnostics);
    procedure SetOptions(const AOptions: TTemplateDwsBridgeOptions);
    function Call(
      const ACtx: ITemplateContext;
      const AScriptName: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): TValue;
    function Render(
      const ACtx: ITemplateContext;
      const AScriptName: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): string;
    function CallInline(
      const ACtx: ITemplateContext;
      const ASource: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): TValue;
    function RenderInline(
      const ACtx: ITemplateContext;
      const ASource: string;
      const AEntryName: string;
      const AExplicitPayload: TValue
    ): string;
  end;

function CreateSempareDwsBridge(const AOptions: TTemplateDwsBridgeOptions): ISempareDwsBridge; overload;
begin
  result := TSempareDwsBridge.Create(AOptions);
end;

function CreateSempareDwsBridge(const ARuntime: ITemplateDwsRuntime; const AOptions: TTemplateDwsBridgeOptions): ISempareDwsBridge; overload;
begin
  result := TSempareDwsBridge.Create(AOptions, ARuntime);
end;

function TryGetRegisteredBridge(const ACtx: ITemplateContext; out ABridge: ISempareDwsBridge): boolean;
var
  LValue: TValue;
begin
  result := false;
  ABridge := nil;
  if (ACtx = nil) or not ACtx.TryGetVariable(TemplateDwsBridgeContextKey, LValue) then
    exit;
  if not LValue.IsType<ISempareDwsBridge> then
    exit(false);
  ABridge := LValue.AsType<ISempareDwsBridge>;
  result := ABridge <> nil;
end;

function HasHelperMethod(const AName: string; const AMethods: TArray<TRttiMethod>): boolean;
var
  LMethod: TRttiMethod;
  LParent: TRttiType;
begin
  for LMethod in AMethods do
  begin
    LParent := LMethod.Parent;
    if (LParent <> nil) and LMethod.IsClassMethod and LMethod.IsStatic and SameText(LMethod.Name, AName) then
    begin
      if (LParent.AsInstance.MetaclassType = TSempareDwsFunctions) or
         (LParent.AsInstance.MetaclassType = TSempareDwsTemplateFunctions) then
        exit(true);
    end;
  end;
  exit(false);
end;

function ContextHasBridgeHelpers(const ACtx: ITemplateContext): boolean;
var
  LMethods: TArray<TRttiMethod>;
begin
  if (ACtx <> nil) and ACtx.TryGetFunction('dwscall', LMethods) and HasHelperMethod('DwsCall', LMethods) then
    exit(true);
  exit(false);
end;

function MakeInlineHash(const ASource: string): string;
begin
{$IFDEF SUPPORT_HASH}
  result := THashMD5.GetHashString(ASource);
{$ELSE}
  result := IntToHex(Length(ASource), 8);
{$ENDIF}
end;

procedure TSempareDwsBridge.AddScript(const AName, ASource: string);
begin
  RequireRegistry.AddOrSet(AName, ASource);
  InvalidateScript(AName);
end;

function TSempareDwsBridge.Call(
  const ACtx: ITemplateContext;
  const AScriptName: string;
  const AEntryName: string;
  const AExplicitPayload: TValue
): TValue;
var
  LCompiled: ITemplateDwsCompiledScript;
  LPayload: TValue;
  LResult: TValue;
  LScript: TTemplateDwsScript;
begin
  LScript := ResolveScript(AScriptName, AEntryName);
  try
    LPayload := RequireMarshaller.BuildPayload(ACtx, AExplicitPayload, FOptions, LScript.Name, AEntryName, LScript.VersionTag);
  except
    on E: ETemplateDwsBridge do
      raise;
    on E: Exception do
      raise ETemplateDwsMarshalError.CreateContext(
        'DWScript payload construction failed. ' + E.Message,
        LScript.Name,
        AEntryName,
        LScript.VersionTag,
        FOptions
      );
  end;
  LCompiled := GetCompiledScript(LScript, AEntryName);
  LResult := RequireRuntime.CallEntry(LCompiled, AEntryName, LPayload, ACtx, FHostServices, FOptions);
  try
    exit(RequireMarshaller.ConvertResultToTemplateValue(LResult, FOptions, LScript.Name, AEntryName, LScript.VersionTag));
  except
    on E: ETemplateDwsBridge do
      raise;
    on E: Exception do
      raise ETemplateDwsMarshalError.CreateContext(
        'DWScript result conversion failed. ' + E.Message,
        LScript.Name,
        AEntryName,
        LScript.VersionTag,
        FOptions
      );
  end;
end;

function TSempareDwsBridge.CallInline(
  const ACtx: ITemplateContext;
  const ASource: string;
  const AEntryName: string;
  const AExplicitPayload: TValue
): TValue;
var
  LCompiled: ITemplateDwsCompiledScript;
  LPayload: TValue;
  LResult: TValue;
  LScript: TTemplateDwsScript;
begin
  if not (tdboAllowInlineScripts in FOptions) then
    raise ETemplateDwsContractError.CreateContext('Inline DWScript execution is disabled by bridge options.', '[inline]', AEntryName, '', FOptions);

  LScript := CreateInlineScript(ASource);
  try
    LPayload := RequireMarshaller.BuildPayload(ACtx, AExplicitPayload, FOptions, LScript.Name, AEntryName, LScript.VersionTag);
  except
    on E: ETemplateDwsBridge do
      raise;
    on E: Exception do
      raise ETemplateDwsMarshalError.CreateContext(
        'DWScript payload construction failed. ' + E.Message,
        LScript.Name,
        AEntryName,
        LScript.VersionTag,
        FOptions
      );
  end;
  LCompiled := GetCompiledScript(LScript, AEntryName);
  LResult := RequireRuntime.CallEntry(LCompiled, AEntryName, LPayload, ACtx, FHostServices, FOptions);
  try
    exit(RequireMarshaller.ConvertResultToTemplateValue(LResult, FOptions, LScript.Name, AEntryName, LScript.VersionTag));
  except
    on E: ETemplateDwsBridge do
      raise;
    on E: Exception do
      raise ETemplateDwsMarshalError.CreateContext(
        'DWScript result conversion failed. ' + E.Message,
        LScript.Name,
        AEntryName,
        LScript.VersionTag,
        FOptions
      );
  end;
end;

procedure TSempareDwsBridge.ClearCompileCache;
begin
  if FCache <> nil then
  begin
    FCache.Clear;
    NotifyCacheEvent(tdcekClear, '*', '');
  end;
end;

procedure TSempareDwsBridge.ClearScripts;
begin
  RequireRegistry.Clear;
  ClearCompileCache;
end;

constructor TSempareDwsBridge.Create(const AOptions: TTemplateDwsBridgeOptions; const ARuntime: ITemplateDwsRuntime);
begin
  inherited Create;
  FRegistry := CreateInMemoryDwsScriptRegistry;
  FProvider := FRegistry;
  FMarshaller := CreateDefaultDwsMarshaller;
  if ARuntime <> nil then
    FRuntime := ARuntime
  else
    FRuntime := CreateDefaultDwsRuntime;
  FCache := CreateDefaultDwsCompileCache;
  FHostServices := CreateDefaultDwsHostServices;
  FOptions := AOptions;
end;

function TSempareDwsBridge.CreateInlineScript(const ASource: string): TTemplateDwsScript;
var
  LHash: string;
  LName: string;
begin
  if Trim(ASource) = '' then
    raise ETemplateDwsContractError.CreateContext('Inline DWScript source must not be empty.', '[inline]', '', '', FOptions);

  LHash := MakeInlineHash(ASource);
  LName := '__inline__/' + LHash;
  result := TTemplateDwsScript.Create(LName, ASource, LName + '@' + LHash);
end;

function TSempareDwsBridge.GetCompiledScript(const AScript: TTemplateDwsScript; const AEntryName: string): ITemplateDwsCompiledScript;
var
  LStopWatch: TStopWatch;
begin
  if (tdboCacheCompiledScripts in FOptions) and (FCache <> nil) then
  begin
    if FCache.TryGet(AScript.Name, AScript.VersionTag, result) then
    begin
      NotifyCacheEvent(tdcekHit, AScript.Name, AScript.VersionTag);
      exit;
    end;
    NotifyCacheEvent(tdcekMiss, AScript.Name, AScript.VersionTag);
  end;

  LStopWatch := TStopWatch.StartNew;
  result := RequireRuntime.CompileNamed(AScript.Name, AScript.Source, AScript.VersionTag, AEntryName);
  NotifyProfileEvent(tdpekCompile, AScript.Name, AEntryName, AScript.VersionTag, LStopWatch.ElapsedMilliseconds);
  if (tdboCacheCompiledScripts in FOptions) and (FCache <> nil) then
  begin
    FCache.Put(AScript.Name, AScript.VersionTag, result);
    NotifyCacheEvent(tdcekStore, AScript.Name, AScript.VersionTag);
  end;
end;

function TSempareDwsBridge.GetOptions: TTemplateDwsBridgeOptions;
begin
  exit(FOptions);
end;

procedure TSempareDwsBridge.InvalidateScript(const AName: string);
begin
  if FCache <> nil then
  begin
    FCache.Invalidate(AName);
    NotifyCacheEvent(tdcekInvalidate, AName, '');
  end;
end;

procedure TSempareDwsBridge.NotifyCacheEvent(
  const AKind: TTemplateDwsCacheEventKind;
  const AScriptName: string;
  const AVersionTag: string
);
begin
  if FDiagnostics <> nil then
    FDiagnostics.CacheEvent(AKind, AScriptName, AVersionTag);
end;

procedure TSempareDwsBridge.NotifyProfileEvent(
  const AKind: TTemplateDwsProfileEventKind;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AElapsedMs: int64
);
begin
  if FDiagnostics <> nil then
    FDiagnostics.ProfileEvent(AKind, AScriptName, AEntryName, AVersionTag, AElapsedMs);
end;

procedure TSempareDwsBridge.RegisterInto(const ACtx: ITemplateContext);
var
  LSelf: ISempareDwsBridge;
begin
  if ACtx = nil then
    raise ETemplateDwsContractError.CreateContext('Template context is required for bridge registration.');

  if not ContextHasBridgeHelpers(ACtx) then
    ACtx.Functions.AddFunctions(TSempareDwsTemplateFunctions);

  LSelf := self;
  ACtx.Variables[TemplateDwsBridgeContextKey] := TValue.From<ISempareDwsBridge>(LSelf);
end;

procedure TSempareDwsBridge.RemoveScript(const AName: string);
begin
  RequireRegistry.Remove(AName);
  InvalidateScript(AName);
end;

function TSempareDwsBridge.Render(
  const ACtx: ITemplateContext;
  const AScriptName: string;
  const AEntryName: string;
  const AExplicitPayload: TValue
): string;
var
  LCompiled: ITemplateDwsCompiledScript;
  LPayload: TValue;
  LResult: TValue;
  LScript: TTemplateDwsScript;
  LStopWatch: TStopWatch;
begin
  LScript := ResolveScript(AScriptName, AEntryName);
  LPayload := RequireMarshaller.BuildPayload(ACtx, AExplicitPayload, FOptions, LScript.Name, AEntryName, LScript.VersionTag);
  LCompiled := GetCompiledScript(LScript, AEntryName);
  LResult := RequireRuntime.CallEntry(LCompiled, AEntryName, LPayload, ACtx, FHostServices, FOptions);

  LStopWatch := TStopWatch.StartNew;
  result := RequireMarshaller.ConvertResultToText(LResult, FOptions, LScript.Name, AEntryName, LScript.VersionTag);
  NotifyProfileEvent(tdpekRender, LScript.Name, AEntryName, LScript.VersionTag, LStopWatch.ElapsedMilliseconds);
end;

function TSempareDwsBridge.RenderInline(
  const ACtx: ITemplateContext;
  const ASource: string;
  const AEntryName: string;
  const AExplicitPayload: TValue
): string;
var
  LCompiled: ITemplateDwsCompiledScript;
  LPayload: TValue;
  LResult: TValue;
  LScript: TTemplateDwsScript;
  LStopWatch: TStopWatch;
begin
  if not (tdboAllowInlineScripts in FOptions) then
    raise ETemplateDwsContractError.CreateContext('Inline DWScript execution is disabled by bridge options.', '[inline]', AEntryName, '', FOptions);

  LScript := CreateInlineScript(ASource);
  LPayload := RequireMarshaller.BuildPayload(ACtx, AExplicitPayload, FOptions, LScript.Name, AEntryName, LScript.VersionTag);
  LCompiled := GetCompiledScript(LScript, AEntryName);
  LResult := RequireRuntime.CallEntry(LCompiled, AEntryName, LPayload, ACtx, FHostServices, FOptions);

  LStopWatch := TStopWatch.StartNew;
  result := RequireMarshaller.ConvertResultToText(LResult, FOptions, LScript.Name, AEntryName, LScript.VersionTag);
  NotifyProfileEvent(tdpekRender, LScript.Name, AEntryName, LScript.VersionTag, LStopWatch.ElapsedMilliseconds);
end;

function TSempareDwsBridge.RequireMarshaller: ITemplateDwsMarshaller;
begin
  if FMarshaller = nil then
    raise ETemplateDwsContractError.CreateContext('No DWScript marshaller has been configured.');
  exit(FMarshaller);
end;

function TSempareDwsBridge.RequireProvider: ITemplateDwsScriptProvider;
begin
  if FProvider = nil then
    raise ETemplateDwsContractError.CreateContext('No DWScript script provider has been configured.');
  exit(FProvider);
end;

function TSempareDwsBridge.RequireRegistry: ITemplateDwsScriptRegistry;
begin
  if FRegistry = nil then
    raise ETemplateDwsContractError.CreateContext('The active DWScript script provider is read-only and cannot accept AddScript/RemoveScript/ClearScripts operations.');
  exit(FRegistry);
end;

function TSempareDwsBridge.RequireRuntime: ITemplateDwsRuntime;
begin
  if FRuntime = nil then
    raise ETemplateDwsContractError.CreateContext('No DWScript runtime has been configured.');
  exit(FRuntime);
end;

function TSempareDwsBridge.ResolveScript(const AScriptName: string; const AEntryName: string): TTemplateDwsScript;
var
  LStopWatch: TStopWatch;
begin
  LStopWatch := TStopWatch.StartNew;
  if not RequireProvider.TryGetScript(AScriptName, result) then
    raise ETemplateDwsScriptNotFound.CreateContext(
      'DWScript script not found.',
      AScriptName,
      AEntryName,
      RequireProvider.VersionTag(AScriptName),
      FOptions
    );
  NotifyProfileEvent(tdpekResolve, result.Name, AEntryName, result.VersionTag, LStopWatch.ElapsedMilliseconds);
end;

procedure TSempareDwsBridge.SetDiagnostics(const ADiagnostics: ITemplateDwsDiagnostics);
begin
  FDiagnostics := ADiagnostics;
  if FRuntime <> nil then
    FRuntime.SetDiagnostics(ADiagnostics);
end;

procedure TSempareDwsBridge.SetHostServices(const AHostServices: ITemplateDwsHostServices);
begin
  FHostServices := AHostServices;
end;

procedure TSempareDwsBridge.SetMarshaller(const AMarshaller: ITemplateDwsMarshaller);
begin
  if AMarshaller = nil then
    raise ETemplateDwsContractError.CreateContext('DWScript marshaller must not be nil.');
  FMarshaller := AMarshaller;
end;

procedure TSempareDwsBridge.SetOptions(const AOptions: TTemplateDwsBridgeOptions);
begin
  FOptions := AOptions;
end;

procedure TSempareDwsBridge.SetScriptProvider(const AProvider: ITemplateDwsScriptProvider);
begin
  if AProvider = nil then
    raise ETemplateDwsContractError.CreateContext('DWScript script provider must not be nil.');

  FProvider := AProvider;
  if not Supports(AProvider, ITemplateDwsScriptRegistry, FRegistry) then
    FRegistry := nil;
  ClearCompileCache;
end;

procedure TSempareDwsBridge.UnregisterFrom(const ACtx: ITemplateContext);
var
  LRegisteredBridge: ISempareDwsBridge;
  LSelf: ISempareDwsBridge;
begin
  if ACtx = nil then
    exit;

  if not TryGetRegisteredBridge(ACtx, LRegisteredBridge) then
    exit;

  LSelf := self;
  if LRegisteredBridge <> LSelf then
    exit;

  ACtx.Variables.Remove(TemplateDwsBridgeContextKey);
  ACtx.Functions.Remove('dws');
  ACtx.Functions.Remove('dwscall');
  ACtx.Functions.Remove('dwsinline');
  ACtx.Functions.Remove('dwsinlinetext');
  ACtx.Functions.Remove('dwsraw');
  ACtx.Functions.Remove('dwsrender');
  ACtx.Functions.Remove('dwstext');
end;

end.



