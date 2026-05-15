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
unit Sempare.Template.DWS.Cache;

interface

{$I 'Sempare.Template.Compiler.inc'}

uses
  Sempare.Template.DWS.Types;

/// <summary>
/// Creates the default in-memory compile cache used by the DWScript bridge.
/// </summary>
/// <returns>
/// A thread-safe cache keyed by normalized script name and version tag.
/// </returns>
function CreateDefaultDwsCompileCache: ITemplateDwsCompileCache;

implementation

uses
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections;

type
  TTemplateDwsCompileCache = class(TInterfacedObject, ITemplateDwsCompileCache)
  private
    FLock: TMultiReadExclusiveWriteSynchronizer;
    FItems: TDictionary<string, ITemplateDwsCompiledScript>;
    function NormalizeName(const AName: string): string;
    function MakeKey(const AName, AVersionTag: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function TryGet(const AName, AVersionTag: string; out ACompiled: ITemplateDwsCompiledScript): boolean;
    procedure Put(const AName, AVersionTag: string; const ACompiled: ITemplateDwsCompiledScript);
    procedure Invalidate(const AName: string);
    procedure Clear;
  end;

function CreateDefaultDwsCompileCache: ITemplateDwsCompileCache;
begin
  result := TTemplateDwsCompileCache.Create;
end;

procedure TTemplateDwsCompileCache.Clear;
begin
  FLock.BeginWrite;
  try
    FItems.Clear;
  finally
    FLock.EndWrite;
  end;
end;

constructor TTemplateDwsCompileCache.Create;
begin
  inherited;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
  FItems := TDictionary<string, ITemplateDwsCompiledScript>.Create;
end;

destructor TTemplateDwsCompileCache.Destroy;
begin
  FItems.Free;
  FLock.Free;
  inherited;
end;

procedure TTemplateDwsCompileCache.Invalidate(const AName: string);
var
  LKeys: TList<string>;
  LKey: string;
  LPrefix: string;
  LPair: TPair<string, ITemplateDwsCompiledScript>;
begin
  LPrefix := NormalizeName(AName) + #1;
  FLock.BeginWrite;
  try
    LKeys := TList<string>.Create;
    try
      for LPair in FItems do
        if Pos(LPrefix, LPair.Key) = 1 then
          LKeys.Add(LPair.Key);

      for LKey in LKeys do
        FItems.Remove(LKey);
    finally
      LKeys.Free;
    end;
  finally
    FLock.EndWrite;
  end;
end;

function TTemplateDwsCompileCache.MakeKey(const AName, AVersionTag: string): string;
begin
  result := NormalizeName(AName) + #1 + AVersionTag;
end;

function TTemplateDwsCompileCache.NormalizeName(const AName: string): string;
begin
  result := LowerCase(Trim(AName));
end;

procedure TTemplateDwsCompileCache.Put(const AName, AVersionTag: string; const ACompiled: ITemplateDwsCompiledScript);
begin
  FLock.BeginWrite;
  try
    FItems.AddOrSetValue(MakeKey(AName, AVersionTag), ACompiled);
  finally
    FLock.EndWrite;
  end;
end;

function TTemplateDwsCompileCache.TryGet(const AName, AVersionTag: string; out ACompiled: ITemplateDwsCompiledScript): boolean;
begin
  FLock.BeginRead;
  try
    exit(FItems.TryGetValue(MakeKey(AName, AVersionTag), ACompiled));
  finally
    FLock.EndRead;
  end;
end;

end.

