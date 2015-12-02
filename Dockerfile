FROM haproxy:latest
MAINTAINER "Bryan Rite" <bryan@bryanrite.com>

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python \
    python-jinja2 \
    inotify-tools \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /
COPY haproxy.cfg.j2 /
COPY track_hosts_file.sh /
COPY update.py /

ENV HAPROXY_HEALTH_CHECK_NODES=true \
    HAPROXY_STATS_ENABLED=false \
    HAPROXY_STATS_LOGIN=admin:docker \
    HAPROXY_SERVICE_NAME_TO_PROXY=web

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
