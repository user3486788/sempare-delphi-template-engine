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
unit Sempare.Template.DWS.HostServices;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Types;

/// <summary>
/// Creates the default bridge host-services implementation exposed through the `SempareHost` DWScript unit.
/// </summary>
/// <param name="AMutationPolicy">Optional policy that decides which variable names may be changed through `SetVar`.</param>
/// <returns>A host-services adapter for template lookup, render, and variable access.</returns>
function CreateDefaultDwsHostServices(
  const AMutationPolicy: TTemplateDwsMutationPolicy = nil
): ITemplateDwsHostServices;

/// <summary>
/// Creates a mutation policy that allows writes only to the supplied variable names.
/// </summary>
/// <param name="AVariableNames">Case-insensitive allow-list of variable names.</param>
/// <returns>A predicate suitable for `CreateDefaultDwsHostServices`.</returns>
function CreateAllowListMutationPolicy(const AVariableNames: array of string): TTemplateDwsMutationPolicy;

implementation

uses
  System.Classes,
  System.Rtti,
  System.SysUtils,
  System.Generics.Collections,
  Sempare.Template,
  Sempare.Template.AST,
  Sempare.Template.Context;

type
  TDefaultDwsHostServices = class(TInterfacedObject, ITemplateDwsHostServices)
  private
    FMutationPolicy: TTemplateDwsMutationPolicy;
  public
    constructor Create(const AMutationPolicy: TTemplateDwsMutationPolicy);
    function TemplateExists(const ACtx: ITemplateContext; const ATemplateName: string): boolean;
    function ResolveTemplate(const ACtx: ITemplateContext; const ATemplateName: string; const AData: TValue): string;
    function TryGetVar(const ACtx: ITemplateContext; const AName: string; out AValue: TValue): boolean;
    procedure SetVar(const ACtx: ITemplateContext; const AName: string; const AValue: TValue);
  end;

function CreateDefaultDwsHostServices(const AMutationPolicy: TTemplateDwsMutationPolicy): ITemplateDwsHostServices;
begin
  result := TDefaultDwsHostServices.Create(AMutationPolicy);
end;

function CreateAllowListMutationPolicy(const AVariableNames: array of string): TTemplateDwsMutationPolicy;
var
  LNames: TArray<string>;
  LIdx: integer;
begin
  SetLength(LNames, Length(AVariableNames));
  for LIdx := 0 to High(AVariableNames) do
    LNames[LIdx] := Trim(AVariableNames[LIdx]);

  result :=
    function(const AName: string): boolean
    var
      LItem: string;
      LNormalizedName: string;
    begin
      LNormalizedName := Trim(AName);
      for LItem in LNames do
        if SameText(LItem, LNormalizedName) then
          exit(true);
      exit(false);
    end;
end;

constructor TDefaultDwsHostServices.Create(const AMutationPolicy: TTemplateDwsMutationPolicy);
begin
  inherited Create;
  FMutationPolicy := AMutationPolicy;
end;

function TDefaultDwsHostServices.ResolveTemplate(
  const ACtx: ITemplateContext;
  const ATemplateName: string;
  const AData: TValue
): string;
var
  LTemplate: ITemplate;
begin
  if ACtx = nil then
    raise ETemplateDwsContractError.CreateContext('Template context is required for DWScript host services.');
  if Trim(ATemplateName) = '' then
    raise ETemplateDwsContractError.CreateContext('DWScript host service template name must not be empty.');

  if not ACtx.TryGetTemplate(ATemplateName, LTemplate) then
    raise ETemplateDwsContractError.CreateContext('DWScript host service template not found: ' + ATemplateName + '.');

  if AData.IsEmpty then
    exit(Template.Eval(ACtx, LTemplate));
  exit(Template.EvalWithContext(ACtx, LTemplate, TValue.Empty, AData));
end;

procedure TDefaultDwsHostServices.SetVar(const ACtx: ITemplateContext; const AName: string; const AValue: TValue);
begin
  if ACtx = nil then
    raise ETemplateDwsContractError.CreateContext('Template context is required for DWScript host service mutation.');
  if Trim(AName) = '' then
    raise ETemplateDwsContractError.CreateContext('DWScript host service variable name must not be empty.');
  if (not Assigned(FMutationPolicy)) or (not FMutationPolicy(AName)) then
    raise ETemplateDwsContractError.CreateContext('DWScript host service mutation is not allowed for variable "' + AName + '".');

  ACtx.Variables[AName] := AValue;
end;

function TDefaultDwsHostServices.TemplateExists(const ACtx: ITemplateContext; const ATemplateName: string): boolean;
var
  LTemplate: ITemplate;
begin
  if ACtx = nil then
    exit(false);
  exit(ACtx.TryGetTemplate(ATemplateName, LTemplate));
end;

function TDefaultDwsHostServices.TryGetVar(const ACtx: ITemplateContext; const AName: string; out AValue: TValue): boolean;
begin
  if ACtx = nil then
    exit(false);
  exit(ACtx.TryGetVariable(AName, AValue));
end;

end.

