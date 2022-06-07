FROM crystallang/crystal:latest-alpine as builder
LABEL stage=builder
WORKDIR /app

RUN apk add sqlite-static
COPY ./bin ./bin
COPY ./db ./db
COPY ./src ./src
COPY ./spec ./spec
COPY ./shard.yml ./shard.lock ./
RUN shards install --production
RUN chmod +x bin/micrate && bin/micrate up
RUN KEMAL_ENV=test bin/micrate up && KEMAL_ENV=test crystal spec
RUN shards build --no-debug --release --production --static --link-flags '-s -w' -v

# Result image with one layer
FROM nginx:alpine
WORKDIR /app
COPY ./public ./public
COPY ./run ./
RUN chmod +x ./run
RUN rm /etc/nginx/conf.d/default.conf
COPY ./feedread-nginx.conf /etc/nginx/conf.d/feedread.conf
COPY --from=builder /app/bin/grab /app/bin/web ./
#COPY --from=builder /app/*.sqlite3 ./
RUN echo $'#!/bin/sh\ncd /app && ./grab -a' > /etc/periodic/15min/grab && chmod a+x /etc/periodic/15min/grab
EXPOSE 80/tcp

CMD ./run
