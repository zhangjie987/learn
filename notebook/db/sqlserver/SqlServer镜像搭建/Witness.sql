USE master
GO

--创建证书，并备份
IF EXISTS(SELECT * FROM sys.databases WHERE name='master' and is_master_key_encrypted_by_server=1)    
    OPEN MASTER KEY DECRYPTION BY PASSWORD='???';
ELSE
    CREATE MASTER KEY ENCRYPTION BY PASSWORD='???';
GO

IF EXISTS(select * from sys.certificates WHERE name='Cert_Witness')
    DROP CERTIFICATE Cert_Witness;
GO

CREATE CERTIFICATE Cert_Witness
    WITH SUBJECT=N'Cert_Witness Certificate',START_DATE='20180525',EXPIRY_DATE='20990101';

BACKUP CERTIFICATE Cert_Witness TO FILE=N'C:\Cert_Witness.cer';
GO

--创建镜像端口
IF EXISTS(select * from sys.database_mirroring_endpoints WHERE name='Endpoint_Witness')
    DROP ENDPOINT Endpoint_Witness
GO
CREATE ENDPOINT Endpoint_Witness
STATE = STARTED
AS TCP
(
    LISTENER_PORT=5022,
    LISTENER_IP=ALL
)
FOR DATABASE_MIRRORING
(
    AUTHENTICATION=CERTIFICATE Cert_Witness,
    ENCRYPTION=REQUIRED ALGORITHM AES,
    ROLE=WITNESS
)
GO

--为主机访问见证机的镜像端口而创建登录和用户，并授予连接权限
CREATE LOGIN Login_For_Host WITH PASSWORD=N'???';
CREATE USER User_For_Host FOR LOGIN Login_For_Host;
CREATE CERTIFICATE Cert_For_Host AUTHORIZATION User_For_Host FROM FILE=N'C:\Cert_Host.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Witness TO Login_For_Host;
GO

--为镜像机访问见证机的镜像端口而创建登录和用户，并授予连接权限
CREATE LOGIN Login_For_Mirror WITH PASSWORD=N'???';
CREATE USER User_For_Mirror FOR LOGIN Login_For_Mirror;
CREATE CERTIFICATE Cert_For_Mirror AUTHORIZATION User_For_Mirror FROM FILE=N'C:\Cert_Mirror.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Witness TO Login_For_Mirror;
GO