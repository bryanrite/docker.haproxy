#!/bin/bash -e

if test -e /haproxy.cfg.j2; then
  cat /haproxy.cfg.j2 | python /update.py > /usr/local/etc/haproxy/haproxy.cfg
  /track_hosts_file.sh &
else
  echo "Cannot find haproxy template config file at /haproxy.cfg.j2" 1>&2
  exit 1
fi

exec "$@"
