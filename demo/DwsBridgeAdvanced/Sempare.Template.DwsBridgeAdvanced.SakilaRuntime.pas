unit Sempare.Template.DwsBridgeAdvanced.SakilaRuntime;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Types;

function CreateSakilaDwsRuntime(const ADatabaseFileName, AOutputRoot: string): ITemplateDwsRuntime; overload;
function CreateSakilaDwsRuntime(const ADatabaseFileName: string): ITemplateDwsRuntime; overload;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.DApt,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Option,
  dwsComp,
  dwsExprs,
  Sempare.Template.DWS.Runtime,
  Sempare.Template.DwsBridgeAdvanced.PosterSupport;

type
  TSakilaDwsRuntimeConfigurator = class(TInterfacedObject, ITemplateDwsRuntimeConfigurator)
  private
    FDatabaseFileName: string;
    function OpenConnection: TFDConnection;
    function FieldAsJsonValue(const AField: TField): TJSONValue;
    function FieldAsInvariantText(const AField: TField): string;
    procedure QueryJsonEval(Info: TProgramInfo);
    procedure ValueTextEval(Info: TProgramInfo);
  public
    constructor Create(const ADatabaseFileName: string);
    procedure ConfigureScript(const AScript: TDelphiWebScript);
  end;

function CreateSakilaDwsRuntime(const ADatabaseFileName, AOutputRoot: string): ITemplateDwsRuntime;
var
  LConfigurator: ITemplateDwsRuntimeConfigurator;
begin
  LConfigurator := CreateCompositeDwsRuntimeConfigurator(
    [
      TSakilaDwsRuntimeConfigurator.Create(ADatabaseFileName),
      CreatePosterDwsRuntimeConfigurator(AOutputRoot)
    ]
  );
  Result := CreateDefaultDwsRuntime(LConfigurator);
end;

function CreateSakilaDwsRuntime(const ADatabaseFileName: string): ITemplateDwsRuntime;
begin
  Result := CreateSakilaDwsRuntime(
    ADatabaseFileName,
    TPath.Combine(TPath.GetDirectoryName(TPath.GetFullPath(ADatabaseFileName)), '..\output')
  );
end;

constructor TSakilaDwsRuntimeConfigurator.Create(const ADatabaseFileName: string);
begin
  inherited Create;
  FDatabaseFileName := TPath.GetFullPath(ADatabaseFileName);
  if not TFile.Exists(FDatabaseFileName) then
    raise Exception.Create('Sakila demo database not found: ' + FDatabaseFileName);
end;

procedure TSakilaDwsRuntimeConfigurator.ConfigureScript(const AScript: TDelphiWebScript);
var
  LUnit: TdwsUnit;
  LFunction: TdwsFunction;
begin
  LUnit := TdwsUnit.Create(AScript);
  LUnit.UnitName := 'SakilaDb';
  LUnit.Script := AScript;

  LFunction := LUnit.Functions.Add('QueryJson', 'String');
  LFunction.Parameters.Add('Sql', 'String');
  LFunction.OnEval := QueryJsonEval;

  LFunction := LUnit.Functions.Add('ValueText', 'String');
  LFunction.Parameters.Add('Sql', 'String');
  LFunction.OnEval := ValueTextEval;
end;

function TSakilaDwsRuntimeConfigurator.FieldAsInvariantText(const AField: TField): string;
var
  LFormatSettings: TFormatSettings;
begin
  if (AField = nil) or AField.IsNull then
    Exit('');

  LFormatSettings := TFormatSettings.Create('en-US');
  case AField.DataType of
    ftSmallint, ftInteger, ftWord, ftLongWord, ftShortint, ftByte, ftLargeint, ftAutoInc:
      Result := IntToStr(AField.AsLargeInt);
    ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftSingle, ftExtended:
      Result := FloatToStr(AField.AsFloat, LFormatSettings);
    ftDate, ftTime, ftDateTime, ftTimeStamp:
      Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', AField.AsDateTime, LFormatSettings);
  else
    Result := AField.AsString;
  end;
end;

function TSakilaDwsRuntimeConfigurator.FieldAsJsonValue(const AField: TField): TJSONValue;
begin
  if (AField = nil) or AField.IsNull then
    Exit(TJSONNull.Create);

  case AField.DataType of
    ftSmallint, ftInteger, ftWord, ftLongWord, ftShortint, ftByte, ftLargeint, ftAutoInc:
      Result := TJSONNumber.Create(IntToStr(AField.AsLargeInt));
    ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftSingle, ftExtended:
      Result := TJSONNumber.Create(FieldAsInvariantText(AField));
    ftBoolean:
      if AField.AsBoolean then
        Result := TJSONTrue.Create
      else
        Result := TJSONFalse.Create;
  else
    Result := TJSONString.Create(FieldAsInvariantText(AField));
  end;
end;

function TSakilaDwsRuntimeConfigurator.OpenConnection: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.DriverName := 'SQLite';
  Result.Params.Values['Database'] := FDatabaseFileName;
  Result.Connected := True;
end;

procedure TSakilaDwsRuntimeConfigurator.QueryJsonEval(Info: TProgramInfo);
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LObject: TJSONObject;
  LFieldIndex: Integer;
begin
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  LArray := TJSONArray.Create;
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text := Info.ParamAsString[0];
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LObject := TJSONObject.Create;
      for LFieldIndex := 0 to LQuery.Fields.Count - 1 do
        LObject.AddPair(LQuery.Fields[LFieldIndex].FieldName, FieldAsJsonValue(LQuery.Fields[LFieldIndex]));
      LArray.AddElement(LObject);
      LQuery.Next;
    end;

    Info.ResultAsString := LArray.ToString;
  finally
    LArray.Free;
    LQuery.Free;
    LConnection.Free;
  end;
end;

procedure TSakilaDwsRuntimeConfigurator.ValueTextEval(Info: TProgramInfo);
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text := Info.ParamAsString[0];
    LQuery.Open;
    if LQuery.Eof or (LQuery.FieldCount = 0) then
      Info.ResultAsString := ''
    else
      Info.ResultAsString := FieldAsInvariantText(LQuery.Fields[0]);
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

end.