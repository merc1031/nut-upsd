FROM alpine:3.12

LABEL maintainer="docker@upshift.fr"

ENV NUT_VERSION 2d5423bf87b407a304c32813bdb0bcde7df6d7f8

ENV UPS_NAME="ups"
ENV UPS_DESC="UPS"
ENV UPS_DRIVER="usbhid-ups"
ENV UPS_PORT="auto"

ENV API_PASSWORD=""
ENV ADMIN_PASSWORD=""

ENV SHUTDOWN_CMD="echo 'System shutdown not configured!'"

RUN set -ex; \
	# run dependencies
	apk add --no-cache \
		openssh-client \
		libusb-compat \
	; \
	# build dependencies
	apk add --no-cache --virtual .build-deps \
		libusb-compat-dev \
		build-base \
		python3 \
		perl \
		autoconf \
		automake \
		libtool \
		pkgconfig \
	; \
	ln -sf python3 /usr/bin/python; \
	# download and extract
	cd /tmp; \
	wget https://github.com/networkupstools/nut/tarball/${NUT_VERSION} -O nut-${NUT_VERSION}.tar.gz; \
	tar xfz nut-$NUT_VERSION.tar.gz; \
	ls; \
	cd networkupstools-nut-$(echo $NUT_VERSION | cut -c-7) \
	; \
	# build
	./autogen.sh; \
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc/nut \
		--disable-dependency-tracking \
		--enable-strip \
		--enable-static \
		--with-all=no \
		--with-usb=yes \
		--datadir=/usr/share/nut \
		--with-drvpath=/usr/share/nut \
		--with-statepath=/var/run/nut \
		--with-user=nut \
		--with-group=nut \
		--enable-maintainer-mode \
		--srcdir=. \
	; \
	# install
	make \
	; \
	make install \
	; \
	# create nut user
	adduser -D -h /var/run/nut nut; \
	chgrp -R nut /etc/nut; \
	chmod -R o-rwx /etc/nut; \
	install -d -m 750 -o nut -g nut /var/run/nut \
	; \
	# cleanup
	rm -rf /tmp/nut-$NUT_VERSION.tar.gz /tmp/nut-$NUT_VERSION; \
	apk del .build-deps

COPY src/docker-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-entrypoint"]

WORKDIR /var/run/nut

EXPOSE 3493
