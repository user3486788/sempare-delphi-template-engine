program DwsBridgeAdvanced;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  {$IFDEF EurekaLog}
  EMemLeaks,
  EResLeaks,
  EDebugJCL,
  EDebugExports,
  EFixSafeCallException,
  EMapWin32,
  EAppConsole,
  EDialogConsole,
  ExceptionLog7,
  {$ENDIF EurekaLog}
  System.SysUtils,
  Sempare.Template.DwsBridgeAdvanced.SakilaDemo,
  Sempare.Template.DwsBridgeAdvanced.Scenarios;

procedure RunChinook;
var
  LReport: TChinookDwsDemoReport;
begin
  LReport := TChinookDwsDemo.Run;
  LReport.SaveHtmlReport;
  Writeln('HTML report written to: ' + LReport.HtmlFileName);
  Writeln;
  Writeln(LReport.RenderConsoleText);
end;

procedure RunSakila;
var
  LReport: TSakilaDwsDemoReport;
begin
  LReport := TSakilaDwsDemo.Run;
  LReport.SaveHtmlReport;
  Writeln('HTML report written to: ' + LReport.HtmlFileName);
  Writeln;
  Writeln(LReport.RenderConsoleText);
end;

var
  LMode: string;

begin
  try
    if ParamCount > 0 then
      LMode := Trim(LowerCase(ParamStr(1)))
    else
      LMode := 'sakila';

    if SameText(LMode, 'chinook') then
      RunChinook
    else
    if SameText(LMode, 'sakila') then
      RunSakila
    else
      raise Exception.Create('Unknown demo mode. Use chinook or sakila.');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.

