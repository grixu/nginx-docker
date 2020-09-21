FROM ubuntu:20.04

LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

ENV NGINX_VERSION   1.19.2
ENV NPS_VERSION     1.13.35.2-stable

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup --system --gid 1001 nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 1001 nginx \
    && apt-get update \
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

RUN cd \
wget -O- https://github.com/apache/incubator-pagespeed-ngx/archive/v${NPS_VERSION}.tar.gz | tar -xz \
nps_dir=$(find . -name "*pagespeed-ngx-${NPS_VERSION}" -type d) \
cd "$nps_dir" \
NPS_RELEASE_NUMBER=${NPS_VERSION/beta/} \
NPS_RELEASE_NUMBER=${NPS_VERSION/stable/} \
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz \
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh P SOL_BINARY_URL) \
wget -O- ${psol_url} | tar -xz;

#[check nginx's site for the latest version]
RUN cd \
wget -O- http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -xz \
cd nginx-${NGINX_VERSION}/ \
./configure --add-module=$HOME/$nps_dir ${PS_NGX_EXTRA_FLAGS} \ 
make \
sudo make install;


RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
# create a docker-entrypoint.d directory
    && mkdir /docker-entrypoint.d

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
