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
unit Sempare.Template.DWS.Marshalling;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Types;

/// <summary>
/// Creates the default payload and result marshaller for the DWScript bridge.
/// </summary>
/// <returns>
/// A marshaller that normalizes Sempare values, explicit payloads, arrays, maps, and JSON-like results.
/// </returns>
function CreateDefaultDwsMarshaller: ITemplateDwsMarshaller;

implementation

uses
  System.SysUtils,
  System.Rtti,
  System.JSON,
  System.TypInfo,
  System.Variants,
  System.Generics.Collections,
  Sempare.Template.AST,
  Sempare.Template.Context,
  Sempare.Template.JSON,
  Sempare.Template.Util;

type
  TTemplateDwsMarshalState = class
  private
    FSeenObjects: TList<Pointer>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure EnterObject(
      const AObject: TObject;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AOptions: TTemplateDwsBridgeOptions
    );
    procedure LeaveObject(const AObject: TObject);
  end;

  TTemplateDwsMarshaller = class(TInterfacedObject, ITemplateDwsMarshaller)
  private
    function ContextRttiContext(const ACtx: ITemplateContext): PRttiContext;
    function UnwrapValue(const AValue: TValue): TValue;
    function NormalizeValue(
      const ACtx: ITemplateContext;
      const AValue: TValue;
      const AState: TTemplateDwsMarshalState;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AOptions: TTemplateDwsBridgeOptions
    ): TValue;
    function NormalizeMap(
      const ACtx: ITemplateContext;
      const AMap: TMap;
      const AState: TTemplateDwsMarshalState;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AOptions: TTemplateDwsBridgeOptions
    ): TMap;
    function NormalizeArray(
      const ACtx: ITemplateContext;
      const AValue: TValue;
      const AState: TTemplateDwsMarshalState;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AOptions: TTemplateDwsBridgeOptions
    ): TArray<TValue>;
    function NormalizeStructuredValue(
      const ACtx: ITemplateContext;
      const AValue: TValue;
      const AState: TTemplateDwsMarshalState;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AOptions: TTemplateDwsBridgeOptions
    ): TMap;
    function NormalizeVariantArray(
      const ACtx: ITemplateContext;
      const AValue: Variant;
      const AState: TTemplateDwsMarshalState;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AOptions: TTemplateDwsBridgeOptions
    ): TArray<TValue>;
    function JsonValueToTemplateValue(const AValue: TJsonValue): TValue;
    function TryConvertJsonLikeText(const AValue: string; out AResult: TValue): boolean;
    function TryGetImplicitRoot(const ACtx: ITemplateContext; out AValue: TValue): boolean;
    function ValueKindText(const AValue: TValue): string;
    function ScalarToText(
      const AValue: TValue;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string;
      const AOptions: TTemplateDwsBridgeOptions
    ): string;
  public
    function BuildPayload(
      const ACtx: ITemplateContext;
      const AExplicitPayload: TValue;
      const AOptions: TTemplateDwsBridgeOptions;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): TValue;
    function ConvertResultToTemplateValue(
      const AValue: TValue;
      const AOptions: TTemplateDwsBridgeOptions;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): TValue;
    function ConvertResultToText(
      const AValue: TValue;
      const AOptions: TTemplateDwsBridgeOptions;
      const AScriptName: string;
      const AEntryName: string;
      const AVersionTag: string
    ): string;
  end;

function CreateDefaultDwsMarshaller: ITemplateDwsMarshaller;
begin
  result := TTemplateDwsMarshaller.Create;
end;

constructor TTemplateDwsMarshalState.Create;
begin
  inherited;
  FSeenObjects := TList<Pointer>.Create;
end;

destructor TTemplateDwsMarshalState.Destroy;
begin
  FSeenObjects.Free;
  inherited;
end;

