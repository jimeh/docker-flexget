FROM alpine:3.9
MAINTAINER wiserain

ARG MAKEFLAGS="-j2"
ARG LIBTORRENT_VER=libtorrent-1_1_13

RUN \
	echo "**** install frolvlad/alpine-python3 ****" && \
	apk add --no-cache python3 && \
	python3 -m ensurepip && \
	rm -r /usr/lib/python*/ensurepip && \
	pip3 install --upgrade pip setuptools && \
	if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
	if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
	echo "**** install plugin: telegram ****" && \
	apk add --no-cache py3-cryptography && \
	pip install --upgrade python-telegram-bot && \
	echo "**** install plugins: cfscraper ****" && \
	apk add --no-cache --virtual=build-deps g++ gcc python3-dev && \
	pip install --upgrade cloudscraper && \
	apk del --purge --no-cache build-deps && \
	echo "**** install plugins: convert_magnet ****" && \
	# https://github.com/emmercm/docker-libtorrent/blob/master/Dockerfile
	set -euo pipefail && \
	apk add --no-cache \
		boost-python3 \
		boost-system \
		libgcc \
		libstdc++ \
		openssl && \
	apk add --no-cache --virtual=build-deps \
		autoconf \
		automake \
		boost-dev \
		coreutils \
		file \
		g++ \
		gcc \
		git \
		libtool \
		make \
		openssl-dev \
		python3-dev && \
	cd $(mktemp -d) && \
	git clone https://github.com/arvidn/libtorrent.git && \
	cd libtorrent && \
	git checkout $LIBTORRENT_VER && \
	./autotool.sh && \
	./configure \
		CFLAGS="-Wno-deprecated-declarations" \
	    CXXFLAGS="-Wno-deprecated-declarations" \
	    --prefix=/usr \
	    --disable-debug \
	    --enable-encryption \
	    --enable-python-binding \
	    --with-libiconv \
	    --with-boost-python="$(ls -1 /usr/lib/libboost_python3*-mt.so* | head -1 | sed 's/.*.\/lib\(.*\)\.so.*/\1/')" \
	    PYTHON=`which python3` && \
	make VERBOSE=1 && \
	make install && \
	apk del --purge --no-cache build-deps && \
	# recover missing symlink for python3
	ln -sf /usr/bin/python3 /usr/bin/python && \
	echo "**** install plugin: misc ****" && \
	pip install --upgrade \
		transmissionrpc \
		deluge_client \
		irc_bot && \
	echo "**** install flexget ****" && \
	pip install --upgrade --force-reinstall \
		flexget && \
	echo "**** system configurations ****" && \
	apk --no-cache add shadow tzdata && \
	sed -i 's/^CREATE_MAIL_SPOOL=yes/CREATE_MAIL_SPOOL=no/' /etc/default/useradd && \
	echo "**** cleanup ****" && \
	rm -rf \
		/tmp/* \
		/root/.cache

# copy local files
COPY files/ /

# add default volumes
VOLUME /config /data
WORKDIR /config

# expose port for flexget webui
EXPOSE 3539 3539/tcp

# run init.sh to set uid, gid, permissions and to launch flexget
RUN chmod +x /scripts/init.sh
CMD ["/scripts/init.sh"]
