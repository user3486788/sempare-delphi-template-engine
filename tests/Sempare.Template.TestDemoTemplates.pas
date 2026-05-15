unit Sempare.Template.TestDemoTemplates;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDemoTemplateTest = class
  public
    [Test]
    procedure PlaygroundSample1TemplateRendersExpectedText;
    [Test]
    procedure PlaygroundIndexTemplateResolvesLayoutAndRootData;
    [Test]
    procedure PlaygroundInvoiceTemplateRendersWithSqliteSeededInvoiceData;
    [Test]
    procedure PlaygroundDwsAssetsAreBundledLocally;
    [Test]
    procedure PlaygroundPreviewHtmlFileNameUsesTempHtmlSnapshots;
    [Test]
    procedure PlaygroundPreviewHtmlWriterFallsBackWhenPreferredTempFileIsLocked;
    [Test]
    procedure PlaygroundProjectInitializesFireDacWaitCursorSupport;
    [Test]
    procedure PlaygroundDwsScenarioTemplateListMatchesBundledDemos;
    [Test]
    procedure PlaygroundSharedTemplatePreloadSkipsBundledDwsScenarios;
    [Test]
    procedure PlaygroundTemplateTabSwitchSoftReloadsDwsBridge;
    [Test]
    procedure PlaygroundEvalRestoresDwsBridgeWithoutTemplateReparse;
    [Test]
    procedure PlaygroundDwsExplicitCallScenarioUsesLocalProfileScript;
    [Test]
    procedure PlaygroundDwsHostRenderScenarioUsesLocalBadgeTemplate;
    [Test]
    procedure PlaygroundDwsInvoiceSummaryScenarioUsesLocalSqliteSeedData;
  end;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.IOUtils,
  System.SysUtils,
  Sempare.Template.PlaygroundForm,
  Sempare.Template,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.Types,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.DApt,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param;

type
  TDemoPerson = record
    FirstName: string;
    LastName: string;
    Score: Integer;
    constructor Create(const AFirstName, ALastName: string; const AScore: Integer);
  end;

  TDemoWebReportingData = record
    HighScores: TArray<TDemoPerson>;
  end;

  TDemoInvoice = record
    InvoiceNo: string;
    InvoiceDate: TDate;
    Client: string;
    ClientAddress1: string;
    ClientAddress2: string;
    LogoPath: string;
    Company: string;
    CompanyAddress1: string;
    CompanyAddress2: string;
    CompanyNo: string;
    BillingPeriodStart: TDateTime;
    BillingPeriodEnd: TDateTime;
    HoursWorked: Double;
    HourlyRate: Double;
    Expenses: Double;
    Currency: string;
    Status: string;
    Bank: string;
    BankDetails1: string;
    BankDetails2: string;
    function WorkTotal: Double;
    function Total: Double;
  end;

  TDemoInvoiceTemplateData = record
    Invoice: TDemoInvoice;
  end;

  TDemoWebReportingFunctions = class
  public
    class function JoinNames(const APerson: TDemoPerson): string; static;
  end;

