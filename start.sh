#!/bin/bash
source /app/.env

service postgresql start &

chmod -R 777 /app/store

cd /app/ \
  && . .env \
  && lapis server $LAPIS_ENVIRONMENT --trace &

sleep infinity

wait -n

# Exit with status of process that exited first
exit $?
