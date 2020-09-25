USE master
GO
--还原数据库
--RESTORE DATABASE BizDB FROM DISK = N'E:\BizDB.bak'
--WITH FILE = 1,
--NORECOVERY, NOUNLOAD, REPLACE, STATS = 10
--GO

--RESTORE LOG BizDB FROM DISK = N'E:\BizDB.bak'
--WITH FILE = 2, NORECOVERY, NOUNLOAD, STATS = 10
--GO

--创建证书，并备份
IF EXISTS(SELECT * FROM sys.databases WHERE name='master' and is_master_key_encrypted_by_server=1)    
    OPEN MASTER KEY DECRYPTION BY PASSWORD='???';
ELSE
    CREATE MASTER KEY ENCRYPTION BY PASSWORD='???';
GO

IF EXISTS(select * from sys.certificates WHERE name='Cert_Mirror')
    DROP CERTIFICATE Cert_Mirror;
GO
CREATE CERTIFICATE Cert_Mirror
	WITH SUBJECT=N'Cert_Mirror Certificate',START_DATE='20180525',EXPIRY_DATE='20990101';
	BACKUP CERTIFICATE Cert_Mirror TO FILE=N'C:\Cert_Mirror.cer';
GO

--创建镜像端口
IF EXISTS(select * from sys.database_mirroring_endpoints WHERE name='Endpoint_Mirror')
    DROP ENDPOINT Endpoint_Mirror
GO
CREATE ENDPOINT Endpoint_Mirror
STATE = STARTED
AS TCP
(
    LISTENER_PORT=5022,
    LISTENER_IP=ALL
)
FOR DATABASE_MIRRORING
(
    AUTHENTICATION=CERTIFICATE Cert_Mirror,
    ENCRYPTION=REQUIRED ALGORITHM AES,
    ROLE=PARTNER
)
GO

--为主机访问镜像机的镜像端口而创建登录和用户，并授予连接权限
CREATE LOGIN Login_For_Host WITH PASSWORD=N'???';
CREATE USER User_For_Host FOR LOGIN Login_For_Host;
CREATE CERTIFICATE Cert_For_Host AUTHORIZATION User_For_Host FROM FILE =N'C:\Cert_Host.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Mirror TO Login_For_Host;
GO

--为见证机访问镜像机的镜像端口而创建登录和用户，并授予连接权限
CREATE LOGIN Login_For_Witness WITH PASSWORD=N'???';
CREATE USER User_For_Witness FOR LOGIN Login_For_Witness;
CREATE CERTIFICATE Cert_For_Witness AUTHORIZATION User_For_Witness FROM FILE =N'C:\Cert_Witness.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Mirror TO Login_For_Witness;
GO

--开始镜像，先于主机执行
--ALTER DATABASE BizDB SET PARTNER =N'TCP://FK-DB-01.gzmetro.com:5022'; 

