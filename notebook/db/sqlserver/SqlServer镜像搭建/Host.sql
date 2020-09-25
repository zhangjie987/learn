USE master
GO

--备份数据库
--BACKUP DATABASE BizDB TO DISK = N'E:\BizDB.bak'
--WITH FORMAT, INIT, NAME = N'BizDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
--GO

--BACKUP LOG BizDB TO DISK = N'E:\BizDB.bak'
--WITH NOFORMAT, NOINIT, NAME = N'BizDB-Transaction Log Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
--GO 

--创建证书，并备份
IF EXISTS(SELECT * FROM sys.databases WHERE name='master' and is_master_key_encrypted_by_server=1)    
    OPEN MASTER KEY DECRYPTION BY PASSWORD='???';
ELSE
    CREATE MASTER KEY ENCRYPTION BY PASSWORD='???';
GO

IF EXISTS(select * from sys.certificates WHERE name='Cert_Host')
    DROP CERTIFICATE Cert_Host;
GO
CREATE CERTIFICATE Cert_Host
	WITH SUBJECT=N'Cert_Host Certificate',START_DATE='20180525',EXPIRY_DATE='20990101';
	BACKUP CERTIFICATE Cert_Host TO FILE=N'C:\Cert_Host.cer';
GO

----创建镜像端口
IF EXISTS(select * from sys.database_mirroring_endpoints WHERE name='Endpoint_Host')
    DROP ENDPOINT Endpoint_Host
GO
CREATE ENDPOINT Endpoint_Host
STATE = STARTED
AS TCP
(
    LISTENER_PORT=5022,
    LISTENER_IP=ALL
)
FOR DATABASE_MIRRORING
(
    AUTHENTICATION=CERTIFICATE Cert_Host,
    ENCRYPTION=REQUIRED ALGORITHM AES,
    ROLE=PARTNER
)
GO

--为镜像机访问主机的镜像端口而创建登录和用户，并授予连接权限
CREATE LOGIN Login_For_Mirror WITH PASSWORD=N'???';
CREATE USER User_For_Mirror FOR LOGIN Login_For_Mirror;
CREATE CERTIFICATE Cert_For_Mirror AUTHORIZATION User_For_Mirror FROM FILE=N'C:\Cert_Mirror.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Host TO Login_For_Mirror;
GO

--为见证机访问主机的镜像端口而创建登录和用户，并授予连接权限
CREATE LOGIN Login_For_Witness WITH PASSWORD=N'???';
CREATE USER User_For_Witness FOR LOGIN Login_For_Witness;
CREATE CERTIFICATE Cert_For_Witness AUTHORIZATION User_For_Witness FROM FILE=N'C:\Cert_Witness.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Host TO Login_For_Witness;
GO

--开始镜像
--ALTER DATABASE BizDB SET PARTNER=N'TCP://FK-DBIMAGE-01.gzmetro.com:5022';
--ALTER DATABASE BizDB SET WITNESS=N'TCP://FK-DBWITNESS-01.gzmetro.com:5022';

--切换主备
--ALTER DATABASE BizDB SET PARTNER FAILOVER;
