FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
  && apt-get install -y lua5.1 \
  && apt-get install -y luarocks

# Install PostgreSQL and create a new database and user
RUN apt-get install -y postgresql  postgresql-client postgresql-contrib \
  && service postgresql start \
  && su postgres -c "psql -c \"CREATE USER snapcloud WITH PASSWORD 'r0b0t1n4c4n';\"" \
  && su postgres -c "psql -c \"CREATE DATABASE snapcloud WITH OWNER snapcloud;\"" 

RUN apt-get install -y git \
  && apt-get install -y libssl-dev \
  && apt-get install -y build-essential \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY . /app

RUN luarocks install /app/snap-cloud-beta-0.rockspec

CMD ["lua"]
