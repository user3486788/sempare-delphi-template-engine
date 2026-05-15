unit Sempare.Template.DwsBridgeAdvanced.SakilaDemo;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  System.Rtti,
  Sempare.Template.Util;

type
  TSakilaDwsDemoScenarioResult = record
    Name: string;
    Output: string;
  end;

  TSakilaDwsDemoReport = record
    DatabaseFileName: string;
    HtmlFileName: string;
    HtmlReport: string;
    ScenarioResults: TArray<TSakilaDwsDemoScenarioResult>;
    DiagnosticsSummary: string;
    PageFiles: TArray<string>;
    function RenderConsoleText: string;
    procedure SaveHtmlReport(const AFileName: string = '');
  end;

  TSakilaDwsDemo = class
  public
    class function DefaultDatabaseFileName: string; static;
    class function DefaultHtmlFileName: string; static;
    class function Run(const ADatabaseFileName: string = ''): TSakilaDwsDemoReport; static;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.HostServices,
  Sempare.Template.DWS.Provider,
  Sempare.Template.DWS.Tooling,
  Sempare.Template.DWS.Types,
  Sempare.Template.DwsBridgeAdvanced.PosterSupport,
  Sempare.Template.DwsBridgeAdvanced.SakilaRuntime;

const
  CCurrentUser = 'sakila-cli';
  CReportTitle = 'Sakila Database HTML Report';
  CInitialStage = 'draft';
  CFilmPageLimit = 12;

type
  TSakilaDwsDemoRunner = class
  private
    FRepoRoot: string;
    FDemoRoot: string;
    FDatabaseFileName: string;
    FCtx: ITemplateContext;
    FBridge: ISempareDwsBridge;
    FDispatch: ISempareDwsBridgeDispatch;
    FDiagnostics: ITemplateDwsDiagnostics;
    function DemoFile(const ARelativePath: string): string;
    function OutputFile(const ARelativePath: string): string;
    function LoadTextFile(const AFileName: string): string;
    procedure SaveOutputTextFile(const ARelativePath, AContent: string);
    procedure RegisterTemplateFile(const ATemplateName, ARelativePath: string);
    procedure ConfigureContext;
    procedure ConfigureBridge;
    function BuildHtmlReport(
      const AScenarioCount: Integer;
      const ADiagnosticsSummary: string;
      const AFilmPages: TArray<TValue>
    ): string;
    function EvaluateTemplateScenario(const AName, ARelativePath: string; const AData: TValue): TSakilaDwsDemoScenarioResult; overload;
    function EvaluateTemplateScenario(const AName, ARelativePath: string): TSakilaDwsDemoScenarioResult; overload;
    function BuildDiagnosticsScenario: TSakilaDwsDemoScenarioResult;
    function LoadFeaturedFilms: TArray<TValue>;
    function GenerateFilmPages(var AFilmPages: TArray<TValue>): TArray<string>;
    function CountDiagnosticEvents(
      const ARecorder: TTemplateDwsDiagnosticsRecorder;
      const ACategory: string;
      const AName: string
    ): Integer;
    procedure AddScenario(
      var AScenarioResults: TArray<TSakilaDwsDemoScenarioResult>;
      const AScenario: TSakilaDwsDemoScenarioResult
    );
  public
    constructor Create(const ADatabaseFileName: string);
    function Run: TSakilaDwsDemoReport;
  end;

function FindRepoRoot: string;
var
  LCurrent: string;
  LParent: string;
begin
  LCurrent := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  while LCurrent <> '' do
  begin
    if TFile.Exists(TPath.Combine(LCurrent, 'AGENTS.md')) and
       TDirectory.Exists(TPath.Combine(LCurrent, 'src')) then
      Exit(LCurrent);

    LParent := TPath.GetDirectoryName(LCurrent);
    if SameText(LParent, LCurrent) then
      Break;
    LCurrent := LParent;
  end;
  raise Exception.Create('Could not locate the Sempare repository root from ' + ParamStr(0));
