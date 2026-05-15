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
unit Sempare.Template.DWS.Provider;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Types;

/// <summary>
/// Creates a writable in-memory registry for named DWScript sources.
/// </summary>
/// <returns>
/// A registry that supports add, replace, remove, and clear operations.
/// </returns>
function CreateInMemoryDwsScriptRegistry: ITemplateDwsScriptRegistry;

/// <summary>
/// Creates a file-backed provider for named DWScript scripts.
/// </summary>
/// <param name="ARootFolder">Root folder that contains the `.dws` files.</param>
/// <param name="AExtension">Optional script extension. Defaults to `.dws`.</param>
/// <returns>A read-only provider that resolves script names relative to the configured root.</returns>
function CreateFileSystemDwsScriptProvider(const ARootFolder: string; const AExtension: string = '.dws'): ITemplateDwsScriptProvider;

/// <summary>
/// Creates a provider chain that resolves scripts from the first provider that can supply them.
/// </summary>
/// <param name="AProviders">Provider order defines fallback order.</param>
/// <returns>A composite named-script provider.</returns>
function CreateCompositeDwsScriptProvider(const AProviders: array of ITemplateDwsScriptProvider): ITemplateDwsScriptProvider;

/// <summary>
/// Creates a provider backed by a bundled set of scripts and a bundle version prefix.
/// </summary>
/// <param name="ABundleVersion">Optional bundle version prefix used in effective version tags.</param>
/// <param name="AScripts">Named scripts included in the bundle.</param>
/// <returns>A read-only provider for packaged bridge scripts.</returns>
function CreateBundledDwsScriptProvider(
  const ABundleVersion: string;
  const AScripts: array of TTemplateDwsScriptDefinition
): ITemplateDwsScriptProvider;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  System.IOUtils,
  System.Generics.Collections,
{$IFDEF SUPPORT_HASH}
  System.Hash;
{$ENDIF}

