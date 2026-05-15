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
unit Sempare.Template.PlaygroundForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Rtti,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  System.Generics.Collections,
  Sempare.Template,
  Sempare.Template.AST,
  Sempare.Template.PrettyPrint,
  Sempare.Template.Common,
  Sempare.Template.DWS.Types,
  Sempare.Template.DWS.Tooling,
  Vcl.StdCtrls,
  Vcl.OleCtrls,
  SHDocVw,
  Vcl.Grids,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.Imaging.pngimage,
  FireDAC.Comp.UI;

type
  TPlaygroundPerson = record
    FirstName: string;
    LastName: string;
    Score: integer;
    constructor Create(const AFirstName, ALastName: string; const AScore: integer);
  end;

  TPlaygroundWebReportingData = record
    HighScores: TArray<TPlaygroundPerson>;
  end;

  TPlaygroundInvoice = record
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

  TPlaygroundInvoiceTemplateData = record
    Invoice: TPlaygroundInvoice;
  end;

  TPlaygroundWebReportingFunctions = class
  public
    class function JoinNames(const APerson: TPlaygroundPerson): string; static;
  end;

  TFormTemplateEnginePlayground = class(TForm)
    memoOutput: TMemo;
    memoTemplate: TMemo;
    cbStripRecurringSpaces: TCheckBox;
    cbConvertTabsToSpaces: TCheckBox;
    memoPrettyPrint: TMemo;
    cbEvalEarly: TCheckBox;
    cbEvalVarsEarly: TCheckBox;
    cbStripRecurringNewlines: TCheckBox;
    cbTrimLines: TCheckBox;
    cbRaiseErrorWhenVariableNotFound: TCheckBox;
    cbHtml: TCheckBox;
    cbSetEncoding: TCheckBox;
    cbUseHtmlBR: TCheckBox;
    WebBrowser1: TWebBrowser;
    butClear: TButton;
    butSave: TButton;
    butOpen: TButton;
    OpenDialog1: TOpenDialog;
    cmbEncoding: TComboBox;
    butSaveAs: TButton;
    SaveDialog1: TSaveDialog;
    pcTemplate: TPageControl;
    tsTemplate: TTabSheet;
    tsPrettyPrint: TTabSheet;
    Panel1: TPanel;
    Splitter1: TSplitter;
    pcOutput: TPageControl;
    tsOutput: TTabSheet;
    tsWebBrowser: TTabSheet;
    gbOptions: TGroupBox;
    Image1: TImage;
    lblTitle: TLabel;
    properties: TStringGrid;
    GroupBox1: TGroupBox;
    butEval: TButton;
    cbAutoEvaluate: TCheckBox;
    cmbCustomScriptTags: TComboBox;
    cbOptimiseTemplate: TCheckBox;
    cbUseCustomScriptTags: TCheckBox;
    cbFlattenTemplate: TCheckBox;
    cbShowWhitespace: TCheckBox;
    lblPosition: TLabel;
    Panel2: TPanel;
    Panel3: TPanel;
    lblTiming: TLabel;
    butExtractVars: TButton;
    tsGithubHelp: TTabSheet;
    wbHelp: TWebBrowser;
    procedure cbConvertTabsToSpacesClick(Sender: TObject);
    procedure cbStripRecurringSpacesClick(Sender: TObject);
    procedure cbTrimLinesClick(Sender: TObject);
    procedure cbStripRecurringNewlinesClick(Sender: TObject);
    procedure cbRaiseErrorWhenVariableNotFoundClick(Sender: TObject);
    procedure cbHtmlClick(Sender: TObject);
    procedure cbUseHtmlBRClick(Sender: TObject);
    procedure cbSetEncodingClick(Sender: TObject);
    procedure cbEvalEarlyClick(Sender: TObject);
    procedure cbEvalVarsEarlyClick(Sender: TObject);
    procedure butClearClick(Sender: TObject);
    procedure butSaveClick(Sender: TObject);
    procedure butOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure memoTemplateChange(Sender: TObject);
    procedure propertiesGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
    procedure propertiesSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure butSaveAsClick(Sender: TObject);
    procedure butEvalClick(Sender: TObject);
    procedure cbUseCustomScriptTagsClick(Sender: TObject);
    procedure cbOptimiseTemplateClick(Sender: TObject);
    procedure cbFlattenTemplateClick(Sender: TObject);
    procedure cmbCustomScriptTagsChange(Sender: TObject);
    procedure cbShowWhitespaceClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure memoTemplateMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure memoTemplateKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure butExtractVarsClick(Sender: TObject);
  private
    { Private declarations }
    FLastContent: string;
    FEncoding: TEncoding;
    FContext: ITemplateContext;
    FTemplate: ITemplate;
    FFilename: string;
    FInit: boolean;
    FForce: boolean;
    FDwsBridge: ISempareDwsBridge;
    FDwsDiagnostics: ITemplateDwsDiagnostics;
    FDwsDiagnosticsRecorder: TTemplateDwsDiagnosticsRecorder;
    FDwsScriptSources: TDictionary<string, string>;
    FDwsBridgeScripts: TDictionary<string, string>;
    FBadgeTemplateSource: string;
    FDwsUiUpdating: boolean;
    FDwsTab: TTabSheet;
    FDwsDiagnosticsTab: TTabSheet;
    FDwsScriptMemo: TMemo;
    FDwsDiagnosticsMemo: TMemo;
    FDwsScenarioCombo: TComboBox;
    FDwsAssetCombo: TComboBox;
    FDwsLoadScenarioButton: TButton;
    FDwsEnableBridgeCheck: TCheckBox;
    FDwsCacheCheck: TCheckBox;
    FDwsPassRootCheck: TCheckBox;
    FDwsInlineCheck: TCheckBox;
    FDwsTrustedTextCheck: TCheckBox;
    FDwsJsonLikeCheck: TCheckBox;
    FDwsStatusLabel: TLabel;
    FExamplePanel: TPanel;
    FExampleTemplatePaths: TDictionary<string, string>;
    FExampleTemplateCombo: TComboBox;
    FExampleLoadButton: TButton;
    FExampleStatusLabel: TLabel;
    FExampleRootData: TValue;
    FExampleUiUpdating: Boolean;
    FPreviewHtmlFileName: string;
    FWaitCursor: TFDGUIxWaitCursor;
    procedure Process;
    procedure GridPropsToContext;
    procedure WriteTmpHtml;
    procedure SetOption(const AEnable: boolean; const AOption: TTemplateEvaluationOption);
    procedure SetScriptTags(const AIdx: Integer);
    procedure Eval;
    procedure CreateDwsBridgeUi;
    procedure LayoutRuntimeUi;
    procedure ApplyDwsScenario(const AIndex: Integer; const AActivateDwsTab: Boolean);
    procedure ConfigureDwsScenarioUi(
      const ATemplateFileName, AAssetName, AStatus: string;
      const APairs: array of string;
      const AEnablePassRoot, AEnableInline, AEnableTrustedRaw, AEnableJsonLike: Boolean;
      const ARootData: TValue
    );
    procedure ResetDwsAssetsToDefaults;
    procedure FillDwsAssetCombo;
    procedure ClearProperties;
    procedure SetProperties(const APairs: array of string);
    procedure LoadDwsScenario(const AIndex: Integer);
    procedure LoadSelectedDwsAsset;
    procedure SaveSelectedDwsAsset;
    procedure DwsAssetChange(Sender: TObject);
    procedure DwsScenarioChange(Sender: TObject);
    procedure DwsLoadScenarioClick(Sender: TObject);
    procedure DwsScriptMemoChange(Sender: TObject);
    procedure DwsOptionsClick(Sender: TObject);
    procedure ResetDwsBridgeRegistration;
    procedure ConfigureDwsBridgeForContext;
    procedure SyncDwsBridgeScripts;
    procedure RenderDwsDiagnostics;
    procedure SetDwsStatus(const AText: string);
    function DwsBridgeOptionsFromUi: TTemplateDwsBridgeOptions;
    function IsDwsTemplateAsset(const AName: string): boolean;
    procedure CreateExampleTemplateUi;
    procedure BuildExampleTemplateCatalog;
    procedure ExampleTemplateChange(Sender: TObject);
    procedure ExampleTemplateLoadClick(Sender: TObject);
    procedure LoadSelectedExampleTemplate;
    procedure TemplateTabChange(Sender: TObject);
    function TemplateTextRequiresDwsBridge: Boolean;
    function CurrentTemplateRequiresDwsBridge: Boolean;
    function ContextHasRegisteredDwsBridge: Boolean;
    procedure EnsureDwsBridgeReadyForCurrentTemplate;
    procedure SoftReloadDwsBridgeForActiveTemplate;
    function IsDwsExamplesTabActive: Boolean;
    function ResolvePlaygroundTemplatesFolder: string;
    function ResolvePlaygroundDwsScriptsFolder: string;
    function ResolvePlaygroundDwsTemplateFolder: string;
    function ReadTextOrFallback(const AFileName, AFallback: string): string;
    class procedure TryDeleteFileQuietly(const AFileName: string); static;
    procedure ApplyTemplateFolderToContext(const AFolder: string);
    procedure ConfigureExampleEnvironment(const AFileName: string);
    procedure SetExampleStatus(const AText: string);
    function CreateDefaultInvoiceData: TPlaygroundInvoiceTemplateData;
    function TryCreateSqliteInvoiceData(out AData: TPlaygroundInvoiceTemplateData; out ADetail: string): Boolean;
  public
    { Public declarations }
    class function BuildPreviewHtmlFileName: string; static;
    class function IsDwsScenarioTemplate(const AFileName: string): Boolean; static;
    class function WritePreviewHtmlSnapshot(
      const AContent: string;
      const AEncoding: TEncoding;
      const APreferredFileName: string = ''
    ): string; static;
    procedure OnException(Sender: TObject; E: Exception);
  end;

var
  FormTemplateEnginePlayground: TFormTemplateEnginePlayground;

implementation

uses
  System.IoUtils,
  System.DateUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Async,
  FireDAC.Stan.Def,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.DApt,
  FireDAC.VCLUI.Wait,
  Sempare.Template.Context,
  Sempare.Template.DWS,
  Sempare.Template.DWS.HostServices;

var
  GFreq: int64;

