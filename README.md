# docker-flexget

docker container for running [flexget](http://flexget.com/)

container features:

- based on lightweight alpine linux
- python3
- transmissionrpc, python-telegram-bot
- flexget with initial settings (default config.yml and webui password)

## Usage

```
docker run -d \
    --name=<container name> \
    -p 3539:3539 \
    -v <path for data files>:/data \
    -v <path for config files>:/config \
    -e FG_WEBUI_PASSWD=<desired password> \
    -e PUID=<UID for user> \
    -e PGID=<GID for user> \
    -e TZ=<timezone> \
    wiserain/flexget
```
