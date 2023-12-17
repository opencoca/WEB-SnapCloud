#!/bin/bash
source /app/.env

service postgresql start &

cd /app/ \
  && . .env \
  && echo $PORT \
  && lapis server $LAPIS_ENVIRONMENT --trace &

sleep infinity

wait -n

# Exit with status of process that exited first
exit $?