function DefaultEncoder(const AValue: string): string; forward;
procedure DebugLog(const AMessage: string); forward;

const
  CDwsBadgeAssetName = '[template] badge';
  CDwsBadgeTemplateFile = 'badge.tpl';
  CDwsProfileScriptName = 'profile';
  CDwsCardScriptName = 'card';
  CDwsMarkupScriptName = 'markup';
  CDwsInvoiceSummaryScriptName = 'invoice_summary';
  CMaxPreviewHtmlWriteAttempts = 5;
  CDwsExplicitScenarioTemplateFile = 'dws-explicit-call.tpl';
  CDwsHostRenderScenarioTemplateFile = 'dws-host-render.tpl';
  CDwsTrustedRawScenarioTemplateFile = 'dws-trusted-raw.tpl';
  CDwsInlineScenarioTemplateFile = 'dws-inline.tpl';
  CDwsInvoiceSummaryScenarioTemplateFile = 'dws-invoice-summary.tpl';

  CDefaultBadgeTemplate =
    '<strong><% name %></strong>';

  CDefaultProfileScript =
    'uses SempareHost;' + sLineBreak +
    'function Main(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := String(GetVar(''currentUser'')) + '':'' + data.stage;' + sLineBreak +
    'end;';

  CDefaultCardScript =
    'uses SempareHost;' + sLineBreak +
    'function Render(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  if TemplateExists(''badge'') then' + sLineBreak +
    '    Result := ResolveTemplate(''badge'', data)' + sLineBreak +
    '  else' + sLineBreak +
    '    Result := String(GetVar(''currentUser'')) + '':'' + data.name;' + sLineBreak +
    'end;';

  CDefaultMarkupScript =
    'function Render(data : JSONVariant) : String;' + sLineBreak +
    'begin' + sLineBreak +
    '  Result := data.html;' + sLineBreak +
    'end;';

  CDefaultInvoiceSummaryScript =
    'function Main(data : JSONVariant) : String;' + sLineBreak +
    'var' + sLineBreak +
    '  workTotal : Float;' + sLineBreak +
    '  total : Float;' + sLineBreak +
    'begin' + sLineBreak +
    '  workTotal := data.Invoice.HoursWorked * data.Invoice.HourlyRate;' + sLineBreak +
    '  total := workTotal + data.Invoice.Expenses;' + sLineBreak +
    '  Result := ''{"invoiceNo":"'' + String(data.Invoice.InvoiceNo) +' + sLineBreak +
    '    ''","client":"'' + String(data.Invoice.Client) +' + sLineBreak +
    '    ''","status":"'' + String(data.Invoice.Status) +' + sLineBreak +
    '    ''","currency":"'' + String(data.Invoice.Currency) +' + sLineBreak +
    '    ''","workTotal":"'' + FloatToStr(workTotal) +' + sLineBreak +
    '    ''","total":"'' + FloatToStr(total) +' + sLineBreak +
    '    ''"}'';' + sLineBreak +
    'end;';

  CScenarioExplicitCallTemplate =
    '<div class="bridge-demo">' + sLineBreak +
    '  <h2>DWScript explicit call</h2>' + sLineBreak +
    '  <p><% DwsCall(''profile'', ''Main'', { "stage": stage }) %></p>' + sLineBreak +
    '</div>';

  CScenarioEscapedRenderTemplate =
    '<div class="bridge-demo">' + sLineBreak +
    '  <h2>Escaped host render</h2>' + sLineBreak +
    '  <p><% DwsRender(''card'', { "name": name }) %></p>' + sLineBreak +
    '</div>';

  CScenarioTrustedRawTemplate =
    '<div class="bridge-demo">' + sLineBreak +
    '  <h2>Trusted raw output</h2>' + sLineBreak +
    '  <% print(DwsRaw(''markup'', ''Render'', { "html": trustedHtml })) %>' + sLineBreak +
    '</div>';

  CScenarioInlineTemplate =
    '<div class="bridge-demo">' + sLineBreak +
    '  <h2>Inline helper</h2>' + sLineBreak +
    '  <p><% DwsInline(''function Main(data : JSONVariant) : String; begin Result := String(data.user) + String(data.stage); end;'', ''Main'', { "user": currentUser, "stage": stage }) %></p>' + sLineBreak +
    '</div>';

  CScenarioInvoiceSummaryTemplate =
    '<div class="bridge-demo">' + sLineBreak +
    '  <h2>SQLite-backed invoice summary via Dws()</h2>' + sLineBreak +
    '  <% summary := Dws(''invoice_summary'', { "Invoice": Invoice }) %>' + sLineBreak +
    '  <p><strong>Invoice:</strong> <% summary.invoiceNo %></p>' + sLineBreak +
    '  <p><strong>Client:</strong> <% summary.client %></p>' + sLineBreak +
    '  <p><strong>Status:</strong> <% summary.status %></p>' + sLineBreak +
    '  <p><strong>Total:</strong> <% summary.total %> <% summary.currency %></p>' + sLineBreak +
    '</div>';

{$R *.dfm}

constructor TPlaygroundPerson.Create(const AFirstName, ALastName: string; const AScore: integer);
begin
  FirstName := AFirstName;
  LastName := ALastName;
  Score := AScore;
end;

class function TPlaygroundWebReportingFunctions.JoinNames(const APerson: TPlaygroundPerson): string;
begin
  Result := Format('%s %s', [APerson.FirstName, APerson.LastName]);
end;

function TPlaygroundInvoice.Total: Double;
begin
  Result := WorkTotal + Expenses;
end;

function TPlaygroundInvoice.WorkTotal: Double;
begin
  Result := HoursWorked * HourlyRate;
end;

procedure TFormTemplateEnginePlayground.butClearClick(Sender: TObject);
var
  LIdx: Integer;
begin
  lblTiming.Caption := '';
  memoTemplate.Lines.Text := '';
  FFilename := '';
  FExampleRootData := TValue.Empty;
  butSave.Enabled := false;
  for LIdx := 1 to properties.RowCount do
  begin
    properties.Cells[0, LIdx] := '';
    properties.Cells[1, LIdx] := '';
  end;
  SetExampleStatus('Editor cleared. Load a demo template or continue with manual input.');
  Eval;
end;

procedure TFormTemplateEnginePlayground.FormResize(Sender: TObject);
begin
  LayoutRuntimeUi;
end;

procedure TFormTemplateEnginePlayground.LayoutRuntimeUi;
var
  LPanelLeft: Integer;
  LPanelTop: Integer;
  LPanelWidth: Integer;
begin
  if (FExamplePanel = nil) or (Panel1 = nil) then
    Exit;

  LPanelLeft := butExtractVars.Left + butExtractVars.Width + 12;
  LPanelTop := butEval.Top - 1;
  LPanelWidth := ClientWidth - LPanelLeft - 20;
  if LPanelWidth < 220 then
    LPanelWidth := 220;

  FExamplePanel.SetBounds(LPanelLeft, LPanelTop, LPanelWidth, 52);
  FExampleTemplateCombo.SetBounds(0, 0, FExamplePanel.Width - 118, 23);
  FExampleLoadButton.SetBounds(FExamplePanel.Width - 110, 0, 110, 25);
  FExampleStatusLabel.SetBounds(0, 29, FExamplePanel.Width, 23);

  Panel1.Top := FExamplePanel.Top + FExamplePanel.Height + 6;
  Panel1.Height := ClientHeight - Panel1.Top - 8;
end;

function TFormTemplateEnginePlayground.ResolvePlaygroundTemplatesFolder: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), 'templates'));
  if TFile.Exists(TPath.Combine(Result, 'sample1.tpl')) then
    Exit;

  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\templates'));
  if TFile.Exists(TPath.Combine(Result, 'sample1.tpl')) then
    Exit;

  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\templates'));
end;

function TFormTemplateEnginePlayground.ResolvePlaygroundDwsScriptsFolder: string;
begin
  Result := TPath.Combine(ResolvePlaygroundTemplatesFolder, 'dws\scripts');
end;

function TFormTemplateEnginePlayground.ResolvePlaygroundDwsTemplateFolder: string;
begin
  Result := TPath.Combine(ResolvePlaygroundTemplatesFolder, 'dws\templates');
end;

function TFormTemplateEnginePlayground.ReadTextOrFallback(const AFileName, AFallback: string): string;
begin
  if TFile.Exists(AFileName) then
    Result := TFile.ReadAllText(AFileName, TEncoding.UTF8)
  else
    Result := AFallback;
end;

procedure TFormTemplateEnginePlayground.ConfigureDwsScenarioUi(
  const ATemplateFileName, AAssetName, AStatus: string;
  const APairs: array of string;
  const AEnablePassRoot, AEnableInline, AEnableTrustedRaw, AEnableJsonLike: Boolean;
  const ARootData: TValue
);
var
  LTemplatePath: string;
begin
  FDwsUiUpdating := True;
  try
    cbHtml.Checked := True;
    cbUseHtmlBR.Checked := True;
    FContext.UseHtmlVariableEncoder;
    FContext.NewLine := '<br>'#13#10;
    FDwsEnableBridgeCheck.Checked := True;
    FDwsCacheCheck.Checked := True;
    FDwsPassRootCheck.Checked := AEnablePassRoot;
    FDwsInlineCheck.Checked := AEnableInline;
    FDwsTrustedTextCheck.Checked := AEnableTrustedRaw;
    if FDwsJsonLikeCheck <> nil then
      FDwsJsonLikeCheck.Checked := AEnableJsonLike;

    SetProperties(APairs);
    FExampleRootData := ARootData;
    LTemplatePath := TPath.Combine(ResolvePlaygroundTemplatesFolder, ATemplateFileName);
    memoTemplate.Lines.Text := ReadTextOrFallback(LTemplatePath, memoTemplate.Lines.Text);
    FFilename := LTemplatePath;
    FDwsAssetCombo.ItemIndex := FDwsAssetCombo.Items.IndexOf(AAssetName);
    SetDwsStatus(AStatus);
  finally
    FDwsUiUpdating := False;
  end;

  LoadSelectedDwsAsset;
end;

procedure TFormTemplateEnginePlayground.ApplyDwsScenario(const AIndex: Integer; const AActivateDwsTab: Boolean);
var
  LInvoiceData: TPlaygroundInvoiceTemplateData;
  LDetail: string;
  LStatus: string;
