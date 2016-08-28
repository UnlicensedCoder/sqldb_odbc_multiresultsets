
The demo for lazarus to handle multiple resultsets using sqldb(odbc).

lazarus 1.6, win7, MSSQL2000

it seems works!

## Demo code
```
  ds := TExSQLQuery.Create(nil);
  oconn := TExODBCConnection.Create(nil);
  tran := TSQLtransaction.Create(nil);
  oconn.Password:= 'a1234';
  oconn.UserName:= 'test';
  oconn.Driver:= 'SQL Server';
  oconn.Params.Add('SERVER=localhost');
  oconn.Params.Add('DATABASE=master');
  oconn.Transaction := tran;
  ds.Database := oconn;
  ds.SQL.text := sql;
  ds.Open;
```

