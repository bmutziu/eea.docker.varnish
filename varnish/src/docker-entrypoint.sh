#!/bin/bash

# Priviledge separation user id
_USER="${PRIVILEDGED_USER:+-u ${PRIVILEDGED_USER}}"

# Pid
PID_FILE="${PID_FILE:-/var/groupon/run/varnish/varnish.pid}"
_PID="${PID_FILE:+-P ${PID_FILE}}"

# Size of the cache storage
CACHE_SIZE="${CACHE_SIZE:-2G}"
CACHE_STORAGE="${CACHE_STORAGE:-malloc,${CACHE_SIZE}}"

# Cache storage
_STORAGE="${CACHE_STORAGE:+-s ${CACHE_STORAGE}}"

# Default TTL used when the backend does not specify one
BACKENDS_TTL="${BACKENDS_TTL:-900}"
_TTL="${BACKENDS_TTL:+-t ${BACKENDS_TTL}}"

# Address:Port
ADDRESS_PORT="${ADDRESS_PORT:-:6081}"
_ADDRESS="${ADDRESS_PORT:+-a ${ADDRESS_PORT}}"

# Admin:Port
_ADMIN="${ADMIN_PORT:+-T ${ADMIN_PORT}}"

# Custom params
PARAM_VALUE="${PARAM_VALUE:--p http_resp_size=32768 -p shm_reclen=255 -p thread_pools=2 -p thread_pool_min=500 -p thread_pool_max=1000 -p thread_pool_timeout=120 -p default_ttl=3600 -p default_grace=3600}"
_VALUE="${PARAM_VALUE}"

PARAM_BIS_VALUE="-pcc_command=exec /usr/bin/gcc -fpic -shared -Wl,-x -o %o %s"
_VALUEBIS="${PARAM_BIS_VALUE}"

PARAMS="${_USER} ${_PID} ${_STORAGE} ${_TTL} ${_ADDRESS} ${_ADMIN} ${_VALUE}"
PARAMSBIS="${_VALUEBIS}"

# Varnishncsa
VARNISHNCSA_FORMAT="%t remote_host=%h request=\"%r\" http_status=%s response_size=%b user_agent=\"%{VCL_Log:user_agent}x\" response_time=%{Varnish:time_firstbyte}x total_time=%D cache_hit=%{VCL_Log:cache_result}x Cache-control=%{Cache-control}i Accept-Language=%{Accept-Language}i X-Request-Id=%{X-Request-Id}i"

# Varnishcachewarmer
WARMER_LOGLIMIT="30"
WARMER_HOST="${WARMER_HOST:-localhost}"
WARMER_THREADS="10"

VARNISH_CACHEWARMER_OPTS="--logTimeLimit ${WARMER_LOGLIMIT} --varnishHost ${WARMER_HOST} --threadCount ${WARMER_THREADS}"

if [ -n "$COOKIES" ]; then
  python3 /cookie_config.py
fi

if [ -n "$DASHBOARD_SERVERS" ]; then
  python3 /dashboard_config.py
fi

if [ -n "$DNS_ENABLED" ]; then

  # Backends are resolved using internal or external DNS service
  touch /etc/varnish/dns.backends
  python3 /add_backends.py dns
  python3 /assemble_vcls.py
  echo "*/${DNS_TTL:-1} * * * * /track_dns  | logger " > /var/crontab.txt

else

  if [ -n "$BACKENDS" ]; then

     # Backend provided via $BACKENDS env
     touch /etc/varnish/env.backends
     python3 /add_backends.py env
     python3 /assemble_vcls.py
     echo "*/${DNS_TTL:-1} * * * * /track_env  | logger " > /var/crontab.txt

  else
     if test "$(ls -A /etc/varnish/conf.d/)"; then
         # Backend vcl files directly added to /etc/varnish/conf.d/
         python3 /assemble_vcls.py
	 # sleep 1
     else
         # Find backend within /etc/hosts

	 echo "*/${DNS_TTL:-1} * * * * /track_hosts  | logger " > /var/crontab.txt
         touch /etc/varnish/hosts.backends
         python3 /add_backends.py hosts
         python3 /assemble_vcls.py
    fi
  fi
fi

if [ -n "$AUTOKILL_CRON" ]; then
    
     echo "$AUTOKILL_CRON /stop_varnish_cache.sh  | logger " >> /var/crontab.txt	

fi


#enable cron logging
service rsyslog restart

#add crontab
crontab /var/crontab.txt
chmod 600 /etc/crontab
service cron restart



