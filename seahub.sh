#!/bin/bash
trap '/opt/seafile/seafile-server-latest/seahub.sh stop' EXIT
/opt/seafile/seafile-server-latest/seahub.sh start
tail -f /opt/seafile/logs/seahub.log