FROM crystallang/crystal:latest-alpine as builder
LABEL stage=builder
WORKDIR /app

RUN apk add sqlite-static
COPY ./bin ./bin
COPY ./db ./db
COPY ./src ./src
COPY ./spec ./spec
COPY ./public/index.html ./public/index.html
COPY ./shard.yml ./shard.lock ./
RUN shards install --production
RUN chmod +x bin/micrate && bin/micrate up
RUN KEMAL_ENV=test bin/micrate up
RUN KEMAL_ENV=test crystal spec
RUN shards build --no-debug --release --production --static --link-flags '-s -w' -v

# Result image with one layer
FROM alpine:latest

WORKDIR /app
COPY ./public ./public
COPY ./run ./
RUN chmod +x ./run
COPY --from=builder /app/bin/grab /app/bin/web ./
COPY --from=builder /app/*.sqlite3 ./
RUN echo $'#!/bin/sh\ncd /app && ./grab -a' > /etc/periodic/15min/grab_all && chmod a+x /etc/periodic/15min/grab_all \
    && echo $'#!/bin/sh\ncd /app && ./grab -p 100' > /etc/periodic/weekly/grab_prune && chmod a+x /etc/periodic/weekly/grab_prune
EXPOSE 80/tcp

CMD ./run
