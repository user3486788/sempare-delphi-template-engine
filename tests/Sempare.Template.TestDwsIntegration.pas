unit Sempare.Template.TestDwsIntegration;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDwsIntegrationTest = class
  public
    [Test]
    procedure TemplateEvalKeepsHtmlEncodingForDwsText;
    [Test]
    procedure TemplateEvalSupportsDwsCallWithExplicitRootPayload;
    [Test]
    procedure TemplateEvalSupportsDwsWithImplicitRootPayload;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.Types,
  Sempare.Template.Util;

const
  CExplicitRootScript =
    'function Calc(data : JSONVariant) : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.total + 5;' + sLineBreak +
    'end;' + sLineBreak +
    'function Main(data : JSONVariant) : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.total + 5;' + sLineBreak +
    'end;';

  CHtmlRenderScript =
    'function Render(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.html;' + sLineBreak +
    'end;';

procedure TDwsIntegrationTest.TemplateEvalKeepsHtmlEncodingForDwsText;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LCtx.UseHtmlVariableEncoder;
  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('snippets', CHtmlRenderScript);
  LBridge.RegisterInto(LCtx);

  Assert.AreEqual(
    '&lt;b&gt;unsafe&lt;/b&gt;',
    Template.Eval(LCtx, '<% DwsText(''snippets'', ''Render'', { "html": "<b>unsafe</b>" }) %>')
  );
end;

procedure TDwsIntegrationTest.TemplateEvalSupportsDwsCallWithExplicitRootPayload;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('pricing', CExplicitRootScript);
  LBridge.RegisterInto(LCtx);

  Assert.AreEqual(
    '15',
    Template.Eval(LCtx, '<% DwsCall(''pricing'', ''Calc'', { "total": 10 }) %>')
  );
end;

procedure TDwsIntegrationTest.TemplateEvalSupportsDwsWithImplicitRootPayload;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LPayload: TMap;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts, tdboPassRootData, tdboDisallowContextMutation]);
  LBridge.AddScript('pricing', CExplicitRootScript);
  LBridge.RegisterInto(LCtx);

  LPayload := TMap.Create;
  LPayload.Add('total', 10);

  Assert.AreEqual(
    '15',
    Template.Eval(LCtx, '<% Dws(''pricing'') %>', TValue.From<TMap>(LPayload))
  );
end;

initialization

TDUnitX.RegisterTestFixture(TDwsIntegrationTest);

end.



