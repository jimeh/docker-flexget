#!/bin/sh
set -e

log_prefix() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') INIT    "
}

# Timezone setting
if [ -n "${TZ}" ]; then
  echo "$(log_prefix) Local timezone to '${TZ}'"
  echo "${TZ}" > /etc/timezone
  cp /usr/share/zoneinfo/"${TZ}" /etc/localtime
fi

# make folders
mkdir -p \
  /config \
  /data

# handling PUID and PGID
if [ -n "${PUID}" ] && [ -n "${PGID}" ]; then
  if [ -z "$(getent group "${PGID}")" ]; then
    groupadd -g "${PGID}" flexget
  fi

  if [ -z "$(getent passwd "${PUID}")" ]; then
    useradd -M -s /bin/sh -u "${PUID}" -g "${PGID}" flexget
  fi

  flexget_user=$(getent passwd "${PUID}" | cut -d: -f1)
  flexget_group=$(getent group "${PGID}" | cut -d: -f1)
  echo "$(log_prefix) Added user '"${flexget_user}":"${flexget_user}"' matching with a given '${PUID}:${PGID}'"
fi

# Remove lockfile if exists
if [ -f /config/.config-lock ]; then
  echo "$(log_prefix) Removing lockfile"
  rm -f /config/.config-lock
fi

# Check if config.yml exists. If not, copy in
if [ -f /config/config.yml ]; then
  echo "$(log_prefix) Using existing config.yml"
else
  echo "$(log_prefix) New config.yml from template"
  cp /scripts/config.example.yml /config/config.yml
  if [ -n "$flexget_user" ]; then
    chown "${flexget_user}":"${flexget_group}" /config/config.yml
  fi
fi

# Set FG_WEBUI_PASSWD
if [[ ! -z "${FG_WEBUI_PASSWD}" ]]; then
  echo "$(log_prefix) Setting flexget web password to '${FG_WEBUI_PASSWD}'"
  echo "$(log_prefix) `flexget web passwd "${FG_WEBUI_PASSWD}"`"
fi

if [ -n "$flexget_user" ]; then
  echo "$(log_prefix) Fixing permissions on files/folders"
  chown -R "${flexget_user}":"${flexget_group}" /config
  chmod -R 775 /config
  chown "${flexget_user}":"${flexget_group}" /data
  chmod 775 /data
fi

echo "$(log_prefix) Starting flexget v$(flexget -V | sed -n 1p) by executing"
flexget_command="flexget -c /config/config.yml --loglevel ${FG_LOG_LEVEL:-info} daemon start --autoreload-config"
echo "$(log_prefix) $flexget_command"
if [ -n "$flexget_user" ]; then
  exec su "${flexget_user}" -m -c "${flexget_command}"
else
  exec $flexget_command
fi