#Add env variables for varnish
echo "export PATH=$PATH" >> /etc/environment
if [ -n "$ADDRESS_PORT" ]; then echo "export ADDRESS_PORT=$ADDRESS_PORT" >> /etc/environment; fi
if [ -n "$ADMIN_PORT" ]; then echo "export ADMIN_PORT=$ADMIN_PORT" >> /etc/environment; fi
if [ -n "$BACKENDS" ]; then echo "export BACKENDS=\"$BACKENDS\"" >> /etc/environment; fi
if [ -n "$BACKENDS_PORT" ]; then echo "export BACKENDS_PORT=$BACKENDS_PORT" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_ENABLED" ]; then echo "export BACKENDS_PROBE_ENABLED=$BACKENDS_PROBE_ENABLED" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_INTERVAL" ]; then echo "export BACKENDS_PROBE_INTERVAL=$BACKENDS_PROBE_INTERVAL" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_REQUEST" ]; then echo "export BACKENDS_PROBE_REQUEST=$BACKENDS_PROBE_REQUEST" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_REQUEST_DELIMITER" ]; then echo "export BACKENDS_PROBE_REQUEST_DELIMITER=$BACKENDS_PROBE_REQUEST_DELIMITER" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_THRESHOLD" ]; then echo "export BACKENDS_PROBE_THRESHOLD=$BACKENDS_PROBE_THRESHOLD" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_TIMEOUT" ]; then echo "export BACKENDS_PROBE_TIMEOUT=$BACKENDS_PROBE_TIMEOUT" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_URL" ]; then echo "export BACKENDS_PROBE_URL=$BACKENDS_PROBE_URL" >> /etc/environment; fi
if [ -n "$BACKENDS_PROBE_WINDOW" ]; then echo "export BACKENDS_PROBE_WINDOW=$BACKENDS_PROBE_WINDOW" >> /etc/environment; fi
if [ -n "$BACKENDS_SAINT_MODE" ]; then echo "export BACKENDS_SAINT_MODE=$BACKENDS_SAINT_MODE" >> /etc/environment; fi
if [ -n "$BACKENDS_PURGE_LIST" ]; then echo "export BACKENDS_PURGE_LIST=$BACKENDS_PURGE_LIST" >> /etc/environment; fi
if [ -n "$CACHE_SIZE" ]; then echo "export CACHE_SIZE=$CACHE_SIZE" >> /etc/environment; fi
if [ -n "$CACHE_STORAGE" ]; then echo "export CACHE_STORAGE=$CACHE_STORAGE" >> /etc/environment; fi
if [ -n "$DNS_ENABLED" ]; then echo "export DNS_ENABLED=$DNS_ENABLED" >> /etc/environment; fi
if [ -n "$DNS_TTL" ]; then echo "export DNS_TTL=$DNS_TTL" >> /etc/environment; fi
if [ -n "$PARAM_VALUE" ]; then echo "export PARAM_VALUE='$PARAM_VALUE'" >> /etc/environment; fi
if [ -n "$PRIVILEDGED_USER" ]; then echo "export PRIVILEDGED_USER=$PRIVILEDGED_USER" >> /etc/environment; fi
if [ -n "$COOKIES" ]; then echo "export COOKIES=$COOKIES" >> /etc/environment; fi
if [ -n "$COOKIES_WHITELIST" ]; then echo "export COOKIES_WHITELIST=\"$COOKIES_WHITELIST\"" >> /etc/environment; fi
if [ -n "$DASHBOARD_USER" ]; then echo "export DASHBOARD_USER=$DASHBOARD_USER" >> /etc/environment; fi
if [ -n "$DASHBOARD_PASSWORD" ]; then echo "export DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD" >> /etc/environment; fi
if [ -n "$DASHBOARD_SERVERS" ]; then echo "export DASHBOARD_SERVERS=\"$DASHBOARD_SERVERS\"" >> /etc/environment; fi
if [ -n "$DASHBOARD_DNS_ENABLED" ]; then echo "export DASHBOARD_DNS_ENABLED=$DASHBOARD_DNS_ENABLED" >> /etc/environment; fi
if [ -n "$DASHBOARD_PORT" ]; then echo "export DASHBOARD_PORT=$DASHBOARD_PORT" >> /etc/environment; fi
if [ -n "$VARNISH_CACHEWARMER_OPTS" ]; then echo "export VARNISH_CACHEWARMER_OPTS=\"$VARNISH_CACHEWARMER_OPTS\"" >> /etc/environment; fi


mkdir -p /usr/local/etc/varnish
mkdir -p /usr/local/varnish_cachewarmer
mkdir -p /var/groupon/varnish/logs
mkdir -p /var/groupon/varnish_cachewarmer/logs
mkdir -p /var/groupon/run/varnish

echo "${DASHBOARD_USER:-admin}:${DASHBOARD_PASSWORD:-admin}" > /usr/local/etc/varnish/agent_secret
chown -R varnish:varnish /usr/local/etc/varnish
chown -R varnish:varnish /usr/local/var/varnish

if [ -n "$DASHBOARD_PORT" ]; then
    varnish-agent -H /var/www/html/varnish-dashboard -c $DASHBOARD_PORT
else
    varnish-agent -H /var/www/html/varnish-dashboard
fi

if [[ $1 == "varnish" ]] && [ -n "${VARNISHNCSA_SUPERVISORD_ENABLED}" ]; then
   varnishd -j unix,user=varnish -F -f /etc/varnish/default.vcl ${PARAMS} "${PARAMSBIS}"
elif [[ $1 == "varnish" ]] && [ -n "${VARNISHNCSA_ENABLED}" ]; then
   # varnishd -j unix,user=varnish -f /etc/varnish/default.vcl ${PARAMS}
   # varnishncsa -a -w /var/groupon/varnish/logs/varnish.log -P /var/run/varnishncsa.pid -F "${VARNISHNCSA_FORMAT}"
   varnishd -j unix,user=varnish -f /etc/varnish/default.vcl ${PARAMS}; ldconfig; varnishncsa -a -w /var/groupon/varnish/logs/varnish.log -P /var/run/varnishncsa.pid -F "${VARNISHNCSA_FORMAT}"
else
   exec "$@"
fi
