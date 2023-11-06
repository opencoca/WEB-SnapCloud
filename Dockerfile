FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y lua5.1 liblua5.1-0-dev
RUN apt-get install -y libssl1.1

# Install dependencies for LuaRocks and OpenSSL
RUN apt-get update && \
    apt-get install -y wget build-essential unzip libreadline-dev libncurses5-dev libssl-dev lua5.1 luarocks


# Upgrade LuaRocks
RUN wget https://luarocks.org/releases/luarocks-3.9.2.tar.gz && \
    tar zxpf luarocks-3.9.2.tar.gz && \
    cd luarocks-3.9.2 && \
    ./configure --lua-version=5.1 --versioned-rocks-dir && \
    make && make install && \
    cd .. && rm -rf luarocks-3.9.2.tar.gz luarocks-3.9.2

# Install OpenSSL module
RUN luarocks install openssl

# Install PostgreSQL and create a new database and user
RUN apt-get install -y postgresql postgresql-client postgresql-contrib \
  && service postgresql start \
  && su postgres -c "psql -c \"CREATE USER cloud WITH PASSWORD 'password';\"" \
  && su postgres -c "psql -c \"CREATE DATABASE snapcloud WITH OWNER cloud;\"" 

RUN apt-get install -yf git
RUN apt-get install -y libssl-dev
RUN apt-get install -y build-essential
RUN apt-get install -y authbind
RUN apt-get install -y lsb-core
RUN apt-get -y install --no-install-recommends wget gnupg ca-certificates
RUN wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN echo "deb http://openresty.org/package/arm64/ubuntu $(lsb_release -sc) main" > openresty.list
RUN cp openresty.list /etc/apt/sources.list.d/
RUN apt-get update
RUN apt-get -y install --no-install-recommends openresty
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

COPY . /app

RUN luarocks install argparse
RUN luarocks install lub
RUN luarocks install openssl
RUN ln -s /usr/lib/aarch64-linux-gnu /usr/lib/x86_64-linux-gnu

#CMD ["/bin/bash"]

RUN git config --global url."https://".insteadOf git://

RUN luarocks install /app/snapcloud-dev-0.rockspec

RUN mkdir keys
RUN cd /keys \
  &&openssl genrsa > privkey.pem  \
  && openssl req -new -x509 -key privkey.pem > fullchain.pem -batch \
  && ln -s /keys /app/certs/cloud.snap.berkeley.edu  \
  && ln -s /keys /app/certs/snap.berkeley.edu \
  && ln -s /keys /app/certs/snap-cloud.cs10.org

RUN cd /app/certs/ \
  && openssl dhparam -out dhparams.pem 1024 -batch \
  && openssl dhparam -out dhparam.cert 1024 -batch

RUN service postgresql start \
  && su postgres -c "psql -d snapcloud -a -f /app/cloud.sql"

EXPOSE 8080
ENV PORT=8080

CMD ["/app/start.sh"]
