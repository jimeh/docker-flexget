FROM ubuntu:16.04
MAINTAINER jimeh

RUN locale-gen en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# make executable and run bash scripts to install app
RUN apt-get update && apt-get install -y \
    python2.7 \
    python-pip \
    build-essential \
    python-dev \
    libyaml-dev \
    libpython2.7-dev \
    deluge \
 && rm -rf /var/lib/apt/lists/*

# define what version of flexget to install
ENV FLEXGET_VERSION 2.5.1

RUN pip install --upgrade pip && pip install --upgrade --force-reinstall \
    setuptools \
    requests \
    transmissionrpc \
    cfscrape \
    "flexget==${FLEXGET_VERSION}"

# add init script
ADD init.sh /

# make scripts executable
RUN chmod +x /init.sh

# add default config file for nobody
ADD config.example.yml /

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /data to host defined data path (used to store data from app)
VOLUME /data

# expose port for flexget webui
EXPOSE 3539

# run script to set uid, gid and permissions
CMD ["/init.sh"]
