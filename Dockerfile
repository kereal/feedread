FROM alpine:edge as builder
LABEL stage=builder

WORKDIR /app
RUN apk add crystal shards nodejs npm sqlite-static sqlite-dev zlib-static libxml2-dev openssl-dev openssl-libs-static
# frontend
COPY ./frontend ./frontend
RUN cd frontend && npm i && npm run build && mkdir ../public && mv dist/* ../public && cd ..
# backend
COPY ./bin ./bin
COPY ./db ./db
COPY ./src ./src
COPY ./spec ./spec
COPY ./shard.yml ./shard.lock ./
RUN shards install --production
RUN KEMAL_ENV=test crystal spec
RUN shards build --no-debug --release --production --static --link-flags '-s -w' -v

# Result image
FROM alpine:edge

WORKDIR /app
COPY ./run ./
RUN chmod +x ./run
COPY --from=builder /app/public ./public
COPY --from=builder /app/bin/grab /app/bin/web ./
COPY --from=builder /app/db ./db
RUN echo $'#!/bin/sh\ncd /app && ./grab -a' > /etc/periodic/15min/grab_all && chmod a+x /etc/periodic/15min/grab_all \
    && echo $'#!/bin/sh\ncd /app && ./grab -p 100' > /etc/periodic/weekly/grab_prune && chmod a+x /etc/periodic/weekly/grab_prune
EXPOSE 80/tcp

CMD ./run
