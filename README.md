# docker-flexget

docker container for [flexget](http://flexget.com/)

container features are

- lightweight alpine linux
- python3
- flexget with initial settings (default config.yml and webui password)
- built-in plug-ins (transmissionrpc, python-telegram-bot)

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
