unit Sempare.Template.TestDwsProviderCache;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDwsProviderCacheTest = class
  public
    [Test]
    procedure CompileCacheInvalidatesEntriesByScriptName;
    [Test]
    procedure RegistryTracksScriptLifecycleAndVersionTags;
  end;

implementation

uses
  Sempare.Template.DWS.Cache,
  Sempare.Template.DWS.Provider,
  Sempare.Template.DWS.Types;

type
  TStubCompiledScript = class(TInterfacedObject, ITemplateDwsCompiledScript)
  private
    FScriptName: string;
    FVersionTag: string;
  public
    constructor Create(const AScriptName, AVersionTag: string);
    function GetScriptName: string;
    function GetVersionTag: string;
  end;

constructor TStubCompiledScript.Create(const AScriptName, AVersionTag: string);
begin
  inherited Create;
  FScriptName := AScriptName;
  FVersionTag := AVersionTag;
end;

function TStubCompiledScript.GetScriptName: string;
begin
  Result := FScriptName;
end;

function TStubCompiledScript.GetVersionTag: string;
begin
  Result := FVersionTag;
end;

procedure TDwsProviderCacheTest.CompileCacheInvalidatesEntriesByScriptName;
var
  LCache: ITemplateDwsCompileCache;
  LCompiled: ITemplateDwsCompiledScript;
begin
  LCache := CreateDefaultDwsCompileCache;
  LCache.Put('calc', 'v1', TStubCompiledScript.Create('calc', 'v1'));
  LCache.Put('calc', 'v2', TStubCompiledScript.Create('calc', 'v2'));
  LCache.Put('other', 'v1', TStubCompiledScript.Create('other', 'v1'));

  Assert.IsTrue(LCache.TryGet('CALC', 'v1', LCompiled));
  Assert.AreEqual('v1', LCompiled.VersionTag);

  Assert.IsTrue(LCache.TryGet('calc', 'v2', LCompiled));
  Assert.AreEqual('v2', LCompiled.VersionTag);

  LCache.Invalidate('calc');

  Assert.IsFalse(LCache.TryGet('calc', 'v1', LCompiled));
  Assert.IsFalse(LCache.TryGet('calc', 'v2', LCompiled));
  Assert.IsTrue(LCache.TryGet('other', 'v1', LCompiled));
  Assert.AreEqual('other', LCompiled.ScriptName);
end;

procedure TDwsProviderCacheTest.RegistryTracksScriptLifecycleAndVersionTags;
var
  LRegistry: ITemplateDwsScriptRegistry;
  LScript: TTemplateDwsScript;
  LVersion1: string;
  LVersion2: string;
begin
  LRegistry := CreateInMemoryDwsScriptRegistry;

  Assert.IsFalse(LRegistry.Exists('calc'));
  Assert.AreEqual('', LRegistry.VersionTag('calc'));

  LRegistry.AddOrSet('calc', 'function Value : Integer; begin Result := 1; end;');
  Assert.IsTrue(LRegistry.Exists('CALC'));
  Assert.IsTrue(LRegistry.TryGetScript('calc', LScript));
  Assert.AreEqual('function Value : Integer; begin Result := 1; end;', LScript.Source);

  LVersion1 := LRegistry.VersionTag('calc');
  Assert.IsTrue(LVersion1 <> '');

  LRegistry.AddOrSet('CALC', 'function Value : Integer; begin Result := 1; end;');
  Assert.AreEqual(LVersion1, LRegistry.VersionTag('calc'));

  LRegistry.AddOrSet('calc', 'function Value : Integer; begin Result := 2; end;');
  LVersion2 := LRegistry.VersionTag('calc');
  Assert.IsTrue(LVersion2 <> '');
  Assert.AreNotEqual(LVersion1, LVersion2);

  LRegistry.Remove('calc');
  Assert.IsFalse(LRegistry.Exists('calc'));
  Assert.AreEqual('', LRegistry.VersionTag('calc'));
  Assert.IsFalse(LRegistry.TryGetScript('calc', LScript));
end;

initialization

TDUnitX.RegisterTestFixture(TDwsProviderCacheTest);

end.
