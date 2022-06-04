FROM crystallang/crystal:latest-alpine as builder
LABEL stage=builder
WORKDIR /app

RUN apk update && apk add sqlite-static
COPY ./bin ./bin
COPY ./db ./db
COPY ./src ./src
COPY ./shard.yml ./shard.lock ./
RUN shards install --production
RUN shards build --no-debug --release --production --static -v
RUN chmod +x bin/micrate && bin/micrate up

# Result image with one layer
FROM nginx:alpine
WORKDIR /app
COPY ./public ./public
COPY ./run ./
RUN chmod +x ./run
RUN rm /etc/nginx/conf.d/default.conf
COPY ./feedread-nginx.conf /etc/nginx/conf.d/feedread.conf
COPY --from=builder /app/bin/grab /app/bin/web ./
COPY --from=builder /app/*.sqlite3 ./
RUN echo $'#!/bin/sh\ncd /app && ./grab -a' > /etc/periodic/15min/grab && chmod +x /etc/periodic/15min/grab
EXPOSE 80/tcp

CMD ./run