end;

procedure AddStringItem(var AItems: TArray<string>; const AValue: string);
var
  LIndex: Integer;
begin
  LIndex := Length(AItems);
  SetLength(AItems, LIndex + 1);
  AItems[LIndex] := AValue;
end;

function JsonValueText(const AValue: TJSONValue): string;
begin
  if (AValue = nil) or (AValue is TJSONNull) then
    Exit('');
  Result := AValue.Value;
end;

function ExtractMapValue(const AValue: TValue): TMap;
begin
  if AValue.IsType<TMap> then
    Exit(AValue.AsType<TMap>);

  raise EInvalidCast.Create('Expected TMap payload.');
end;

procedure TSakilaDwsDemoRunner.AddScenario(
  var AScenarioResults: TArray<TSakilaDwsDemoScenarioResult>;
  const AScenario: TSakilaDwsDemoScenarioResult
);
var
  LIndex: Integer;
begin
  LIndex := Length(AScenarioResults);
  SetLength(AScenarioResults, LIndex + 1);
  AScenarioResults[LIndex] := AScenario;
end;

function TSakilaDwsDemoReport.RenderConsoleText: string;
var
  LBuilder: TStringBuilder;
  LScenario: TSakilaDwsDemoScenarioResult;
  LIndex: Integer;
begin
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.AppendLine('Sempare DWScript Sakila CLI Demo');
    LBuilder.AppendLine('Database: ' + DatabaseFileName);
    if HtmlFileName <> '' then
      LBuilder.AppendLine('HTML report: ' + HtmlFileName);
    if Length(PageFiles) > 0 then
      LBuilder.AppendLine('Film pages: ' + IntToStr(Length(PageFiles)));
    LBuilder.AppendLine('');
    for LIndex := 0 to High(ScenarioResults) do
    begin
      LScenario := ScenarioResults[LIndex];
      LBuilder.AppendLine(IntToStr(LIndex + 1) + '. ' + LScenario.Name);
      LBuilder.AppendLine(LScenario.Output);
      LBuilder.AppendLine('');
    end;
    if DiagnosticsSummary <> '' then
    begin
      LBuilder.AppendLine('Summary');
      LBuilder.AppendLine(DiagnosticsSummary);
    end;
    Result := TrimRight(LBuilder.ToString);
  finally
    LBuilder.Free;
  end;
end;

procedure TSakilaDwsDemoReport.SaveHtmlReport(const AFileName: string = '');
var
  LTargetFileName: string;
  LFolder: string;
begin
  if AFileName <> '' then
    LTargetFileName := TPath.GetFullPath(AFileName)
  else
    LTargetFileName := HtmlFileName;

  if LTargetFileName = '' then
    raise Exception.Create('HTML report file name is not configured.');

  LFolder := TPath.GetDirectoryName(LTargetFileName);
  if LFolder <> '' then
    TDirectory.CreateDirectory(LFolder);

  TFile.WriteAllText(LTargetFileName, HtmlReport, TEncoding.UTF8);
end;

class function TSakilaDwsDemo.DefaultDatabaseFileName: string;
begin
  Result := TPath.Combine(
    FindRepoRoot,
    'demo\DwsBridgeAdvanced\templates\sakila.db'
  );
end;

class function TSakilaDwsDemo.DefaultHtmlFileName: string;
begin
  Result := TPath.Combine(
    FindRepoRoot,
    'demo\DwsBridgeAdvanced\output\sakila-report.html'
  );
end;

class function TSakilaDwsDemo.Run(const ADatabaseFileName: string): TSakilaDwsDemoReport;
var
  LRunner: TSakilaDwsDemoRunner;
  LStep: string;
begin
  LRunner := nil;
  LStep := 'create runner';
  try
    LRunner := TSakilaDwsDemoRunner.Create(ADatabaseFileName);
    LStep := 'execute runner';
    Result := LRunner.Run;
  except
    on E: Exception do
      raise Exception.CreateFmt(
        'TSakilaDwsDemo.Run failed at %s. %s: %s',
        [LStep, E.ClassName, E.Message]
      );
  end;
  LRunner.Free;
