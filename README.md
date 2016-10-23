# jimeh/flexget

Simple Docker container for running [Flexget](http://flexget.com/).

Some features:

- `convert_magnet` plugin works without missing libtorrent or boost errors.
- `deluge` plugin works.
- `transmission` plugin should work (untested).

## Usage

```
docker run -d \
    --name=<container name> \
    -p 3539:3539 \
    -v <path for data files>:/data \
    -v <path for config files>:/config \
    -e FLEXGET_WEBUI_PASSWORD=<desired password> \
    -e PUID=<UID for user> \
    -e PGID=<GID for user> \
    jimeh/flexget
```
