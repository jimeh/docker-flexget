#! /usr/bin/env bash

cd /config || exit

echo "[info] Setting permissions on files/folders inside container..."
chown -R "${PUID}":"${PGID}" /config
chmod -R 775 /config

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
  chown "${PUID}":"${PGID}" /config/config.yml
fi

# if FLEXGET_WEBUI_PASSWORD not specified then use default FLEXGET_WEBUI_PASSWORD = flexpass
if [[ -z "${FLEXGET_WEBUI_PASSWORD}" ]]; then
  echo "[info] Using default Flexget-webui password of flexpass"
  FLEXGET_WEBUI_PASSWORD="flexpass"
else
  echo "[info] Using userdefined Flexget-webui password of " "${FLEXGET_WEBUI_PASSWORD}"
fi

# set webui password
flexget web passwd "${FLEXGET_WEBUI_PASSWORD}"

echo "[info] Starting Flexget daemon..."
exec flexget -c /config/config.yml daemon start