end;

function TSakilaDwsDemoRunner.BuildDiagnosticsScenario: TSakilaDwsDemoScenarioResult;
var
  LDiagnostics: ITemplateDwsDiagnostics;
  LRecorder: TTemplateDwsDiagnosticsRecorder;
  LPayload: TMap;
  LMissCount: Integer;
  LHitCount: Integer;
  LCompileCount: Integer;
  LCallCount: Integer;
begin
  LRecorder := TTemplateDwsDiagnosticsRecorder.Create;
  LDiagnostics := LRecorder;
  FBridge.SetDiagnostics(LDiagnostics);
  try
    FBridge.ClearCompileCache;

    LPayload := TMap.Create;
    LPayload.Add('audience', 'operations');

    FDispatch.Call(FCtx, 'actor_profile', 'Describe', TValue.From<TMap>(LPayload));
    FDispatch.Call(FCtx, 'actor_profile', 'Describe', TValue.From<TMap>(LPayload));

    LMissCount := CountDiagnosticEvents(LRecorder, 'cache', 'tdcekMiss');
    LHitCount := CountDiagnosticEvents(LRecorder, 'cache', 'tdcekHit');
    LCompileCount := CountDiagnosticEvents(LRecorder, 'runtime', 'tdrekCompileSuccess');
    LCallCount := CountDiagnosticEvents(LRecorder, 'profile', 'tdpekCall');

    Result.Name := 'Diagnostics and cache';
    Result.Output := Format(
      'File provider reused compiled scripts. Cache miss=%d, cache hit=%d, compile success=%d, call profiles=%d.',
      [LMissCount, LHitCount, LCompileCount, LCallCount]
    );
  finally
    FBridge.SetDiagnostics(FDiagnostics);
  end;
end;

function TSakilaDwsDemoRunner.BuildHtmlReport(
  const AScenarioCount: Integer;
  const ADiagnosticsSummary: string;
  const AFilmPages: TArray<TValue>
): string;
var
  LPayload: TMap;
  LTemplateText: string;
begin
  LPayload := TMap.Create;
  LPayload.Add('reportTitle', CReportTitle);
  LPayload.Add('databaseName', ExtractFileName(FDatabaseFileName));
  LPayload.Add('scenarioCountText', IntToStr(AScenarioCount));
  LPayload.Add('diagnosticsSummary', ADiagnosticsSummary);
  LPayload.Add('filmCountText', IntToStr(Length(AFilmPages)));
  LPayload.Add('films', TValue.From<TArray<TValue>>(AFilmPages));
  LPayload.Add('generatedAt', FCtx.Variables['generatedAt']);
  LPayload.Add('reportStage', FCtx.Variables['reportStage']);
  LTemplateText := LoadTextFile(DemoFile('templates\sakila\report\film-cards-report.tpl'));
  Result := Trim(Template.Eval(FCtx, LTemplateText, TValue.From<TMap>(LPayload)));
end;

procedure TSakilaDwsDemoRunner.ConfigureBridge;
var
  LFileProvider: ITemplateDwsScriptProvider;
begin
  FBridge := CreateSempareDwsBridge(
    CreateSakilaDwsRuntime(FDatabaseFileName, DemoFile('output')),
    [
      tdboCacheCompiledScripts,
      tdboPassRootData,
      tdboExpectJsonLikeReturn,
      tdboAllowInlineScripts,
      tdboAllowTrustedText
    ]
  );

  FDiagnostics := TTemplateDwsDiagnosticsRecorder.Create;
  FBridge.SetDiagnostics(FDiagnostics);
  FBridge.SetHostServices(
    CreateDefaultDwsHostServices(CreateAllowListMutationPolicy(['reportStage']))
  );

  LFileProvider := CreateFileSystemDwsScriptProvider(DemoFile('scripts\sakila'));
  FBridge.SetScriptProvider(LFileProvider);
  FBridge.RegisterInto(FCtx);

  if not Supports(FBridge, ISempareDwsBridgeDispatch, FDispatch) then
    raise Exception.Create('The configured DWScript bridge does not expose dispatch support.');