function RepoFile(const ARelativePath: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\' + ARelativePath));
end;

procedure AssertContains(const ANeedle, AHaystack: string);
begin
  Assert.IsTrue(
    Pos(ANeedle, AHaystack) > 0,
    Format('Expected "%s" to be present in "%s".', [ANeedle, AHaystack])
  );
end;

procedure AssertFilesExist(const ARelativePaths: array of string);
var
  LRelativePath: string;
begin
  for LRelativePath in ARelativePaths do
    Assert.IsTrue(
      TFile.Exists(RepoFile(LRelativePath)),
      'Expected demo asset to exist: ' + LRelativePath
    );
end;

procedure RegisterTemplateFile(const ACtx: ITemplateContext; const AName, ARelativePath: string);
begin
  ACtx.SetTemplate(
    AName,
    Template.Parse(ACtx, TFile.ReadAllText(RepoFile(ARelativePath), TEncoding.UTF8))
  );
end;

constructor TDemoPerson.Create(const AFirstName, ALastName: string; const AScore: Integer);
begin
  FirstName := AFirstName;
  LastName := ALastName;
  Score := AScore;
end;

class function TDemoWebReportingFunctions.JoinNames(const APerson: TDemoPerson): string;
begin
  Result := Format('%s %s', [APerson.FirstName, APerson.LastName]);
end;

function TDemoInvoice.Total: Double;
begin
  Result := WorkTotal + Expenses;
end;

function TDemoInvoice.WorkTotal: Double;
begin
  Result := HoursWorked * HourlyRate;
end;

function LoadSqliteInvoiceData: TDemoInvoiceTemplateData;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  Result := Default(TDemoInvoiceTemplateData);

  LConnection := TFDConnection.Create(nil);
  LQuery := TFDQuery.Create(nil);
  try
    LConnection.LoginPrompt := False;
    LConnection.DriverName := 'SQLite';
    LConnection.Params.Values['Database'] := ':memory:';
    LConnection.Connected := True;

    LQuery.Connection := LConnection;
    LQuery.SQL.Text :=
      'create table invoice (' +
      'invoice_no text, invoice_date text, client text, client_address1 text, client_address2 text, ' +
      'company text, company_address1 text, company_address2 text, company_no text, logo_path text, ' +
      'billing_period_start text, billing_period_end text, hours_worked real, hourly_rate real, expenses real, ' +
      'currency text, status text, bank text, bank_details1 text, bank_details2 text)';
    LQuery.ExecSQL;

    LQuery.SQL.Text :=
      'insert into invoice (' +
      'invoice_no, invoice_date, client, client_address1, client_address2, company, company_address1, company_address2, company_no, logo_path, ' +
      'billing_period_start, billing_period_end, hours_worked, hourly_rate, expenses, currency, status, bank, bank_details1, bank_details2) values (' +
      ':invoice_no, :invoice_date, :client, :client_address1, :client_address2, :company, :company_address1, :company_address2, :company_no, :logo_path, ' +
      ':billing_period_start, :billing_period_end, :hours_worked, :hourly_rate, :expenses, :currency, :status, :bank, :bank_details1, :bank_details2)';
    LQuery.ParamByName('invoice_no').AsString := 'INV-SQLITE-001';
    LQuery.ParamByName('invoice_date').AsString := '2026-03-25';
    LQuery.ParamByName('client').AsString := 'SQLite Demo Client';
    LQuery.ParamByName('client_address1').AsString := '42 Query Street';
    LQuery.ParamByName('client_address2').AsString := 'Moscow';
    LQuery.ParamByName('company').AsString := 'Sempare Ltd';
    LQuery.ParamByName('company_address1').AsString := '128 City Road';
    LQuery.ParamByName('company_address2').AsString := 'London EC1V 2NX';
    LQuery.ParamByName('company_no').AsString := '12345678';
    LQuery.ParamByName('logo_path').AsString := 'logo.png';
    LQuery.ParamByName('billing_period_start').AsString := '2026-03-01';
    LQuery.ParamByName('billing_period_end').AsString := '2026-03-24';
    LQuery.ParamByName('hours_worked').AsFloat := 72.25;
    LQuery.ParamByName('hourly_rate').AsFloat := 110;
    LQuery.ParamByName('expenses').AsFloat := 240.5;
    LQuery.ParamByName('currency').AsString := 'GBP';
    LQuery.ParamByName('status').AsString := 'SQLite seeded';
    LQuery.ParamByName('bank').AsString := 'Starling Bank';
    LQuery.ParamByName('bank_details1').AsString := 'Account No: 123123, Sort Code: 12-12-12';
    LQuery.ParamByName('bank_details2').AsString := 'IBAN: GB00 STAR 1234 5678 90';
    LQuery.ExecSQL;

    LQuery.SQL.Text := 'select * from invoice';
    LQuery.Open;

    Result.Invoice.InvoiceNo := LQuery.FieldByName('invoice_no').AsString;
    Result.Invoice.InvoiceDate := ISO8601ToDate(LQuery.FieldByName('invoice_date').AsString);
    Result.Invoice.Client := LQuery.FieldByName('client').AsString;
    Result.Invoice.ClientAddress1 := LQuery.FieldByName('client_address1').AsString;
    Result.Invoice.ClientAddress2 := LQuery.FieldByName('client_address2').AsString;
    Result.Invoice.Company := LQuery.FieldByName('company').AsString;
    Result.Invoice.CompanyAddress1 := LQuery.FieldByName('company_address1').AsString;
    Result.Invoice.CompanyAddress2 := LQuery.FieldByName('company_address2').AsString;
    Result.Invoice.CompanyNo := LQuery.FieldByName('company_no').AsString;
    Result.Invoice.LogoPath := LQuery.FieldByName('logo_path').AsString;
    Result.Invoice.BillingPeriodStart := ISO8601ToDate(LQuery.FieldByName('billing_period_start').AsString);
    Result.Invoice.BillingPeriodEnd := ISO8601ToDate(LQuery.FieldByName('billing_period_end').AsString);
    Result.Invoice.HoursWorked := LQuery.FieldByName('hours_worked').AsFloat;
    Result.Invoice.HourlyRate := LQuery.FieldByName('hourly_rate').AsFloat;
    Result.Invoice.Expenses := LQuery.FieldByName('expenses').AsFloat;
    Result.Invoice.Currency := LQuery.FieldByName('currency').AsString;
    Result.Invoice.Status := LQuery.FieldByName('status').AsString;
    Result.Invoice.Bank := LQuery.FieldByName('bank').AsString;
    Result.Invoice.BankDetails1 := LQuery.FieldByName('bank_details1').AsString;
    Result.Invoice.BankDetails2 := LQuery.FieldByName('bank_details2').AsString;
  finally
    LQuery.Free;
    LConnection.Free;
  end;
end;

procedure TDemoTemplateTest.PlaygroundDwsAssetsAreBundledLocally;
begin
  AssertFilesExist([
    'demo\SempareTemplatePlayground\templates\dws-explicit-call.tpl',
    'demo\SempareTemplatePlayground\templates\dws-host-render.tpl',
    'demo\SempareTemplatePlayground\templates\dws-inline.tpl',
    'demo\SempareTemplatePlayground\templates\dws-invoice-summary.tpl',
    'demo\SempareTemplatePlayground\templates\dws-trusted-raw.tpl',
    'demo\SempareTemplatePlayground\templates\layout.tpl',
    'demo\SempareTemplatePlayground\templates\index.tpl',
    'demo\SempareTemplatePlayground\templates\invoice.tpl',
    'demo\SempareTemplatePlayground\templates\dws\scripts\profile.dws',
    'demo\SempareTemplatePlayground\templates\dws\scripts\card.dws',
    'demo\SempareTemplatePlayground\templates\dws\scripts\markup.dws',
    'demo\SempareTemplatePlayground\templates\dws\scripts\invoice_summary.dws',
    'demo\SempareTemplatePlayground\templates\dws\templates\badge.tpl'
  ]);
end;

procedure TDemoTemplateTest.PlaygroundPreviewHtmlFileNameUsesTempHtmlSnapshots;
var
  LFileNameOne: string;
  LFileNameTwo: string;
begin
  LFileNameOne := TFormTemplateEnginePlayground.BuildPreviewHtmlFileName;
  LFileNameTwo := TFormTemplateEnginePlayground.BuildPreviewHtmlFileName;

  Assert.AreEqual('.htm', TPath.GetExtension(LFileNameOne).ToLowerInvariant);
  Assert.AreEqual(
    ExcludeTrailingPathDelimiter(TPath.GetTempPath).ToLowerInvariant,
    ExcludeTrailingPathDelimiter(TPath.GetDirectoryName(LFileNameOne)).ToLowerInvariant
  );
  Assert.IsFalse(SameText(LFileNameOne, LFileNameTwo));
end;

procedure TDemoTemplateTest.PlaygroundPreviewHtmlWriterFallsBackWhenPreferredTempFileIsLocked;
var
  LLockedFileName: string;
  LWrittenFileName: string;
  LLockStream: TFileStream;
const
  CPreviewText = '<p>locked preview fallback</p>';
begin
  LLockedFileName := TFormTemplateEnginePlayground.BuildPreviewHtmlFileName;
  LLockStream := TFileStream.Create(LLockedFileName, fmCreate or fmShareExclusive);
  try
    LWrittenFileName := TFormTemplateEnginePlayground.WritePreviewHtmlSnapshot(
      CPreviewText,
      TEncoding.UTF8WithoutBOM,
      LLockedFileName
    );
    Assert.IsFalse(SameText(LLockedFileName, LWrittenFileName));
    Assert.IsTrue(TFile.Exists(LWrittenFileName));
    Assert.AreEqual(CPreviewText, TFile.ReadAllText(LWrittenFileName, TEncoding.UTF8));
  finally
    LLockStream.Free;
    if TFile.Exists(LLockedFileName) then
      TFile.Delete(LLockedFileName);
    if (LWrittenFileName <> '') and TFile.Exists(LWrittenFileName) then
      TFile.Delete(LWrittenFileName);
  end;
end;

procedure TDemoTemplateTest.PlaygroundProjectInitializesFireDacWaitCursorSupport;
var
  LProjectSource: string;
  LFormSource: string;
begin
  LProjectSource := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\Sempare.TemplateEngine.Playground.dpr'),
    TEncoding.UTF8
  );
  LFormSource := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\Sempare.Template.PlaygroundForm.pas'),
    TEncoding.UTF8
  );

  AssertContains('FireDAC.VCLUI.Wait', LProjectSource);
  AssertContains('FWaitCursor := TFDGUIxWaitCursor.Create(Self);', LFormSource);
  AssertContains('FWaitCursor.Provider := ''Forms'';', LFormSource);
