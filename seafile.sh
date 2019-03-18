#!/bin/bash
trap '/opt/seafile/seafile-server-latest/seafile.sh stop' EXIT
/opt/seafile/seafile-server-latest/seafile.sh start
tail -f /opt/seafile/logs/seafile.log