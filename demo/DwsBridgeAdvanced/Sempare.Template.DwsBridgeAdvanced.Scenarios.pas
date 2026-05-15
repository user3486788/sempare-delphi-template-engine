unit Sempare.Template.DwsBridgeAdvanced.Scenarios;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  System.Rtti,
  Sempare.Template.Util;

type
  TChinookDwsDemoScenarioResult = record
    Name: string;
    Output: string;
  end;

  TChinookDwsDemoReport = record
    DatabaseFileName: string;
    HtmlFileName: string;
    HtmlReport: string;
    ScenarioResults: TArray<TChinookDwsDemoScenarioResult>;
    DiagnosticsSummary: string;
    PageFiles: TArray<string>;
    function RenderConsoleText: string;
    procedure SaveHtmlReport(const AFileName: string = '');
  end;

  TChinookDwsDemo = class
  public
    class function DefaultDatabaseFileName: string; static;
    class function DefaultHtmlFileName: string; static;
    class function Run(const ADatabaseFileName: string = ''): TChinookDwsDemoReport; static;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.DApt,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.HostServices,
  Sempare.Template.DWS.Provider,
  Sempare.Template.DWS.Runtime,
  Sempare.Template.DWS.Tooling,
  Sempare.Template.DWS.Types,
  Sempare.Template.DwsBridgeAdvanced.PosterSupport;

const
  CCurrentUser = 'cli-runner';
  CReportTitle = 'Chinook Database HTML Report';
  CInitialStage = 'draft';
  CAlbumPageLimit = 12;

  CArtistProfileScript =
    'uses SempareHost;' + sLineBreak +
    'function Describe(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := String(GetVar(''currentUser'')) + '' reviewed '' + data.artist.name + '' with '' + data.artist.trackCountText + '' tracks.'';' + sLineBreak +
    'end;';

  CPlaylistSummaryScript =
    'function Main(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := ''Playlist #'' + data.playlistIdText + '' '' + data.name + '' contains '' + data.trackCountText + '' tracks.'';' + sLineBreak +
    'end;';

  CGenreJsonScript =
    'function Build(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result :=' + sLineBreak +
    '    ''{"title":"Top Chinook genres","items":['' +' + sLineBreak +
    '    ''{"name":"'' + data.firstName + ''","tracks":"'' + data.firstCountText + ''"},'' +' + sLineBreak +
    '    ''{"name":"'' + data.secondName + ''","tracks":"'' + data.secondCountText + ''"},'' +' + sLineBreak +
    '    ''{"name":"'' + data.thirdName + ''","tracks":"'' + data.thirdCountText + ''"}'' +' + sLineBreak +
    '    '']}'';' + sLineBreak +
    'end;';

type
  TChinookDwsDemoRunner = class
  private
    FRepoRoot: string;
    FDemoRoot: string;
    FDatabaseFileName: string;
    FCtx: ITemplateContext;
    FBridge: ISempareDwsBridge;
    FDispatch: ISempareDwsBridgeDispatch;
    FDiagnostics: ITemplateDwsDiagnostics;
    FReportData: TMap;
    function DemoFile(const ARelativePath: string): string;
    function OutputFile(const ARelativePath: string): string;
    function LoadTextFile(const AFileName: string): string;
    procedure SaveOutputTextFile(const ARelativePath, AContent: string);
    procedure RegisterTemplateFile(const ATemplateName, ARelativePath: string);
    procedure ConfigureContext;
    procedure ConfigureBridge;
    function OpenConnection: TFDConnection;
    function LoadTotals: TMap;
    function LoadTopArtist: TMap;
    function LoadTopArtists(const ALimit: Integer = 5): TArray<TValue>;
    function LoadTopPlaylist: TMap;
    function LoadTopUsCustomer: TMap;
    function LoadTopCustomers(const ALimit: Integer = 5): TArray<TValue>;
    function LoadTopSupportRep: TMap;
    function LoadTopGenres: TArray<TValue>;
    function LoadCountrySales(const ALimit: Integer = 5): TArray<TValue>;
    function LoadFeaturedAlbums(const ALimit: Integer = CAlbumPageLimit): TArray<TValue>;
    function GenerateAlbumPages(var AAlbumPages: TArray<TValue>): TArray<string>;
    function LoadReportData: TMap;
    function BuildGenrePayload: TMap;
    function BuildHtmlReport: string;
    function BuildScenarioResultsPayload(const AScenarioResults: TArray<TChinookDwsDemoScenarioResult>): TArray<TValue>;
    function EvaluateTemplateScenario(const AName, ARelativePath: string; const AData: TValue): TChinookDwsDemoScenarioResult; overload;
    function EvaluateTemplateScenario(const AName, ARelativePath: string): TChinookDwsDemoScenarioResult; overload;
    function BuildDiagnosticsScenario: TChinookDwsDemoScenarioResult;
    function CountDiagnosticEvents(
      const ARecorder: TTemplateDwsDiagnosticsRecorder;
      const ACategory: string;
      const AName: string
    ): Integer;
    procedure AddScenario(
      var AScenarioResults: TArray<TChinookDwsDemoScenarioResult>;
      const AScenario: TChinookDwsDemoScenarioResult
    );
  public
    constructor Create(const ADatabaseFileName: string);
    function Run: TChinookDwsDemoReport;
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

