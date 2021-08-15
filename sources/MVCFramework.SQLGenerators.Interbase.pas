// *************************************************************************** }
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2021 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit MVCFramework.SQLGenerators.Interbase;

interface

uses
  System.Rtti,
  System.Generics.Collections,
  FireDAC.Phys.IB,
  FireDAC.Phys.IBDef,
  MVCFramework.ActiveRecord,
  MVCFramework.Commons,
  MVCFramework.SQLGenerators.Firebird,
  MVCFramework.RQL.Parser;

type
  TMVCSQLGeneratorInterbase = class(TMVCSQLGeneratorFirebird)
  public
    function CreateInsertSQL(const TableName: string;
      const Map: TFieldsMap;
      const PKFieldName: string;
      const PKOptions: TMVCActiveRecordFieldOptions): string; override;
    function HasReturning: Boolean; override;
  end;

implementation

uses
  System.SysUtils;

{ TMVCSQLGeneratorInterbase }

function TMVCSQLGeneratorInterbase.CreateInsertSQL(const TableName: string;
  const Map: TFieldsMap;
  const PKFieldName: string;
  const PKOptions: TMVCActiveRecordFieldOptions): string;
var
  lKeyValue: TPair<TRttiField, TFieldInfo>;
  lSB: TStringBuilder;
  lPKInInsert: Boolean;
begin
  lPKInInsert := (not PKFieldName.IsEmpty); // and (not(TMVCActiveRecordFieldOption.foAutoGenerated in PKOptions));
  lPKInInsert := lPKInInsert and (not(TMVCActiveRecordFieldOption.foReadOnly in PKOptions));
  lSB := TStringBuilder.Create;
  try
    lSB.Append('INSERT INTO ' + TableName + '(');
    if lPKInInsert then
    begin
      lSB.Append(PKFieldName + ',');
    end;
    for lKeyValue in Map do
    begin
      if lKeyValue.Value.Writeable then
      begin
        lSB.Append(lKeyValue.Value.FieldName + ',');
      end;
    end;

    lSB.Remove(lSB.Length - 1, 1);
    lSB.Append(') values (');
    if lPKInInsert then
    begin
      lSB.Append(':' + PKFieldName + ',');
    end;
    for lKeyValue in Map do
    begin
      if lKeyValue.Value.Writeable then
      begin
        lSB.Append(':' + lKeyValue.Value.FieldName + ',');
      end;
    end;

    lSB.Remove(lSB.Length - 1, 1);
    lSB.Append(')');
    Result := lSB.ToString;
  finally
    lSB.Free;
  end;
end;

function TMVCSQLGeneratorInterbase.HasReturning: Boolean;
begin
  Result := False;
end;

initialization

TMVCSQLGeneratorRegistry.Instance.RegisterSQLGenerator('interbase',
  TMVCSQLGeneratorInterbase);

finalization

TMVCSQLGeneratorRegistry.Instance.UnRegisterSQLGenerator('interbase');

end.
