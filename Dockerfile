FROM alpine:3.5
MAINTAINER wiserain

# define what version of flexget to install
ENV FG_VERSION 2.8.14

# install frolvlad/alpine-python3
RUN apk add --no-cache python3 && \ 
	python3 -m ensurepip && \ 
	rm -r /usr/lib/python*/ensurepip && \ 
	pip3 install --upgrade pip setuptools && \ 
	rm -r /root/.cache

# install flexget
RUN apk --no-cache add ca-certificates tzdata && \ 
	pip3 install --upgrade --force-reinstall --ignore-installed \
		transmissionrpc python-telegram-bot "flexget==${FG_VERSION}" && \
	rm -r /root/.cache

# add init.sh
RUN mkdir /scripts
ADD init.sh /scripts/init.sh
RUN chmod +x /scripts/init.sh

# add default config.yml
RUN mkdir /templates
ADD config.example.yml /templates/

# add default volumes
VOLUME /config /data
WORKDIR /config

# expose port for flexget webui
EXPOSE 3539 3539/tcp

# run init.sh to set uid, gid, permissions and to launch flexget
CMD ["/scripts/init.sh"]
