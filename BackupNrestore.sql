--NOTE: please download and restore AdventureWorks2014 database before playing with below queries
use master;
go
--						---: RECOVERY MODELs :---
--1. FULL recovery model: 
--	+ Complete protection against data loss
--	+ Point-in-time recovery by restoring transaction logs
--  - Rapid Txn logs growth 
--  - must control txn growth by regulare Txn log backups
-- Use cases:
--  - OLTP databases where you deal with most critical data, where you dont want to lose any transactions
alter database AdventureWorks2014 set recovery FULL;
go;
--2. BULK-LOGGED recovery model:
-- + Provides better performace for bulk data operations(bcp,BULK INSERT,SELECT INTO, etc) by logging only minimal bulk transactions
-- - Possibility of data loss for bulk ops
-- - must control txn growth by regulare Txn log backups
-- Use cases:
--     - Environments where frequent bulk operations needed. Switch to Bulk-logged prior to perform bulk ops so that you can minimise txn logs.
alter database AdventureWorks2014 set recovery BULK_LOGGED;
--3. SIMPLE recovery model
-- + Easy and no maintenance overhead
-- + Txn log growth under control since SQL Server flushes logs after every check-point
-- - Cant supports point-in-time recovery since no txn log backups
--Use Cases:
--   - Data warehousing environments where you can replay data loads when data load failures
--   - Best for Test/Developemnt environments where data loss can be ignored.
alter database AdventureWorks2014 set recovery SIMPLE;
GO
--							---: BACKUP types :---
--1. FULL database backup
--   -> Backup entire database
BACKUP DATABASE AdventureWorks2014
TO DISK ='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_full_bkp';
--2. DIFFERENTIAL database backup
--   -> Backup only modified extents since last FULL backup
GO
BACKUP DATABASE AdventureWorks2014
TO DISK ='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_DIFF_bkp'
WITH DIFFERENTIAL;
GO
--3. FILE and FILEGROUPs backups
--  -> Backups files and file groups. Its better for huge databases
BACKUP DATABASE AdventureWorks2014
FILE 'AdventureWorks2014_Data' 
	TO DISK='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_filegroup_bkp';
GO
--4. PARTIAL Backups
--  -> Backup only READ_WRITE filegroups and ignore READ_ONLY filegrops which stores static data
BACKUP DATABASE AdventureWorks2014 READ_WRITE_FILEGROUPS --<== Giving only read_write filegroups to backup
TO DISK='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_partial_bkp';
GO
--5. DIFFERENTIAL PARTIAL backups
BACKUP DATABASE AdventureWorks2014 READ_WRITE_FILEGROUPS --<== Giving only read_write filegroups to backup
TO DISK='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_diff_partial_bkp';
WITH DIFFERENTIAL;
GO
--6. COPY-ONLY backups
BACKUP DATABASE AdventureWorks2014
TO DISK ='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_COPY_ONLY_bkp'
WITH COPY_ONLY;
GO
--7. Transactional Log backups
BACKUP LOG AdventureWorks2014
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_lOG';
with init,format;

--TO SEE LIST OF FILE/FILEGROUPS NAMES
RESTORE FILELISTONLY
from disk ='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_filegroup_bkp';
--TO SEE DETAILS ABOUT BACKUP DATA
restore HEADERONLY
from disk ='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_filegroup_bkp';
-- TO VERIFY BACKUP FILES
restore VERIFYONLY
from disk ='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_filegroup_bkp';

--							---: RESTORE DATABASE/LOG :--
--1. RESTORE DATABASE FROM BACKUP
USE MASTER;
GO
RESTORE DATABASE AdventureWorks2014_NEW
FROM DISK='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_full_bkp'
WITH REPLACE
GO
--2. RESTORE DATABASE BY MOVE DATA AND LOG FILES TO SEPERATE LOCATIONS
restore database AdventureWorks2014_NEW
from disk='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014.bak'
with
	move 'AdventureWorks2014_data' to 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\DATA\AdventureWorks2014.mdf',
	move 'AdventureWorks2014_log' to 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Log\AdventureWorks2014.ldf',
replace;
GO
--3. RESTORE LOG
RESTORE LOG AdventureWorks2014_NEW
FROM DISK='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_lOG'
WITH RECOVERY;
GO
--RECOVERY   => rolebacks uncommited transactions from txn log and the db is made available for use. Set this option for the last restore.
--NORECOVERY => DB inaccessible and waiting for additional transaction log. set this option when still one or more txn logs present to restore.
--STANDBY    => DB available for read and allows additional txn logs to be restored.


--							--: DATABASE SNAPSHOT :---
-- -> It is not a backup like FULL,DIFFERENTIAL etc, its just copy of your db and allow to restore from snapshot copy.
-- -> its faster than taking full backup
-- Use cases: take snapshot of your db when you upgrade your database instead of full backup. 
--1. create snapshot of your backups
CREATE DATABASE AdventureWorks2014_SNAPSHOT
ON (NAME='AdventureWorks2014_data',
	FILENAME='C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER_01\MSSQL\Backup\AdventureWorks2014_SNAPSHOT')
AS SNAPSHOT OF AdventureWorks2014;
GO
--2.RESTORE DB FROM A SNAPSHOT
USER MASTER;
GO
RESTORE DATABASE AdventureWorks2014_new
FROM DATABASE_SNAPSHOT = 'AdventureWorks2014_SNAPSHOT';
GO