function InvariantFloatText(const AValue: Double): string;
var
  LFormatSettings: TFormatSettings;
begin
  LFormatSettings := TFormatSettings.Create('en-US');
  Result := FormatFloat('0.00', AValue, LFormatSettings);
end;

function InvariantTimestampText(const AValue: TDateTime): string;
var
  LFormatSettings: TFormatSettings;
begin
  LFormatSettings := TFormatSettings.Create('en-US');
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', AValue, LFormatSettings);
end;

procedure AddStringItem(var AItems: TArray<string>; const AValue: string);
var
  LIndex: Integer;
begin
  LIndex := Length(AItems);
  SetLength(AItems, LIndex + 1);
  AItems[LIndex] := AValue;
end;

function TChinookDwsDemoReport.RenderConsoleText: string;
var
  LBuilder: TStringBuilder;
  LScenario: TChinookDwsDemoScenarioResult;
  LIndex: Integer;
begin
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.AppendLine('Sempare DWScript Chinook CLI Demo');
    LBuilder.AppendLine('Database: ' + DatabaseFileName);
    if HtmlFileName <> '' then
      LBuilder.AppendLine('HTML report: ' + HtmlFileName);
    if Length(PageFiles) > 0 then
      LBuilder.AppendLine('Album pages: ' + IntToStr(Length(PageFiles)));
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

procedure TChinookDwsDemoReport.SaveHtmlReport(const AFileName: string = '');
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

class function TChinookDwsDemo.DefaultDatabaseFileName: string;
begin
  Result := TPath.Combine(
    FindRepoRoot,
    'demo\DwsBridgeAdvanced\templates\chinook.db'
  );
end;

class function TChinookDwsDemo.DefaultHtmlFileName: string;
begin
  Result := TPath.Combine(
    FindRepoRoot,
    'demo\DwsBridgeAdvanced\output\chinook-report.html'
  );
end;

class function TChinookDwsDemo.Run(const ADatabaseFileName: string): TChinookDwsDemoReport;
var
  LRunner: TChinookDwsDemoRunner;
  LStep: string;
begin
  LRunner := nil;
  LStep := 'create runner';
  try
    LRunner := TChinookDwsDemoRunner.Create(ADatabaseFileName);
    LStep := 'execute runner';
    Result := LRunner.Run;
  except
    on E: Exception do
      raise Exception.CreateFmt(
        'TChinookDwsDemo.Run failed at %s. %s: %s',
        [LStep, E.ClassName, E.Message]
      );
  end;
  LRunner.Free;
end;

procedure TChinookDwsDemoRunner.AddScenario(
  var AScenarioResults: TArray<TChinookDwsDemoScenarioResult>;
  const AScenario: TChinookDwsDemoScenarioResult
);
var
  LCount: Integer;
begin
  LCount := Length(AScenarioResults);
  SetLength(AScenarioResults, LCount + 1);
  AScenarioResults[LCount] := AScenario;
end;

function TChinookDwsDemoRunner.BuildDiagnosticsScenario: TChinookDwsDemoScenarioResult;
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
    LPayload.Add('artist', FReportData['artist'].AsType<TMap>);

    FDispatch.Call(FCtx, 'artist_profile', 'Describe', TValue.From<TMap>(LPayload));
    FDispatch.Call(FCtx, 'artist_profile', 'Describe', TValue.From<TMap>(LPayload));

    LMissCount := CountDiagnosticEvents(LRecorder, 'cache', 'tdcekMiss');
    LHitCount := CountDiagnosticEvents(LRecorder, 'cache', 'tdcekHit');
    LCompileCount := CountDiagnosticEvents(LRecorder, 'runtime', 'tdrekCompileSuccess');
    LCallCount := CountDiagnosticEvents(LRecorder, 'profile', 'tdpekCall');

    Result.Name := 'Diagnostics and cache';
    Result.Output := Format(
      'Bundled+file provider reused compiled scripts. Cache miss=%d, cache hit=%d, compile success=%d, call profiles=%d.',
      [LMissCount, LHitCount, LCompileCount, LCallCount]
    );
  finally
    FBridge.SetDiagnostics(FDiagnostics);
  end;
