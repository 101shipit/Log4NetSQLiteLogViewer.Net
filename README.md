Log4NetSQLiteLogViewer.Net
==========================
Log4NetSQLiteLogViewer.Net is an asp.Net page to view a log4Net SQLite Log database in a grid, with filters and ordering

![Log Grid View](/ViewLog.png "View Log - Grid View")

Notes: 
 * This requires the SQLite ADO.Net package/reference (It's easiest to include it in your project/solution using NuGet), 
 * The SQLite DB must already be created with the "Log" table
 * Example Create Log4Net SQLite Log DB SQL script:
<Pre>
	CREATE TABLE Log (
	LogId INTEGER PRIMARY KEY autoincrement,
	Date DATETIME NOT NULL,
	Thread varchar(255) NOT NULL,
	Level VARCHAR(50) NOT NULL,
	Logger VARCHAR(255) NOT NULL,
	Message TEXT DEFAULT NULL,
	Exception varchar(2000) NULL
	);
	CREATE VIEW "All In Last 24 hours" AS  
	select * from Log where Date > datetime('now','-1 day') ORDER BY LogId DESC;
	CREATE VIEW "All In Last Week" AS  
	select * from Log where [Date] > datetime('now','-7 day') ORDER BY LogId DESC;
	CREATE VIEW "Warnings And Higher Last Week" AS  
	select * from Log where (Level = "WARN" OR  Level = "ERROR"  OR  Level = "FATAL") AND (Date > datetime('now','-7 day') ) ORDER BY LogId DESC;
	CREATE VIEW "Warnings And Higher In Last 24 Hours" AS  
	select * from Log where (Level = "WARN" OR  Level = "ERROR"  OR  Level = "FATAL") AND (Date > datetime('now','-1 day') ) ORDER BY LogId DESC;
	CREATE INDEX [IDX_LOG_DATE] ON [Log](
	[Date]  DESC
	);
	CREATE INDEX [IDX_LOG_LEVEL] ON [Log](
	[Level]  DESC
	);
	CREATE INDEX [IDX_LOG_LOGGER] ON [Log](
	[Logger]  DESC
	);
	PRAGMA journal_mode=WAL;
</Pre>
 * You could run the above SQL with the SQLite command line exe such as:
 <pre>
 c:\SQLite\sqlite3.exe c:\path\to\new\LogDB.sqlite < c:\path\to\CreateLog4NetDbSQLScript.sql
 </pre>
 * Log4Net logging configuration to log to an Ado.Net appender (SQLite DB) would be like the following:
<pre>
	&lt;log4net&gt;
		&lt;appender name="sqlite" type="log4net.Appender.AdoNetAppender"&gt;
			&lt;bufferSize value="1" /&gt;
			&lt;connectionType value="System.Data.SQLite.SQLiteConnection, System.Data.SQLite" /&gt;
			&lt;connectionString value="Data Source=C:\Logs\MyLog.sqlite;Version=3;" /&gt;
			&lt;commandText value="INSERT INTO Log (Date, Thread, Level, Logger, Message, Exception) VALUES (@Date, @Thread, @Level, @Logger, @Message, @Exception)" /&gt;
			&lt;parameter&gt;
				&lt;parameterName value="@Date" /&gt;
				&lt;dbType value="DateTime" /&gt;
				&lt;layout type="log4net.Layout.RawTimeStampLayout" /&gt;
			&lt;/parameter&gt;
			&lt;parameter&gt;
				&lt;parameterName value="@Thread" /&gt;
				&lt;dbType value="String" /&gt;
				&lt;size value="255" /&gt;
				&lt;layout type="log4net.Layout.PatternLayout"&gt;
					&lt;conversionPattern value="%thread" /&gt;
				&lt;/layout&gt;
			&lt;/parameter&gt;
			&lt;parameter&gt;
			&lt;parameterName value="@Level" /&gt;
			&lt;dbType value="String" /&gt;
			&lt;layout type="log4net.Layout.PatternLayout"&gt;
				&lt;conversionPattern value="%level" /&gt;
			&lt;/layout&gt;
			&lt;/parameter&gt;
			&lt;parameter&gt;
			&lt;parameterName value="@Logger" /&gt;
			&lt;dbType value="String" /&gt;
			&lt;layout type="log4net.Layout.PatternLayout"&gt;
				&lt;conversionPattern value="%logger" /&gt;
			&lt;/layout&gt;
			&lt;/parameter&gt;
			&lt;parameter&gt;
				&lt;parameterName value="@Message" /&gt;
				&lt;dbType value="String" /&gt;
				&lt;layout type="log4net.Layout.PatternLayout"&gt;
					&lt;conversionPattern value="%message" /&gt;
				&lt;/layout&gt;
			&lt;/parameter&gt;
			&lt;parameter&gt;
				&lt;parameterName value="@Exception" /&gt;
				&lt;dbType value="String" /&gt;
				&lt;size value="2000" /&gt;
				&lt;layout type="log4net.Layout.ExceptionLayout" /&gt;
			&lt;/parameter&gt;
		&lt;/appender&gt;
		&lt;!--Setup the root category, add the appenders and set the default priority --&gt;
		&lt;root&gt;
			&lt;priority value="DEBUG" /&gt;
			&lt;appender-ref ref="sqlite" /&gt;
		&lt;/root&gt;
	&lt;/log4net
</pre>
