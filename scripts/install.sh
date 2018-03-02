#!/usr/bin/env bash
set -x
VERSION=$1
CONFIG="\
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-http_xslt_module=shared \
	--with-http_image_filter_module=shared \
	--with-http_geoip_module=shared \
	--with-threads \
	--with-http_slice_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-file-aio \
	--with-http_v2_module \
	--with-http_concat_module \
	--with-http_sysguard_module \
	--with-http_dyups_module \
	"
addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		linux-headers \
		curl \
		gnupg \
		libxslt-dev \
		gd-dev \
		geoip-dev;

curl -L "http://tengine.taobao.org/download/tengine-$VERSION.tar.gz" -o tengine.tar.gz \
&& mkdir -p /usr/src \
&& tar  xfz  tengine.tar.gz -C /usr/src \
&& rm tengine.tar.gz \
&& cd /usr/src/tengine-${VERSION}/ \
&& ./configure ${CONFIG} --with-debug \
&& make -j$(getconf _NPROCESSORS_ONLN) \
&& mv objs/nginx objs/nginx-debug \
&& ./configure ${CONFIG} \
&& make -j$(getconf _NPROCESSORS_ONLN) \
&& make install \
&& rm -rf /etc/nginx/html/ \
&& mkdir /etc/nginx/conf.d/ \
&& mkdir -p /usr/share/nginx/html/ \
&& install -m644 html/index.html /usr/share/nginx/html/ \
&& install -m644 html/50x.html /usr/share/nginx/html/ \
&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
&& strip /usr/sbin/nginx* \
&& strip /etc/nginx/modules/*.so \
&& rm -rf /usr/src/tengine-${VERSION} \
&& apk add --no-cache --virtual .gettext gettext \
&& mv /usr/bin/envsubst /tmp/ \
\
&& runDeps="$( \
    scanelf --needed --nobanner /usr/sbin/nginx /etc/nginx/modules/*.so /tmp/envsubst \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
)" \
&& apk add --no-cache --virtual .nginx-rundeps $runDeps \
&& apk del .build-deps \
&& apk del .gettext \
&& mv /tmp/envsubst /usr/local/bin/\
&& ln -sf /dev/stdout /var/log/nginx/access.log \
&& ln -sf /dev/stderr /var/log/nginx/error.log

#CMD ["nginx", "-g", "daemon off;"]
