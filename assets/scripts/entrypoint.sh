#!/bin/bash

WEB_ROOT=/var/www/html

function init_settings {
    # Initialize settings.php file
    cp "$WEB_ROOT/sites/default/default.settings.php" "$WEB_ROOT/sites/default/settings.php"
    chmod a+w "$WEB_ROOT/sites/default/settings.php"
    chmod a+w "$WEB_ROOT/sites/default"
    setenforce 0
}

function init_db {
    # is a mysql or postgresql database linked?
    # requires that the mysql or postgresql containers have exposed
    # port 3306 and 5432 respectively.
    if [ -n "${MYSQL_PORT_3306_TCP_ADDR}" ]; then
        DB_TYPE=mysql
        DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
        DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}
	DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
	DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
	DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
        DB_DRIVER="mysql"
    elif [ -n "${MARIADB_PORT_3306_TCP_ADDR}" ]; then
	DB_TYPE=mysql
        DB_HOST=${DB_HOST:-${MARIADB_PORT_3306_TCP_ADDR}}
        DB_PORT=${DB_PORT:-${MARIADB_PORT_3306_TCP_PORT}}
	DB_PASS=${DB_PASS:-${MARIADB_ENV_MYSQL_PASSWORD}}
	DB_USER=${DB_USER:-${MARIADB_ENV_MYSQL_USER}}
	DB_NAME=${DB_NAME:-${MARIADB_ENV_MYSQL_DATABASE}}
        DB_DRIVER="mysql"
	
#    elif [ -n "${POSTGRESQL_PORT_5432_TCP_ADDR}" ]; then
#        DB_TYPE=postgres
#        DB_HOST=${DB_HOST:-${POSTGRESQL_PORT_5432_TCP_ADDR}}
#        DB_PORT=${DB_PORT:-${POSTGRESQL_PORT_5432_TCP_PORT}}
#        # support for linked official postgres image
#        DB_USER=${DB_USER:-${POSTGRESQL_ENV_POSTGRES_USER}}
#        DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_POSTGRES_PASS}}
#        DB_NAME=${DB_NAME:-${DB_USER}}
#        DB_DRIVER="pgsql"
    elif [ -n "${DB_DRIVER}" ] || [ -n "${DB_NAME}" ] || [ -n "${DB_HOST}"] || [ -n "${DB_USER}" ] || [ -n "${DB_PASS}" ]; then
        echo "Error: DB must be alias'ed correctly, or all DB parameters must be specified."
        exit 1
    fi

    cat >> "$WEB_ROOT/sites/default/settings.php" <<- EOFDBSETTINGS
\$databases['default']['default'] = array(
      'driver' => '$DB_DRIVER',
      'database' => "$DB_NAME",
      'username' => "$DB_USER",
      'password' => "$DB_PASS",
      'host' => "$DB_HOST",
      'prefix' => "$DB_PREFIX",
    );
EOFDBSETTINGS
}

function fix_perm {
    chmod 644 "$WEB_ROOT/sites/default/settings.php"
    chmod 755 "$WEB_ROOT/sites/default"
}

if [ -e "/.bootstrap" ] ; then
    echo ".bootstrap file found. skipping initial configuration."
else
    echo "Bootstrapping..."
    init_settings
    init_db

    touch /.bootstrap
fi

if [ -e "/.bootstrap" ] ; then
    supervisord 
fi