procedure TTemplateDwsMarshalState.EnterObject(
  const AObject: TObject;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
);
begin
  if AObject = nil then
    exit;

  if FSeenObjects.Contains(AObject) then
    raise ETemplateDwsMarshalError.CreateContext(
      'Cyclic object graph is not supported for DWScript payload marshalling.',
      AScriptName,
      AEntryName,
      AVersionTag,
      AOptions
    );

  FSeenObjects.Add(AObject);
end;

procedure TTemplateDwsMarshalState.LeaveObject(const AObject: TObject);
begin
  if AObject = nil then
    exit;
  FSeenObjects.Remove(AObject);
end;

function TTemplateDwsMarshaller.BuildPayload(
  const ACtx: ITemplateContext;
  const AExplicitPayload: TValue;
  const AOptions: TTemplateDwsBridgeOptions;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): TValue;
var
  LState: TTemplateDwsMarshalState;
  LPayload: TValue;
  LRoot: TValue;
  LMap: TMap;
begin
  LState := TTemplateDwsMarshalState.Create;
  try
    if AExplicitPayload.IsEmpty then
      LPayload := TValue.Empty
    else
      LPayload := NormalizeValue(ACtx, AExplicitPayload, LState, AScriptName, AEntryName, AVersionTag, AOptions);

    if (tdboPassRootData in AOptions) and TryGetImplicitRoot(ACtx, LRoot) then
    begin
      LRoot := NormalizeValue(ACtx, LRoot, LState, AScriptName, AEntryName, AVersionTag, AOptions);
      if LPayload.IsEmpty then
        exit(LRoot);

      if LPayload.IsType<TMap> then
      begin
        LMap := LPayload.AsType<TMap>.Clone;
        if not LMap.ContainsKey('_') then
          LMap.Add('_', LRoot);
        exit(TValue.From<TMap>(LMap));
      end;
    end;

    exit(LPayload);
  finally
    LState.Free;
  end;
end;

function TTemplateDwsMarshaller.ContextRttiContext(const ACtx: ITemplateContext): PRttiContext;
begin
  result := nil;
  if ACtx = nil then
    exit;
  if Assigned(ACtx.RttiContext) then
    result := ACtx.RttiContext();
end;

function TTemplateDwsMarshaller.ConvertResultToTemplateValue(
  const AValue: TValue;
  const AOptions: TTemplateDwsBridgeOptions;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): TValue;
begin
  if AValue.IsEmpty then
    exit(TValue.Empty);

  if AValue.IsType<TMap> then
    exit(TValue.From<TMap>(AValue.AsType<TMap>.Clone));

  if AValue.Kind in [tkDynArray, tkArray] then
    exit(TValue.From<TArray<TValue>>(AValue.AsType<TArray<TValue>>));

  if (tdboExpectJsonLikeReturn in AOptions) and
     (AValue.Kind in [tkString, tkLString, tkWString, tkUString, tkChar, tkWChar]) and
     TryConvertJsonLikeText(AValue.AsString, result) then
    exit;

  case AValue.Kind of
    tkString, tkLString, tkWString, tkUString, tkChar, tkWChar:
      exit(AValue.AsString);
    tkInteger, tkInt64:
      exit(AValue.AsInt64);
    tkFloat:
      exit(FloatToTValue(AValue.AsExtended));
    tkEnumeration:
      if AValue.TypeInfo = TypeInfo(boolean) then
        exit(AValue.AsBoolean)
      else
        exit(AValue.AsInt64);
    tkPointer:
      if AValue.AsType<Pointer> = nil then
        exit(TValue.From<Pointer>(nil));
    tkClass:
      if AValue.AsObject = nil then
        exit(TValue.From<Pointer>(nil));
  end;

  raise ETemplateDwsMarshalError.CreateContext(
    'Unsupported DWScript result kind for template value conversion: ' + ValueKindText(AValue) + '.',
    AScriptName,
    AEntryName,
    AVersionTag,
    AOptions
  );
end;

function TTemplateDwsMarshaller.ConvertResultToText(
  const AValue: TValue;
  const AOptions: TTemplateDwsBridgeOptions;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string
): string;
begin
  if AValue.IsEmpty then
    exit('');
  exit(ScalarToText(AValue, AScriptName, AEntryName, AVersionTag, AOptions));