end;

function TChinookDwsDemoRunner.BuildGenrePayload: TMap;
var
  LGenres: TArray<TValue>;
begin
  if FReportData.ContainsKey('genres') then
    LGenres := FReportData['genres'].AsType<TArray<TValue>>
  else
    LGenres := LoadTopGenres;

  Result := TMap.Create;
  Result.Add('firstName', LGenres[0].AsType<TMap>['name'].AsString);
  Result.Add('firstCountText', LGenres[0].AsType<TMap>['trackCountText'].AsString);
  Result.Add('secondName', LGenres[1].AsType<TMap>['name'].AsString);
  Result.Add('secondCountText', LGenres[1].AsType<TMap>['trackCountText'].AsString);
  Result.Add('thirdName', LGenres[2].AsType<TMap>['name'].AsString);
  Result.Add('thirdCountText', LGenres[2].AsType<TMap>['trackCountText'].AsString);
end;

function TChinookDwsDemoRunner.BuildHtmlReport: string;
var
  LTemplateText: string;
begin
  LTemplateText := LoadTextFile(DemoFile('templates\report\chinook-report.tpl'));
  Result := Trim(Template.Eval(FCtx, LTemplateText, TValue.From<TMap>(FReportData)));
end;

function TChinookDwsDemoRunner.BuildScenarioResultsPayload(
  const AScenarioResults: TArray<TChinookDwsDemoScenarioResult>
): TArray<TValue>;
var
  LIndex: Integer;
  LScenario: TMap;
begin
  SetLength(Result, Length(AScenarioResults));
  for LIndex := 0 to High(AScenarioResults) do
  begin
    LScenario := TMap.Create;
    LScenario.Add('name', AScenarioResults[LIndex].Name);
    LScenario.Add('output', AScenarioResults[LIndex].Output);
    Result[LIndex] := TValue.From<TMap>(LScenario);
  end;
end;

procedure TChinookDwsDemoRunner.ConfigureBridge;
var
  LFileProvider: ITemplateDwsScriptProvider;
  LBundledProvider: ITemplateDwsScriptProvider;