begin
  ResetDwsAssetsToDefaults;

  case AIndex of
    1:
      ConfigureDwsScenarioUi(
        CDwsHostRenderScenarioTemplateFile,
        CDwsCardScriptName,
        'Host render demo loaded. Evaluate twice to observe cache hits in Bridge Diagnostics.',
        ['currentUser', 'ada', 'name', 'Ada'],
        False,
        False,
        False,
        False,
        TValue.Empty
      );
    2:
      ConfigureDwsScenarioUi(
        CDwsTrustedRawScenarioTemplateFile,
        CDwsMarkupScriptName,
        'Trusted raw demo loaded. The output tab shows markup and the browser tab renders it.',
        ['trustedHtml', '<em>trusted</em>'],
        False,
        False,
        True,
        False,
        TValue.Empty
      );
    3:
      ConfigureDwsScenarioUi(
        CDwsInlineScenarioTemplateFile,
        CDwsProfileScriptName,
        'Inline demo loaded. Edit the template source to change the inline DWScript entry.',
        ['currentUser', 'ada', 'stage', 'sandbox'],
        False,
        True,
        False,
        False,
        TValue.Empty
      );
    4:
      begin
        if not TryCreateSqliteInvoiceData(LInvoiceData, LDetail) then
        begin
          LInvoiceData := CreateDefaultInvoiceData;
          if LDetail = '' then
            LDetail := 'SQLite sample unavailable, using static invoice seed.';
        end;
        LStatus := 'SQLite invoice DWS demo loaded. ' + LDetail + ' Evaluate twice to observe cache hits and JSON-like result parsing.';
        ConfigureDwsScenarioUi(
          CDwsInvoiceSummaryScenarioTemplateFile,
          CDwsInvoiceSummaryScriptName,
          LStatus,
          [],
          False,
          False,
          False,
          True,
          TValue.From<TPlaygroundInvoiceTemplateData>(LInvoiceData)
        );
      end;
  else
      ConfigureDwsScenarioUi(
        CDwsExplicitScenarioTemplateFile,
        CDwsProfileScriptName,
        'Explicit call demo loaded. Edit profile script or template payload, then evaluate again.',
        ['currentUser', 'ada', 'stage', 'ready'],
        False,
        False,
        False,
        False,
        TValue.Empty
      );
  end;

  FForce := True;
  if AActivateDwsTab then
    pcTemplate.ActivePage := FDwsTab;
end;

procedure TFormTemplateEnginePlayground.ApplyTemplateFolderToContext(const AFolder: string);
var
  LFile: string;
  LFileName: string;
  LName: string;
begin
  FContext.ClearTemplates;
  for LFile in TDirectory.GetFiles(AFolder, '*.tpl') do
  begin
    LFileName := ExtractFileName(LFile);
    if IsDwsScenarioTemplate(LFileName) then
    begin
      DebugLog('[FIX] Skipping DWScript scenario template during shared template preload: ' + LFileName);
      Continue;
    end;
    LName := ChangeFileExt(ExtractFileName(LFile), '');
    FContext.SetTemplate(LName, Template.Parse(FContext, TFile.ReadAllText(LFile, FEncoding)));
  end;
end;

procedure TFormTemplateEnginePlayground.butEvalClick(Sender: TObject);
begin
  Eval;
end;

procedure TFormTemplateEnginePlayground.butExtractVarsClick(Sender: TObject);
var
  LVars: TArray<string>;
  LFuncs: TArray<string>;
  i: Integer;
begin
  EnsureDwsBridgeReadyForCurrentTemplate;
  FTemplate := Template.Parse(FContext, memoTemplate.Lines.Text);
  for i := 1 to properties.RowCount do
  begin
    properties.Cells[0, i] := '';
    properties.Cells[1, i] := '';
  end;
  Template.ExtractReferences(FTemplate, LVars, LFuncs);
  for i := 0 to high(LVars) do
  begin
    properties.Cells[0, i + 1] := LVars[i];
  end;
end;

procedure TFormTemplateEnginePlayground.butOpenClick(Sender: TObject);
begin
  OpenDialog1.DefaultExt := '.template';
  OpenDialog1.Filter := '*.template';
  if OpenDialog1.Execute then
  begin
    FFilename := OpenDialog1.FileName;
    FExampleRootData := TValue.Empty;

    memoTemplate.Lines.LoadFromFile(FFilename, FEncoding);
    butSave.Enabled := false;
    pcTemplate.ActivePageIndex := 0;
    pcOutput.ActivePageIndex := 0;
    SetExampleStatus('Loaded template from file system without demo root data.');
  end;
end;

procedure TFormTemplateEnginePlayground.butSaveAsClick(Sender: TObject);
begin
  SaveDialog1.DefaultExt := '.template';
  SaveDialog1.Filter := '*.template';
  if FFilename = '' then
    SaveDialog1.FileName := 'output.template'
  else
    SaveDialog1.FileName := FFilename;
  if SaveDialog1.Execute then
  begin

    FFilename := SaveDialog1.FileName;
    memoTemplate.Lines.SaveToFile(FFilename, FEncoding);
  end;
end;

procedure TFormTemplateEnginePlayground.butSaveClick(Sender: TObject);
begin
  if FFilename = '' then
    exit;
  memoTemplate.Lines.SaveToFile(FFilename, FEncoding);
  butSave.Enabled := false;
end;

class function TFormTemplateEnginePlayground.IsDwsScenarioTemplate(const AFileName: string): Boolean;
begin
  Result := SameText(AFileName, CDwsExplicitScenarioTemplateFile) or
    SameText(AFileName, CDwsHostRenderScenarioTemplateFile) or
    SameText(AFileName, CDwsTrustedRawScenarioTemplateFile) or
    SameText(AFileName, CDwsInlineScenarioTemplateFile) or
    SameText(AFileName, CDwsInvoiceSummaryScenarioTemplateFile);
end;

function TFormTemplateEnginePlayground.TemplateTextRequiresDwsBridge: Boolean;
var
  LTemplateText: string;
begin
  LTemplateText := LowerCase(memoTemplate.Lines.Text);
  Result :=
    (Pos('dwscall(', LTemplateText) > 0) or
    (Pos('dwstext(', LTemplateText) > 0) or
    (Pos('dwsrender(', LTemplateText) > 0) or
    (Pos('dwsraw(', LTemplateText) > 0) or
    (Pos('dwsinline(', LTemplateText) > 0) or
    (Pos('dwsinlinetext(', LTemplateText) > 0) or
    (Pos('dws(', LTemplateText) > 0);
end;

function TFormTemplateEnginePlayground.CurrentTemplateRequiresDwsBridge: Boolean;
begin
  Result := IsDwsScenarioTemplate(ExtractFileName(FFilename)) or TemplateTextRequiresDwsBridge;
end;

function TFormTemplateEnginePlayground.ContextHasRegisteredDwsBridge: Boolean;
var
  LBridgeValue: TValue;
  LMethods: TArray<TRttiMethod>;
begin
  Result := False;
  if FContext = nil then
    Exit;
  if not FContext.TryGetFunction('dwscall', LMethods) then
    Exit;
  if not FContext.TryGetVariable(TemplateDwsBridgeContextKey, LBridgeValue) then
    Exit;
  Result := LBridgeValue.IsType<ISempareDwsBridge> and (LBridgeValue.AsType<ISempareDwsBridge> <> nil);
end;

procedure TFormTemplateEnginePlayground.EnsureDwsBridgeReadyForCurrentTemplate;
begin
  if not CurrentTemplateRequiresDwsBridge then
    Exit;
  if FDwsEnableBridgeCheck = nil then
    Exit;

  if not FDwsEnableBridgeCheck.Checked then
  begin
    FDwsUiUpdating := True;
    try
      FDwsEnableBridgeCheck.Checked := True;
    finally
      FDwsUiUpdating := False;
    end;
    SetDwsStatus('Auto-enabled DWScript bridge for the loaded demo template.');
  end;

  if ContextHasRegisteredDwsBridge then
    Exit;

  ResetDwsBridgeRegistration;
  ConfigureDwsBridgeForContext;
  FForce := True;
  RenderDwsDiagnostics;
  if IsDwsExamplesTabActive then
    SetDwsStatus('DWScript bridge restored for the loaded demo template.')
  else
    SetDwsStatus('DWScript bridge restored before evaluating the current template.');
end;

procedure TFormTemplateEnginePlayground.SoftReloadDwsBridgeForActiveTemplate;
begin
  if FDwsEnableBridgeCheck = nil then
    Exit;

  if CurrentTemplateRequiresDwsBridge then
  begin
    if not FDwsEnableBridgeCheck.Checked then
      FDwsEnableBridgeCheck.Checked := True;
    ResetDwsBridgeRegistration;
    ConfigureDwsBridgeForContext;
    RenderDwsDiagnostics;
    if IsDwsExamplesTabActive then
      SetDwsStatus('DWScript bridge refreshed for the loaded demo template.')
    else
      SetDwsStatus('DWScript bridge kept warm while viewing the current template.');
    Exit;
  end;

  ResetDwsBridgeRegistration;
  if FDwsDiagnosticsMemo <> nil then
    FDwsDiagnosticsMemo.Lines.Text := 'DWScript bridge is idle for the current non-DWScript template.';
  if IsDwsExamplesTabActive then
    SetDwsStatus('DWScript editor is ready. Load a scenario to activate the bridge.');
end;

function TFormTemplateEnginePlayground.IsDwsExamplesTabActive: Boolean;
begin
  Result := (pcTemplate <> nil) and (FDwsTab <> nil) and (pcTemplate.ActivePage = FDwsTab);
end;

procedure TFormTemplateEnginePlayground.BuildExampleTemplateCatalog;
var
  LFolder: string;
  LFile: string;
  LFileName: string;
  LLabel: string;
  LSelectedPath: string;
  LPath: string;
  LIdx: Integer;
  LShowDwsExamples: Boolean;
