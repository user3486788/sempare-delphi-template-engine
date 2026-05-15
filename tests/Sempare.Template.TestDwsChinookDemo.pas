unit Sempare.Template.TestDwsChinookDemo;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework,
  Sempare.Template.DwsBridgeAdvanced.Scenarios;

type
  [TestFixture]
  TDwsChinookDemoTest = class
  private
    function FindScenario(
      const AReport: TChinookDwsDemoReport;
      const AScenarioName: string
    ): TChinookDwsDemoScenarioResult;
  public
    [Test]
    procedure ChinookCliAssetsExist;
    [Test]
    procedure ChinookCliDemoRendersAllBridgeShowcaseScenarios;
    [Test]
    procedure ChinookCliDemoGeneratesRichHtmlReport;
    [Test]
    procedure ChinookCliDemoGeneratesAlbumPagesAndPosterCache;
    [Test]
    procedure ChinookCliDemoCanSaveHtmlReportToCustomFile;
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

procedure TDwsChinookDemoTest.ChinookCliAssetsExist;
begin
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\Sempare.Template.DwsBridgeAdvanced.Scenarios.pas')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\chinook.db')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\Sempare.Template.DwsBridgeAdvanced.PosterSupport.pas')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\album_page.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\banner_render.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\customer_card.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\html_blurb.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\scripts\stage_gate.dws')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\host\customer_badge.tpl')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\host\report_banner.tpl')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\report\chinook-report.tpl')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\scenarios\01-explicit-call.tpl')));
  Assert.IsTrue(TFile.Exists(RepoFile('demo\DwsBridgeAdvanced\templates\scenarios\09-structured-json.tpl')));
end;

procedure TDwsChinookDemoTest.ChinookCliDemoCanSaveHtmlReportToCustomFile;
var
  LReport: TChinookDwsDemoReport;
  LTargetFileName: string;
begin
  LReport := TChinookDwsDemo.Run;
  LTargetFileName := TPath.Combine(
    TPath.GetTempPath,
    'Sempare.Chinook.Report.' + TGuid.NewGuid.ToString.Replace('{', '').Replace('}', '') + '.html'
  );
  try
    LReport.SaveHtmlReport(LTargetFileName);
    Assert.IsTrue(TFile.Exists(LTargetFileName));
    AssertContains('<!doctype html>', TFile.ReadAllText(LTargetFileName, TEncoding.UTF8));
    AssertContains('DWScript Integration Showcase', TFile.ReadAllText(LTargetFileName, TEncoding.UTF8));
  finally
    if TFile.Exists(LTargetFileName) then
      TFile.Delete(LTargetFileName);
  end;
end;

procedure TDwsChinookDemoTest.ChinookCliDemoGeneratesAlbumPagesAndPosterCache;
var
  LReport: TChinookDwsDemoReport;
  LFirstPage: string;
  LPosterCacheFolder: string;
  LPosterFiles: TArray<string>;
begin
  LReport := TChinookDwsDemo.Run;

  Assert.IsTrue(Length(LReport.PageFiles) > 0, 'Expected Chinook multipage export to generate album pages.');
  LFirstPage := LReport.PageFiles[0];
  Assert.IsTrue(TFile.Exists(LFirstPage));
  AssertContains('<!doctype html>', TFile.ReadAllText(LFirstPage, TEncoding.UTF8));
  AssertContains('Back to Chinook report', TFile.ReadAllText(LFirstPage, TEncoding.UTF8));
  AssertContains('poster-cache/chinook/', TFile.ReadAllText(LFirstPage, TEncoding.UTF8));

  LPosterCacheFolder := RepoFile('demo\DwsBridgeAdvanced\output\poster-cache\chinook');
  Assert.IsTrue(TDirectory.Exists(LPosterCacheFolder));
  LPosterFiles := TDirectory.GetFiles(LPosterCacheFolder, '*.svg');
  Assert.IsTrue(Length(LPosterFiles) > 0, 'Expected Chinook poster cache to contain generated poster assets.');
end;

