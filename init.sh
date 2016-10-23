#! /usr/bin/env bash
set -e

cd /config || exit

echo "[info] Setting permissions on files/folders inside container..."

if [ -n "${PUID}" ] && [ -n "${PGID}" ]; then
  if [ -z "$(getent group "${PGID}")" ]; then
    groupadd -g "${PGID}" flexget
  fi

  if [ -z "$(getent passwd "${PUID}")" ]; then
    useradd -u "${PUID}" -g "${PGID}" flexget
  fi

  flex_user=$(getent passwd "${PUID}" | cut -d: -f1)
  flex_group=$(getent group "${PGID}" | cut -d: -f1)

  chown -R "${flex_user}":"${flex_group}" /config
  chmod -R 775 /config
fi

# Remove lockfile if exists
if [ -f /config/.config-lock ]; then
  echo "[info] Lockfile found...removing"
  rm -f /config/.config-lock
fi

# Check if config.yml exists. If not, copy in
if [ -f /config/config.yml ]; then
  echo "[info] Using existing config file."
else
  echo "[info] Creating config.yml from template."
  cp /config.example.yml /config/config.yml
  if [ -n "$flex_user" ]; then
    chown "${flex_user}":"${flex_group}" /config/config.yml
  fi
fi

# if FLEXGET_WEBUI_PASSWORD not specified then use default:
# FLEXGET_WEBUI_PASSWORD = flexpass
if [[ -z "${FLEXGET_WEBUI_PASSWORD}" ]]; then
  echo "[info] Using default Flexget-webui password of flexpass"
  FLEXGET_WEBUI_PASSWORD="flexpass"
else
  echo "[info] Using userdefined Flexget-webui password of " \
       "${FLEXGET_WEBUI_PASSWORD}"
fi

# set webui password
flexget web passwd "${FLEXGET_WEBUI_PASSWORD}"

echo "[info] Starting Flexget daemon..."
if [ -n "$flex_user" ]; then
  exec su "${flex_user}" -m -c 'flexget -c /config/config.yml daemon start'
else
  exec flexget -c /config/config.yml daemon start
fi
