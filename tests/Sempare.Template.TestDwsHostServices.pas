unit Sempare.Template.TestDwsHostServices;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDwsHostServicesTest = class
  public
    [Test]
    procedure HostResolveTemplateUsesDedicatedSempareHostUnit;
    [Test]
    procedure HostResolveTemplatePreservesOuterExtendsState;
    [Test]
    procedure HostServicesCanReadContextVariablesAndTemplateAvailability;
    [Test]
    procedure MutationRemainsBlockedByDefaultAndRequiresExplicitPolicy;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.Functions,
  Sempare.Template.DWS.HostServices,
  Sempare.Template.DWS.Types,
  Sempare.Template.Util;

const
  CResolveTemplateScript =
    'uses SempareHost;' + sLineBreak +
    'function RenderCard(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := ResolveTemplate(''inner'', data);' + sLineBreak +
    'end;';

  CResolveTemplateExtendsScript =
    'uses SempareHost;' + sLineBreak +
    'function RenderNested(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := ResolveTemplate(''inner-ext'', data);' + sLineBreak +
    'end;';

  CReadContextScript =
    'uses SempareHost;' + sLineBreak +
    'function Describe(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  if TemplateExists(''inner'') then' + sLineBreak +
    '    Result := String(GetVar(''currentUser'')) + ''-'' + data.suffix' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := ''missing'';' + sLineBreak +
    'end;';

  CMutateScript =
    'uses SempareHost;' + sLineBreak +
    'function Mutate(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  SetVar(''stage'', data.stage);' + sLineBreak +
    '  Result := String(GetVar(''stage''));' + sLineBreak +
    'end;';

procedure AssertContains(const ANeedle, AHaystack: string);
begin
  Assert.IsTrue(Pos(ANeedle, AHaystack) > 0, Format('Expected "%s" to be present in "%s".', [ANeedle, AHaystack]));
end;

function CreateStagePayload(const AStage: string): TMap;
begin
  Result := TMap.Create;
  Result.Add('stage', AStage);
end;

function CreateSuffixPayload(const ASuffix: string): TMap;
begin
  Result := TMap.Create;
  Result.Add('suffix', ASuffix);
end;

function CreateTemplateData(const AName: string): TMap;
begin
  Result := TMap.Create;
  Result.Add('name', AName);
end;

procedure TDwsHostServicesTest.HostResolveTemplateUsesDedicatedSempareHostUnit;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LCtx.SetTemplate('inner', Template.Parse(LCtx, '<% name %>'));

  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('render', CResolveTemplateScript);
  LBridge.RegisterInto(LCtx);

  Assert.AreEqual(
    'Ada',
    Template.Eval(LCtx, '<% DwsText(''render'', ''RenderCard'', _) %>', TValue.From<TMap>(CreateTemplateData('Ada')))
  );
end;

procedure TDwsHostServicesTest.HostResolveTemplatePreservesOuterExtendsState;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
  LOuterTemplate: string;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LCtx.SetTemplate('header', Template.Parse(LCtx, 'H[<% block ''body'' %>header-default<% end %>]'));
  LCtx.SetTemplate('footer', Template.Parse(LCtx, 'F[<% block ''body'' %>footer-default<% end %>]'));
  LCtx.SetTemplate('outer-base', Template.Parse(LCtx, '<% include(''header'') %>|<% include(''footer'') %>'));
  LCtx.SetTemplate('inner-base', Template.Parse(LCtx, 'I[<% block ''body'' %>inner-default<% end %>]'));
  LCtx.SetTemplate('inner-ext', Template.Parse(LCtx, '<% extends (''inner-base'') %><% block ''body'' %><% name %><% end %><% end %>'));

  LBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts]);
  LBridge.AddScript('renderNested', CResolveTemplateExtendsScript);
  LBridge.RegisterInto(LCtx);

  LOuterTemplate := '<% extends (''outer-base'') %><% block ''body'' %>outer <% DwsText(''renderNested'', ''RenderNested'', _) %><% end %><% end %>';

  Assert.AreEqual(
    'H[outer I[Ada]]|F[outer I[Ada]]',
    Template.Eval(LCtx, LOuterTemplate, TValue.From<TMap>(CreateTemplateData('Ada')))
  );
  Assert.AreEqual(
    'H[outer I[Bob]]|F[outer I[Bob]]',
    Template.Eval(LCtx, LOuterTemplate, TValue.From<TMap>(CreateTemplateData('Bob')))
  );
end;

procedure TDwsHostServicesTest.HostServicesCanReadContextVariablesAndTemplateAvailability;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LCtx.Variables['currentUser'] := 'ada';
  LCtx.SetTemplate('inner', Template.Parse(LCtx, ''));

  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('reader', CReadContextScript);
  LBridge.RegisterInto(LCtx);

  Assert.AreEqual(
    'ada-online',
    Template.Eval(LCtx, '<% DwsText(''reader'', ''Describe'', _) %>', TValue.From<TMap>(CreateSuffixPayload('online')))
  );
end;

procedure TDwsHostServicesTest.MutationRemainsBlockedByDefaultAndRequiresExplicitPolicy;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
  LAllowedBridge: ISempareDwsBridge;
  LAllowedCtx: ITemplateContext;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LBridge.AddScript('mutator', CMutateScript);
  LBridge.RegisterInto(LCtx);

  try
    TSempareDwsFunctions.DwsText(
      LCtx,
      TArray<TValue>.Create(
        'mutator',
        'Mutate',
        TValue.From<TMap>(CreateStagePayload('blocked'))
      )
    );
    Assert.Fail('Expected ETemplateDwsRuntimeError for blocked mutation.');
  except
    on E: ETemplateDwsRuntimeError do
      AssertContains('mutation', E.Message.ToLower);
  end;

  LAllowedCtx := Template.Context([eoNoDefaultFunctions]);
  LAllowedBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts]);
  LAllowedBridge.SetHostServices(
    CreateDefaultDwsHostServices(CreateAllowListMutationPolicy(['stage']))
  );
  LAllowedBridge.AddScript('mutator', CMutateScript);
  LAllowedBridge.RegisterInto(LAllowedCtx);

  Assert.AreEqual(
    'ready',
    TSempareDwsFunctions.DwsText(
      LAllowedCtx,
      TArray<TValue>.Create(
        'mutator',
        'Mutate',
        TValue.From<TMap>(CreateStagePayload('ready'))
      )
    )
  );
  Assert.AreEqual('ready', LAllowedCtx.Variables['stage'].AsString);
end;

initialization

TDUnitX.RegisterTestFixture(TDwsHostServicesTest);

end.