begin
  if (FExampleTemplatePaths = nil) or (FExampleTemplateCombo = nil) then
    Exit;

  LSelectedPath := '';
  if (FExampleTemplateCombo.ItemIndex >= 0) and FExampleTemplatePaths.TryGetValue(FExampleTemplateCombo.Text, LPath) then
    LSelectedPath := LPath;

  LShowDwsExamples := IsDwsExamplesTabActive;
  FExampleUiUpdating := True;
  try
    FExampleTemplatePaths.Clear;
    FExampleTemplateCombo.Items.BeginUpdate;
    try
      FExampleTemplateCombo.Items.Clear;

      LFolder := ResolvePlaygroundTemplatesFolder;
      if TDirectory.Exists(LFolder) then
        for LFile in TDirectory.GetFiles(LFolder, '*.tpl') do
        begin
          LFileName := ExtractFileName(LFile);
          if SameText(LFileName, 'layout.tpl') then
            Continue;
          if IsDwsScenarioTemplate(LFileName) <> LShowDwsExamples then
            Continue;

          if LShowDwsExamples then
            LLabel := 'DWScript: ' + LFileName
          else
            LLabel := 'Playground: ' + LFileName;
          FExampleTemplatePaths.AddOrSetValue(LLabel, TPath.GetFullPath(LFile));
          FExampleTemplateCombo.Items.Add(LLabel);
        end;

      FExampleTemplateCombo.ItemIndex := -1;
      if LSelectedPath <> '' then
        for LIdx := 0 to FExampleTemplateCombo.Items.Count - 1 do
          if FExampleTemplatePaths.TryGetValue(FExampleTemplateCombo.Items[LIdx], LPath) and SameText(LPath, LSelectedPath) then
          begin
            FExampleTemplateCombo.ItemIndex := LIdx;
            Break;
          end;

      if (FExampleTemplateCombo.ItemIndex < 0) and (FExampleTemplateCombo.Items.Count > 0) then
        FExampleTemplateCombo.ItemIndex := 0;
    finally
      FExampleTemplateCombo.Items.EndUpdate;
    end;
  finally
    FExampleUiUpdating := False;
  end;
end;

procedure TFormTemplateEnginePlayground.TemplateTabChange(Sender: TObject);
begin
  BuildExampleTemplateCatalog;
  if IsDwsExamplesTabActive then
    SetExampleStatus('Choose a DWScript demo from the shared example list above.')
  else
    SetExampleStatus('Choose a Playground template from the shared example list above.');
  SoftReloadDwsBridgeForActiveTemplate;
end;

procedure TFormTemplateEnginePlayground.ClearProperties;
var
  LIdx: Integer;
begin
  for LIdx := 1 to properties.RowCount - 1 do
  begin
    properties.Cells[0, LIdx] := '';
    properties.Cells[1, LIdx] := '';
  end;
end;

procedure TFormTemplateEnginePlayground.ConfigureExampleEnvironment(const AFileName: string);
var
  LData: TPlaygroundWebReportingData;
  LInvoiceData: TPlaygroundInvoiceTemplateData;
  LDetail: string;
  LIsDwsScenario: Boolean;
begin
  LIsDwsScenario := IsDwsScenarioTemplate(AFileName);
  FExampleRootData := TValue.Empty;
  FContext.VariableEncoder := DefaultEncoder;
  FContext.NewLine := sLineBreak;
  cbHtml.Checked := false;
  cbUseHtmlBR.Checked := false;
  if not LIsDwsScenario then
  begin
    if FDwsEnableBridgeCheck <> nil then
      FDwsEnableBridgeCheck.Checked := false;
    if FDwsPassRootCheck <> nil then
      FDwsPassRootCheck.Checked := false;
    if FDwsInlineCheck <> nil then
      FDwsInlineCheck.Checked := false;
    if FDwsTrustedTextCheck <> nil then
      FDwsTrustedTextCheck.Checked := false;
    if FDwsJsonLikeCheck <> nil then
      FDwsJsonLikeCheck.Checked := false;
  end;
  SetProperties(['name', 'world']);

  if SameText(AFileName, 'international.tpl') then
  begin
    SetProperties(['show_translation', 'true']);
    cbHtml.Checked := true;
    cbUseHtmlBR.Checked := true;
    FContext.UseHtmlVariableEncoder;
    FContext.NewLine := '<br>'#13#10;
    SetExampleStatus('Loaded Playground international sample.');
    Exit;
  end;

  if SameText(AFileName, 'sample1.tpl') then
  begin
    SetProperties(['firstname', 'Conrad', 'lastname', 'Akunga']);
    SetExampleStatus('Loaded Playground sample1.tpl with default author variables.');
    Exit;
  end;

  if SameText(AFileName, 'sample2.tpl') then
  begin
    SetProperties([]);
    SetExampleStatus('Loaded Playground sample2.tpl loop sample.');
    Exit;
  end;

  if SameText(AFileName, 'index.tpl') then
  begin
    LData.HighScores := [
      TPlaygroundPerson.Create('joe', 'blogs', 10000),
      TPlaygroundPerson.Create('pete', 'pan', 954),
      TPlaygroundPerson.Create('adam', 'smith', 44)
    ];
    FExampleRootData := TValue.From<TPlaygroundWebReportingData>(LData);
    cbHtml.Checked := true;
    cbUseHtmlBR.Checked := true;
    FContext.UseHtmlVariableEncoder;
    FContext.NewLine := '<br>'#13#10;
    SetExampleStatus('Loaded local index.tpl with layout.tpl dependency and sample high-score root data.');
    Exit;
  end;

  if SameText(AFileName, 'invoice.tpl') then
  begin
    if not TryCreateSqliteInvoiceData(LInvoiceData, LDetail) then
    begin
      LInvoiceData := CreateDefaultInvoiceData;
      if LDetail = '' then
        LDetail := 'SQLite sample unavailable, using static invoice seed.';
    end;

    FExampleRootData := TValue.From<TPlaygroundInvoiceTemplateData>(LInvoiceData);
    cbHtml.Checked := true;
    cbUseHtmlBR.Checked := true;
    FContext.UseHtmlVariableEncoder;
    FContext.NewLine := '<br>'#13#10;
    SetExampleStatus(LDetail);
    Exit;
  end;

  if SameText(AFileName, CDwsExplicitScenarioTemplateFile) then
  begin
    ApplyDwsScenario(0, false);
    SetExampleStatus('Loaded local DwsCall demo template and bridge assets.');
    Exit;
  end;

  if SameText(AFileName, CDwsHostRenderScenarioTemplateFile) then
  begin
    ApplyDwsScenario(1, false);
    SetExampleStatus('Loaded local DwsRender host-template demo with editable card and badge assets.');
    Exit;
  end;

  if SameText(AFileName, CDwsTrustedRawScenarioTemplateFile) then
  begin
    ApplyDwsScenario(2, false);
    SetExampleStatus('Loaded local trusted raw-output demo with editable markup script.');
    Exit;
  end;

  if SameText(AFileName, CDwsInlineScenarioTemplateFile) then
  begin
    ApplyDwsScenario(3, false);
    SetExampleStatus('Loaded local inline DWScript demo.');
    Exit;
  end;

  if SameText(AFileName, CDwsInvoiceSummaryScenarioTemplateFile) then
  begin
    ApplyDwsScenario(4, false);
    SetExampleStatus('Loaded local SQLite-backed DWS invoice summary demo.');
    Exit;
  end;

  SetExampleStatus('Loaded local Playground template.');
end;

procedure TFormTemplateEnginePlayground.CreateExampleTemplateUi;
begin
  FExamplePanel := TPanel.Create(Self);
  FExamplePanel.Parent := Self;
  FExamplePanel.BevelOuter := bvNone;
  FExamplePanel.Caption := '';
  FExamplePanel.Anchors := [akLeft, akTop, akRight];

  FExampleTemplateCombo := TComboBox.Create(Self);
  FExampleTemplateCombo.Parent := FExamplePanel;
  FExampleTemplateCombo.Style := csDropDownList;
  FExampleTemplateCombo.OnChange := ExampleTemplateChange;

  FExampleLoadButton := TButton.Create(Self);
  FExampleLoadButton.Parent := FExamplePanel;
  FExampleLoadButton.Width := 110;
  FExampleLoadButton.Height := 25;
  FExampleLoadButton.Caption := 'Load Example';
  FExampleLoadButton.OnClick := ExampleTemplateLoadClick;

  FExampleStatusLabel := TLabel.Create(Self);
  FExampleStatusLabel.Parent := FExamplePanel;
  FExampleStatusLabel.AutoSize := false;
  FExampleStatusLabel.WordWrap := true;
  FExampleStatusLabel.Caption := 'Choose a Playground template from the shared example list above.';

  LayoutRuntimeUi;
end;

function TFormTemplateEnginePlayground.CreateDefaultInvoiceData: TPlaygroundInvoiceTemplateData;
begin
  Result.Invoice.InvoiceNo := 'INV-2026-001';
  Result.Invoice.InvoiceDate := EncodeDate(2026, 3, 25);
  Result.Invoice.Client := 'Acme Corp';
  Result.Invoice.ClientAddress1 := '1 Infinite Loop';
  Result.Invoice.ClientAddress2 := 'London';
  Result.Invoice.Company := 'Sempare Ltd';
  Result.Invoice.CompanyAddress1 := '128 City Road';
  Result.Invoice.CompanyAddress2 := 'London EC1V 2NX';
  Result.Invoice.CompanyNo := '12345678';
  Result.Invoice.LogoPath := TPath.Combine(TPath.GetDirectoryName(Application.ExeName), 'logo.png');
  Result.Invoice.BillingPeriodStart := EncodeDate(2026, 3, 1);
  Result.Invoice.BillingPeriodEnd := EncodeDate(2026, 3, 24);
  Result.Invoice.HoursWorked := 64.5;
  Result.Invoice.HourlyRate := 95;
  Result.Invoice.Expenses := 180.75;
  Result.Invoice.Currency := 'GBP';
  Result.Invoice.Status := 'Draft';
  Result.Invoice.Bank := 'Starling Bank';
  Result.Invoice.BankDetails1 := 'Account No: 123123, Sort Code: 12-12-12';
  Result.Invoice.BankDetails2 := 'IBAN: GB00 STAR 1234 5678 90';
end;

procedure TFormTemplateEnginePlayground.ExampleTemplateChange(Sender: TObject);
begin
  if FExampleUiUpdating then
    Exit;
  if cbAutoEvaluate.Checked then
    LoadSelectedExampleTemplate;
end;

procedure TFormTemplateEnginePlayground.ExampleTemplateLoadClick(Sender: TObject);
begin
  LoadSelectedExampleTemplate;
