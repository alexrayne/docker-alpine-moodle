#!/usr/bin/env bash
set -ex

# Provision conainer at first run
if [ -f /data/www/composer.json ] || [ -f /data/www-provisioned/composer.json ] || [ -z "$REPOSITORY_URL" ]
then
	echo "Do nothing, initial provisioning done"
else
    # Make sure to init xdebug, not to slow-down composer
    /init-xdebug.sh

    # Layout default directory structure
    mkdir -p /data/www-provisioned
    mkdir -p /data/logs
    mkdir -p /data/tmp/nginx

    ###
    # Install into /data/www
    ###
    cd /data/www-provisioned
    if [ -n "$REPOSITORY_URL" ]; then
       if [ -z "$REPOSITORY_WWW" ]; then
          REPOSITORY_WWW = '.'
       fi

       if [ -n "$REPOSITORY_CMD" ]; then
          $REPOSITORY_CMD
       else
          git clone -b $VERSION $REPOSITORY_URL $REPOSITORY_WWW
       fi
    fi
    #composer install --prefer-source

    # Apply beard patches
    if [ -f /data/www-provisioned/beard.json ]
        then
            beard patch
    fi

    ###
    # Copy DB connection settings
    ###
    if [ -f "/Settings.yaml" ]
       then
           mkdir -p /data/www-provisioned/Configuration
           cp /Settings.yaml /data/www-provisioned/Configuration/
    fi

    # Set permissions
    chown www-data:www-data -R /tmp/
    chown www-data:www-data -R /data/
    chmod g+rwx -R /data/tmp
    chmod g+rwx -R /data/www-provisioned

	# Set ssh permissions
	if [ -z "/data/.ssh/authorized_keys" ]
		then
			chown www-data:www-data -R /data/.ssh
			chmod go-w /data/
			chmod 700 /data/.ssh
			chmod 600 /data/.ssh/authorized_keys
	fi
fi
