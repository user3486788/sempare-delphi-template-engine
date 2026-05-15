unit Sempare.Template.TestDwsSakilaDemo;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework,
  Sempare.Template.DwsBridgeAdvanced.SakilaDemo;

type
  [TestFixture]
  TDwsSakilaDemoTest = class
  private
    function FindScenario(
      const AReport: TSakilaDwsDemoReport;
      const AScenarioName: string
    ): TSakilaDwsDemoScenarioResult;
  public
    [Test]
    procedure SakilaCliAssetsExist;
    [Test]
    procedure SakilaCliDemoCanRunRepeatedlyWithoutDiagnosticsLifetimeErrors;
    [Test]
    procedure SakilaCliInlineScenariosRenderWithoutParserErrors;
    [Test]
    procedure SakilaCliDemoRendersAllBridgeShowcaseScenarios;
    [Test]
    procedure SakilaCliDemoGeneratesRichHtmlReport;
    [Test]
    procedure SakilaCliDemoGeneratesSinglePageFilmCardsAndPosterCache;
    [Test]
    procedure SakilaCliDemoCanSaveHtmlReportToCustomFile;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils;

procedure AssertContains(const ANeedle, AHaystack: string);
begin
  Assert.IsTrue(
    Pos(ANeedle, AHaystack) > 0,
    Format('Expected "%s" to be present in "%s".', [ANeedle, AHaystack])
  );
end;

function RepoFile(const ARelativePath: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\' + ARelativePath));
end;

procedure TDwsSakilaDemoTest.SakilaCliAssetsExist;
begin
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\Sempare.Template.DwsBridgeAdvanced.SakilaDemo.pas')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\Sempare.Template.DwsBridgeAdvanced.SakilaRuntime.pas')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\sakila.db')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\sakila\actor_profile.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\sakila\film_catalog.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\sakila\report_html.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\sakila\host\customer_badge.tpl')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\sakila\report\film-cards-report.tpl')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\sakila\scenarios\09-structured-json.tpl')));
end;

procedure TDwsSakilaDemoTest.SakilaCliDemoCanSaveHtmlReportToCustomFile;
var
  LReport: TSakilaDwsDemoReport;
  LTargetFileName: string;
begin
  LReport := TSakilaDwsDemo.Run;
  LTargetFileName := TPath.Combine(
    TPath.GetTempPath,
    'Sempare.Sakila.Report.' + TGuid.NewGuid.ToString.Replace('{', '').Replace('}', '') + '.html'
  );
  try
    LReport.SaveHtmlReport(LTargetFileName);
    Assert.IsTrue(TFile.Exists(LTargetFileName));
    AssertContains('<!doctype html>', TFile.ReadAllText(LTargetFileName, TEncoding.UTF8));
    AssertContains('Sakila Database HTML Report', TFile.ReadAllText(LTargetFileName, TEncoding.UTF8));
  finally
    if TFile.Exists(LTargetFileName) then
      TFile.Delete(LTargetFileName);
  end;
end;

procedure TDwsSakilaDemoTest.SakilaCliDemoCanRunRepeatedlyWithoutDiagnosticsLifetimeErrors;
var
  LFirstReport: TSakilaDwsDemoReport;
  LSecondReport: TSakilaDwsDemoReport;
begin
  LFirstReport := TSakilaDwsDemo.Run;
  LSecondReport := TSakilaDwsDemo.Run;

  AssertContains(
    'Scenarios=10, provider=file, db=sakila.db',
    LFirstReport.HtmlReport
  );
  AssertContains(
    'Scenarios=10, provider=file, db=sakila.db',
    LSecondReport.HtmlReport
  );
end;

procedure TDwsSakilaDemoTest.SakilaCliInlineScenariosRenderWithoutParserErrors;
var
  LReport: TSakilaDwsDemoReport;
begin
  LReport := TSakilaDwsDemo.Run;

  AssertContains(
    'Store #1 serves 326 customers',
    FindScenario(LReport, 'DwsInlineText store summary').Output
  );
  AssertContains(
    'Composite Sakila score: 1799',
    FindScenario(LReport, 'DwsInline numeric value').Output
  );
end;

procedure TDwsSakilaDemoTest.SakilaCliDemoGeneratesSinglePageFilmCardsAndPosterCache;
var
  LReport: TSakilaDwsDemoReport;
  LPosterCacheFolder: string;
  LPosterFiles: TArray<string>;