end;

procedure TDemoTemplateTest.PlaygroundDwsScenarioTemplateListMatchesBundledDemos;
begin
  Assert.IsTrue(TFormTemplateEnginePlayground.IsDwsScenarioTemplate('dws-explicit-call.tpl'));
  Assert.IsTrue(TFormTemplateEnginePlayground.IsDwsScenarioTemplate('dws-host-render.tpl'));
  Assert.IsTrue(TFormTemplateEnginePlayground.IsDwsScenarioTemplate('dws-trusted-raw.tpl'));
  Assert.IsTrue(TFormTemplateEnginePlayground.IsDwsScenarioTemplate('dws-inline.tpl'));
  Assert.IsTrue(TFormTemplateEnginePlayground.IsDwsScenarioTemplate('dws-invoice-summary.tpl'));
  Assert.IsFalse(TFormTemplateEnginePlayground.IsDwsScenarioTemplate('index.tpl'));
  Assert.IsFalse(TFormTemplateEnginePlayground.IsDwsScenarioTemplate('invoice.tpl'));
end;

procedure TDemoTemplateTest.PlaygroundSharedTemplatePreloadSkipsBundledDwsScenarios;
var
  LCtx: ITemplateContext;
  LFile: string;
  LFileName: string;
  LFormSource: string;
