program odbc_multiresults;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, db, sqldb, sqldbex, CustApp
  { you can add units after this };

type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
    procedure TestDb(const sql: string);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TMyApplication }

procedure TMyApplication.DoRun;
const
  sql1 = '	select name, id, xtype, crdate from sysobjects where id=4'#13#10
	  + 'select name, id, xtype, length, xprec, xscale, colid from syscolumns where id=4';
  sql2 = ' exec sp_multiple_resultsets_test';
begin
  try
    TestDb(sql1);
    TestDb(sql2);
  except
    on E: Exception do
      Writeln(E.Message);
  end;
  readln;
  // stop program loop
  Terminate;
end;

procedure TMyApplication.TestDb(const sql: string);
var
  ds: TExSQLQuery;
  oconn: TExODBCConnection;
  tran: TSQLTransaction;

  procedure dump;
  var
    s: string;
    i: Integer;
  begin
    ds.First;
    while not ds.EOF do
    begin
      s := '';
      for i := 0 to ds.FieldCount-1 do
        s := s + ds.Fields[i].AsString + #9;
      writeln(s);
      ds.Next;
    end;
  end;

begin
  ds := TExSQLQuery.Create(nil);
  oconn := TExODBCConnection.Create(nil);
  tran := TSQLtransaction.Create(nil);
  try
    oconn.Password:= 'a1234';
    oconn.UserName:= 'test';
    oconn.Driver:= 'SQL Server';
    oconn.Params.Add('SERVER=localhost');
    oconn.Params.Add('DATABASE=TradeMail');
    oconn.Transaction := tran;
    ds.Database := oconn;
    ds.SQL.text := sql;
    ds.Open;

    Writeln('SQL: ' + sql);
    repeat
      dump;
      Writeln('================');
      if not ds.NextResultSet then Break;
    until False;
    Writeln('No more results to dump.');
  finally
    ds.Free;
    tran.Free;
    oconn.Free;
  end;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='My Application';
  Application.Run;
  Application.Free;
end.

