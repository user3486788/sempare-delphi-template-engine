unit Sempare.Template.TestDwsMarshalling;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDwsMarshallingTest = class
  public
    [Test]
    procedure BuildPayloadAddsRootOnlyWhenRequested;
    [Test]
    procedure BuildPayloadDoesNotImportAmbientVariables;
    [Test]
    procedure BuildPayloadKeepsExplicitRootPayload;
    [Test]
    procedure BuildPayloadRejectsUnsupportedInterfacePayloads;
  end;

implementation

uses
  System.Rtti,
  System.SysUtils,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS.Marshalling,
  Sempare.Template.DWS.Types,
  Sempare.Template.Util;

procedure AssertContains(const ANeedle, AHaystack: string);
begin
  Assert.IsTrue(Pos(ANeedle, AHaystack) > 0, Format('Expected "%s" to be present in "%s".', [ANeedle, AHaystack]));
end;

function CreateModeMap: TMap;
begin
  Result := TMap.Create;
  Result.Add('mode', 'net');
end;

function CreateRootMap: TMap;
begin
  Result := TMap.Create;
  Result.Add('id', 42);
  Result.Add('name', 'root');
end;

procedure TDwsMarshallingTest.BuildPayloadAddsRootOnlyWhenRequested;
var
  LCtx: ITemplateContext;
  LMarshaller: ITemplateDwsMarshaller;
  LPayload: TValue;
  LPayloadMap: TMap;
  LRootMap: TMap;
begin
  LCtx := Template.Context;
  LCtx.Variables['_'] := TValue.From<TMap>(CreateRootMap);
  LMarshaller := CreateDefaultDwsMarshaller;

  LPayload := LMarshaller.BuildPayload(
    LCtx,
    TValue.From<TMap>(CreateModeMap),
    [tdboPassRootData],
    'pricing',
    'Calc',
    'v1'
  );

  Assert.IsTrue(LPayload.IsType<TMap>);
  LPayloadMap := LPayload.AsType<TMap>;
  Assert.AreEqual('net', LPayloadMap['mode'].AsString);
  Assert.IsTrue(LPayloadMap.ContainsKey('_'));

  LRootMap := LPayloadMap['_'].AsType<TMap>;
  Assert.AreEqual(Int64(42), LRootMap['id'].AsInt64);
  Assert.AreEqual('root', LRootMap['name'].AsString);
end;

procedure TDwsMarshallingTest.BuildPayloadDoesNotImportAmbientVariables;
var
  LCtx: ITemplateContext;
  LMarshaller: ITemplateDwsMarshaller;
  LPayload: TValue;
  LPayloadMap: TMap;
begin
  LCtx := Template.Context;
  LCtx.Variables['_'] := TValue.From<TMap>(CreateRootMap);
  LCtx.Variables['secret'] := 'hidden';
  LMarshaller := CreateDefaultDwsMarshaller;

  LPayload := LMarshaller.BuildPayload(
    LCtx,
    TValue.From<TMap>(CreateModeMap),
    [],
    'pricing',
    'Calc',
    'v1'
  );

  Assert.IsTrue(LPayload.IsType<TMap>);
  LPayloadMap := LPayload.AsType<TMap>;
  Assert.AreEqual('net', LPayloadMap['mode'].AsString);
  Assert.IsFalse(LPayloadMap.ContainsKey('_'));
  Assert.IsFalse(LPayloadMap.ContainsKey('secret'));
end;

procedure TDwsMarshallingTest.BuildPayloadKeepsExplicitRootPayload;
var
  LCtx: ITemplateContext;
  LMarshaller: ITemplateDwsMarshaller;
  LPayload: TValue;
  LPayloadMap: TMap;
begin
  LCtx := Template.Context;
  LCtx.Variables['_'] := TValue.From<TMap>(CreateRootMap);
  LCtx.Variables['secret'] := 'hidden';
  LMarshaller := CreateDefaultDwsMarshaller;

  LPayload := LMarshaller.BuildPayload(
    LCtx,
    LCtx.Variables['_'],
    [],
    'pricing',
    'RootOnly',
    'v1'
  );

  Assert.IsTrue(LPayload.IsType<TMap>);
  LPayloadMap := LPayload.AsType<TMap>;
  Assert.AreEqual(Int64(42), LPayloadMap['id'].AsInt64);
  Assert.AreEqual('root', LPayloadMap['name'].AsString);
  Assert.IsFalse(LPayloadMap.ContainsKey('secret'));
end;

procedure TDwsMarshallingTest.BuildPayloadRejectsUnsupportedInterfacePayloads;
var
  LCtx: ITemplateContext;
  LMarshaller: ITemplateDwsMarshaller;
  LIntf: IInterface;
begin
  LCtx := Template.Context;
  LMarshaller := CreateDefaultDwsMarshaller;
  LIntf := TInterfacedObject.Create;

  try
    LMarshaller.BuildPayload(
      LCtx,
      TValue.From<IInterface>(LIntf),
      [],
      'pricing',
      'Unsupported',
      'v1'
    );
    Assert.Fail('Expected ETemplateDwsMarshalError.');
  except
    on E: ETemplateDwsMarshalError do
    begin
      AssertContains('script=''pricing''', E.Message);
      AssertContains('entry=''Unsupported''', E.Message);
    end;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TDwsMarshallingTest);

end.