begin
  LCtx := Template.Context;
  LCtx.Functions.AddFunctions(TDemoWebReportingFunctions);
  for LFile in TDirectory.GetFiles(RepoFile('demo\SempareTemplatePlayground\templates'), '*.tpl') do
  begin
    LFileName := ExtractFileName(LFile);
    if TFormTemplateEnginePlayground.IsDwsScenarioTemplate(LFileName) then
      Continue;

    try
      LCtx.SetTemplate(
        ChangeFileExt(LFileName, ''),
        Template.Parse(LCtx, TFile.ReadAllText(LFile, TEncoding.UTF8))
      );
    except
      on E: Exception do
        Assert.Fail('Shared template preload should not raise for ' + LFileName + ': ' + E.Message);
    end;
  end;

  LFormSource := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\Sempare.Template.PlaygroundForm.pas'),
    TEncoding.UTF8
  );
  AssertContains('if IsDwsScenarioTemplate(LFileName) then', LFormSource);
  AssertContains('Skipping DWScript scenario template during shared template preload', LFormSource);
end;

procedure TDemoTemplateTest.PlaygroundTemplateTabSwitchSoftReloadsDwsBridge;
var
  LFormSource: string;
begin
  LFormSource := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\Sempare.Template.PlaygroundForm.pas'),
    TEncoding.UTF8
  );

  AssertContains('procedure TFormTemplateEnginePlayground.SoftReloadDwsBridgeForActiveTemplate;', LFormSource);
  AssertContains('SoftReloadDwsBridgeForActiveTemplate;', LFormSource);
  AssertContains('DWScript bridge refreshed for the loaded demo template.', LFormSource);
  AssertContains('DWScript bridge kept warm while viewing the current template.', LFormSource);
