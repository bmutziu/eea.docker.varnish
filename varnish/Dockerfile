FROM debian:stretch-slim
MAINTAINER "EEA: IDM2 A-Team" <eea-edw-a-team-alerts@googlegroups.com>

ARG VARNISH_ARTIFACTS=artifacts/varnishservice
ARG VARNISH_ARTIFACTS_CONFIG_PATH=artifacts/varnishservice/config

COPY src/docker-install.sh /tmp/docker-install.sh
RUN /tmp/docker-install.sh \
 && rm -rvf /tmp/*

COPY src/*.py src/track* src/*.sh  /
COPY src/reload                    /usr/bin/reload
COPY src/default.vcl               /etc/varnish/
COPY src/cache_reload.vcl src/app.vcl src/assets.vcl src/logging.vcl                  /etc/varnish/conf.d/
COPY src/supervisord.conf	   /etc/supervisord.conf

ENV VARNISH_CACHEWARMER_ARTIFACTS /usr/local/varnish_cachewarmer
COPY ${VARNISH_ARTIFACTS_CONFIG_PATH}/run_cachewarmer.sh ${VARNISH_CACHEWARMER_ARTIFACTS}/run_cachewarmer.sh
COPY ${VARNISH_ARTIFACTS}/varnish-cachewarmer-jar-with-dependencies.jar ${VARNISH_CACHEWARMER_ARTIFACTS}/varnish-cachewarmer-jar-with-dependencies.jar

ENV VARNISH_NCSA_LOGFILE=/var/groupon/varnish/logs/varnish.log
ENV VARNISH_NCSA_PIDFILE=/var/groupon/run/varnish/varnishncsa.pid
ENV VARNISH_NCSA_FORMAT %t remote_host=%h request="%r" http_status=%s response_size=%b user_agent="%{VCL_Log:user_agent}x" response_time=%{Varnish:time_firstbyte}x total_time=%D cache_hit=%{VCL_Log:cache_result}x  Cache-control=%{Cache-control}i  Accept-Language=%{Accept-Language}i  X-Request-Id=%{X-Request-Id}i

EXPOSE 6081 6085

HEALTHCHECK --interval=1m --timeout=3s \
  CMD ["/docker-healthcheck.sh"]

ENTRYPOINT ["/docker-entrypoint-supervisord.sh"]
CMD ["varnish"]
