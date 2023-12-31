FROM openco/snapcloud-develop:latest-prerequisites

ENV DEBIAN_FRONTEND noninteractive

# Add canonical snap store
COPY ./store /app/store
# Add canonical database
COPY snapcloud.sql /app/bin/snapcloud.sql

RUN service postgresql start \
  && su postgres -c "dropdb snapcloud" \
  && su postgres -c "createdb snapcloud" \
  && su postgres -c "psql -c \"ALTER USER cloud WITH SUPERUSER;\"" \
  && su postgres -c "psql -d snapcloud -f /app/bin/snapcloud.sql"
# env file for snap cloud
COPY env.sh /app/.env

COPY . /app

RUN chmod -R 777 /app/store

EXPOSE 80
ENV PORT=80

CMD ["/app/start.sh"]
