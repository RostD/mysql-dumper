#!/bin/bash

# SYNTAX:
# mysql-dumper db_name user_name user_password host /dump/dir [excluded_table_one,excluded_table_two,excluded_table_n]
#
# USAGE:
# mv mysql-dumper.sh /usr/bin/mysql-dumper
# chmod 777 /usr/bin/mysql-dumper
# mysql-dumper myDB user_account '123abc' '127.0.0.1' /var/backup accounting_logs,accounting_history

DB_NAME=$1
DB_USER=$2
DB_PASSWORD=$3
DB_HOST=$4
DIR=$5
IGNORED_TABLES=$6

BACKUP_PATH=${DIR}/$(date +"%d-%m-%Y")/${DB_NAME}

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
   mysqldump -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} ${t} | gzip > ${BACKUP_PATH}/${t}.sql.gz
   echo "Done"
done
