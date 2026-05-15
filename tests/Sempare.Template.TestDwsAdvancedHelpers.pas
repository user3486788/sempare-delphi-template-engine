unit Sempare.Template.TestDwsAdvancedHelpers;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDwsAdvancedHelpersTest = class
  public
    [Test]
    procedure DiagnosticsRecorderCapturesCacheAndRuntimeEvents;
    [Test]
    procedure InlineHelpersRemainOptInAndExecuteWhenEnabled;
    [Test]
    procedure OptionalSugarAndRawHelpersRemainExplicit;
    [Test]
    procedure StructuredJsonLikeResultsAndVariantArrayPayloadsAreSupported;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  System.Variants,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.Functions,
  Sempare.Template.DWS.Tooling,
  Sempare.Template.DWS.Types,
  Sempare.Template.Util;

const
  CStructuredPayloadScript =
    'function Sum(data : JSONVariant) : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.values[0] + data.values[1] + data.values[2];' + sLineBreak +
    'end;' + sLineBreak +
    'function JsonDoc(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := ''{"items":[1,2,3],"meta":{"ok":true}}'';' + sLineBreak +
    'end;';

  CDefaultEntryScript =
    'function Main(data : JSONVariant) : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.value + 1;' + sLineBreak +
    'end;' + sLineBreak +
    'function Render(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.html;' + sLineBreak +
    'end;';

  CCacheScript =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 5;' + sLineBreak +
    'end;';

function CreateHtmlPayload(const AHtml: string): TMap;
begin
  Result := TMap.Create;
  Result.Add('html', AHtml);
end;

function CreateNamePayload(const AName: string): TMap;
begin
  Result := TMap.Create;
  Result.Add('name', AName);
end;

function CreateValuePayload(const AValue: integer): TMap;
begin
  Result := TMap.Create;
  Result.Add('value', AValue);
end;

function CreateVariantArrayValue: TValue;
var
  LVariant: Variant;
begin
  LVariant := VarArrayOf([1, 2, 3]);
  TValue.Make(@LVariant, TypeInfo(Variant), Result);
end;

function CreateVariantArrayPayload: TMap;
begin
  Result := TMap.Create;
  Result.Add('values', CreateVariantArrayValue);
end;

procedure TDwsAdvancedHelpersTest.DiagnosticsRecorderCapturesCacheAndRuntimeEvents;
var
  LHarness: TSempareDwsTestHarness;
  LRecorder: TTemplateDwsDiagnosticsRecorder;
begin
  LHarness := TSempareDwsTestHarness.Create;
  try
    LRecorder := TTemplateDwsDiagnosticsRecorder.Create;
    LHarness.Bridge.SetDiagnostics(LRecorder);
    LHarness.AddScript('cache', CCacheScript);

    Assert.AreEqual(Int64(5), LHarness.Call('cache', 'Value').AsInt64);
    Assert.AreEqual(Int64(5), LHarness.Call('cache', 'Value').AsInt64);

    Assert.IsTrue(LRecorder.Count > 0);
    Assert.AreEqual('cache', LRecorder.FindFirst('cache', 'tdcekMiss').Category);
    Assert.AreEqual('cache', LRecorder.FindFirst('cache', 'tdcekHit').Category);
    Assert.AreEqual('runtime', LRecorder.FindFirst('runtime', 'tdrekCompileSuccess').Category);
    Assert.AreEqual('profile', LRecorder.FindFirst('profile', 'tdpekCall').Category);
  finally
    LHarness.Free;
  end;
end;

procedure TDwsAdvancedHelpersTest.InlineHelpersRemainOptInAndExecuteWhenEnabled;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LInlineSource: string;
begin
  LInlineSource :=
    'function Render(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.name;' + sLineBreak +
    'end;';

  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.RegisterInto(LCtx);

  try
    TSempareDwsFunctions.DwsInlineText(
      LCtx,
      TArray<TValue>.Create(
        LInlineSource,
        'Render',
        TValue.From<TMap>(TMap.Create)
      )
    );
    Assert.Fail('Expected ETemplateDwsContractError when inline mode is disabled.');
  except
    on E: ETemplateDwsContractError do
      Assert.IsTrue(Pos('inline', E.Message.ToLower) > 0);
  end;

  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts, tdboDisallowContextMutation, tdboAllowInlineScripts]);
  LBridge.RegisterInto(LCtx);

  Assert.AreEqual(
    'Ada',
    TSempareDwsFunctions.DwsInlineText(
      LCtx,
      TArray<TValue>.Create(
        LInlineSource,
        'Render',
        TValue.From<TMap>(CreateNamePayload('Ada'))
      )
    )
  );
end;

procedure TDwsAdvancedHelpersTest.OptionalSugarAndRawHelpersRemainExplicit;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LCtx.UseHtmlVariableEncoder;
  LBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts, tdboDisallowContextMutation, tdboAllowTrustedText]);
  LBridge.AddScript('macro', CDefaultEntryScript);
  LBridge.RegisterInto(LCtx);

  Assert.AreEqual(
    '5',
    Template.Eval(LCtx, '<% Dws(''macro'', { "value": 4 }) %>')
  );
  Assert.AreEqual(
    '&lt;b&gt;safe&lt;/b&gt;',
    Template.Eval(LCtx, '<% DwsRender(''macro'', { "html": "<b>safe</b>" }) %>')
  );
  Assert.AreEqual(
    '&lt;b&gt;safe&lt;/b&gt;',
    Template.Eval(LCtx, '<% DwsRaw(''macro'', ''Render'', { "html": "<b>safe</b>" }) %>')
  );
  Assert.AreEqual(
    '<b>safe</b>',
    Template.Eval(LCtx, '<% print(DwsRaw(''macro'', ''Render'', { "html": "<b>safe</b>" })) %>')
  );
end;

procedure TDwsAdvancedHelpersTest.StructuredJsonLikeResultsAndVariantArrayPayloadsAreSupported;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
  LResult: TValue;
  LMap: TMap;
  LItems: TArray<TValue>;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts, tdboDisallowContextMutation, tdboExpectJsonLikeReturn]);
  LBridge.AddScript('structured', CStructuredPayloadScript);
  LBridge.RegisterInto(LCtx);

  try
    LResult := TSempareDwsFunctions.DwsCall(
      LCtx,
      TArray<TValue>.Create(
        'structured',
        'Sum',
        TValue.From<TMap>(CreateVariantArrayPayload)
      )
    );
    Assert.AreEqual(Int64(6), LResult.AsInt64);
  except
    on E: Exception do
      raise Exception.Create('Variant-array payload scenario failed: ' + E.Message);
  end;

  try
    LResult := TSempareDwsFunctions.DwsCall(
      LCtx,
      TArray<TValue>.Create('structured', 'JsonDoc')
    );
    Assert.IsTrue(LResult.IsType<TMap>);
    LMap := LResult.AsType<TMap>;
    Assert.IsTrue(LMap['meta'].AsType<TMap>['ok'].AsBoolean);
    LItems := LMap['items'].AsType<TArray<TValue>>;
    Assert.AreEqual(3, Length(LItems));
    Assert.AreEqual(Int64(3), LItems[2].AsInt64);
  except
    on E: Exception do
      raise Exception.Create('JSON-like result scenario failed: ' + E.Message);
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TDwsAdvancedHelpersTest);

end.
