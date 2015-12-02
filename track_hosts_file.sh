#!/bin/bash

while inotifywait -e close_write /etc/hosts 1>/dev/null 2>/dev/null; do
  cat haproxy.cfg.j2 | python update.py > /usr/local/etc/haproxy/haproxy.cfg
  haproxy -f /usr/local/etc/haproxy/haproxy.cfg -p $(</var/run/haproxy.pid) -st $(</var/run/haproxy.pid)
done
