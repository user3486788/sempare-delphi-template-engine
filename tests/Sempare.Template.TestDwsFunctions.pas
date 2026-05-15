unit Sempare.Template.TestDwsFunctions;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDwsFunctionsTest = class
  public
    [Test]
    procedure CachedCompiledScriptsAreReusedUntilVersionChangesOrInvalidation;
    [Test]
    procedure CompileErrorsIncludeScriptAndEntryContext;
    [Test]
    procedure HelpersExecuteBridgeScripts;
    [Test]
    procedure HelpersRejectBadArguments;
    [Test]
    procedure MissingScriptsIncludeScriptAndEntryContext;
    [Test]
    procedure RuntimeErrorsIncludeScriptAndEntryContext;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.Functions,
  Sempare.Template.DWS.Types,
  Sempare.Template.Util;

const
  CCalcScript =
    'function CalcTotal(data : JSONVariant) : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.order.total + data.fee;' + sLineBreak +
    'end;' + sLineBreak +
    'function RenderLabel(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.label;' + sLineBreak +
    'end;';

  CBrokenCompileScript =
    'function Broken(data : JSONVariant) : Integer' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := ;' + sLineBreak +
    'end;';

  CRuntimeErrorScript =
    'function BlowUp(data : JSONVariant) : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 100 div data.zero;' + sLineBreak +
    'end;';

  CValueOneScript =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 1;' + sLineBreak +
    'end;';

  CValueTwoScript =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 2;' + sLineBreak +
    'end;';

  CValueThreeScript =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 3;' + sLineBreak +
    'end;';

type
  TMutableDwsScriptProvider = class(TInterfacedObject, ITemplateDwsScriptProvider)
  private
    FName: string;
    FSource: string;
    FVersionTag: string;
  public
    constructor Create(const AName, ASource, AVersionTag: string);
    function TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
    function Exists(const AName: string): boolean;
    function VersionTag(const AName: string): string;
    property Source: string read FSource write FSource;
    property VersionTagValue: string read FVersionTag write FVersionTag;
  end;

procedure AssertContains(const ANeedle, AHaystack: string);
begin
  Assert.IsTrue(Pos(ANeedle, AHaystack) > 0, Format('Expected "%s" to be present in "%s".', [ANeedle, AHaystack]));
end;

function CreateCalcPayload: TMap;
var
  LOrder: TMap;
begin
  LOrder := TMap.Create;
  LOrder.Add('total', 12);

  Result := TMap.Create;
  Result.Add('order', TValue.From<TMap>(LOrder));
  Result.Add('fee', 3);
  Result.Add('label', 'Total');
end;

function CreateZeroPayload: TMap;
begin
  Result := TMap.Create;
  Result.Add('zero', 0);
end;

function MakeArgs(const AScriptName, AEntryName: string): TArray<TValue>; overload;
begin
  Result := TArray<TValue>.Create(
    TValue.From<string>(AScriptName),
    TValue.From<string>(AEntryName)
  );
end;

function MakeArgs(const AScriptName, AEntryName: string; const APayload: TValue): TArray<TValue>; overload;
begin
  Result := TArray<TValue>.Create(
    TValue.From<string>(AScriptName),
    TValue.From<string>(AEntryName),
    APayload
  );
end;

constructor TMutableDwsScriptProvider.Create(const AName, ASource, AVersionTag: string);
begin
  inherited Create;
  FName := AName;
  FSource := ASource;
  FVersionTag := AVersionTag;
end;

function TMutableDwsScriptProvider.Exists(const AName: string): boolean;
begin
  Result := SameText(Trim(AName), FName);
end;

function TMutableDwsScriptProvider.TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
begin
  Result := Exists(AName);
  if Result then
    AScript := TTemplateDwsScript.Create(AName, FSource, FVersionTag);
end;

function TMutableDwsScriptProvider.VersionTag(const AName: string): string;
begin
  if Exists(AName) then
    Result := FVersionTag
  else
    Result := '';
end;

