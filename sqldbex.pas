unit sqldbex;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, sqldb, odbcconn, odbcsqldyn;

type

  { TExODBCConnection }

  TExODBCConnection = class(TODBCConnection)
  protected
    FGetNext: Boolean;
    FNextStmt: SQLHStmt;
    procedure PrepareStatement(cursor:TSQLCursor; ATransaction:TSQLTransaction; buf:string; AParams:TParams); override;
    procedure UnPrepareStatement(cursor:TSQLCursor); override;
    procedure Execute(cursor:TSQLCursor; ATransaction:TSQLTransaction; AParams:TParams); override;
    procedure UpdateIndexDefs(IndexDefs: TIndexDefs; TableName: string); override;
  end;

  { TExSQLQuery }

  TExSQLQuery = class(TSQLQuery)
  private
    function OdbcNextResultSet: Boolean;
  public
    // Get next resultset if it is exists.
    // Return true if resultset has take, otherwise return false
    function NextResultSet: Boolean;
  end;

implementation
uses dynlibs;
type
  TODBCCursorCrack = class(TODBCCursor);

{ TExODBCConnection }

procedure TExODBCConnection.Execute(cursor: TSQLCursor;
  ATransaction: TSQLTransaction; AParams: TParams);
begin
  if FGetNext then
  begin
    TODBCCursorCrack(cursor).FSTMTHandle := Self.FNextStmt;
    cursor.FSelectable:= True;
  end
  else
    inherited;
end;

procedure TExODBCConnection.PrepareStatement(cursor: TSQLCursor;
  ATransaction: TSQLTransaction; buf: string; AParams: TParams);
begin
  if FGetNext then
  begin
    cursor.FPrepared:= True;
  end
  else
    inherited;
end;

procedure TExODBCConnection.UnPrepareStatement(cursor: TSQLCursor);
begin
  if FGetNext then
    cursor.FPrepared := False
  else
    inherited;
end;

procedure TExODBCConnection.UpdateIndexDefs(IndexDefs: TIndexDefs;
  TableName: string);
begin
  if not FGetNext then
    inherited UpdateIndexDefs(IndexDefs, TableName);
end;

{ TExSQLQuery }

function TExSQLQuery.NextResultSet: Boolean;
begin
  if Self.DataBase is TExODBCConnection then
  begin
    Result := OdbcNextResultSet;
  end
  else
    DatabaseError('Not support multiple result sets', Self);
end;

type
  TSQLMoreResults = function(
    HStmt: SQLHStmt
  ): SQLRETURN; {$IFDEF Windows}stdcall{$ELSE} cdecl {$ENDIF};
var
  SQLMoreResults: TSQLMoreResults;

procedure LoadFunc;
begin
  if SQLMoreResults = nil then
    pointer(SQLMoreResults) := GetProcedureAddress(ODBCLibraryHandle,'SQLMoreResults');
end;

function ODBCSuccess(const Res:SQLRETURN):boolean;
begin
  Result:=(Res=SQL_SUCCESS) or (Res=SQL_SUCCESS_WITH_INFO);
end;

procedure OdbcCheck(res: SQLRETURN);
begin
  if ODBCSuccess(Res) then Exit;
  DatabaseError('odbc error code: ' + IntToStr(res));
end;

function TExSQLQuery.OdbcNextResultSet: Boolean;
var
  cur: TODBCCursorCrack;
  savedStmt: Pointer;
  res: SQLRETURN;
  colCount: SQLSMALLINT;
begin
  LoadFunc;
  cur := TODBCCursorCrack(Self.Cursor);
  savedStmt := cur.FSTMTHandle;
  while True do
  begin
    res := SQLMoreResults(savedStmt);
    if res = SQL_NO_DATA then
    begin
      Result := False;
      Exit;
    end;
    OdbcCheck(res);
    // if column count is 0, this is not a resultset
    if ODBCSuccess(SQLNumResultCols(savedStmt, ColCount)) then
    begin
      if colCount > 0 then Break;
    end;
  end;
  OdbcCheck(SQLFreeStmt(savedStmt, SQL_UNBIND));
  cur.FSTMTHandle := nil; // prevent from release this stmt on close
  Close;
  FieldDefs.Updated:= False;

  // Reopen dataset and use next resultset.
  TExODBCConnection(Self.DataBase).FGetNext:= True;
  TExODBCConnection(Self.DataBase).FNextStmt:= savedStmt;
  try
    Open;
  finally
    TExODBCConnection(Self.DataBase).FGetNext:= False;
    TExODBCConnection(Self.DataBase).FNextStmt:= nil;
  end;
  Result := True;
end;

end.

