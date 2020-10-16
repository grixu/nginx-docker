FROM ubuntu:20.04

LABEL maintainer="Mateusz Gostanski <mg@grixu.dev>"

ARG user_uid=1001
ARG group_gid=1001
ARG port=80

ENV NGINX_VERSION   1.19.3
ENV NPS_VERSION     1.13.35.2-stable
ENV NPS_RELEASE_NUMBER ${NPS_VERSION}/stable/
ENV TZ=Europe/Warsaw

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup --system --gid $group_gid nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid $user_uid nginx
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y gnupg1 ca-certificates \
    && \
    NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
    found=''; \
    for server in \
        ha.pool.sks-keyservers.net \
        hkp://keyserver.ubuntu.com:80 \
        hkp://p80.pool.sks-keyservers.net:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
        apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
    apt-get remove --purge --auto-remove -y gnupg1 && rm -rf /var/lib/apt/lists/* 

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

RUN apt-get update && apt-get install -qy build-essential zlib1g-dev libpcre3 libpcre3-dev unzip uuid-dev wget brotli libbrotli-dev libssl-dev curl libgd-dev procps iputils-ping
RUN apt-get install -qy git

RUN cd && git clone https://github.com/google/ngx_brotli.git

RUN curl -f -L -sS https://ngxpagespeed.com/install > install.sh 
RUN bash install.sh --nginx-version latest \
     -y \
     -a '--add-module=/root/ngx_brotli --sbin-path=/usr/sbin --user=www-data --group=www-data --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_auth_request_module --with-stream --with-stream_ssl_module' \
     || true

RUN cd /root/nginx-${NGINX_VERSION} && make install

COPY h5bp /usr/local/nginx/conf/h5bp
COPY conf.d /usr/local/nginx/conf/conf.d
COPY nginx.conf /usr/local/nginx/conf/nginx.conf

# COPY ./docker-entrypoint.sh /
# RUN mkdir /docker-entrypoint.d
# ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE $port

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
