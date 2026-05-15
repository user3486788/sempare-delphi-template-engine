unit Sempare.Template.DwsBridgeAdvanced.PosterSupport;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Runtime;

function CreatePosterDwsRuntimeConfigurator(const AOutputRoot: string): ITemplateDwsRuntimeConfigurator;
function CreateCompositeDwsRuntimeConfigurator(
  const AConfigurators: array of ITemplateDwsRuntimeConfigurator
): ITemplateDwsRuntimeConfigurator;
function NormalizeDemoSlug(const AText: string): string;
function PosterRelativePath(const AScope, ACacheKey: string): string;
function PagesFolderName(const AScope: string): string;

implementation

uses
  System.Classes,
  System.Character,
  System.IOUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding,
  System.SysUtils,
  dwsComp,
  dwsExprs;

type
  TCompositeDwsRuntimeConfigurator = class(TInterfacedObject, ITemplateDwsRuntimeConfigurator)
  private
    FConfigurators: TArray<ITemplateDwsRuntimeConfigurator>;
  public
    constructor Create(const AConfigurators: array of ITemplateDwsRuntimeConfigurator);
    procedure ConfigureScript(const AScript: TDelphiWebScript);
  end;

  TPosterDwsRuntimeConfigurator = class(TInterfacedObject, ITemplateDwsRuntimeConfigurator)
  private
    FOutputRoot: string;
    function EscapeSvgText(const AText: string): string;
    function BuildPosterUrl(const ATitle, ASubtitle: string): string;
    function BuildPlaceholderSvg(const ATitle, ASubtitle: string): string;
    function AbsolutePosterFileName(const AScope, ACacheKey: string): string;
    function TryDownloadPoster(const ASourceUrl, ATargetFileName: string): Boolean;
    procedure EnsureCachedPosterEval(Info: TProgramInfo);
    procedure PosterUrlEval(Info: TProgramInfo);
    procedure SlugEval(Info: TProgramInfo);
  public
    constructor Create(const AOutputRoot: string);
    procedure ConfigureScript(const AScript: TDelphiWebScript);
  end;

function NormalizeDemoSlug(const AText: string): string;
var
  LChar: Char;
  LBuilder: TStringBuilder;
  LNeedsDash: Boolean;
begin
  LBuilder := TStringBuilder.Create;
  try
    LNeedsDash := False;
    for LChar in Trim(AText) do
    begin
      if LChar.IsLetterOrDigit then
      begin
        if LNeedsDash and (LBuilder.Length > 0) and (LBuilder.Chars[LBuilder.Length - 1] <> '-') then
          LBuilder.Append('-');
        LBuilder.Append(LChar.ToLower);
        LNeedsDash := False;
      end
      else
        LNeedsDash := LBuilder.Length > 0;
    end;
    Result := LBuilder.ToString.Trim(['-']);
  finally
    LBuilder.Free;
  end;

  if Result = '' then
    Result := 'item';
end;

function PagesFolderName(const AScope: string): string;
begin
  Result := NormalizeDemoSlug(AScope) + '-pages';
end;

function PosterRelativePath(const AScope, ACacheKey: string): string;
begin
  Result := 'poster-cache/' + NormalizeDemoSlug(AScope) + '/' + NormalizeDemoSlug(ACacheKey) + '.svg';
end;

function CreateCompositeDwsRuntimeConfigurator(
  const AConfigurators: array of ITemplateDwsRuntimeConfigurator
): ITemplateDwsRuntimeConfigurator;
begin
  Result := TCompositeDwsRuntimeConfigurator.Create(AConfigurators);
end;

function CreatePosterDwsRuntimeConfigurator(const AOutputRoot: string): ITemplateDwsRuntimeConfigurator;
begin
  Result := TPosterDwsRuntimeConfigurator.Create(AOutputRoot);
end;

function TPosterDwsRuntimeConfigurator.AbsolutePosterFileName(const AScope, ACacheKey: string): string;
var
  LRelativePath: string;
begin
  LRelativePath := StringReplace(PosterRelativePath(AScope, ACacheKey), '/', PathDelim, [rfReplaceAll]);
  Result := TPath.Combine(FOutputRoot, LRelativePath);
end;

function TPosterDwsRuntimeConfigurator.BuildPlaceholderSvg(const ATitle, ASubtitle: string): string;
var
  LTitle: string;
  LSubtitle: string;
begin
  LTitle := EscapeSvgText(ATitle);
  LSubtitle := EscapeSvgText(ASubtitle);
  Result :=
    '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="900" viewBox="0 0 600 900">' +
    '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">' +
    '<stop offset="0%" stop-color="#1f2933"/><stop offset="100%" stop-color="#a64b2a"/>' +
    '</linearGradient></defs>' +
    '<rect width="600" height="900" fill="url(#g)"/>' +
    '<rect x="34" y="34" width="532" height="832" rx="28" fill="rgba(255,255,255,0.08)" stroke="rgba(255,255,255,0.16)"/>' +
    '<text x="300" y="360" text-anchor="middle" fill="#f8fafc" font-family="Segoe UI, Arial, sans-serif" font-size="34" font-weight="700">' + LTitle + '</text>' +
    '<text x="300" y="420" text-anchor="middle" fill="#fde68a" font-family="Segoe UI, Arial, sans-serif" font-size="20">' + LSubtitle + '</text>' +
    '<text x="300" y="810" text-anchor="middle" fill="#e5e7eb" font-family="Segoe UI, Arial, sans-serif" font-size="16">Sempare DWS poster cache fallback</text>' +
    '</svg>';
end;

function TPosterDwsRuntimeConfigurator.BuildPosterUrl(const ATitle, ASubtitle: string): string;
var
  LText: string;
