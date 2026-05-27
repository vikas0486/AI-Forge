#!/bin/bash

prepareDB () {

    MISP_PASSWORD=$1
    DBUSER_ADMIN=$2
    DBPASSWORD_ADMIN=$3
    DBNAME=$4
    PATH_TO_MISP=$5
    DBUSER_MISP=$6
    DBPASSWORD_MISP=$7
    
    # Add your credentials if needed, if sudo has NOPASS, comment out the relevant lines
    pw=$MISP_PASSWORD

    mysqld_safe &
    mysqladmin --silent --wait=30 ping || exit 1

    script -c 'mysql_secure_installation' <<EOF 
y
${DBPASSWORD_ADMIN}
${DBPASSWORD_ADMIN}
y
y
y
y
Y

EOF

  mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "create database $DBNAME;"
  mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "grant usage on *.* to $DBNAME@localhost identified by '$DBPASSWORD_MISP';"
  mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "grant all privileges on $DBNAME.* to '$DBUSER_MISP'@'localhost';"
  mysql -u $DBUSER_ADMIN -p$DBPASSWORD_ADMIN -e "flush privileges;"
  # Import the empty MISP database from MYSQL.sql
  cat $PATH_TO_MISP/INSTALL/MYSQL.sql | mysql -u $DBUSER_MISP -p$DBPASSWORD_MISP $DBNAME
}

prepareDB $1 $2 $3 $4 $5 $6 $7