end;

function TTemplateDwsMarshaller.JsonValueToTemplateValue(const AValue: TJsonValue): TValue;
var
  LArray: TArray<TValue>;
  LIdx: integer;
  LMap: TMap;
  LObject: TJSONObject;
  LPair: TJSONPair;
begin
  if AValue = nil then
    exit(TValue.Empty);

{$IFDEF SUPPORT_JSON_BOOL}
  if AValue is TJSONBool then
    exit(TJSONBool(AValue).AsBoolean);
{$ENDIF}

  if AValue is TJSONNull then
    exit(TValue.From<Pointer>(nil));

  if AValue is TJsonArray then
  begin
    SetLength(LArray, TJsonArray(AValue).Count);
    for LIdx := 0 to TJsonArray(AValue).Count - 1 do
      LArray[LIdx] := JsonValueToTemplateValue(TJsonArray(AValue).Items[LIdx]);
    exit(TValue.From<TArray<TValue>>(LArray));
  end;

  if AValue is TJSONObject then
  begin
    LMap := TMap.Create;
    LObject := TJSONObject(AValue);
    for LPair in LObject do
      LMap.Add(LPair.JsonString.Value, JsonValueToTemplateValue(LPair.JsonValue));
    exit(TValue.From<TMap>(LMap));
  end;

  if AValue is TJSONString then
    exit(TJSONString(AValue).Value);

  if AValue is TJSONNumber then
  begin
    if Pos('.', TJSONNumber(AValue).Value) > 0 then
      exit(FloatToTValue(TJSONNumber(AValue).AsDouble));
    exit(TJSONNumber(AValue).AsInt64);
  end;

{$IFNDEF SUPPORT_JSON_BOOL}
  if AValue is TJSONTrue then
    exit(true);
  if AValue is TJSONFalse then
    exit(false);
{$ENDIF}

  exit(TValue.Empty);
end;

function TTemplateDwsMarshaller.NormalizeArray(
  const ACtx: ITemplateContext;
  const AValue: TValue;
  const AState: TTemplateDwsMarshalState;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
): TArray<TValue>;
var
  LIdx: integer;
begin
  SetLength(result, AValue.GetArrayLength);
  for LIdx := 0 to High(result) do
    result[LIdx] := NormalizeValue(ACtx, AValue.GetArrayElement(LIdx), AState, AScriptName, AEntryName, AVersionTag, AOptions);
end;

function TTemplateDwsMarshaller.NormalizeVariantArray(
  const ACtx: ITemplateContext;
  const AValue: Variant;
  const AState: TTemplateDwsMarshalState;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
): TArray<TValue>;
var
  LHigh: integer;
  LIdx: integer;
  LLow: integer;
begin
  if VarArrayDimCount(AValue) <> 1 then
    raise ETemplateDwsMarshalError.CreateContext(
      'Only one-dimensional Variant arrays are supported for DWScript payload marshalling.',
      AScriptName,
      AEntryName,
      AVersionTag,
      AOptions
    );

  LLow := VarArrayLowBound(AValue, 1);
  LHigh := VarArrayHighBound(AValue, 1);
  SetLength(result, LHigh - LLow + 1);
  for LIdx := LLow to LHigh do
    result[LIdx - LLow] := NormalizeValue(
      ACtx,
      TValue.FromVariant(AValue[LIdx]),
      AState,
      AScriptName,
      AEntryName,
      AVersionTag,
      AOptions
    );
end;

function TTemplateDwsMarshaller.NormalizeMap(
  const ACtx: ITemplateContext;
  const AMap: TMap;
  const AState: TTemplateDwsMarshalState;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
): TMap;
var
  LPair: TPair<string, TValue>;
begin
  result := TMap.Create;
  for LPair in AMap.GetItems do
    result.Add(LPair.Key, NormalizeValue(ACtx, LPair.Value, AState, AScriptName, AEntryName, AVersionTag, AOptions));
