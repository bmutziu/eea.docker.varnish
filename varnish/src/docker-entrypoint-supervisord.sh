#!/bin/bash

echo "Varnish through SuperVisorD"

mkdir -p /var/log/supervisor

if [[ $1 == "varnish" ]]; then
   exec /usr/local/bin/supervisord -n -c /etc/supervisord.conf
else
   exec "$@"
fi