type
  TTemplateDwsStoredScript = record
    Source: string;
    VersionTag: string;
    Revision: int64;
  end;

  TInMemoryDwsScriptRegistry = class(TInterfacedObject, ITemplateDwsScriptRegistry)
  private
    FLock: TMultiReadExclusiveWriteSynchronizer;
    FScripts: TDictionary<string, TTemplateDwsStoredScript>;
    FRevisionSeed: int64;
    function NextVersionTag(var AState: TTemplateDwsStoredScript; const AName: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddOrSet(const AName, ASource: string);
    procedure Remove(const AName: string);
    procedure Clear;
    function TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
    function Exists(const AName: string): boolean;
    function VersionTag(const AName: string): string;
  end;

  TFileSystemDwsScriptProvider = class(TInterfacedObject, ITemplateDwsScriptProvider)
  private
    FRootFolder: string;
    FRootFolderWithDelimiter: string;
    FExtension: string;
    function ResolveFileName(const AName: string): string;
    function TryLoadScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
  public
    constructor Create(const ARootFolder: string; const AExtension: string);
    function TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
    function Exists(const AName: string): boolean;
    function VersionTag(const AName: string): string;
  end;

  TCompositeDwsScriptProvider = class(TInterfacedObject, ITemplateDwsScriptProvider)
  private
    FProviders: TArray<ITemplateDwsScriptProvider>;
  public
    constructor Create(const AProviders: array of ITemplateDwsScriptProvider);
    function TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
    function Exists(const AName: string): boolean;
    function VersionTag(const AName: string): string;
  end;

  TBundleDwsScriptProvider = class(TInterfacedObject, ITemplateDwsScriptProvider)
  private
    FLock: TMultiReadExclusiveWriteSynchronizer;
    FScripts: TDictionary<string, TTemplateDwsStoredScript>;
  public
    constructor Create(const ABundleVersion: string; const AScripts: array of TTemplateDwsScriptDefinition);
    destructor Destroy; override;
    function TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
    function Exists(const AName: string): boolean;
    function VersionTag(const AName: string): string;
  end;

function NormalizeScriptName(const AName: string): string;
begin
  result := LowerCase(Trim(AName));
end;

function MakeContentVersionTag(const AName, ASource: string; const APrefix: string = ''): string;
var
  LPrefix: string;
begin
  if APrefix <> '' then
    LPrefix := APrefix + ':'
  else
    LPrefix := '';

{$IFDEF SUPPORT_HASH}
  result := NormalizeScriptName(AName) + '@' + LPrefix + THashMD5.GetHashString(ASource);
{$ELSE}
  result := NormalizeScriptName(AName) + '@' + LPrefix + IntToHex(Length(ASource), 8);
{$ENDIF}
end;

function CreateBundledDwsScriptProvider(
  const ABundleVersion: string;
  const AScripts: array of TTemplateDwsScriptDefinition
): ITemplateDwsScriptProvider;
begin
  result := TBundleDwsScriptProvider.Create(ABundleVersion, AScripts);
end;

function CreateCompositeDwsScriptProvider(const AProviders: array of ITemplateDwsScriptProvider): ITemplateDwsScriptProvider;
begin
  result := TCompositeDwsScriptProvider.Create(AProviders);
end;

function CreateFileSystemDwsScriptProvider(const ARootFolder: string; const AExtension: string): ITemplateDwsScriptProvider;
begin
  result := TFileSystemDwsScriptProvider.Create(ARootFolder, AExtension);
end;

function CreateInMemoryDwsScriptRegistry: ITemplateDwsScriptRegistry;
begin
  result := TInMemoryDwsScriptRegistry.Create;
end;

constructor TBundleDwsScriptProvider.Create(const ABundleVersion: string; const AScripts: array of TTemplateDwsScriptDefinition);
var
  LScript: TTemplateDwsScriptDefinition;
  LKey: string;
  LStored: TTemplateDwsStoredScript;
  LVersionPrefix: string;
begin
  inherited Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
  FScripts := TDictionary<string, TTemplateDwsStoredScript>.Create;
  LVersionPrefix := Trim(ABundleVersion);

  for LScript in AScripts do
  begin
    if Trim(LScript.Name) = '' then
      raise ETemplateDwsContractError.CreateContext('Bundled DWScript script name must not be empty.', LScript.Name);

    LKey := NormalizeScriptName(LScript.Name);
    LStored.Source := LScript.Source;
    if LScript.VersionTag <> '' then
    begin
      if LVersionPrefix <> '' then
        LStored.VersionTag := LVersionPrefix + ':' + LScript.VersionTag
      else
        LStored.VersionTag := LScript.VersionTag;
    end
    else
      LStored.VersionTag := MakeContentVersionTag(LScript.Name, LScript.Source, LVersionPrefix);
    FScripts.AddOrSetValue(LKey, LStored);
  end;
end;

destructor TBundleDwsScriptProvider.Destroy;
begin
  FScripts.Free;
  FLock.Free;
  inherited;
end;

function TBundleDwsScriptProvider.Exists(const AName: string): boolean;
var
  LKey: string;
begin
  LKey := NormalizeScriptName(AName);
  FLock.BeginRead;
  try
    exit(FScripts.ContainsKey(LKey));
  finally
    FLock.EndRead;
  end;
end;

function TBundleDwsScriptProvider.TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
var
  LKey: string;
  LStored: TTemplateDwsStoredScript;
begin
  LKey := NormalizeScriptName(AName);
  FLock.BeginRead;
  try
    result := FScripts.TryGetValue(LKey, LStored);
    if result then
      AScript := TTemplateDwsScript.Create(AName, LStored.Source, LStored.VersionTag);
  finally
    FLock.EndRead;
  end;
end;

function TBundleDwsScriptProvider.VersionTag(const AName: string): string;
var
  LScript: TTemplateDwsScript;
begin
  if TryGetScript(AName, LScript) then
    exit(LScript.VersionTag);
  exit('');
end;

constructor TCompositeDwsScriptProvider.Create(const AProviders: array of ITemplateDwsScriptProvider);
var
  LIdx: integer;
begin
  inherited Create;
  SetLength(FProviders, Length(AProviders));
  for LIdx := 0 to High(AProviders) do
    FProviders[LIdx] := AProviders[LIdx];
end;

function TCompositeDwsScriptProvider.Exists(const AName: string): boolean;
var
  LProvider: ITemplateDwsScriptProvider;
begin
  for LProvider in FProviders do
    if (LProvider <> nil) and LProvider.Exists(AName) then
      exit(true);
  exit(false);
end;

function TCompositeDwsScriptProvider.TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
var
  LProvider: ITemplateDwsScriptProvider;
begin
  for LProvider in FProviders do
  begin
    if (LProvider <> nil) and LProvider.TryGetScript(AName, AScript) then
      exit(true);
  end;
  exit(false);
end;

function TCompositeDwsScriptProvider.VersionTag(const AName: string): string;
var
  LProvider: ITemplateDwsScriptProvider;
begin
  for LProvider in FProviders do
  begin
    if LProvider = nil then
      continue;
    result := LProvider.VersionTag(AName);
    if result <> '' then
      exit;
  end;
  exit('');
end;

constructor TFileSystemDwsScriptProvider.Create(const ARootFolder: string; const AExtension: string);
begin
  inherited Create;
  FRootFolder := TPath.GetFullPath(Trim(ARootFolder));
  if FRootFolder = '' then
    raise ETemplateDwsContractError.CreateContext('DWScript file provider root folder must not be empty.');
  FRootFolderWithDelimiter := IncludeTrailingPathDelimiter(FRootFolder);

  FExtension := Trim(AExtension);
  if FExtension = '' then
    FExtension := '.dws'
  else if not FExtension.StartsWith('.') then
    FExtension := '.' + FExtension;
end;

function TFileSystemDwsScriptProvider.Exists(const AName: string): boolean;
var
  LScript: TTemplateDwsScript;
begin
  result := TryLoadScript(AName, LScript);
end;

function TFileSystemDwsScriptProvider.ResolveFileName(const AName: string): string;
var
  LRelativeName: string;
  LFullPath: string;
begin
  LRelativeName := Trim(AName);
  if LRelativeName = '' then
    raise ETemplateDwsContractError.CreateContext('DWScript file provider script name must not be empty.', AName);

  LRelativeName := StringReplace(LRelativeName, '/', PathDelim, [rfReplaceAll]);
  LRelativeName := StringReplace(LRelativeName, '\', PathDelim, [rfReplaceAll]);
  if TPath.GetExtension(LRelativeName) = '' then
    LRelativeName := LRelativeName + FExtension;

  LFullPath := TPath.GetFullPath(TPath.Combine(FRootFolder, LRelativeName));
  if not SameText(Copy(LFullPath, 1, Length(FRootFolderWithDelimiter)), FRootFolderWithDelimiter) and
     not SameText(LFullPath, FRootFolder) then
    raise ETemplateDwsContractError.CreateContext('DWScript file provider path escapes the configured root.', AName);

  result := LFullPath;
end;

function TFileSystemDwsScriptProvider.TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
begin
  result := TryLoadScript(AName, AScript);
end;

function TFileSystemDwsScriptProvider.TryLoadScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
var
  LFileName: string;
  LSource: string;
begin
  LFileName := ResolveFileName(AName);
  if not TFile.Exists(LFileName) then
    exit(false);

  LSource := TFile.ReadAllText(LFileName, TEncoding.UTF8);
  AScript := TTemplateDwsScript.Create(AName, LSource, MakeContentVersionTag(AName, LSource));
  exit(true);
end;

function TFileSystemDwsScriptProvider.VersionTag(const AName: string): string;
var
  LScript: TTemplateDwsScript;
begin
  if TryGetScript(AName, LScript) then
    exit(LScript.VersionTag);
  exit('');
end;

procedure TInMemoryDwsScriptRegistry.AddOrSet(const AName, ASource: string);
var
  LKey: string;
  LState: TTemplateDwsStoredScript;
begin
  if Trim(AName) = '' then
    raise ETemplateDwsContractError.CreateContext('Script name must not be empty.', AName);

  LKey := NormalizeScriptName(AName);

  FLock.BeginWrite;
  try
    if FScripts.TryGetValue(LKey, LState) then
    begin
      if LState.Source = ASource then
        exit;
    end;
    LState.Source := ASource;
    LState.VersionTag := NextVersionTag(LState, AName);
    FScripts.AddOrSetValue(LKey, LState);
  finally
    FLock.EndWrite;
  end;
end;

procedure TInMemoryDwsScriptRegistry.Clear;
begin
  FLock.BeginWrite;
  try
    FScripts.Clear;
  finally
    FLock.EndWrite;
  end;
end;

constructor TInMemoryDwsScriptRegistry.Create;
begin
  inherited;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
  FScripts := TDictionary<string, TTemplateDwsStoredScript>.Create;
  FRevisionSeed := 0;
end;

destructor TInMemoryDwsScriptRegistry.Destroy;
begin
  FScripts.Free;
  FLock.Free;
  inherited;
end;

function TInMemoryDwsScriptRegistry.Exists(const AName: string): boolean;
var
  LKey: string;
begin
  LKey := NormalizeScriptName(AName);
  FLock.BeginRead;
  try
    exit(FScripts.ContainsKey(LKey));
  finally
    FLock.EndRead;
  end;
end;

function TInMemoryDwsScriptRegistry.NextVersionTag(var AState: TTemplateDwsStoredScript; const AName: string): string;
begin
  Inc(FRevisionSeed);
  AState.Revision := FRevisionSeed;
  result := NormalizeScriptName(AName) + '@' + IntToHex(AState.Revision, 8);
end;

procedure TInMemoryDwsScriptRegistry.Remove(const AName: string);
var
  LKey: string;
begin
  LKey := NormalizeScriptName(AName);
  FLock.BeginWrite;
  try
    FScripts.Remove(LKey);
  finally
    FLock.EndWrite;
  end;
end;

function TInMemoryDwsScriptRegistry.TryGetScript(const AName: string; out AScript: TTemplateDwsScript): boolean;
var
  LKey: string;
  LState: TTemplateDwsStoredScript;
begin
  LKey := NormalizeScriptName(AName);
  FLock.BeginRead;
  try
    result := FScripts.TryGetValue(LKey, LState);
    if result then
      AScript := TTemplateDwsScript.Create(AName, LState.Source, LState.VersionTag);
  finally
    FLock.EndRead;
  end;
end;

function TInMemoryDwsScriptRegistry.VersionTag(const AName: string): string;
var
  LScript: TTemplateDwsScript;
begin
  if TryGetScript(AName, LScript) then
    exit(LScript.VersionTag);
  exit('');
end;

end.