end;

function TTemplateDwsMarshaller.NormalizeStructuredValue(
  const ACtx: ITemplateContext;
  const AValue: TValue;
  const AState: TTemplateDwsMarshalState;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
): TMap;
var
  LRttiCtx: PRttiContext;
  LRttiType: TRttiType;
  LMembers: TDictionary<string, boolean>;
  LField: TRttiField;
  LProperty: TRttiProperty;
  LObject: TObject;
  LPtr: Pointer;
  LName: string;
begin
  LObject := nil;

  if AValue.Kind = tkClass then
  begin
    LObject := AValue.AsObject;
    if LObject = nil then
      exit(TMap.Create);
    AState.EnterObject(LObject, AScriptName, AEntryName, AVersionTag, AOptions);
    LPtr := LObject;
  end
  else
  begin
    LPtr := AValue.GetReferenceToRawData;
  end;

  LRttiCtx := ContextRttiContext(ACtx);
  if LRttiCtx = nil then
    raise ETemplateDwsMarshalError.CreateContext(
      'A valid RTTI context is required for structured payload marshalling.',
      AScriptName,
      AEntryName,
      AVersionTag,
      AOptions
    );

  LRttiType := LRttiCtx.GetType(AValue.TypeInfo);
  if LRttiType = nil then
    raise ETemplateDwsMarshalError.CreateContext(
      'No RTTI metadata is available for payload kind ' + ValueKindText(AValue) + '.',
      AScriptName,
      AEntryName,
      AVersionTag,
      AOptions
    );

  result := TMap.Create;
  LMembers := TDictionary<string, boolean>.Create;
  try
    for LField in LRttiType.GetFields do
    begin
      if (AValue.Kind = tkClass) and not (LField.Visibility in [mvPublic, mvPublished]) then
        continue;
      LName := LField.Name;
      if LMembers.ContainsKey(LName) then
        continue;
      result.Add(LName, NormalizeValue(ACtx, LField.GetValue(LPtr), AState, AScriptName, AEntryName, AVersionTag, AOptions));
      LMembers.Add(LName, true);
    end;

    for LProperty in LRttiType.GetProperties do
    begin
      if not LProperty.IsReadable then
        continue;
      if (AValue.Kind = tkClass) and not (LProperty.Visibility in [mvPublic, mvPublished]) then
        continue;

      LName := LProperty.Name;
      if LMembers.ContainsKey(LName) then
        continue;
      try
        result.Add(LName, NormalizeValue(ACtx, LProperty.GetValue(LPtr), AState, AScriptName, AEntryName, AVersionTag, AOptions));
        LMembers.Add(LName, true);
      except
        continue;
      end;
    end;
  finally
    LMembers.Free;
    if LObject <> nil then
      AState.LeaveObject(LObject);
  end;
end;

function TTemplateDwsMarshaller.NormalizeValue(
  const ACtx: ITemplateContext;
  const AValue: TValue;
  const AState: TTemplateDwsMarshalState;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
): TValue;
var
  LValue: TValue;
  LMapExpr: IMapExpr;
