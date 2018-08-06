#!/bin/bash

# Script for dumping mysql tables into separate files
#
# SYNTAX:
# mysql-dumper db_name user_name user_password host /dump/dir [count_of_expiration_days] [excluded_table_one,excluded_table_two,excluded_table_n]
#
# USAGE:
# mv mysql-dumper.sh /usr/bin/mysql-dumper
# chmod 777 /usr/bin/mysql-dumper
# mysql-dumper myDB user_account '123abc' '127.0.0.1' /var/backup 64 accounting_logs,accounting_history

DB_NAME=$1
DB_USER=$2
DB_PASSWORD=$3
DB_HOST=$4
DIR=$5
EXPIRATION_DAYS=$6
IGNORED_TABLES=$7

BACKUP_PATH=${DIR}/${DB_NAME}/$(date +"%d-%m-%Y")

mkdir -p ${BACKUP_PATH}

# Explode string by ignored tables
if [ -z "${IGNORED_TABLES}" ]; then
    EXCLUDE=''
else
      EXCLUDE="AND TABLE_NAME NOT IN("
      count=0

      for k in $(echo ${IGNORED_TABLES} | tr "," "\n")
      do
           if (( count > 0 )); then
           EXCLUDE="${EXCLUDE},"
           fi
           EXCLUDE="${EXCLUDE} '${k}'"
           count=$((count+1))
      done

      if [ ${count} == 0 ]; then
            EXCLUDE="${EXCLUDE} '${IGNORED_TABLES}'"
      fi

      EXCLUDE="${EXCLUDE} )"
fi

SQL="SELECT TABLE_NAME FROM information_schema.tables WHERE TABLE_SCHEMA='${DB_NAME}' ${EXCLUDE}"

for t in $(mysql -u"${DB_USER}" -p"${DB_PASSWORD}" -h"${DB_HOST}" -e"${SQL}" | grep -v TABLE_NAME)
do
   echo "Exporting $t table..."
   mysqldump --single-transaction=true --lock-tables=false -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} ${t} | gzip > ${BACKUP_PATH}/${t}.sql.gz
   echo "Done"
done

if [ ! -z "${EXPIRATION_DAYS}" ]; then
    find ${DIR}/${DB_NAME}/* -type d -mtime ${EXPIRATION_DAYS} | xargs rm -rf
fi
