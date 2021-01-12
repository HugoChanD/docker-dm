#!/bin/sh

DM_PATH=/home/dmdba/dmdbms
DM_DATA_DIR=/home/dmdba/data/DAMENG

check_is_init() {
  declare -g DATABASE_ALREADY_EXISTS
 if [ -d "${DM_DATA_DIR}" -a `ls -A ${DM_DATA_DIR}|wc -w` -ne 0 ];then
    DATABASE_ALREADY_EXISTS='true'
  fi
}

db_init(){
  mkdir -p ${DM_DATA_DIR}
  chown -R dmdba ${DM_DATA_DIR}
  cd /home/dmdba/dmdbms/bin
  echo ${SYSDBA_PWD-SYSDBA}
  ${DM_PATH}/bin/dminit PATH=/home/dmdba/data PAGE_SIZE=16 SYSDBA_PWD=${SYSDBA_PWD-SYSDBA}
}

check_is_init
if [ -z "${DATABASE_ALREADY_EXISTS}" ];then
  db_init
  if [ $? -ne 0 ];then
    echo "initdb failed"
    exit 1
  fi
fi

if [ ! -f "${DM_PATH}/bin/DmAPService}" ];then
  ${DM_PATH}/script/root/dm_service_installer.sh -s "${DM_PATH}/bin/DmAPService"
fi
if [ ! -f "${DM_PATH}/bin/DmServiceBase" ];then
  ${DM_PATH}/script/root/dm_service_installer.sh -t dmserver -p Base -dm_ini ${DM_DATA_DIR}/dm.ini
fi

gosu dmdba ${DM_PATH}/bin/DmAPService start
gosu dmdba ${DM_PATH}/bin/DmServiceBase start

exec gosu dmdba tail -f /home/dmdba/dmdbms/log/DmServiceBase.log

