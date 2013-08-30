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