end;

procedure TDemoTemplateTest.PlaygroundEvalRestoresDwsBridgeWithoutTemplateReparse;
var
  LFormSource: string;
begin
  LFormSource := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\Sempare.Template.PlaygroundForm.pas'),
    TEncoding.UTF8
  );

  AssertContains('function TFormTemplateEnginePlayground.ContextHasRegisteredDwsBridge: Boolean;', LFormSource);
  AssertContains('procedure TFormTemplateEnginePlayground.EnsureDwsBridgeReadyForCurrentTemplate;', LFormSource);
  AssertContains('function TFormTemplateEnginePlayground.TemplateTextRequiresDwsBridge: Boolean;', LFormSource);
  AssertContains('Pos(''dwscall('', LTemplateText) > 0', LFormSource);
  AssertContains('Result := IsDwsScenarioTemplate(ExtractFileName(FFilename)) or TemplateTextRequiresDwsBridge;', LFormSource);
  AssertContains('if ContextHasRegisteredDwsBridge then', LFormSource);
  AssertContains('EnsureDwsBridgeReadyForCurrentTemplate;', LFormSource);
  AssertContains('FForce := True;', LFormSource);
  AssertContains('DWScript bridge restored for the loaded demo template.', LFormSource);
end;

procedure TDemoTemplateTest.PlaygroundDwsExplicitCallScenarioUsesLocalProfileScript;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LTemplateText: string;
  LOutput: string;
begin
  LCtx := Template.Context;
  LCtx.Variables['currentUser'] := 'ada';
  LCtx.Variables['stage'] := 'ready';

  LBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts, tdboDisallowContextMutation]);
  LBridge.AddScript(
    'profile',
    TFile.ReadAllText(
      RepoFile('demo\SempareTemplatePlayground\templates\dws\scripts\profile.dws'),
      TEncoding.UTF8
    )
  );
  LBridge.RegisterInto(LCtx);

  LTemplateText := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\templates\dws-explicit-call.tpl'),
    TEncoding.UTF8
  );

  LOutput := Template.Eval(LCtx, LTemplateText);

  AssertContains('DWScript explicit call', LOutput);
  AssertContains('ada:ready', LOutput);
end;

procedure TDemoTemplateTest.PlaygroundDwsHostRenderScenarioUsesLocalBadgeTemplate;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LTemplateText: string;
  LOutput: string;
begin
  LCtx := Template.Context;
  LCtx.UseHtmlVariableEncoder;
  LCtx.Variables['name'] := 'Ada';
  RegisterTemplateFile(LCtx, 'badge', 'demo\SempareTemplatePlayground\templates\dws\templates\badge.tpl');

  LBridge := CreateSempareDwsBridge([tdboCacheCompiledScripts, tdboDisallowContextMutation]);
  LBridge.AddScript(
    'card',
    TFile.ReadAllText(
      RepoFile('demo\SempareTemplatePlayground\templates\dws\scripts\card.dws'),
      TEncoding.UTF8
    )
  );
  LBridge.RegisterInto(LCtx);

  LTemplateText := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\templates\dws-host-render.tpl'),
    TEncoding.UTF8
  );

  LOutput := Template.Eval(LCtx, LTemplateText);

  AssertContains('Escaped host render', LOutput);
  AssertContains('&lt;strong&gt;Ada&lt;/strong&gt;', LOutput);
end;