begin
  FBridge := CreateSempareDwsBridge(
    CreateDefaultDwsRuntime(CreatePosterDwsRuntimeConfigurator(DemoFile('output'))),
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

  LBundledProvider := CreateBundledDwsScriptProvider(
    'chinook-cli-v1',
    [
      TTemplateDwsScriptDefinition.Create('artist_profile', CArtistProfileScript),
      TTemplateDwsScriptDefinition.Create('playlist_summary', CPlaylistSummaryScript),
      TTemplateDwsScriptDefinition.Create('genre_json', CGenreJsonScript)
    ]
  );
  LFileProvider := CreateFileSystemDwsScriptProvider(DemoFile('scripts'));
  FBridge.SetScriptProvider(
    CreateCompositeDwsScriptProvider([LBundledProvider, LFileProvider])
  );
  FBridge.RegisterInto(FCtx);

  if not Supports(FBridge, ISempareDwsBridgeDispatch, FDispatch) then
    raise Exception.Create('The configured DWScript bridge does not expose dispatch support.');
end;

procedure TChinookDwsDemoRunner.ConfigureContext;
begin
  FCtx := Template.Context;
  FCtx.UseHtmlVariableEncoder;
  FCtx.Variables['currentUser'] := CCurrentUser;
  FCtx.Variables['reportTitle'] := CReportTitle;
  FCtx.Variables['reportStage'] := CInitialStage;
  FCtx.Variables['totalTracks'] := FReportData['totals'].AsType<TMap>['tracksText'].AsString;
  FCtx.Variables['totalArtists'] := FReportData['totals'].AsType<TMap>['artistsText'].AsString;
  FCtx.Variables['databaseName'] := FReportData['databaseName'].AsString;
  FCtx.Variables['generatedAt'] := FReportData['generatedAt'].AsString;

  RegisterTemplateFile('customer_badge', 'templates\host\customer_badge.tpl');
  RegisterTemplateFile('report_banner', 'templates\host\report_banner.tpl');
end;

constructor TChinookDwsDemoRunner.Create(const ADatabaseFileName: string);
begin
  inherited Create;
  FRepoRoot := FindRepoRoot;
  FDemoRoot := TPath.Combine(FRepoRoot, 'demo\DwsBridgeAdvanced');
  if Trim(ADatabaseFileName) <> '' then
    FDatabaseFileName := TPath.GetFullPath(ADatabaseFileName)
  else
    FDatabaseFileName := TChinookDwsDemo.DefaultDatabaseFileName;
  if not TFile.Exists(FDatabaseFileName) then
    raise Exception.Create('Chinook demo database not found: ' + FDatabaseFileName);

  FReportData := LoadReportData;
  ConfigureContext;
  ConfigureBridge;
end;

function TChinookDwsDemoRunner.CountDiagnosticEvents(
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

function TChinookDwsDemoRunner.DemoFile(const ARelativePath: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(FDemoRoot, ARelativePath));
end;

function TChinookDwsDemoRunner.OutputFile(const ARelativePath: string): string;
begin
  Result := DemoFile('output\\' + ARelativePath);
end;

function TChinookDwsDemoRunner.EvaluateTemplateScenario(
  const AName, ARelativePath: string;
  const AData: TValue
): TChinookDwsDemoScenarioResult;
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

function TChinookDwsDemoRunner.EvaluateTemplateScenario(
  const AName, ARelativePath: string
): TChinookDwsDemoScenarioResult;
begin
  Result := EvaluateTemplateScenario(AName, ARelativePath, TValue.Empty);
end;

function TChinookDwsDemoRunner.GenerateAlbumPages(var AAlbumPages: TArray<TValue>): TArray<string>;
var
  LIndex: Integer;
  LAlbum: TMap;
  LPageFileName: string;
  LPageHtml: string;
  LAbsolutePageFileName: string;
  LPosterCacheKey: string;
  LFolderName: string;
begin
  SetLength(Result, 0);
  LFolderName := PagesFolderName('chinook');
  for LIndex := 0 to High(AAlbumPages) do
  begin
    LAlbum := AAlbumPages[LIndex].AsType<TMap>;
    LPosterCacheKey := IntToStr(LAlbum['albumId'].AsInt64) + '-' + LAlbum['title'].AsString;
    LPageFileName := Format(
      '%s-%s.html',
      [IntToStr(LAlbum['albumId'].AsInt64), NormalizeDemoSlug(LAlbum['title'].AsString)]
    );

    LAlbum['posterCacheKey'] := LPosterCacheKey;
    LAlbum['posterPath'] := PosterRelativePath('chinook', LPosterCacheKey);
    LAlbum['pageFileName'] := LPageFileName;
    LAlbum['pageHref'] := LFolderName + '/' + LPageFileName;
    LAlbum['backHref'] := '../chinook-report.html';
    LAlbum['posterPrefix'] := '../';
    AAlbumPages[LIndex] := TValue.From<TMap>(LAlbum);

    LPageHtml := Trim(FDispatch.Render(FCtx, 'album_page', 'Render', TValue.From<TMap>(LAlbum)));
    SaveOutputTextFile(TPath.Combine(LFolderName, LPageFileName), LPageHtml);
    LAbsolutePageFileName := OutputFile(TPath.Combine(LFolderName, LPageFileName));
    AddStringItem(Result, LAbsolutePageFileName);
  end;
end;

function TChinookDwsDemoRunner.LoadCountrySales(const ALimit: Integer = 5): TArray<TValue>;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LCountrySale: TMap;
  LIndex: Integer;
begin
  SetLength(Result, 0);
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      Format(
        'select c.Country, round(sum(i.Total), 2) as Revenue, count(i.InvoiceId) as InvoiceCount ' +
        'from customers c ' +
        'join invoices i on i.CustomerId = c.CustomerId ' +
        'group by c.Country ' +
        'order by Revenue desc, c.Country ' +
        'limit %d',
        [ALimit]
      );
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LIndex := Length(Result);
      SetLength(Result, LIndex + 1);
      LCountrySale := TMap.Create;
      LCountrySale.Add('country', LQuery.FieldByName('Country').AsString);
      LCountrySale.Add('revenueText', InvariantFloatText(LQuery.FieldByName('Revenue').AsFloat));
      LCountrySale.Add('invoiceCountText', LQuery.FieldByName('InvoiceCount').AsString);
      Result[LIndex] := TValue.From<TMap>(LCountrySale);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadFeaturedAlbums(const ALimit: Integer = CAlbumPageLimit): TArray<TValue>;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LAlbum: TMap;
  LIndex: Integer;
begin
  SetLength(Result, 0);
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      Format(
        'select al.AlbumId, al.Title, a.Name as ArtistName, ' +
        'count(distinct t.TrackId) as TrackCount, ' +
        'printf(''%%.2f'', coalesce(sum(ii.UnitPrice * ii.Quantity), 0)) as RevenueText, ' +
        'coalesce((select g.Name from tracks t2 ' +
        'join genres g on g.GenreId = t2.GenreId ' +
        'where t2.AlbumId = al.AlbumId ' +
        'group by g.GenreId, g.Name ' +
        'order by count(*) desc, g.Name limit 1), ''Mixed'') as GenreName, ' +
        'coalesce((select t3.Name from tracks t3 where t3.AlbumId = al.AlbumId order by t3.TrackId limit 1), ''No sample track'') as SampleTrack ' +
        'from albums al ' +
        'join artists a on a.ArtistId = al.ArtistId ' +
        'left join tracks t on t.AlbumId = al.AlbumId ' +
        'left join invoice_items ii on ii.TrackId = t.TrackId ' +
        'group by al.AlbumId, al.Title, a.Name ' +
        'order by coalesce(sum(ii.UnitPrice * ii.Quantity), 0) desc, TrackCount desc, al.Title ' +
        'limit %d',
        [ALimit]
      );
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LIndex := Length(Result);
      SetLength(Result, LIndex + 1);
      LAlbum := TMap.Create;
      LAlbum.Add('albumId', LQuery.FieldByName('AlbumId').AsInteger);
      LAlbum.Add('albumIdText', LQuery.FieldByName('AlbumId').AsString);
      LAlbum.Add('title', LQuery.FieldByName('Title').AsString);
      LAlbum.Add('artistName', LQuery.FieldByName('ArtistName').AsString);
      LAlbum.Add('trackCountText', LQuery.FieldByName('TrackCount').AsString);
      LAlbum.Add('revenueText', LQuery.FieldByName('RevenueText').AsString);
      LAlbum.Add('genreName', LQuery.FieldByName('GenreName').AsString);
      LAlbum.Add('sampleTrack', LQuery.FieldByName('SampleTrack').AsString);
      LAlbum.Add(
        'summaryText',
        Format(
          '%s delivers %s tracks by %s and contributed %s in tracked Chinook sales.',
          [
            LQuery.FieldByName('Title').AsString,
            LQuery.FieldByName('TrackCount').AsString,
            LQuery.FieldByName('ArtistName').AsString,
            LQuery.FieldByName('RevenueText').AsString
          ]
        )
      );
      Result[LIndex] := TValue.From<TMap>(LAlbum);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadReportData: TMap;
var
  LArtistPayload: TMap;
  LSupportPayload: TMap;
  LScorePayload: TMap;
begin
  Result := TMap.Create;
  Result.Add('databaseName', ExtractFileName(FDatabaseFileName));
  Result.Add('generatedAt', InvariantTimestampText(Now));
  Result.Add('artist', TValue.From<TMap>(LoadTopArtist));
  Result.Add('topArtists', TValue.From<TArray<TValue>>(LoadTopArtists));
  Result.Add('playlist', TValue.From<TMap>(LoadTopPlaylist));
  Result.Add('customer', TValue.From<TMap>(LoadTopUsCustomer));
  Result.Add('topCustomers', TValue.From<TArray<TValue>>(LoadTopCustomers));
  Result.Add('countrySales', TValue.From<TArray<TValue>>(LoadCountrySales));
  Result.Add('supportRep', TValue.From<TMap>(LoadTopSupportRep));
  Result.Add('totals', TValue.From<TMap>(LoadTotals));
  Result.Add('genres', TValue.From<TArray<TValue>>(LoadTopGenres));
  Result.Add('genrePayload', TValue.From<TMap>(BuildGenrePayload));

  LArtistPayload := TMap.Create;
  LArtistPayload.Add('artist', Result['artist']);
  Result.Add('artistPayload', TValue.From<TMap>(LArtistPayload));

  LSupportPayload := TMap.Create;
  LSupportPayload.Add('supportRep', Result['supportRep']);
  Result.Add('supportPayload', TValue.From<TMap>(LSupportPayload));

  LScorePayload := TMap.Create;
  LScorePayload.Add('artist', Result['artist']);
  LScorePayload.Add('supportRep', Result['supportRep']);
  LScorePayload.Add('totals', Result['totals']);
  Result.Add('scorePayload', TValue.From<TMap>(LScorePayload));
end;

function TChinookDwsDemoRunner.LoadTextFile(const AFileName: string): string;
begin
  Result := TFile.ReadAllText(AFileName, TEncoding.UTF8);
end;

function TChinookDwsDemoRunner.LoadTopArtist: TMap;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := TMap.Create;
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      'select a.Name as ArtistName, count(*) as TrackCount ' +
      'from artists a ' +
      'join albums al on al.ArtistId = a.ArtistId ' +
      'join tracks t on t.AlbumId = al.AlbumId ' +
      'group by a.ArtistId ' +
      'order by TrackCount desc, ArtistName ' +
      'limit 1';
    LQuery.Open;

    Result.Add('name', LQuery.FieldByName('ArtistName').AsString);
    Result.Add('trackCount', LQuery.FieldByName('TrackCount').AsInteger);
    Result.Add('trackCountText', LQuery.FieldByName('TrackCount').AsString);
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadTopArtists(const ALimit: Integer = 5): TArray<TValue>;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LArtist: TMap;
  LIndex: Integer;
begin
  SetLength(Result, 0);
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      Format(
        'select a.Name as ArtistName, count(*) as TrackCount ' +
        'from artists a ' +
        'join albums al on al.ArtistId = a.ArtistId ' +
        'join tracks t on t.AlbumId = al.AlbumId ' +
        'group by a.ArtistId ' +
        'order by TrackCount desc, ArtistName ' +
        'limit %d',
        [ALimit]
      );
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LIndex := Length(Result);
      SetLength(Result, LIndex + 1);
      LArtist := TMap.Create;
      LArtist.Add('name', LQuery.FieldByName('ArtistName').AsString);
      LArtist.Add('trackCountText', LQuery.FieldByName('TrackCount').AsString);
      Result[LIndex] := TValue.From<TMap>(LArtist);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadTopCustomers(const ALimit: Integer = 5): TArray<TValue>;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LCustomer: TMap;
  LIndex: Integer;
begin
  SetLength(Result, 0);
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      Format(
        'select c.FirstName || '' '' || c.LastName as CustomerName, c.Country, round(sum(i.Total), 2) as Revenue, count(i.InvoiceId) as InvoiceCount ' +
        'from customers c ' +
        'join invoices i on i.CustomerId = c.CustomerId ' +
        'group by c.CustomerId ' +
        'order by Revenue desc, CustomerName ' +
        'limit %d',
        [ALimit]
      );
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LIndex := Length(Result);
      SetLength(Result, LIndex + 1);
      LCustomer := TMap.Create;
      LCustomer.Add('fullName', LQuery.FieldByName('CustomerName').AsString);
      LCustomer.Add('country', LQuery.FieldByName('Country').AsString);
      LCustomer.Add('revenueText', InvariantFloatText(LQuery.FieldByName('Revenue').AsFloat));
      LCustomer.Add('invoiceCountText', LQuery.FieldByName('InvoiceCount').AsString);
      Result[LIndex] := TValue.From<TMap>(LCustomer);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadTopGenres: TArray<TValue>;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
  LGenre: TMap;
  LIndex: Integer;
begin
  SetLength(Result, 0);
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      'select g.Name as GenreName, count(*) as TrackCount ' +
      'from genres g ' +
      'join tracks t on t.GenreId = g.GenreId ' +
      'group by g.GenreId ' +
      'order by TrackCount desc, GenreName ' +
      'limit 3';
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LIndex := Length(Result);
      SetLength(Result, LIndex + 1);
      LGenre := TMap.Create;
      LGenre.Add('name', LQuery.FieldByName('GenreName').AsString);
      LGenre.Add('tracks', LQuery.FieldByName('TrackCount').AsString);
      LGenre.Add('trackCountText', LQuery.FieldByName('TrackCount').AsString);
      Result[LIndex] := TValue.From<TMap>(LGenre);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadTopPlaylist: TMap;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := TMap.Create;
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      'select p.PlaylistId, p.Name as PlaylistName, count(pt.TrackId) as TrackCount ' +
      'from playlists p ' +
      'left join playlist_track pt on pt.PlaylistId = p.PlaylistId ' +
      'group by p.PlaylistId ' +
      'order by TrackCount desc, p.PlaylistId ' +
      'limit 1';
    LQuery.Open;

    Result.Add('playlistId', LQuery.FieldByName('PlaylistId').AsInteger);
    Result.Add('playlistIdText', LQuery.FieldByName('PlaylistId').AsString);
    Result.Add('name', LQuery.FieldByName('PlaylistName').AsString);
    Result.Add('trackCount', LQuery.FieldByName('TrackCount').AsInteger);
    Result.Add('trackCountText', LQuery.FieldByName('TrackCount').AsString);
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadTopSupportRep: TMap;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := TMap.Create;
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      'select e.FirstName || '' '' || e.LastName as EmployeeName, count(c.CustomerId) as CustomerCount ' +
      'from employees e ' +
      'left join customers c on c.SupportRepId = e.EmployeeId ' +
      'group by e.EmployeeId ' +
      'order by CustomerCount desc, EmployeeName ' +
      'limit 1';
    LQuery.Open;

    Result.Add('name', LQuery.FieldByName('EmployeeName').AsString);
    Result.Add('customerCount', LQuery.FieldByName('CustomerCount').AsInteger);
    Result.Add('customerCountText', LQuery.FieldByName('CustomerCount').AsString);
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadTopUsCustomer: TMap;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := TMap.Create;
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      'select c.FirstName || '' '' || c.LastName as CustomerName, c.Country, round(sum(i.Total), 2) as Revenue ' +
      'from customers c ' +
      'join invoices i on i.CustomerId = c.CustomerId ' +
      'where c.Country = ''USA'' ' +
      'group by c.CustomerId ' +
      'order by Revenue desc, CustomerName ' +
      'limit 1';
    LQuery.Open;

    Result.Add('fullName', LQuery.FieldByName('CustomerName').AsString);
    Result.Add('country', LQuery.FieldByName('Country').AsString);
    Result.Add('revenue', LQuery.FieldByName('Revenue').AsFloat);
    Result.Add('revenueText', InvariantFloatText(LQuery.FieldByName('Revenue').AsFloat));
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.LoadTotals: TMap;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := TMap.Create;
  LConnection := OpenConnection;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      'select ' +
      '  (select count(*) from artists) as ArtistCount, ' +
      '  (select count(*) from albums) as AlbumCount, ' +
      '  (select count(*) from tracks) as TrackCount, ' +
      '  (select count(*) from customers) as CustomerCount, ' +
      '  (select count(*) from invoices) as InvoiceCount, ' +
      '  (select count(*) from playlists) as PlaylistCount';
    LQuery.Open;

    Result.Add('artists', LQuery.FieldByName('ArtistCount').AsInteger);
    Result.Add('artistsText', LQuery.FieldByName('ArtistCount').AsString);
    Result.Add('albums', LQuery.FieldByName('AlbumCount').AsInteger);
    Result.Add('albumsText', LQuery.FieldByName('AlbumCount').AsString);
    Result.Add('tracks', LQuery.FieldByName('TrackCount').AsInteger);
    Result.Add('tracksText', LQuery.FieldByName('TrackCount').AsString);
    Result.Add('customers', LQuery.FieldByName('CustomerCount').AsInteger);
    Result.Add('customersText', LQuery.FieldByName('CustomerCount').AsString);
    Result.Add('invoices', LQuery.FieldByName('InvoiceCount').AsInteger);
    Result.Add('invoicesText', LQuery.FieldByName('InvoiceCount').AsString);
    Result.Add('playlists', LQuery.FieldByName('PlaylistCount').AsInteger);
    Result.Add('playlistsText', LQuery.FieldByName('PlaylistCount').AsString);
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

function TChinookDwsDemoRunner.OpenConnection: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.DriverName := 'SQLite';
  Result.Params.Values['Database'] := FDatabaseFileName;
  Result.Connected := True;
end;

procedure TChinookDwsDemoRunner.RegisterTemplateFile(const ATemplateName, ARelativePath: string);
begin
  FCtx.SetTemplate(
    ATemplateName,
    Template.Parse(FCtx, LoadTextFile(DemoFile(ARelativePath)))
  );
end;

function TChinookDwsDemoRunner.Run: TChinookDwsDemoReport;
var
  LScenarios: TArray<TChinookDwsDemoScenarioResult>;
  LScenario: TChinookDwsDemoScenarioResult;
  LAlbumPages: TArray<TValue>;
  LPageFiles: TArray<string>;
  LStep: string;
begin
  SetLength(LScenarios, 0);
  SetLength(LAlbumPages, 0);
  SetLength(LPageFiles, 0);
  LStep := 'bootstrap';
  try
    LStep := 'scenario: DwsCall explicit payload';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsCall explicit payload',
        'templates\scenarios\01-explicit-call.tpl',
        TValue.From<TMap>(FReportData)
      )
    );

    LStep := 'scenario: Dws default Main';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'Dws default Main',
        'templates\scenarios\02-main-root.tpl',
        TValue.From<TMap>(FReportData['playlist'].AsType<TMap>)
      )
    );

    LStep := 'scenario: DwsText escaped host render';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsText escaped host render',
        'templates\scenarios\03-dws-text.tpl',
        TValue.From<TMap>(FReportData)
      )
    );

    LStep := 'scenario: DwsRender host banner';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsRender host banner',
        'templates\scenarios\04-dws-render.tpl'
      )
    );

    LStep := 'scenario: DwsRaw trusted html';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsRaw trusted html',
        'templates\scenarios\05-dws-raw.tpl',
        TValue.From<TMap>(FReportData)
      )
    );

    LStep := 'scenario: DwsInlineText support rep';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsInlineText support rep',
        'templates\scenarios\06-inline-text.tpl',
        TValue.From<TMap>(FReportData)
      )
    );

    LStep := 'scenario: DwsInline numeric value';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'DwsInline numeric value',
        'templates\scenarios\07-inline-value.tpl',
        TValue.From<TMap>(FReportData)
      )
    );

    LStep := 'scenario: SetVar allow list';
    FCtx.Variables['reportStage'] := CInitialStage;
    LScenario := EvaluateTemplateScenario(
      'SetVar allow list',
      'templates\scenarios\08-mutation.tpl'
    );
    LScenario.Output := LScenario.Output + sLineBreak + 'Context stage: ' + FCtx.Variables['reportStage'].AsString;
    AddScenario(LScenarios, LScenario);

    LStep := 'scenario: JSON-like result';
    AddScenario(
      LScenarios,
      EvaluateTemplateScenario(
        'JSON-like result',
        'templates\scenarios\09-structured-json.tpl',
        TValue.From<TMap>(BuildGenrePayload)
      )
    );

    LStep := 'scenario: diagnostics';
    AddScenario(LScenarios, BuildDiagnosticsScenario);

    LStep := 'album pages';
    LAlbumPages := LoadFeaturedAlbums;
    LPageFiles := GenerateAlbumPages(LAlbumPages);

    LStep := 'report metadata';
    Result.DatabaseFileName := FDatabaseFileName;
    Result.HtmlFileName := TChinookDwsDemo.DefaultHtmlFileName;
    Result.PageFiles := LPageFiles;
    Result.ScenarioResults := LScenarios;
    Result.DiagnosticsSummary :=
      'Scenarios=' + IntToStr(Length(LScenarios)) +
      ', provider=composite(bundled+file), db=chinook.db';

    LStep := 'report payload';
    FCtx.Variables['reportStage'] := 'published';
    FReportData['publicationFlowText'] := 'draft to published';
    FReportData['artistSummaryText'] := LScenarios[0].Output;
    FReportData['playlistSummaryText'] := LScenarios[1].Output;
    FReportData['bannerText'] := LScenarios[3].Output;
    FReportData['supportSummaryText'] := LScenarios[5].Output;
    FReportData['scoreSummaryText'] := LScenarios[6].Output;
    FReportData['genreSummaryText'] := LScenarios[8].Output;
    FReportData['scenarioResults'] := TValue.From<TArray<TValue>>(BuildScenarioResultsPayload(LScenarios));
    FReportData['scenarioCountText'] := IntToStr(Length(LScenarios));
    FReportData['albumPages'] := TValue.From<TArray<TValue>>(LAlbumPages);
    FReportData['albumPageCountText'] := IntToStr(Length(LAlbumPages));
    FReportData['diagnosticsSummary'] := Result.DiagnosticsSummary;

    LStep := 'html render';
    Result.HtmlReport := BuildHtmlReport;
  except
    on E: Exception do
      raise Exception.CreateFmt(
        'Chinook DWS demo failed at %s. %s: %s',
        [LStep, E.ClassName, E.Message]
      );
  end;
end;
procedure TChinookDwsDemoRunner.SaveOutputTextFile(const ARelativePath, AContent: string);
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