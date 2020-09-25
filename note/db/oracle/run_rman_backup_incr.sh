#!/bin/bash
#echo "rman backup level 1"
export ORACLE_SID=acc1
export ORACLE_UNQNAME=acc
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1
export LIBPATH=$ORACLE_HOME/lib
export ORA_NLS10=$ORACLE_HOME/nls/data
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$PATH
export nls_date_format='yyyymmdd hh24:mi:ss';
/u01/app/oracle/product/11.2.0/db_1/bin/rman target / log=/orabackup/db_level1_`date +%Y%m%d`.log <<EOF
configure retention policy to recovery window of 3 days;
run{
allocate channel disk1 type disk;
allocate channel disk2 type disk;
backup incremental level 1 database include current controlfile format '/orabackup/db_level1_data_%d_%T_%s'
plus archivelog format '/orabackup/db_level1_arch_%d_%T_%s'delete all input;
delete noprompt obsolete;
crosscheck backup;
delete noprompt expired backup;
release channel disk1;
release channel disk2;
}
exit;
EOF