procedure TDemoTemplateTest.PlaygroundDwsInvoiceSummaryScenarioUsesLocalSqliteSeedData;
var
  LCtx: ITemplateContext;
  LBridge: ISempareDwsBridge;
  LData: TDemoInvoiceTemplateData;
  LTemplateText: string;
  LOutput: string;
begin
  LCtx := Template.Context;
  LBridge := CreateSempareDwsBridge([
    tdboCacheCompiledScripts,
    tdboDisallowContextMutation,
    tdboExpectJsonLikeReturn
  ]);
  LBridge.AddScript(
    'invoice_summary',
    TFile.ReadAllText(
      RepoFile('demo\SempareTemplatePlayground\templates\dws\scripts\invoice_summary.dws'),
      TEncoding.UTF8
    )
  );
  LBridge.RegisterInto(LCtx);

  LData := LoadSqliteInvoiceData;
  LTemplateText := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\templates\dws-invoice-summary.tpl'),
    TEncoding.UTF8
  );

  LOutput := Template.Eval<TDemoInvoiceTemplateData>(LCtx, LTemplateText, LData);

  AssertContains('SQLite-backed invoice summary via Dws()', LOutput);
  AssertContains('INV-SQLITE-001', LOutput);
  AssertContains('SQLite Demo Client', LOutput);
  AssertContains('SQLite seeded', LOutput);
  AssertContains('8188', LOutput);
  AssertContains('GBP', LOutput);
end;

procedure TDemoTemplateTest.PlaygroundIndexTemplateResolvesLayoutAndRootData;
var
  LCtx: ITemplateContext;
  LData: TDemoWebReportingData;
  LTemplateText: string;
  LOutput: string;
begin
  LCtx := Template.Context;
  LCtx.Functions.AddFunctions(TDemoWebReportingFunctions);
  RegisterTemplateFile(LCtx, 'layout', 'demo\SempareTemplatePlayground\templates\layout.tpl');
  LTemplateText := TFile.ReadAllText(RepoFile('demo\SempareTemplatePlayground\templates\index.tpl'), TEncoding.UTF8);

  LData.HighScores := [
    TDemoPerson.Create('joe', 'blogs', 10000),
    TDemoPerson.Create('pete', 'pan', 954),
    TDemoPerson.Create('adam', 'smith', 44)
  ];

  LOutput := Template.Eval<TDemoWebReportingData>(LCtx, LTemplateText, LData);

  AssertContains('<title>The high scores for the Dev Days 2024 demo</title>', LOutput);
  AssertContains('joe blogs', LOutput);
  AssertContains('10000', LOutput);
end;

procedure TDemoTemplateTest.PlaygroundInvoiceTemplateRendersWithSqliteSeededInvoiceData;
var
  LCtx: ITemplateContext;
  LData: TDemoInvoiceTemplateData;
  LTemplateText: string;
  LOutput: string;
begin
  LCtx := Template.Context;
  LTemplateText := TFile.ReadAllText(RepoFile('demo\SempareTemplatePlayground\templates\invoice.tpl'), TEncoding.UTF8);
  LData := LoadSqliteInvoiceData;

  LOutput := Template.Eval<TDemoInvoiceTemplateData>(LCtx, LTemplateText, LData);

  AssertContains('INV-SQLITE-001', LOutput);
  AssertContains('SQLite Demo Client', LOutput);
  AssertContains('8188.00', LOutput);
  AssertContains('Starling Bank', LOutput);
end;

procedure TDemoTemplateTest.PlaygroundSample1TemplateRendersExpectedText;
var
  LCtx: ITemplateContext;
  LOutput: string;
  LTemplateText: string;
begin
  LCtx := Template.Context;
  LCtx.Variables['firstname'] := 'Conrad';
  LCtx.Variables['lastname'] := 'Akunga';
  LTemplateText := TFile.ReadAllText(
    RepoFile('demo\SempareTemplatePlayground\templates\sample1.tpl'),
    TEncoding.UTF8
  );

  LOutput := Template.Eval(LCtx, LTemplateText);

  AssertContains('hello Conrad.', LOutput);
  AssertContains('Your last name is Akunga.', LOutput);
end;

initialization
  TDUnitX.RegisterTestFixture(TDemoTemplateTest);

end.