end;

procedure TSakilaDwsDemoRunner.ConfigureContext;
begin
  FCtx := Template.Context;
  FCtx.UseHtmlVariableEncoder;
  FCtx.Variables['currentUser'] := CCurrentUser;
  FCtx.Variables['reportTitle'] := CReportTitle;
  FCtx.Variables['reportStage'] := CInitialStage;
  FCtx.Variables['databaseName'] := ExtractFileName(FDatabaseFileName);
  FCtx.Variables['generatedAt'] := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now, TFormatSettings.Create('en-US'));

  RegisterTemplateFile('customer_badge', 'templates\sakila\host\customer_badge.tpl');
  RegisterTemplateFile('report_banner', 'templates\sakila\host\report_banner.tpl');
end;

constructor TSakilaDwsDemoRunner.Create(const ADatabaseFileName: string);
begin
  inherited Create;
  FRepoRoot := FindRepoRoot;
  FDemoRoot := TPath.Combine(FRepoRoot, 'demo\DwsBridgeAdvanced');
  if Trim(ADatabaseFileName) <> '' then
    FDatabaseFileName := TPath.GetFullPath(ADatabaseFileName)
  else
    FDatabaseFileName := TSakilaDwsDemo.DefaultDatabaseFileName;
  if not TFile.Exists(FDatabaseFileName) then
    raise Exception.Create('Sakila demo database not found: ' + FDatabaseFileName);

  ConfigureContext;
  ConfigureBridge;
end;

function TSakilaDwsDemoRunner.CountDiagnosticEvents(
  const ARecorder: TTemplateDwsDiagnosticsRecorder;
  const ACategory: string;
  const AName: string
): Integer;
var
  LEvent: TTemplateDwsDiagnosticEvent;
begin
  Result := 0;
  for LEvent in ARecorder.Events do
    if SameText(LEvent.Category, ACategory) and SameText(LEvent.Name, AName) then
      Inc(Result);
end;

function TSakilaDwsDemoRunner.DemoFile(const ARelativePath: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(FDemoRoot, ARelativePath));
end;

