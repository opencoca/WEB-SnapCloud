FROM openco/snapcloud-develop:manifest-latest

ENV DEBIAN_FRONTEND noninteractive

COPY . /app

# add an empty store dir to /app and allow all to write to it
RUN mkdir -p /app/store \
  && chmod 777 /app/store

# env file for snap cloud
COPY env.sh /app/.env

EXPOSE 8080
ENV PORT=8080

CMD ["/app/start.sh"]
