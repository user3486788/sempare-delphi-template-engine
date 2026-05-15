unit Sempare.Template.TestDwsProvidersAdvanced;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDwsProvidersAdvancedTest = class
  public
    [Test]
    procedure BundledProviderUsesVersionedNamedScripts;
    [Test]
    procedure CompositeProviderFallsBackFromRegistryToFileSystem;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.Provider,
  Sempare.Template.DWS.Types;

const
  CRegistryScript =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 1;' + sLineBreak +
    'end;';

  CFileScript =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 42;' + sLineBreak +
    'end;';

  CBundleScriptV1 =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 7;' + sLineBreak +
    'end;';

  CBundleScriptV2 =
    'function Value : Integer;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := 11;' + sLineBreak +
    'end;';

function NewTempFolder: string;
var
  LToken: string;
begin
  LToken := StringReplace(TGuid.NewGuid.ToString, '-', '', [rfReplaceAll]);
  LToken := StringReplace(LToken, '{', '', [rfReplaceAll]);
  LToken := StringReplace(LToken, '}', '', [rfReplaceAll]);
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'dws-provider-temp\' + LToken);
  ForceDirectories(Result);
end;

procedure TDwsProvidersAdvancedTest.BundledProviderUsesVersionedNamedScripts;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
  LProvider: ITemplateDwsScriptProvider;
begin
  LCtx := Template.Context([eoNoDefaultFunctions]);
  LBridge := CreateSempareDwsBridge;
  LProvider := CreateBundledDwsScriptProvider(
    'bundle-v1',
    [TTemplateDwsScriptDefinition.Create('calc', CBundleScriptV1)]
  );
  LBridge.SetScriptProvider(LProvider);
  LBridge.RegisterInto(LCtx);

  Assert.IsTrue(Pos('bundle-v1', LProvider.VersionTag('calc')) > 0);
  Assert.AreEqual('7', Template.Eval(LCtx, '<% DwsCall(''calc'', ''Value'') %>'));

  LProvider := CreateBundledDwsScriptProvider(
    'bundle-v2',
    [TTemplateDwsScriptDefinition.Create('calc', CBundleScriptV2)]
  );
  LBridge.SetScriptProvider(LProvider);
  Assert.IsTrue(Pos('bundle-v2', LProvider.VersionTag('calc')) > 0);
  Assert.AreEqual('11', Template.Eval(LCtx, '<% DwsCall(''calc'', ''Value'') %>'));
end;

procedure TDwsProvidersAdvancedTest.CompositeProviderFallsBackFromRegistryToFileSystem;
var
  LBridge: ISempareDwsBridge;
  LCtx: ITemplateContext;
  LProvider: ITemplateDwsScriptProvider;
  LRegistry: ITemplateDwsScriptRegistry;
  LRoot: string;
begin
  LRoot := NewTempFolder;
  try
    TFile.WriteAllText(TPath.Combine(LRoot, 'calc.dws'), CFileScript, TEncoding.UTF8);

    LCtx := Template.Context([eoNoDefaultFunctions]);
    LBridge := CreateSempareDwsBridge;
    LRegistry := CreateInMemoryDwsScriptRegistry;
    LRegistry.AddOrSet('calc', CRegistryScript);
    LProvider := CreateCompositeDwsScriptProvider([
      LRegistry,
      CreateFileSystemDwsScriptProvider(LRoot)
    ]);
    LBridge.SetScriptProvider(LProvider);
    LBridge.RegisterInto(LCtx);

    Assert.AreEqual('1', Template.Eval(LCtx, '<% DwsCall(''calc'', ''Value'') %>'));

    LRegistry.Remove('calc');
    LBridge.ClearCompileCache;
    Assert.AreEqual('42', Template.Eval(LCtx, '<% DwsCall(''calc'', ''Value'') %>'));
  finally
    TDirectory.Delete(LRoot, true);
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TDwsProvidersAdvancedTest);

end.
