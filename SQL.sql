CREATE PROC sp_multiple_resultsets_test
AS
	select name, id, xtypee crdate from sysobjects where id=4
	select name, id, xtype, length, xprec, xscale, colid from syscolumns where id=4
