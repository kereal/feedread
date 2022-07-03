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
RUN KEMAL_ENV=test bin/micrate up
RUN KEMAL_ENV=test crystal spec
RUN shards build --no-debug --release --production --static --link-flags '-s -w' -v

# Result image with one layer
FROM alpine:latest
ENV NGINX_VERSION 1.21.6
ENV NJS_VERSION   0.7.3
ENV PKG_RELEASE   1
RUN set -x \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apkArch="$(cat /etc/apk/arch)" \
    && nginxPackages="nginx=${NGINX_VERSION}-r${PKG_RELEASE}" \
    && apk add --no-cache --virtual .checksum-deps openssl \
    && case "$apkArch" in \
        x86_64|aarch64) \
            set -x \
            && KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
            && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
            && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
                echo "key verification succeeded!"; \
                mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
            else \
                echo "key verification failed!"; \
                exit 1; \
            fi \
            && apk add -X "https://nginx.org/packages/mainline/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages \
            ;; \
        *) \
            set -x \
            && tempDir="$(mktemp -d)" \
            && chown nobody:nobody $tempDir \
            && apk add --no-cache --virtual .build-deps \
                gcc libc-dev make openssl-dev pcre2-dev zlib-dev \
                linux-headers libxslt-dev libedit-dev bash alpine-sdk findutils \
            && su nobody -s /bin/sh -c " \
                export HOME=${tempDir} \
                && cd ${tempDir} \
                && curl -f -O https://hg.nginx.org/pkg-oss/archive/688.tar.gz \
                && PKGOSSCHECKSUM=\"a8ab6ff80ab67c6c9567a9103b52a42a5962e9c1bc7091b7710aaf553a3b484af61b0797dd9b048c518e371a6f69e34d474cfaaeaa116fd2824bffa1cd9d4718 *688.tar.gz\" \
                && if [ \"\$(openssl sha512 -r 688.tar.gz)\" = \"\$PKGOSSCHECKSUM\" ]; then \
                    echo \"pkg-oss tarball checksum verification succeeded!\"; \
                else \
                    echo \"pkg-oss tarball checksum verification failed!\"; \
                    exit 1; \
                fi \
                && tar xzvf 688.tar.gz && cd pkg-oss-688 && cd alpine && make all \
                && apk index -o ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz ${tempDir}/packages/alpine/${apkArch}/*.apk \
                && abuild-sign -k ${tempDir}/.abuild/abuild-key.rsa ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz \
                " \
            && cp ${tempDir}/.abuild/abuild-key.rsa.pub /etc/apk/keys/ \
            && apk del .build-deps \
            && apk add -X ${tempDir}/packages/alpine/ --no-cache $nginxPackages \
            ;; \
    esac \
    && apk del .checksum-deps \
    && if [ -n "$tempDir" ]; then rm -rf "$tempDir"; fi \
    && if [ -n "/etc/apk/keys/abuild-key.rsa.pub" ]; then rm -f /etc/apk/keys/abuild-key.rsa.pub; fi \
    && if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | sort -u | xargs -r apk info --installed | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && apk del libintl libc-utils \
    && mv /tmp/envsubst /usr/local/bin/ \
    && apk add --no-cache tzdata \
    && apk add --no-cache curl ca-certificates \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log


WORKDIR /app
COPY ./public ./public
COPY ./run ./
RUN chmod +x ./run
RUN rm /etc/nginx/conf.d/default.conf
COPY ./feedread-nginx.conf /etc/nginx/conf.d/feedread.conf
COPY --from=builder /app/bin/grab /app/bin/web ./
COPY --from=builder /app/*.sqlite3 ./
RUN echo $'#!/bin/sh\ncd /app && ./grab -a' > /etc/periodic/15min/grab && chmod a+x /etc/periodic/15min/grab
RUN ln -sf /dev/stdout /app/grab.log
EXPOSE 80/tcp

CMD ./run