end;

procedure TFormTemplateEnginePlayground.LoadSelectedExampleTemplate;
var
  LPath: string;
  LFileName: string;
  LActivePage: TTabSheet;
begin
  if (FExampleTemplateCombo = nil) or (FExampleTemplateCombo.ItemIndex < 0) then
    Exit;

  if not FExampleTemplatePaths.TryGetValue(FExampleTemplateCombo.Text, LPath) then
    Exit;

  LFileName := ExtractFileName(LPath);
  LActivePage := pcTemplate.ActivePage;
  FExampleUiUpdating := True;
  try
    if IsDwsScenarioTemplate(LFileName) then
      ConfigureExampleEnvironment(LFileName)
    else
    begin
      ApplyTemplateFolderToContext(ExtractFileDir(LPath));
      memoTemplate.Lines.LoadFromFile(LPath, FEncoding);
      FFilename := LPath;
      ConfigureExampleEnvironment(LFileName);
    end;
  finally
    FExampleUiUpdating := False;
  end;

  pcTemplate.ActivePage := LActivePage;
  FForce := True;
  Eval;
end;

procedure TFormTemplateEnginePlayground.SetExampleStatus(const AText: string);
begin
  if FExampleStatusLabel <> nil then
    FExampleStatusLabel.Caption := AText;
end;

function TFormTemplateEnginePlayground.TryCreateSqliteInvoiceData(out AData: TPlaygroundInvoiceTemplateData; out ADetail: string): Boolean;
var
  LConnection: TFDConnection;
  LQuery: TFDQuery;
begin
  AData := Default(TPlaygroundInvoiceTemplateData);
  ADetail := '';
  Result := False;
  LConnection := TFDConnection.Create(nil);
//    FDGUIxWaitCursor1:= TFDGUIxWaitCursor
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
    LQuery.ParamByName('logo_path').AsString := TPath.Combine(TPath.GetDirectoryName(Application.ExeName), 'logo.png');
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
    if LQuery.Eof then
      Exit;

    AData.Invoice.InvoiceNo := LQuery.FieldByName('invoice_no').AsString;
    AData.Invoice.InvoiceDate := ISO8601ToDate(LQuery.FieldByName('invoice_date').AsString);
    AData.Invoice.Client := LQuery.FieldByName('client').AsString;
    AData.Invoice.ClientAddress1 := LQuery.FieldByName('client_address1').AsString;
    AData.Invoice.ClientAddress2 := LQuery.FieldByName('client_address2').AsString;
    AData.Invoice.Company := LQuery.FieldByName('company').AsString;
    AData.Invoice.CompanyAddress1 := LQuery.FieldByName('company_address1').AsString;
    AData.Invoice.CompanyAddress2 := LQuery.FieldByName('company_address2').AsString;
    AData.Invoice.CompanyNo := LQuery.FieldByName('company_no').AsString;
    AData.Invoice.LogoPath := LQuery.FieldByName('logo_path').AsString;
    AData.Invoice.BillingPeriodStart := ISO8601ToDate(LQuery.FieldByName('billing_period_start').AsString);
    AData.Invoice.BillingPeriodEnd := ISO8601ToDate(LQuery.FieldByName('billing_period_end').AsString);
    AData.Invoice.HoursWorked := LQuery.FieldByName('hours_worked').AsFloat;
    AData.Invoice.HourlyRate := LQuery.FieldByName('hourly_rate').AsFloat;
    AData.Invoice.Expenses := LQuery.FieldByName('expenses').AsFloat;
    AData.Invoice.Currency := LQuery.FieldByName('currency').AsString;
    AData.Invoice.Status := LQuery.FieldByName('status').AsString;
    AData.Invoice.Bank := LQuery.FieldByName('bank').AsString;
    AData.Invoice.BankDetails1 := LQuery.FieldByName('bank_details1').AsString;
    AData.Invoice.BankDetails2 := LQuery.FieldByName('bank_details2').AsString;
    ADetail := 'Loaded local invoice.tpl using an in-memory SQLite seed.';
    Result := True;
  except
    on E: Exception do
      ADetail := 'SQLite sample unavailable, using static invoice seed. ' + E.Message;
  end;
  LQuery.Free;
  LConnection.Free;
end;

procedure TFormTemplateEnginePlayground.ConfigureDwsBridgeForContext;
begin
  if (FDwsEnableBridgeCheck = nil) or (not FDwsEnableBridgeCheck.Checked) then
  begin
    if FDwsBridge <> nil then
      FDwsBridge.SetDiagnostics(nil);
    FDwsDiagnostics := nil;
    FDwsDiagnosticsRecorder := nil;
    if FDwsDiagnosticsMemo <> nil then
      FDwsDiagnosticsMemo.Lines.Text := 'DWScript bridge is disabled. Open the DWScript tab and load a scenario to enable it.';
    exit;
  end;

  if FDwsBridge = nil then
  begin
    FDwsBridge := CreateSempareDwsBridge(DwsBridgeOptionsFromUi);
    FDwsBridge.SetHostServices(CreateDefaultDwsHostServices);
  end
  else
  begin
    FDwsBridge.SetOptions(DwsBridgeOptionsFromUi);
    FDwsBridge.SetHostServices(CreateDefaultDwsHostServices);
    FDwsBridge.SetDiagnostics(nil);
  end;

  FDwsDiagnostics := nil;
  FDwsDiagnosticsRecorder := nil;
  FDwsDiagnosticsRecorder := TTemplateDwsDiagnosticsRecorder.Create;
  FDwsDiagnostics := FDwsDiagnosticsRecorder;
  FDwsBridge.SetDiagnostics(FDwsDiagnostics);

  SyncDwsBridgeScripts;
  FContext.SetTemplate('badge', Template.Parse(FContext, FBadgeTemplateSource));
  FDwsBridge.RegisterInto(FContext);
end;

procedure TFormTemplateEnginePlayground.CreateDwsBridgeUi;
var
  LTopPanel: TPanel;
  LScenarioLabel: TLabel;
  LAssetLabel: TLabel;
begin
  FDwsTab := TTabSheet.Create(pcTemplate);
  FDwsTab.PageControl := pcTemplate;
  FDwsTab.Caption := 'DWScript';

  LTopPanel := TPanel.Create(FDwsTab);
  LTopPanel.Parent := FDwsTab;
  LTopPanel.Align := alTop;
  LTopPanel.Height := 126;
  LTopPanel.BevelOuter := bvNone;
  LTopPanel.Caption := '';

  LScenarioLabel := TLabel.Create(LTopPanel);
  LScenarioLabel.Parent := LTopPanel;
  LScenarioLabel.Left := 8;
  LScenarioLabel.Top := 10;
  LScenarioLabel.Width := 360;
  LScenarioLabel.AutoSize := False;
  LScenarioLabel.WordWrap := True;
  LScenarioLabel.Caption := 'Use the shared Load Example list above to switch DWScript demos for this tab.';

  FDwsScenarioCombo := TComboBox.Create(LTopPanel);
  FDwsScenarioCombo.Parent := LTopPanel;
  FDwsScenarioCombo.Visible := False;
  FDwsScenarioCombo.Enabled := False;
  FDwsScenarioCombo.Style := csDropDownList;
  FDwsScenarioCombo.Items.Add('DwsCall - explicit entry');
  FDwsScenarioCombo.Items.Add('DwsRender - host resolve');
  FDwsScenarioCombo.Items.Add('DwsRaw - trusted output');
  FDwsScenarioCombo.Items.Add('DwsInline - inline source');
  FDwsScenarioCombo.Items.Add('Dws - SQLite invoice root');
  FDwsScenarioCombo.ItemIndex := 0;
  FDwsScenarioCombo.OnChange := DwsScenarioChange;

  FDwsLoadScenarioButton := TButton.Create(LTopPanel);
  FDwsLoadScenarioButton.Parent := LTopPanel;
  FDwsLoadScenarioButton.Visible := False;
  FDwsLoadScenarioButton.Enabled := False;
  FDwsLoadScenarioButton.Caption := 'Load Demo';
  FDwsLoadScenarioButton.OnClick := DwsLoadScenarioClick;

  LAssetLabel := TLabel.Create(LTopPanel);
  LAssetLabel.Parent := LTopPanel;
  LAssetLabel.Left := 8;
  LAssetLabel.Top := 48;
  LAssetLabel.Caption := 'Asset';

  FDwsAssetCombo := TComboBox.Create(LTopPanel);
  FDwsAssetCombo.Parent := LTopPanel;
  FDwsAssetCombo.Left := 64;
  FDwsAssetCombo.Top := 44;
  FDwsAssetCombo.Width := 194;
  FDwsAssetCombo.Style := csDropDownList;
  FDwsAssetCombo.OnChange := DwsAssetChange;

  FDwsPassRootCheck := TCheckBox.Create(LTopPanel);
  FDwsPassRootCheck.Parent := LTopPanel;
  FDwsPassRootCheck.Left := 266;
  FDwsPassRootCheck.Top := 46;
  FDwsPassRootCheck.Caption := 'Pass root data';
  FDwsPassRootCheck.OnClick := DwsOptionsClick;

  FDwsTrustedTextCheck := TCheckBox.Create(LTopPanel);
  FDwsTrustedTextCheck.Parent := LTopPanel;
  FDwsTrustedTextCheck.Left := 266;
  FDwsTrustedTextCheck.Top := 68;
  FDwsTrustedTextCheck.Caption := 'Allow trusted raw';
  FDwsTrustedTextCheck.OnClick := DwsOptionsClick;

  FDwsJsonLikeCheck := TCheckBox.Create(LTopPanel);
  FDwsJsonLikeCheck.Parent := LTopPanel;
  FDwsJsonLikeCheck.Left := 266;
  FDwsJsonLikeCheck.Top := 90;
  FDwsJsonLikeCheck.Caption := 'JSON-like return';
  FDwsJsonLikeCheck.OnClick := DwsOptionsClick;

  FDwsEnableBridgeCheck := TCheckBox.Create(LTopPanel);
  FDwsEnableBridgeCheck.Parent := LTopPanel;
  FDwsEnableBridgeCheck.Left := 392;
  FDwsEnableBridgeCheck.Top := 18;
  FDwsEnableBridgeCheck.Caption := 'Enable bridge';
  FDwsEnableBridgeCheck.OnClick := DwsOptionsClick;

  FDwsCacheCheck := TCheckBox.Create(LTopPanel);
  FDwsCacheCheck.Parent := LTopPanel;
  FDwsCacheCheck.Left := 392;
  FDwsCacheCheck.Top := 42;
  FDwsCacheCheck.Caption := 'Cache compiled';
  FDwsCacheCheck.Checked := true;
  FDwsCacheCheck.OnClick := DwsOptionsClick;

  FDwsInlineCheck := TCheckBox.Create(LTopPanel);
  FDwsInlineCheck.Parent := LTopPanel;
  FDwsInlineCheck.Left := 392;
  FDwsInlineCheck.Top := 66;
  FDwsInlineCheck.Caption := 'Allow inline';
  FDwsInlineCheck.OnClick := DwsOptionsClick;

  FDwsStatusLabel := TLabel.Create(LTopPanel);
  FDwsStatusLabel.Parent := LTopPanel;
  FDwsStatusLabel.Left := 8;
  FDwsStatusLabel.Top := 102;
  FDwsStatusLabel.Width := 520;
  FDwsStatusLabel.AutoSize := false;
  FDwsStatusLabel.WordWrap := true;
  FDwsStatusLabel.Caption := 'Use the shared example selector above, edit the selected asset, and Evaluate to exercise the bridge.';

  FDwsScriptMemo := TMemo.Create(FDwsTab);
  FDwsScriptMemo.Parent := FDwsTab;
  FDwsScriptMemo.Align := alClient;
  FDwsScriptMemo.ScrollBars := ssBoth;
  FDwsScriptMemo.WantTabs := true;
  FDwsScriptMemo.OnChange := DwsScriptMemoChange;

  FDwsDiagnosticsTab := TTabSheet.Create(pcOutput);
  FDwsDiagnosticsTab.PageControl := pcOutput;
  FDwsDiagnosticsTab.Caption := 'Bridge Diagnostics';

  FDwsDiagnosticsMemo := TMemo.Create(FDwsDiagnosticsTab);
  FDwsDiagnosticsMemo.Parent := FDwsDiagnosticsTab;
  FDwsDiagnosticsMemo.Align := alClient;
  FDwsDiagnosticsMemo.ReadOnly := true;
  FDwsDiagnosticsMemo.ScrollBars := ssBoth;
  FDwsDiagnosticsMemo.Lines.Text := 'DWScript bridge is disabled. Load a scenario to start collecting diagnostics.';