procedure TDwsFunctionsTest.CachedCompiledScriptsAreReusedUntilVersionChangesOrInvalidation;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LProvider: TMutableDwsScriptProvider;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LProvider := TMutableDwsScriptProvider.Create('calc', CValueOneScript, 'v1');
  LBridge.SetScriptProvider(LProvider);
  LBridge.RegisterInto(LCtx);

  Assert.AreEqual(Int64(1), TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('calc', 'Value')).AsInt64);

  LProvider.Source := CBrokenCompileScript;
  Assert.AreEqual(Int64(1), TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('calc', 'Value')).AsInt64);

  LProvider.Source := CValueTwoScript;
  LBridge.InvalidateScript('calc');
  Assert.AreEqual(Int64(2), TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('calc', 'Value')).AsInt64);

  LProvider.Source := CValueThreeScript;
  LProvider.VersionTagValue := 'v2';
  Assert.AreEqual(Int64(3), TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('calc', 'Value')).AsInt64);
end;

procedure TDwsFunctionsTest.CompileErrorsIncludeScriptAndEntryContext;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('broken', CBrokenCompileScript);
  LBridge.RegisterInto(LCtx);

  try
    TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('broken', 'Broken'));
    Assert.Fail('Expected ETemplateDwsCompileError.');
  except
    on E: ETemplateDwsCompileError do
    begin
      AssertContains('script=''broken''', E.Message);
      AssertContains('entry=''Broken''', E.Message);
    end;
  end;
end;

procedure TDwsFunctionsTest.HelpersExecuteBridgeScripts;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LPayload: TMap;
  LValue: TValue;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('pricing', CCalcScript);
  LBridge.RegisterInto(LCtx);

  LPayload := CreateCalcPayload;
  LValue := TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('pricing', 'CalcTotal', TValue.From<TMap>(LPayload)));

  Assert.AreEqual(Int64(15), LValue.AsInt64);
  Assert.AreEqual('Total', TSempareDwsFunctions.DwsText(LCtx, MakeArgs('pricing', 'RenderLabel', TValue.From<TMap>(LPayload))));
end;

procedure TDwsFunctionsTest.HelpersRejectBadArguments;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.RegisterInto(LCtx);

  try
    TSempareDwsFunctions.DwsCall(
      LCtx,
      TArray<TValue>.Create(TValue.From<Integer>(123), TValue.From<string>('Run'))
    );
    Assert.Fail('Expected ETemplateDwsContractError for invalid script name.');
  except
    on E: ETemplateDwsContractError do
      AssertContains('argument 0 (script name)', E.Message);
  end;

  try
    TSempareDwsFunctions.DwsText(
      LCtx,
      TArray<TValue>.Create(TValue.From<string>('calc'))
    );
    Assert.Fail('Expected ETemplateDwsContractError for invalid argument count.');
  except
    on E: ETemplateDwsContractError do
      AssertContains('expect 2 or 3 arguments', E.Message);
  end;
end;

procedure TDwsFunctionsTest.MissingScriptsIncludeScriptAndEntryContext;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.RegisterInto(LCtx);

  try
    TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('missing', 'Run'));
    Assert.Fail('Expected ETemplateDwsScriptNotFound.');
  except
    on E: ETemplateDwsScriptNotFound do
    begin
      AssertContains('script=''missing''', E.Message);
      AssertContains('entry=''Run''', E.Message);
    end;
  end;
end;

procedure TDwsFunctionsTest.RuntimeErrorsIncludeScriptAndEntryContext;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LPayload: TMap;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('runtime', CRuntimeErrorScript);
  LBridge.RegisterInto(LCtx);
  LPayload := CreateZeroPayload;

  try
    TSempareDwsFunctions.DwsCall(LCtx, MakeArgs('runtime', 'BlowUp', TValue.From<TMap>(LPayload)));
    Assert.Fail('Expected ETemplateDwsRuntimeError.');
  except
    on E: ETemplateDwsRuntimeError do
    begin
      AssertContains('script=''runtime''', E.Message);
      AssertContains('entry=''BlowUp''', E.Message);
    end;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TDwsFunctionsTest);

end.