begin
  if Trim(ASubtitle) <> '' then
    LText := Trim(ATitle) + ' | ' + Trim(ASubtitle)
  else
    LText := Trim(ATitle);
  Result := 'https://placehold.co/600x900/1f2933/F8FAFC/svg?text=' + TNetEncoding.URL.Encode(LText);
end;

procedure TPosterDwsRuntimeConfigurator.ConfigureScript(const AScript: TDelphiWebScript);
var
  LUnit: TdwsUnit;
  LFunction: TdwsFunction;
begin
  LUnit := TdwsUnit.Create(AScript);
  LUnit.UnitName := 'PosterCache';
  LUnit.Script := AScript;

  LFunction := LUnit.Functions.Add('Slug', 'String');
  LFunction.Parameters.Add('Text', 'String');
  LFunction.OnEval := SlugEval;

  LFunction := LUnit.Functions.Add('PosterUrl', 'String');
  LFunction.Parameters.Add('Title', 'String');
  LFunction.Parameters.Add('Subtitle', 'String');
  LFunction.OnEval := PosterUrlEval;

  LFunction := LUnit.Functions.Add('EnsureCachedPoster', 'String');
  LFunction.Parameters.Add('Scope', 'String');
  LFunction.Parameters.Add('CacheKey', 'String');
  LFunction.Parameters.Add('SourceUrl', 'String');
  LFunction.Parameters.Add('Title', 'String');
  LFunction.Parameters.Add('Subtitle', 'String');
  LFunction.OnEval := EnsureCachedPosterEval;
end;

constructor TCompositeDwsRuntimeConfigurator.Create(const AConfigurators: array of ITemplateDwsRuntimeConfigurator);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FConfigurators, Length(AConfigurators));
  for LIndex := 0 to High(AConfigurators) do
    FConfigurators[LIndex] := AConfigurators[LIndex];
end;

procedure TCompositeDwsRuntimeConfigurator.ConfigureScript(const AScript: TDelphiWebScript);
var
  LConfigurator: ITemplateDwsRuntimeConfigurator;
begin
  for LConfigurator in FConfigurators do
    if LConfigurator <> nil then
      LConfigurator.ConfigureScript(AScript);
end;

constructor TPosterDwsRuntimeConfigurator.Create(const AOutputRoot: string);
begin
  inherited Create;
  FOutputRoot := TPath.GetFullPath(AOutputRoot);
  TDirectory.CreateDirectory(FOutputRoot);
end;

function TPosterDwsRuntimeConfigurator.EscapeSvgText(const AText: string): string;
begin
  Result := AText;
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
end;

procedure TPosterDwsRuntimeConfigurator.EnsureCachedPosterEval(Info: TProgramInfo);
var
  LScope: string;
  LCacheKey: string;
  LSourceUrl: string;
  LTitle: string;
  LSubtitle: string;
  LTargetFileName: string;
  LFolder: string;
begin
  LScope := Info.ParamAsString[0];
  LCacheKey := Info.ParamAsString[1];
  LSourceUrl := Info.ParamAsString[2];
  LTitle := Info.ParamAsString[3];
  LSubtitle := Info.ParamAsString[4];
  LTargetFileName := AbsolutePosterFileName(LScope, LCacheKey);
  LFolder := TPath.GetDirectoryName(LTargetFileName);
  TDirectory.CreateDirectory(LFolder);

  if (not TFile.Exists(LTargetFileName)) or (TFile.GetSize(LTargetFileName) = 0) then
  begin
    if not TryDownloadPoster(LSourceUrl, LTargetFileName) then
      TFile.WriteAllText(LTargetFileName, BuildPlaceholderSvg(LTitle, LSubtitle), TEncoding.UTF8);
  end;

  Info.ResultAsString := PosterRelativePath(LScope, LCacheKey);
end;

procedure TPosterDwsRuntimeConfigurator.PosterUrlEval(Info: TProgramInfo);
begin
  Info.ResultAsString := BuildPosterUrl(Info.ParamAsString[0], Info.ParamAsString[1]);
end;

procedure TPosterDwsRuntimeConfigurator.SlugEval(Info: TProgramInfo);
begin
  Info.ResultAsString := NormalizeDemoSlug(Info.ParamAsString[0]);
end;

function TPosterDwsRuntimeConfigurator.TryDownloadPoster(const ASourceUrl, ATargetFileName: string): Boolean;
var
  LClient: THTTPClient;
  LResponse: IHTTPResponse;
  LTempFileName: string;
  LStream: TFileStream;
begin
  Result := False;
  if Trim(ASourceUrl) = '' then
    Exit;

  LTempFileName := ATargetFileName + '.download';
  if TFile.Exists(LTempFileName) then
    TFile.Delete(LTempFileName);

  LClient := THTTPClient.Create;
  try
    LClient.ConnectionTimeout := 5000;
    LClient.ResponseTimeout := 10000;
    LClient.UserAgent := 'Sempare-DwsBridgeAdvanced/1.0';

    LStream := TFileStream.Create(LTempFileName, fmCreate);
    try
      LResponse := LClient.Get(ASourceUrl, LStream);
      Result := (LResponse <> nil) and (LResponse.StatusCode >= 200) and (LResponse.StatusCode < 300) and (LStream.Size > 0);
    finally
      LStream.Free;
    end;

    if Result then
    begin
      if TFile.Exists(ATargetFileName) then
        TFile.Delete(ATargetFileName);
      TFile.Move(LTempFileName, ATargetFileName);
    end
    else if TFile.Exists(LTempFileName) then
      TFile.Delete(LTempFileName);
  except
    if TFile.Exists(LTempFileName) then
      TFile.Delete(LTempFileName);
    Result := False;
  end;
  LClient.Free;
end;

end.