begin
  LReport := TSakilaDwsDemo.Run;

  Assert.AreEqual(0, Length(LReport.PageFiles), 'Sakila export should stay on a single HTML page.');
  AssertContains('<h2>Film Cards</h2>', LReport.HtmlReport);
  AssertContains('This Sakila report stays on a single HTML page', LReport.HtmlReport);
  AssertContains('class="film-card"', LReport.HtmlReport);
  AssertContains('poster-cache/sakila/', LReport.HtmlReport);
  AssertContains('BUCKET BROTHERHOOD', LReport.HtmlReport);
  AssertContains('Rating</dt><dd>PG</dd>', LReport.HtmlReport);
  AssertContains('Rental Rate</dt><dd>0.99</dd>', LReport.HtmlReport);
  AssertContains('Replacement</dt><dd>28.99</dd>', LReport.HtmlReport);
  AssertContains('<strong>Cast:</strong>', LReport.HtmlReport);

  LPosterCacheFolder := RepoFile('demo\DwsBridgeAdvanced\output\poster-cache\sakila');
  Assert.IsTrue(TDirectory.Exists(LPosterCacheFolder));
  LPosterFiles := TDirectory.GetFiles(LPosterCacheFolder, '*.svg');
  Assert.IsTrue(Length(LPosterFiles) > 0, 'Expected Sakila poster cache to contain generated poster assets.');
end;

procedure TDwsSakilaDemoTest.SakilaCliDemoGeneratesRichHtmlReport;
var
  LReport: TSakilaDwsDemoReport;
begin
  LReport := TSakilaDwsDemo.Run;

  AssertContains('<!doctype html>', LReport.HtmlReport);
  AssertContains('Sakila Database HTML Report', LReport.HtmlReport);
  AssertContains('Generated From sakila.db', LReport.HtmlReport);
  AssertContains('Film cards 12', LReport.HtmlReport);
  AssertContains('Bridge showcase 10 scenarios', LReport.HtmlReport);
  AssertContains('Final stage</strong>', StringReplace(LReport.HtmlReport, 'Stage published', 'Final stage</strong>', []));
  AssertContains('Scenarios=10, provider=file, db=sakila.db', LReport.HtmlReport);
end;

procedure TDwsSakilaDemoTest.SakilaCliDemoRendersAllBridgeShowcaseScenarios;
var
  LReport: TSakilaDwsDemoReport;
begin
  LReport := TSakilaDwsDemo.Run;

  Assert.AreEqual(10, Length(LReport.ScenarioResults));
  AssertContains('provider=file', LReport.DiagnosticsSummary);

  AssertContains(
    'sakila-cli spotlighted GINA DEGENERES with 42 films for operations.',
    FindScenario(LReport, 'DwsCall explicit payload').Output
  );
  AssertContains(
    'Store #1 in Lethbridge, Canada leads with 326 customers and 37001.52 revenue.',
    FindScenario(LReport, 'Dws default Main').Output
  );
  AssertContains(
    '&lt;div class=&quot;customer-badge&quot;&gt;&lt;strong&gt;KARL SEAL&lt;/strong&gt; from Cape Coral, United States spent 221.55&lt;/div&gt;',
    FindScenario(LReport, 'DwsText escaped host render').Output
  );
  AssertContains(
    '[Sakila Database HTML Report] totals: 1000 films across 200 actors and 599 customers',
    FindScenario(LReport, 'DwsRender host banner').Output
  );
  AssertContains(
    '<section class="film-blurb"><h2>BUCKET BROTHERHOOD</h2><p>Rating: PG</p><p>Rentals: 34</p></section>',
    FindScenario(LReport, 'DwsRaw trusted html').Output
  );
  AssertContains(
    'Store #1 serves 326 customers',
    FindScenario(LReport, 'DwsInlineText store summary').Output
  );
  AssertContains(
    'Composite Sakila score: 1799',
    FindScenario(LReport, 'DwsInline numeric value').Output
  );
  AssertContains(
    'draft to published via Sports',
    FindScenario(LReport, 'SetVar allow list').Output
  );
  AssertContains(
    'Context stage: published',
    FindScenario(LReport, 'SetVar allow list').Output
  );
  AssertContains(
    'Sports (74), Foreign (73), Family (69)',
    FindScenario(LReport, 'JSON-like result').Output
  );
  AssertContains(
    'Cache miss=1, cache hit=1, compile success=1, call profiles=2.',
    FindScenario(LReport, 'Diagnostics and cache').Output
  );
end;

function TDwsSakilaDemoTest.FindScenario(
  const AReport: TSakilaDwsDemoReport;
  const AScenarioName: string
): TSakilaDwsDemoScenarioResult;
var
  LScenario: TSakilaDwsDemoScenarioResult;
begin
  for LScenario in AReport.ScenarioResults do
    if SameText(LScenario.Name, AScenarioName) then
      Exit(LScenario);
  Assert.Fail('Scenario not found: ' + AScenarioName);
end;

initialization

TDUnitX.RegisterTestFixture(TDwsSakilaDemoTest);

end.