end;

procedure TFormTemplateEnginePlayground.DwsAssetChange(Sender: TObject);
begin
  LoadSelectedDwsAsset;
end;

function TFormTemplateEnginePlayground.DwsBridgeOptionsFromUi: TTemplateDwsBridgeOptions;
begin
  Result := [tdboDisallowContextMutation];
  if (FDwsCacheCheck <> nil) and FDwsCacheCheck.Checked then
    Include(Result, tdboCacheCompiledScripts);
  if (FDwsPassRootCheck <> nil) and FDwsPassRootCheck.Checked then
    Include(Result, tdboPassRootData);
  if (FDwsInlineCheck <> nil) and FDwsInlineCheck.Checked then
    Include(Result, tdboAllowInlineScripts);
  if (FDwsTrustedTextCheck <> nil) and FDwsTrustedTextCheck.Checked then
    Include(Result, tdboAllowTrustedText);
  if (FDwsJsonLikeCheck <> nil) and FDwsJsonLikeCheck.Checked then
    Include(Result, tdboExpectJsonLikeReturn);
end;

procedure TFormTemplateEnginePlayground.DwsLoadScenarioClick(Sender: TObject);
begin
  LoadDwsScenario(FDwsScenarioCombo.ItemIndex);
end;

procedure TFormTemplateEnginePlayground.DwsOptionsClick(Sender: TObject);
begin
  SetDwsStatus('Bridge options: ' + TemplateDwsOptionsToString(DwsBridgeOptionsFromUi));
  if cbAutoEvaluate.Checked then
    Eval;
end;

procedure TFormTemplateEnginePlayground.DwsScenarioChange(Sender: TObject);
const
  CDescriptions: array [0 .. 4] of string = (
    'Use DwsCall with an explicit entry name and payload map.',
    'Use DwsRender with a named script that resolves a Sempare host template.',
    'Use DwsRaw in an explicit trusted-output path.',
    'Use DwsInline to execute temporary inline DWScript source.',
    'Use Dws() with an explicit Invoice payload plus tdboExpectJsonLikeReturn over SQLite-seeded invoice data.'
  );
begin
  if (FDwsScenarioCombo.ItemIndex >= Low(CDescriptions)) and (FDwsScenarioCombo.ItemIndex <= High(CDescriptions)) then
    SetDwsStatus(CDescriptions[FDwsScenarioCombo.ItemIndex]);
end;

procedure TFormTemplateEnginePlayground.DwsScriptMemoChange(Sender: TObject);
begin
  SaveSelectedDwsAsset;
  if cbAutoEvaluate.Checked and (FDwsEnableBridgeCheck <> nil) and FDwsEnableBridgeCheck.Checked then
    Eval;
end;

procedure TFormTemplateEnginePlayground.FillDwsAssetCombo;
begin
  FDwsAssetCombo.Items.BeginUpdate;
  try
    FDwsAssetCombo.Items.Clear;
    FDwsAssetCombo.Items.Add(CDwsProfileScriptName);
    FDwsAssetCombo.Items.Add(CDwsCardScriptName);
    FDwsAssetCombo.Items.Add(CDwsMarkupScriptName);
    FDwsAssetCombo.Items.Add(CDwsInvoiceSummaryScriptName);
    FDwsAssetCombo.Items.Add(CDwsBadgeAssetName);
    if FDwsAssetCombo.ItemIndex < 0 then
      FDwsAssetCombo.ItemIndex := 0;
  finally
    FDwsAssetCombo.Items.EndUpdate;
  end;
end;

procedure TFormTemplateEnginePlayground.FormDestroy(Sender: TObject);
begin
  ResetDwsBridgeRegistration;
  if FDwsBridge <> nil then
    FDwsBridge.SetDiagnostics(nil);
  FDwsDiagnostics := nil;
  FDwsDiagnosticsRecorder := nil;
  TryDeleteFileQuietly(FPreviewHtmlFileName);
  FPreviewHtmlFileName := '';
  FExampleTemplatePaths.Free;
  FDwsScriptSources.Free;
  FDwsBridgeScripts.Free;
end;

function TFormTemplateEnginePlayground.IsDwsTemplateAsset(const AName: string): boolean;
begin
  Result := SameText(AName, CDwsBadgeAssetName);
end;

procedure TFormTemplateEnginePlayground.LoadDwsScenario(const AIndex: Integer);
begin
  ApplyDwsScenario(AIndex, True);
  Eval;
end;

procedure TFormTemplateEnginePlayground.LoadSelectedDwsAsset;
var
  LAssetName: string;
  LSource: string;
begin
  if FDwsUiUpdating or (FDwsAssetCombo = nil) or (FDwsScriptMemo = nil) then
    exit;

  LAssetName := FDwsAssetCombo.Text;

  FDwsUiUpdating := true;
  try
    if IsDwsTemplateAsset(LAssetName) then
      LSource := FBadgeTemplateSource
    else if not FDwsScriptSources.TryGetValue(LAssetName, LSource) then
      LSource := '';
    FDwsScriptMemo.Lines.Text := LSource;
  finally
    FDwsUiUpdating := false;
  end;
end;

procedure TFormTemplateEnginePlayground.RenderDwsDiagnostics;
var
  LLines: TStringList;
  LEvent: TTemplateDwsDiagnosticEvent;
  LScriptNames: TStringList;
  LName: string;
begin
  if FDwsDiagnosticsMemo = nil then
    exit;

  if (FDwsEnableBridgeCheck = nil) or not FDwsEnableBridgeCheck.Checked then
  begin
    FDwsDiagnosticsMemo.Lines.Text := 'DWScript bridge is disabled. Load a scenario to start collecting diagnostics.';
    exit;
  end;

  LLines := TStringList.Create;
  LScriptNames := TStringList.Create;
  try
    LLines.Add('Bridge options: ' + TemplateDwsOptionsToString(DwsBridgeOptionsFromUi));
    for LName in FDwsScriptSources.Keys do
      LScriptNames.Add(LName);
    LLines.Add('Registered scripts: ' + LScriptNames.CommaText);
    LLines.Add('Host template: badge');
    LLines.Add('');

    if (FDwsDiagnosticsRecorder = nil) or (FDwsDiagnosticsRecorder.Count = 0) then
      LLines.Add('No bridge events captured yet. Evaluate twice to observe cache hits.')
    else
      for LEvent in FDwsDiagnosticsRecorder.Events do
      begin
        LLines.Add(Format(
          '[%s/%s] script=%s entry=%s version=%s elapsedMs=%d detail=%s',
          [LEvent.Category, LEvent.Name, LEvent.ScriptName, LEvent.EntryName, LEvent.VersionTag, LEvent.ElapsedMs, LEvent.Detail]
        ));
      end;

    FDwsDiagnosticsMemo.Lines.Assign(LLines);
  finally
    LScriptNames.Free;
    LLines.Free;
  end;
end;

procedure TFormTemplateEnginePlayground.ResetDwsAssetsToDefaults;
begin
  FDwsScriptSources.Clear;
  FDwsScriptSources.AddOrSetValue(
    CDwsProfileScriptName,
    ReadTextOrFallback(TPath.Combine(ResolvePlaygroundDwsScriptsFolder, CDwsProfileScriptName + '.dws'), CDefaultProfileScript)
  );
  FDwsScriptSources.AddOrSetValue(
    CDwsCardScriptName,
    ReadTextOrFallback(TPath.Combine(ResolvePlaygroundDwsScriptsFolder, CDwsCardScriptName + '.dws'), CDefaultCardScript)
  );
  FDwsScriptSources.AddOrSetValue(
    CDwsMarkupScriptName,
    ReadTextOrFallback(TPath.Combine(ResolvePlaygroundDwsScriptsFolder, CDwsMarkupScriptName + '.dws'), CDefaultMarkupScript)
  );
  FDwsScriptSources.AddOrSetValue(
    CDwsInvoiceSummaryScriptName,
    ReadTextOrFallback(TPath.Combine(ResolvePlaygroundDwsScriptsFolder, CDwsInvoiceSummaryScriptName + '.dws'), CDefaultInvoiceSummaryScript)
  );
  FBadgeTemplateSource := ReadTextOrFallback(
    TPath.Combine(ResolvePlaygroundDwsTemplateFolder, CDwsBadgeTemplateFile),
    CDefaultBadgeTemplate
  );
  FillDwsAssetCombo;
  LoadSelectedDwsAsset;
