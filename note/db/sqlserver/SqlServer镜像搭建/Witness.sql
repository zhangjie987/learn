USE master
GO

--����֤�飬������
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

--��������˿�
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

--Ϊ�������ʼ�֤���ľ���˿ڶ�������¼���û�������������Ȩ��
CREATE LOGIN Login_For_Host WITH PASSWORD=N'???';
CREATE USER User_For_Host FOR LOGIN Login_For_Host;
CREATE CERTIFICATE Cert_For_Host AUTHORIZATION User_For_Host FROM FILE=N'C:\Cert_Host.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Witness TO Login_For_Host;
GO

--Ϊ��������ʼ�֤���ľ���˿ڶ�������¼���û�������������Ȩ��
CREATE LOGIN Login_For_Mirror WITH PASSWORD=N'???';
CREATE USER User_For_Mirror FOR LOGIN Login_For_Mirror;
CREATE CERTIFICATE Cert_For_Mirror AUTHORIZATION User_For_Mirror FROM FILE=N'C:\Cert_Mirror.cer';
GRANT CONNECT ON ENDPOINT::Endpoint_Witness TO Login_For_Mirror;
GO