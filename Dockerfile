#
# Golang dependencies build step
#
FROM golang:1-bullseye AS go-dependencies

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl git

RUN go install github.com/jwilder/dockerize@v0.6.1

RUN go install github.com/aptible/supercronic@v0.2.1

RUN go install github.com/centrifugal/centrifugo/v4@v4.0.5

#
# Final build image
#
FROM mariadb:10.9-jammy

ENV TZ="UTC"

# Add Dockerize
COPY --from=go-dependencies /go/bin/dockerize /usr/local/bin
COPY --from=go-dependencies /go/bin/supercronic /usr/local/bin/supercronic
COPY --from=go-dependencies /go/bin/centrifugo /usr/local/bin/centrifugo

# Run base build process
COPY ./util/docker/common /bd_build/
RUN chmod a+x /bd_build/*.sh \
    && /bd_build/prepare.sh \
    && /bd_build/add_user.sh \
    && /bd_build/cleanup.sh \
    && rm -rf /bd_build

# Build each set of dependencies in their own step for cacheability.
ARG ARM_FULL_BUILD

COPY ./util/docker/supervisor /bd_build/supervisor/
RUN bash /bd_build/supervisor/setup.sh \
    && rm -rf /bd_build/supervisor

COPY ./util/docker/stations /bd_build/stations/
RUN bash /bd_build/stations/setup.sh \
    && rm -rf /bd_build/stations

COPY ./util/docker/web /bd_build/web/
RUN bash /bd_build/web/setup.sh \
    && rm -rf /bd_build/web

COPY ./util/docker/mariadb /bd_build/mariadb/
RUN bash /bd_build/mariadb/setup.sh \
    && rm -rf /bd_build/mariadb

COPY ./util/docker/redis /bd_build/redis/
RUN bash /bd_build/redis/setup.sh \
    && rm -rf /bd_build/redis

#
# START Operations as `azuracast` user
#
USER azuracast

WORKDIR /var/azuracast/www

COPY --chown=azuracast:azuracast ./composer.json ./composer.lock ./
RUN composer install \
    --no-dev \
    --no-ansi \
    --no-autoloader \
    --no-interaction

COPY --chown=azuracast:azuracast . .

RUN composer dump-autoload --optimize --classmap-authoritative \
    && touch /var/azuracast/.docker

VOLUME ["/var/azuracast/stations", "/var/azuracast/uploads", "/var/azuracast/backups", "/var/azuracast/sftpgo/persist", "/var/azuracast/servers/shoutcast2"]
ENV PATH="${PATH}:/var/azuracast/servers/shoutcast2"

#
# END Operations as `azuracast` user
#
USER root

EXPOSE 80 2022
EXPOSE 8000-8999

# Sensible default environment variables.
ENV LANG="en_US.UTF-8" \
    DOCKER_IS_STANDALONE="true" \
    APPLICATION_ENV="production" \
    MYSQL_HOST="localhost" \
    MYSQL_PORT=3306 \
    MYSQL_USER="azuracast" \
    MYSQL_PASSWORD="azur4c457" \
    MYSQL_DATABASE="azuracast" \
    ENABLE_REDIS="true" \
    REDIS_HOST="localhost" \
    REDIS_PORT=6379 \
    REDIS_DB=1 \
    NGINX_RADIO_PORTS="default" \
    NGINX_WEBDJ_PORTS="default" \
    PREFER_RELEASE_BUILDS="false" \
    COMPOSER_PLUGIN_MODE="false" \
    ADDITIONAL_MEDIA_SYNC_WORKER_COUNT=0 \
    PROFILING_EXTENSION_ENABLED=0 \
    PROFILING_EXTENSION_ALWAYS_ON=0 \
    PROFILING_EXTENSION_HTTP_KEY=dev \
    PROFILING_EXTENSION_HTTP_IP_WHITELIST=* \
    ENABLE_WEB_UPDATER="true"

# Entrypoint and default command
ENTRYPOINT ["tini", "--", "/usr/local/bin/my_init"]
CMD ["--no-main-command"]