begin
  LValue := UnwrapValue(AValue);

  if LValue.IsEmpty then
    exit(TValue.Empty);

  if LValue.IsType<TMap> then
    exit(TValue.From<TMap>(NormalizeMap(ACtx, LValue.AsType<TMap>, AState, AScriptName, AEntryName, AVersionTag, AOptions)));

  if LValue.IsType<IMapExpr> then
  begin
    LMapExpr := LValue.AsType<IMapExpr>;
    exit(TValue.From<TMap>(NormalizeMap(ACtx, LMapExpr.GetMap, AState, AScriptName, AEntryName, AVersionTag, AOptions)));
  end;

  case LValue.Kind of
    tkString, tkLString, tkWString, tkUString, tkChar, tkWChar:
      exit(LValue.AsString);

    tkInteger, tkInt64:
      exit(LValue.AsInt64);

    tkFloat:
      exit(FloatToTValue(LValue.AsExtended));

    tkEnumeration:
      begin
        if LValue.TypeInfo = TypeInfo(boolean) then
          exit(LValue.AsBoolean);
        exit(LValue.AsInt64);
      end;

    tkPointer:
      begin
        if LValue.AsType<Pointer> = nil then
          exit(TValue.From<Pointer>(nil));
      end;

    tkVariant:
      begin
        if VarIsArray(LValue.AsVariant) then
          exit(TValue.From<TArray<TValue>>(NormalizeVariantArray(
            ACtx,
            LValue.AsVariant,
            AState,
            AScriptName,
            AEntryName,
            AVersionTag,
            AOptions
          )));
        exit(NormalizeValue(ACtx, TValue.FromVariant(LValue.AsVariant), AState, AScriptName, AEntryName, AVersionTag, AOptions));
      end;

    tkDynArray, tkArray:
      begin
        exit(TValue.From<TArray<TValue>>(NormalizeArray(ACtx, LValue, AState, AScriptName, AEntryName, AVersionTag, AOptions)));
      end;

    tkClass:
      begin
        if LValue.AsObject = nil then
          exit(TValue.From<Pointer>(nil));
        exit(TValue.From<TMap>(NormalizeStructuredValue(ACtx, LValue, AState, AScriptName, AEntryName, AVersionTag, AOptions)));
      end;

    tkRecord{$IFDEF SUPPORT_CUSTOM_MANAGED_RECORDS}, tkMRecord{$ENDIF}:
      begin
        exit(TValue.From<TMap>(NormalizeStructuredValue(ACtx, LValue, AState, AScriptName, AEntryName, AVersionTag, AOptions)));
      end;
  end;

  raise ETemplateDwsMarshalError.CreateContext(
    'Unsupported payload kind for DWScript marshalling: ' + ValueKindText(LValue) + '.',
    AScriptName,
    AEntryName,
    AVersionTag,
    AOptions
  );
end;

function TTemplateDwsMarshaller.ScalarToText(
  const AValue: TValue;
  const AScriptName: string;
  const AEntryName: string;
  const AVersionTag: string;
  const AOptions: TTemplateDwsBridgeOptions
): string;
var
  LFormatSettings: TFormatSettings;
begin
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
    'DwsText expects a scalar/string-compatible result, but got ' + ValueKindText(AValue) + '.',
    AScriptName,
    AEntryName,
    AVersionTag,
    AOptions
  );
end;

function TTemplateDwsMarshaller.TryConvertJsonLikeText(const AValue: string; out AResult: TValue): boolean;
var
  LJson: TJsonValue;
  LTrimmed: string;
begin
  AResult := TValue.Empty;
  LTrimmed := Trim(AValue);
  if LTrimmed = '' then
    exit(false);

  case LTrimmed[1] of
    '{', '[', '"', '-', '0' .. '9', 't', 'f', 'n':
      ;
  else
    exit(false);
  end;

  LJson := TJSONObject.ParseJSONValue(LTrimmed);
  try
    if LJson = nil then
      exit(false);
    AResult := JsonValueToTemplateValue(LJson);
    exit(true);
  finally
    LJson.Free;
  end;
end;

function TTemplateDwsMarshaller.TryGetImplicitRoot(const ACtx: ITemplateContext; out AValue: TValue): boolean;
begin
  if ACtx = nil then
    exit(false);
  exit(ACtx.TryGetVariable('_', AValue));
end;

function TTemplateDwsMarshaller.UnwrapValue(const AValue: TValue): TValue;
begin
  if AValue.TypeInfo = TypeInfo(TValue) then
    exit(UnwrapValue(AValue.AsType<TValue>));
  exit(AValue);
end;

function TTemplateDwsMarshaller.ValueKindText(const AValue: TValue): string;
begin
  if AValue.IsEmpty then
    exit('empty');
  if AValue.TypeInfo = nil then
    exit('untyped');
  exit(GetTypeName(AValue.TypeInfo));
end;

end.

