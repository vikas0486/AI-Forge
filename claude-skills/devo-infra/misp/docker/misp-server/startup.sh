#!/bin/bash

. /root/misp.config

cat /root/misp.config
/sbin/ifconfig
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &

if [ -f /first_start ]; then
    sleep 5
    rm -f /first_start
    su - www-data
    /bin/bash /tmp/2_core-cake.sh $PATH_TO_MISP $GPG_EMAIL_ADDRESS $GPG_PASSPHRASE $FLAVOUR $MISP_BASEURL
fi