end;

procedure TFormTemplateEnginePlayground.ResetDwsBridgeRegistration;
begin
  if (FDwsBridge <> nil) and (FContext <> nil) then
    FDwsBridge.UnregisterFrom(FContext);
end;

procedure TFormTemplateEnginePlayground.SaveSelectedDwsAsset;
var
  LAssetName: string;
  LTargetFile: string;
begin
  if FDwsUiUpdating or (FDwsAssetCombo = nil) or (FDwsScriptMemo = nil) then
    exit;

  LAssetName := FDwsAssetCombo.Text;
  if IsDwsTemplateAsset(LAssetName) then
  begin
    FBadgeTemplateSource := FDwsScriptMemo.Lines.Text;
    LTargetFile := TPath.Combine(ResolvePlaygroundDwsTemplateFolder, CDwsBadgeTemplateFile);
  end
  else
  begin
    FDwsScriptSources.AddOrSetValue(LAssetName, FDwsScriptMemo.Lines.Text);
    LTargetFile := TPath.Combine(ResolvePlaygroundDwsScriptsFolder, LAssetName + '.dws');
  end;

  ForceDirectories(TPath.GetDirectoryName(LTargetFile));
  TFile.WriteAllText(LTargetFile, FDwsScriptMemo.Lines.Text, TEncoding.UTF8);
end;

procedure TFormTemplateEnginePlayground.SetDwsStatus(const AText: string);
begin
  if FDwsStatusLabel <> nil then
    FDwsStatusLabel.Caption := AText;
end;

procedure TFormTemplateEnginePlayground.SetProperties(const APairs: array of string);
var
  LIdx: Integer;
  LRow: Integer;
begin
  ClearProperties;
  LRow := 1;
  LIdx := 0;
  while LIdx < Length(APairs) do
  begin
    if LRow >= properties.RowCount then
      break;
    properties.Cells[0, LRow] := APairs[LIdx];
    if LIdx + 1 < Length(APairs) then
      properties.Cells[1, LRow] := APairs[LIdx + 1]
    else
      properties.Cells[1, LRow] := '';
    Inc(LRow);
    Inc(LIdx, 2);
  end;
end;

procedure TFormTemplateEnginePlayground.SyncDwsBridgeScripts;
var
  LName: string;
  LSource: string;
  LExisting: string;
  LRemovals: TStringList;
begin
  if FDwsBridge = nil then
    exit;

  LRemovals := TStringList.Create;
  try
    for LName in FDwsBridgeScripts.Keys do
      if not FDwsScriptSources.ContainsKey(LName) then
        LRemovals.Add(LName);

    for LName in LRemovals do
      FDwsBridge.RemoveScript(LName);

    for LName in FDwsScriptSources.Keys do
    begin
      LSource := FDwsScriptSources[LName];
      if (not FDwsBridgeScripts.TryGetValue(LName, LExisting)) or (LExisting <> LSource) then
        FDwsBridge.AddScript(LName, LSource);
    end;

    FDwsBridgeScripts.Clear;
    for LName in FDwsScriptSources.Keys do
      FDwsBridgeScripts.AddOrSetValue(LName, FDwsScriptSources[LName]);
  finally
    LRemovals.Free;
  end;
end;

procedure TFormTemplateEnginePlayground.cbConvertTabsToSpacesClick(Sender: TObject);
begin
  SetOption(cbConvertTabsToSpaces.Checked, eoConvertTabsToSpaces);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbEvalEarlyClick(Sender: TObject);
begin
  SetOption(cbEvalEarly.Checked, eoEvalEarly);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbEvalVarsEarlyClick(Sender: TObject);
begin
  SetOption(cbEvalVarsEarly.Checked, eoEvalVarsEarly);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbFlattenTemplateClick(Sender: TObject);
begin
  SetOption(cbFlattenTemplate.Checked, eoFlattenTemplate);
  FForce := true;
  Eval;
end;

function DefaultEncoder(const AValue: string): string;
begin
  exit(AValue);
end;

procedure DebugLog(const AMessage: string);
begin
  OutputDebugString(PChar('[DEBUG] ' + AMessage));
end;

class function TFormTemplateEnginePlayground.BuildPreviewHtmlFileName: string;
var
  LGuid: TGuid;
begin
  CreateGUID(LGuid);
  Result := TPath.Combine(
    TPath.GetTempPath,
    'Sempare.Template.Playground.' +
    StringReplace(
      StringReplace(
        StringReplace(GUIDToString(LGuid), '{', '', [rfReplaceAll]),
        '}',
        '',
        [rfReplaceAll]
      ),
      '-',
      '',
      [rfReplaceAll]
    ) +
    '.htm'
  );
end;

class procedure TFormTemplateEnginePlayground.TryDeleteFileQuietly(const AFileName: string);
begin
  if (AFileName = '') or not TFile.Exists(AFileName) then
    Exit;
  try
    TFile.Delete(AFileName);
  except
    on E: Exception do
      DebugLog('Could not delete preview file "' + AFileName + '": ' + E.Message);
  end;
end;

class function TFormTemplateEnginePlayground.WritePreviewHtmlSnapshot(
  const AContent: string;
  const AEncoding: TEncoding;
  const APreferredFileName: string
): string;
var
  LAttempt: Integer;
  LFileName: string;
begin
  Result := '';
  LFileName := APreferredFileName;
  for LAttempt := 1 to CMaxPreviewHtmlWriteAttempts do
  begin
    if LFileName = '' then
      LFileName := BuildPreviewHtmlFileName;
    try
      TFile.WriteAllText(LFileName, AContent, AEncoding);
      Exit(LFileName);
    except
      on E: Exception do
      begin
        DebugLog(
          Format(
            'Preview HTML write attempt %d failed for "%s": %s',
            [LAttempt, LFileName, E.Message]
          )
        );
        TryDeleteFileQuietly(LFileName);
        LFileName := '';
        if LAttempt = CMaxPreviewHtmlWriteAttempts then
          raise;
      end;
    end;
  end;
end;

procedure TFormTemplateEnginePlayground.cbHtmlClick(Sender: TObject);
begin
  if cbHtml.Checked then
    FContext.UseHtmlVariableEncoder
  else
    FContext.VariableEncoder := DefaultEncoder;
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbOptimiseTemplateClick(Sender: TObject);
begin
  SetOption(cbOptimiseTemplate.Checked, eoOptimiseTemplate);
  if cbOptimiseTemplate.Checked then
    cbFlattenTemplate.Checked := true;
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbRaiseErrorWhenVariableNotFoundClick(Sender: TObject);
begin
  SetOption(cbRaiseErrorWhenVariableNotFound.Checked, eoRaiseErrorWhenVariableNotFound);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbStripRecurringNewlinesClick(Sender: TObject);
begin
  SetOption(cbStripRecurringNewlines.Checked, eoStripRecurringNewlines);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbStripRecurringSpacesClick(Sender: TObject);
begin
  SetOption(cbStripRecurringSpaces.Checked, eoStripRecurringSpaces);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbTrimLinesClick(Sender: TObject);
begin
  SetOption(cbTrimLines.Checked, eoTrimLines);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbUseCustomScriptTagsClick(Sender: TObject);
begin
  if cbUseCustomScriptTags.Checked then
    SetScriptTags(cmbCustomScriptTags.ItemIndex)
  else
    SetScriptTags(0);
end;

procedure TFormTemplateEnginePlayground.cbUseHtmlBRClick(Sender: TObject);
begin
  if cbUseHtmlBR.Checked then
    FContext.NewLine := '<br>'#13#10
  else
    FContext.NewLine := #13#10;
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cmbCustomScriptTagsChange(Sender: TObject);
begin
  cbUseCustomScriptTags.Checked := true;
  SetScriptTags(cmbCustomScriptTags.ItemIndex);
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.Eval;
var
  LActivePage: TTabSheet;
begin
  try
    EnsureDwsBridgeReadyForCurrentTemplate;

    if FFilename <> '' then
      butSave.Enabled := true;

    if FForce or (FLastContent <> memoTemplate.Lines.Text) then
    begin
      if (FDwsEnableBridgeCheck <> nil) and FDwsEnableBridgeCheck.Checked then
      begin
        ResetDwsBridgeRegistration;
        ConfigureDwsBridgeForContext;
      end;
      FTemplate := Template.Parse(FContext, memoTemplate.Lines.Text);
      FLastContent := memoTemplate.Lines.Text;
    end;

    Process;
    // this is a hack so that app does not throw an exception
    // during shutdown. it seems that the webbrowser must be visible
    // or else it does not shutdown properly
    LActivePage := pcOutput.ActivePage;
    pcOutput.ActivePage := tsWebBrowser;
    if not cbHtml.Checked then
      pcOutput.ActivePage := LActivePage;
  except
    on E: Exception do
      memoOutput.Lines.Text := E.Message;
  end;
end;

procedure TFormTemplateEnginePlayground.cbSetEncodingClick(Sender: TObject);
begin
  if cbSetEncoding.Checked then
  begin
    case cmbEncoding.ItemIndex of
      0:
        FEncoding := TEncoding.ASCII;
      1:
        FEncoding := TEncoding.UTF8;
    else
      FEncoding := TEncoding.UTF8WithoutBOM;
    end;
  end
  else
    FEncoding := TEncoding.UTF8WithoutBOM;
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.cbShowWhitespaceClick(Sender: TObject);
begin
  if cbShowWhitespace.Checked then
  begin
    if cbHtml.Checked then
      FContext.WhitespaceChar := '&bull;'
    else
      FContext.WhitespaceChar := #183
  end
  else
    FContext.WhitespaceChar := ' ';
  FForce := true;
  Eval;
end;