function TSakilaDwsDemoRunner.OutputFile(const ARelativePath: string): string;
begin
  Result := DemoFile('output\' + ARelativePath);
end;

function TSakilaDwsDemoRunner.EvaluateTemplateScenario(
  const AName, ARelativePath: string;
  const AData: TValue
): TSakilaDwsDemoScenarioResult;
var
  LTemplateText: string;
begin
  LTemplateText := LoadTextFile(DemoFile(ARelativePath));
  Result.Name := AName;
  if AData.IsEmpty then
    Result.Output := Trim(Template.Eval(FCtx, LTemplateText))
  else
    Result.Output := Trim(Template.Eval(FCtx, LTemplateText, AData));
end;

function TSakilaDwsDemoRunner.EvaluateTemplateScenario(
  const AName, ARelativePath: string
): TSakilaDwsDemoScenarioResult;
begin
  Result := EvaluateTemplateScenario(AName, ARelativePath, TValue.Empty);
end;

function TSakilaDwsDemoRunner.GenerateFilmPages(var AFilmPages: TArray<TValue>): TArray<string>;
var
  LIndex: Integer;
  LFilm: TMap;
  LPageFileName: string;
  LPageHtml: string;
  LAbsolutePageFileName: string;
  LPosterCacheKey: string;
  LFolderName: string;
begin
  SetLength(Result, 0);
  LFolderName := PagesFolderName('sakila');
  for LIndex := 0 to High(AFilmPages) do
  begin
    LFilm := ExtractMapValue(AFilmPages[LIndex]);
    LPosterCacheKey := LFilm['film_id'].ToString + '-' + LFilm['title'].AsString;
    LPageFileName := Format(
      '%s-%s.html',
      [LFilm['film_id'].ToString, NormalizeDemoSlug(LFilm['title'].AsString)]
    );

    LFilm['posterCacheKey'] := LPosterCacheKey;
    LFilm['posterPath'] := PosterRelativePath('sakila', LPosterCacheKey);
    LFilm['pageFileName'] := LPageFileName;
    LFilm['pageHref'] := LFolderName + '/' + LPageFileName;
    LFilm['backHref'] := '../sakila-report.html';
    LFilm['posterPrefix'] := '../';
    AFilmPages[LIndex] := TValue.From<TMap>(LFilm);

    LPageHtml := Trim(FDispatch.Render(FCtx, 'film_page', 'Render', TValue.From<TMap>(LFilm)));
    SaveOutputTextFile(TPath.Combine(LFolderName, LPageFileName), LPageHtml);
    LAbsolutePageFileName := OutputFile(TPath.Combine(LFolderName, LPageFileName));
    AddStringItem(Result, LAbsolutePageFileName);
  end;
end;

function TSakilaDwsDemoRunner.LoadFeaturedFilms: TArray<TValue>;
var
  LJsonText: string;
  LJsonValue: TJSONValue;
  LJsonArray: TJSONArray;
  LJsonObject: TJSONObject;
  LJsonPair: TJSONPair;
  LFilm: TMap;
  LPosterPayload: TMap;
  LIndex: Integer;
begin
  LJsonText := FDispatch.Render(FCtx, 'film_catalog', 'ListFilms', TValue.Empty);
  if Trim(LJsonText) = '' then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  LJsonValue := TJSONObject.ParseJSONValue(LJsonText);
  try
    if not (LJsonValue is TJSONArray) then
    begin
      SetLength(Result, 0);
      Exit;
    end;

    LJsonArray := TJSONArray(LJsonValue);
    SetLength(Result, LJsonArray.Count);
    for LIndex := 0 to LJsonArray.Count - 1 do
    begin
      if not (LJsonArray.Items[LIndex] is TJSONObject) then
        raise EInvalidCast.Create('Expected film_catalog items to be JSON objects.');
      LJsonObject := TJSONObject(LJsonArray.Items[LIndex]);
      LFilm := TMap.Create;
      for LJsonPair in LJsonObject do
        LFilm.Add(LJsonPair.JsonString.Value, JsonValueText(LJsonPair.JsonValue));
      if not LFilm.ContainsKey('poster_path') or (Trim(LFilm['poster_path'].AsString) = '') then
      begin
        LPosterPayload := TMap.Create;
        LPosterPayload.Add('cache_key', LFilm['film_id'].ToString + '-' + NormalizeDemoSlug(LFilm['title'].AsString));
        LPosterPayload.Add('title', LFilm['title'].AsString);
        LPosterPayload.Add('category_name', LFilm['category_name'].AsString);
        if LFilm.ContainsKey('poster_path') then
          LFilm['poster_path'] := Trim(FDispatch.Render(FCtx, 'poster_materialize', 'Main', TValue.From<TMap>(LPosterPayload)))
        else
          LFilm.Add('poster_path', Trim(FDispatch.Render(FCtx, 'poster_materialize', 'Main', TValue.From<TMap>(LPosterPayload))));
      end;
      Result[LIndex] := TValue.From<TMap>(LFilm);
    end;
  finally
    LJsonValue.Free;
  end;
end;

function TSakilaDwsDemoRunner.LoadTextFile(const AFileName: string): string;
var
  LStream: TFileStream;
  LReader: TStreamReader;
begin
  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    LReader := TStreamReader.Create(LStream, TEncoding.UTF8, True);
    try
      Result := LReader.ReadToEnd;
    finally
      LReader.Free;
    end;
  finally
    LStream.Free;
  end;
end;

procedure TSakilaDwsDemoRunner.RegisterTemplateFile(const ATemplateName, ARelativePath: string);
begin
  FCtx.SetTemplate(
    ATemplateName,
    Template.Parse(FCtx, LoadTextFile(DemoFile(ARelativePath)))
  );
end;

function TSakilaDwsDemoRunner.Run: TSakilaDwsDemoReport;
var
  LScenarios: TArray<TSakilaDwsDemoScenarioResult>;
  LScenario: TSakilaDwsDemoScenarioResult;
  LFilmPages: TArray<TValue>;
  LStep: string;
begin
  SetLength(LScenarios, 0);
  SetLength(LFilmPages, 0);
  LStep := 'bootstrap';
  try
    LStep := 'scenario: DwsCall explicit payload';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsCall explicit payload',
        'templates\sakila\scenarios\01-explicit-call.tpl'
      )
    );

    LStep := 'scenario: Dws default Main';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'Dws default Main',
        'templates\sakila\scenarios\02-main-root.tpl'
      )
    );

    LStep := 'scenario: DwsText escaped host render';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsText escaped host render',
        'templates\sakila\scenarios\03-dws-text.tpl'
      )
    );

    LStep := 'scenario: DwsRender host banner';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsRender host banner',
        'templates\sakila\scenarios\04-dws-render.tpl'
      )
    );

    LStep := 'scenario: DwsRaw trusted html';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsRaw trusted html',
        'templates\sakila\scenarios\05-dws-raw.tpl'
      )
    );

    LStep := 'scenario: DwsInlineText store summary';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsInlineText store summary',
        'templates\sakila\scenarios\06-inline-text.tpl'
      )
    );

    LStep := 'scenario: DwsInline numeric value';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsInline numeric value',
        'templates\sakila\scenarios\07-inline-value.tpl'
      )
    );

    LStep := 'scenario: SetVar allow list';
    FCtx.Variables['reportStage'] := CInitialStage;
    LScenario := EvaluateTemplateScenario(
      'SetVar allow list',
      'templates\sakila\scenarios\08-mutation.tpl'
    );
    LScenario.Output := LScenario.Output + sLineBreak + 'Context stage: ' + FCtx.Variables['reportStage'].AsString;
    AddScenario(LScenarios, LScenario);

    LStep := 'scenario: JSON-like result';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'JSON-like result',
        'templates\sakila\scenarios\09-structured-json.tpl'
      )
    );

    LStep := 'scenario: diagnostics';
    AddScenario(LScenarios, BuildDiagnosticsScenario);

    LStep := 'film cards';
    LFilmPages := LoadFeaturedFilms;

    LStep := 'report metadata';
    Result.DatabaseFileName := FDatabaseFileName;
    Result.HtmlFileName := TSakilaDwsDemo.DefaultHtmlFileName;
    SetLength(Result.PageFiles, 0);
    Result.ScenarioResults := LScenarios;
    Result.DiagnosticsSummary :=
      'Scenarios=' + IntToStr(Length(LScenarios)) +
      ', provider=file, db=sakila.db';

    LStep := 'html render';
    FCtx.Variables['reportStage'] := 'published';
    Result.HtmlReport := BuildHtmlReport(Length(LScenarios), Result.DiagnosticsSummary, LFilmPages);
  except
    on E: Exception do
      raise Exception.CreateFmt(
        'Sakila DWS demo failed at %s. %s: %s',
        [LStep, E.ClassName, E.Message]
      );
  end;
end;

procedure TSakilaDwsDemoRunner.SaveOutputTextFile(const ARelativePath, AContent: string);
var
  LTargetFileName: string;
  LFolder: string;
begin
  LTargetFileName := OutputFile(ARelativePath);
  LFolder := TPath.GetDirectoryName(LTargetFileName);
  if LFolder <> '' then
    TDirectory.CreateDirectory(LFolder);
  TFile.WriteAllText(LTargetFileName, AContent, TEncoding.UTF8);
end;

end.





