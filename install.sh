#! /usr/bin/env bash
set -e

apt-get update

# install runtime dependencies
apt-get install -y \
        python2.7 \
        python-pip \
        deluge-common \
        python-libtorrent

# install build-time dependencies
apt-get install -y \
        build-essential \
        python-dev \
        libyaml-dev \
        libpython2.7-dev

pip install --upgrade pip
pip install --upgrade --force-reinstall \
    setuptools \
    requests \
    transmissionrpc \
    cfscrape \
    "flexget==${FLEXGET_VERSION}"

apt-get remove -y \
        build-essential \
        python-dev \
        libyaml-dev \
        libpython2.7-dev

apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