procedure TFormTemplateEnginePlayground.FormCreate(Sender: TObject);
begin
  Self.OnDestroy := FormDestroy;
  Self.OnResize := FormResize;
  lblTiming.Caption := '';
  FWaitCursor := TFDGUIxWaitCursor.Create(Self);
  FWaitCursor.Provider := 'Forms';
  DebugLog('Registered FireDAC VCL wait cursor for Playground.');
  FContext := Template.Context();
  FContext.Functions.AddFunctions(TPlaygroundWebReportingFunctions);
  FDwsScriptSources := TDictionary<string, string>.Create;
  FDwsBridgeScripts := TDictionary<string, string>.Create;
  FExampleTemplatePaths := TDictionary<string, string>.Create;
  FContext.Variable['name'] := 'world';
  properties.Cells[0, 1] := 'name';
  properties.Cells[1, 1] := 'world';
  FEncoding := TEncoding.UTF8WithoutBOM;
  FTemplate := Template.Parse(FContext, '');
  properties.Cells[0, 0] := 'Variable';
  properties.Cells[1, 0] := 'Value';
  properties.ColWidths[1] := properties.Width - properties.ColWidths[0] - 25;
  memoOutput.Lines.Text := '';
  memoTemplate.Lines.Text := '';
  memoPrettyPrint.Lines.Text := '';
  WebBrowser1.Enabled := true;
  tsGithubHelp.TabVisible := false;
  wbHelp.Enabled := false; // Doesn't work on github at this stage
  // wbHelp.Navigate('https://github.com/sempare/sempare-delphi-template-engine#Introduction');
{$IF defined(RELEASE)}
  FContext.MaxRunTimeMs := 5000;
{$ENDIF}
  CreateExampleTemplateUi;
  CreateDwsBridgeUi;
  pcTemplate.OnChange := TemplateTabChange;
  BuildExampleTemplateCatalog;
  ResetDwsAssetsToDefaults;
  LayoutRuntimeUi;
  cbHtml.Checked := true;
  cbUseHtmlBR.Checked := true;
  cbFlattenTemplate.Checked := true;
  cbOptimiseTemplate.Checked := true;
  WebBrowser1.Enabled := true;
  pcTemplate.ActivePageIndex := 0;
  pcOutput.ActivePageIndex := 0;

  memoTemplate.Text := '<% template("local_template") %> Hello <% name %><br> <% end %> ' + #13#10 + //
    '  ' + #13#10 + //
    ' Welcome to the <i>Sempare Template Engine</i> <b><% SEMPARE_TEMPLATE_ENGINE_VERSION %></b> playground project. ' + #13#10 + //
    '  ' + #13#10 + //
    ' You can prototype and test templates here.<p> ' + #13#10 + //
    '  ' + #13#10 + //
    '  ' + #13#10 + //
    ' For HTML output, preview using the brower tab to the right.<p> ' + #13#10 + //
    '  ' + #13#10 + //
    '  ' + #13#10 + //
    ' Press the "Evaluate" button to process this template or enable the "auto evaluate" option to process on every keypress.<p> ' + #13#10 + //
    '  ' + #13#10 + //
    '  ' + #13#10 + //
    ' <% include("local_template") %> ' + #13#10 + //
    '  ' + #13#10 + //
    ' This project is available on <a href="https://github.com/sempare/sempare-delphi-template-engine">https://github.com/sempare/sempare-delphi-template-engine</a><p> ' + #13#10 + //
    '  ' + #13#10 + //
    ' <% include("local_template") %> ' + #13#10 + //
    '  ' + #13#10 + //
    '  ' + #13#10 + //
    ' Templates can work nicely on almost any Delphi construct.<p> ' + #13#10 + //
    '  ' + #13#10 + //
    '  You can have loops:<br> ' + #13#10 + //
    '  ' + #13#10 + //

    ' <% for i := 1 to 10 %> ' + #13#10 + //
    '    <% i %><br> ' + #13#10 + //
    ' <% end %> ' + #13#10 + //
    '  <p>' + #13#10 + //
    '  You can define local variables and have conditional blocks:<br> ' + #13#10 + //
    '  ' + #13#10 + //

    ' <% val := 42 %> <-- try change this ' + #13#10 + //
    ' <% if val = 42 %> ' + #13#10 + //
    '    the value is 42 ' + #13#10 + //
    ' <% else %> ' + #13#10 + //
    ' the value is <b><% val %></b>! ' + #13#10 + //
    ' <% end %> ' + #13#10 + //
    '  <p>' + #13#10 + //
    ' Review the documentation and tests to explore all the features. ' + #13#10 + //
    ' <p> ' + #13#10 + //
    ' Otherwise, please raise an issue on github or email <a href="mailto:support@sempare.ltd">support@sempare.ltd</a> for support. ' + #13#10 + //
    '  ' + #13#10 + //
    ' If you like this project, please consider supporting enhancements via a commercial license which also entitles you to priority support.<p> ' + #13#10;

  FInit := true;
  TemplateTabChange(nil);
  SetExampleStatus('Choose a Playground template from the shared example list above.');
end;

procedure TFormTemplateEnginePlayground.GridPropsToContext;
var
  LIdx: Integer;
  LKey, LValue: string;
begin
  FContext.Variables.Clear;
  for LIdx := 1 to properties.RowCount do
  begin
    LKey := trim(properties.Cells[0, LIdx]);
    if LKey = '' then
      continue;
    LValue := trim(properties.Cells[1, LIdx]);
    FContext.Variables[LKey] := LValue;
  end;
end;

procedure TFormTemplateEnginePlayground.memoTemplateChange(Sender: TObject);
begin
  if FExampleUiUpdating or FDwsUiUpdating then
    Exit;
  if not cbAutoEvaluate.Checked then
    Exit;
  butEvalClick(Sender);
end;

function GetRowCol(const AMemo: TMemo): string;
begin
  exit(format('(Line: %d, Position: %d)   ', [AMemo.CaretPos.Y + 1, AMemo.CaretPos.X + 1]));
end;

procedure TFormTemplateEnginePlayground.memoTemplateKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  lblPosition.Caption := GetRowCol(memoTemplate);
end;

procedure TFormTemplateEnginePlayground.memoTemplateMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  lblPosition.Caption := GetRowCol(memoTemplate);
end;

procedure TFormTemplateEnginePlayground.OnException(Sender: TObject; E: Exception);
begin
end;

function FormatTimeMS(const ANS: int64): string;
const
  NSPerMs = 1000000;
begin
  exit(format('%.3fms', [ANS / NSPerMs]));
end;

procedure TFormTemplateEnginePlayground.Process;
var
  LPrettyOk: boolean;
  LStart: int64;
  LStr: string;
  function GetNanoSeconds: int64;
  var
    LEnd: int64;
  begin
    QueryPerformanceCounter(LEnd);
    exit(trunc(((LEnd - LStart) * 1000000000.0) / GFreq));
  end;

begin
  if not FInit then
    exit;
  ResetDwsBridgeRegistration;
  GridPropsToContext;
  LPrettyOk := false;
  try
    ConfigureDwsBridgeForContext;
    memoPrettyPrint.Lines.Text := Sempare.Template.Template.PrettyPrint(FTemplate);
    LPrettyOk := true;
    QueryPerformanceCounter(LStart);

    if FExampleRootData.IsEmpty then
      LStr := Template.Eval(FContext, FTemplate)
    else
      LStr := Template.Eval<TValue>(FContext, FTemplate, FExampleRootData);

    lblTiming.Caption := format('Evaluation %s', [FormatTimeMS(GetNanoSeconds())]);
    memoOutput.Lines.Text := LStr;
  except
    on E: Exception do
    begin
      memoOutput.Lines.Text := E.Message;
      if not LPrettyOk then
        memoPrettyPrint.Lines.Text := '';
    end;
  end;
  RenderDwsDiagnostics;
  WriteTmpHtml;
end;

procedure TFormTemplateEnginePlayground.propertiesGetEditText(Sender: TObject; ACol, ARow: Integer; var Value: string);
begin
  if cbAutoEvaluate.Checked then
    Eval;
end;

procedure TFormTemplateEnginePlayground.propertiesSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  if cbAutoEvaluate.Checked then
    Eval;
end;

procedure TFormTemplateEnginePlayground.SetOption(const AEnable: boolean; const AOption: TTemplateEvaluationOption);
begin
  if AEnable then
    FContext.Options := FContext.Options + [AOption]
  else
    FContext.Options := FContext.Options - [AOption];
  Eval;
end;

procedure TFormTemplateEnginePlayground.SetScriptTags(const AIdx: Integer);
begin
  case AIdx of
    1:
      begin
        FContext.StartToken := '{{';
        FContext.EndToken := '}}';
      end;
    2:
      begin
        FContext.StartToken := '<+';
        FContext.EndToken := '+>';
      end;
    3:
      begin
        FContext.StartToken := '{+';
        FContext.EndToken := '+}';
      end;
    4:
      begin
        FContext.StartToken := '{%';
        FContext.EndToken := '%}';
      end;
    5:
      begin
        FContext.StartToken := '<<';
        FContext.EndToken := '>>';
      end;
  else
    begin
      FContext.StartToken := '<%';
      FContext.EndToken := '%>';
    end;
  end;
end;

procedure TFormTemplateEnginePlayground.WriteTmpHtml;
var
  LPreviousFileName: string;
  LPreviewFileName: string;
  url: string;
begin
  if not WebBrowser1.Enabled or WebBrowser1.Busy then
    exit;
  LPreviousFileName := FPreviewHtmlFileName;
  LPreviewFileName := '';
  try
    LPreviewFileName := WritePreviewHtmlSnapshot(memoOutput.Lines.Text, FEncoding);
    FPreviewHtmlFileName := LPreviewFileName;
    url := 'file://' + ExpandUNCFileName(LPreviewFileName).Replace('\', '/', [rfReplaceAll]);
    WebBrowser1.Navigate(url);
    DebugLog('Wrote preview HTML to "' + LPreviewFileName + '".');
    TryDeleteFileQuietly(LPreviousFileName);
  except
    on E: Exception do
    begin
      DebugLog('Preview HTML write failed: ' + E.Message);
      TryDeleteFileQuietly(LPreviewFileName);
      FPreviewHtmlFileName := LPreviousFileName;
    end;
  end;
end;

initialization

QueryPerformanceFrequency(GFreq);

end.














