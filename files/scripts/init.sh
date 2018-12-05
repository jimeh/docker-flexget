#!/bin/sh
set -e

# Timezone setting
if [ -n "${TZ}" ]; then
  echo "$(date '+%Y-%m-%d %H:%m') INIT     Local timezone to ${TZ}"
  echo "${TZ}" > /etc/timezone
  cp /usr/share/zoneinfo/"${TZ}" /etc/localtime
fi

# PUID and PGUID
cd /config || exit

echo "$(date '+%Y-%m-%d %H:%m') INIT     Setting permissions on files/folders inside container"
if [ -n "${PUID}" ] && [ -n "${PGID}" ]; then
  if [ -z "$(getent group "${PGID}")" ]; then
    groupadd -g "${PGID}" flexget
  fi

  if [ -z "$(getent passwd "${PUID}")" ]; then
    useradd -M -s /bin/sh -u "${PUID}" -g "${PGID}" flexget
  fi

  flex_user=$(getent passwd "${PUID}" | cut -d: -f1)
  flex_group=$(getent group "${PGID}" | cut -d: -f1)

  chown -R "${flex_user}":"${flex_group}" /config
  chmod -R 775 /config
fi

# Remove lockfile if exists
if [ -f /config/.config-lock ]; then
  echo "$(date '+%Y-%m-%d %H:%m') INIT     Removing lockfile"
  rm -f /config/.config-lock
fi

# Check if config.yml exists. If not, copy in
if [ -f /config/config.yml ]; then
  echo "$(date '+%Y-%m-%d %H:%m') INIT     Using existing config.yml"
else
  echo "$(date '+%Y-%m-%d %H:%m') INIT     New config.yml from template"
  cp /scripts/config.example.yml /config/config.yml
  if [ -n "$flex_user" ]; then
    chown "${flex_user}":"${flex_group}" /config/config.yml
  fi
fi

# Set FG_WEBUI_PASSWD
if [[ ! -z "${FG_WEBUI_PASSWD}" ]]; then
  echo "$(date '+%Y-%m-%d %H:%m') INIT     Using userdefined FG_WEBUI_PASSWD: ${FG_WEBUI_PASSWD}"
  flexget web passwd "${FG_WEBUI_PASSWD}"
fi

COMMAND="flexget -c /config/config.yml --loglevel info daemon start"
echo "$(date '+%Y-%m-%d %H:%m') INIT     Starting flexget daemon by"
echo "$(date '+%Y-%m-%d %H:%m') INIT     ${COMMAND}"
if [ -n "$flex_user" ]; then
  exec su "${flex_user}" -m -c "${COMMAND}"
else
  exec "${COMMAND}"
fi