procedure TDwsChinookDemoTest.ChinookCliDemoGeneratesRichHtmlReport;
var
  LReport: TChinookDwsDemoReport;
begin
  LReport := TChinookDwsDemo.Run;

  AssertContains('<!doctype html>', LReport.HtmlReport);
  AssertContains('Chinook Database HTML Report', LReport.HtmlReport);
  AssertContains('Top Artists', LReport.HtmlReport);
  AssertContains('Top Customers', LReport.HtmlReport);
  AssertContains('Sales by Country', LReport.HtmlReport);
  AssertContains('DWScript Integration Showcase', LReport.HtmlReport);
  AssertContains('Album Pages', LReport.HtmlReport);
  AssertContains('poster-cache/chinook/', LReport.HtmlReport);
  AssertContains('Bridge showcase 10 scenarios', LReport.HtmlReport);
  AssertContains('Final stage published', LReport.HtmlReport);
  AssertContains('cli-runner reviewed Iron Maiden with 213 tracks.', LReport.HtmlReport);
  AssertContains('Richard Cunningham', LReport.HtmlReport);
  AssertContains('Jane Peacock supports 21 customers', LReport.HtmlReport);
  AssertContains('Bundled+file provider reused compiled scripts.', LReport.HtmlReport);
  AssertContains('Scenarios=10, provider=composite(bundled+file), db=chinook.db', LReport.HtmlReport);
end;

procedure TDwsChinookDemoTest.ChinookCliDemoRendersAllBridgeShowcaseScenarios;
var
  LReport: TChinookDwsDemoReport;
begin
  LReport := TChinookDwsDemo.Run;

  Assert.AreEqual(10, Length(LReport.ScenarioResults));
  AssertContains('provider=composite(bundled+file)', LReport.DiagnosticsSummary);

  AssertContains(
    'cli-runner reviewed Iron Maiden with 213 tracks.',
    FindScenario(LReport, 'DwsCall explicit payload').Output
  );
  AssertContains(
    'Playlist #1 Music contains 3290 tracks.',
    FindScenario(LReport, 'Dws default Main').Output
  );
  AssertContains(
    '&lt;strong&gt;Richard Cunningham&lt;/strong&gt; from USA spent 47.62',
    FindScenario(LReport, 'DwsText escaped host render').Output
  );
  AssertContains(
    '[Chinook Database HTML Report] totals: 3503 tracks across 275 artists',
    FindScenario(LReport, 'DwsRender host banner').Output
  );
  AssertContains(
    '<section class="artist-blurb"><h2>Iron Maiden</h2><p>Tracks: 213</p></section>',
    FindScenario(LReport, 'DwsRaw trusted html').Output
  );
  AssertContains(
    'Jane Peacock supports 21 customers',
    FindScenario(LReport, 'DwsInlineText support rep').Output
  );
  AssertContains(
    'Composite Chinook score: 352',
    FindScenario(LReport, 'DwsInline numeric value').Output
  );
  AssertContains(
    'draft to published',
    FindScenario(LReport, 'SetVar allow list').Output
  );
  AssertContains(
    'Context stage: published',
    FindScenario(LReport, 'SetVar allow list').Output
  );
  AssertContains(
    'Rock (1297), Latin (579), Metal (374)',
    FindScenario(LReport, 'JSON-like result').Output
  );
  AssertContains(
    'Cache miss=1, cache hit=1, compile success=1, call profiles=2.',
    FindScenario(LReport, 'Diagnostics and cache').Output
  );
end;

function TDwsChinookDemoTest.FindScenario(
  const AReport: TChinookDwsDemoReport;
  const AScenarioName: string
): TChinookDwsDemoScenarioResult;
var
  LScenario: TChinookDwsDemoScenarioResult;
begin
  for LScenario in AReport.ScenarioResults do
    if SameText(LScenario.Name, AScenarioName) then
      Exit(LScenario);
  Assert.Fail('Scenario not found: ' + AScenarioName);
end;

initialization

TDUnitX.RegisterTestFixture(TDwsChinookDemoTest);

end.


