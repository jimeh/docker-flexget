FROM ubuntu:16.04
MAINTAINER jimeh

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# define what version of flexget to install
ENV FLEXGET_VERSION 2.5.0

# install everything
ADD install.sh /
RUN chmod +x /install.sh
RUN /install.sh

# add init script
ADD init.sh /
RUN chmod +x /init.sh

# add default config file
ADD config.example.yml /

# used to store flexget config files
VOLUME /config
WORKDIR /config

# use /data in your flexget config.yml file for input/output of files
VOLUME /data

# expose port for flexget webui
EXPOSE 3539

# init script sets uid, gid, permissions and launches flexget
CMD ["/init.sh"]
