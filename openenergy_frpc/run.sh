#!/usr/bin/with-contenv bashio
set -euo pipefail

# -----------------------------------------------------------------------------
# OpenEnergy FRP Client add-on entrypoint
# - Reads configuration from Supervisor (options.json) via bashio
# - Generates /data/frpc.toml
# - Starts frpc
# -----------------------------------------------------------------------------

SERVER_ADDR="$(bashio::config 'server_addr')"
SERVER_PORT="$(bashio::config 'server_port')"
TLS_ENABLE="$(bashio::config 'tls_enable')"

HA_UUID="$(bashio::config 'ha_uuid')"
DEVICE_SECRET="$(bashio::config 'device_secret')"

TUNNEL_DOMAIN="$(bashio::config 'tunnel_domain')"
LOCAL_IP="$(bashio::config 'local_ip')"
LOCAL_PORT="$(bashio::config 'local_port')"

if [[ -z "${SERVER_ADDR}" ]]; then bashio::log.fatal "Missing option: server_addr"; exit 1; fi
if [[ -z "${HA_UUID}" ]]; then bashio::log.fatal "Missing option: ha_uuid"; exit 1; fi
if [[ -z "${DEVICE_SECRET}" ]]; then bashio::log.fatal "Missing option: device_secret"; exit 1; fi
if [[ -z "${TUNNEL_DOMAIN}" ]]; then bashio::log.fatal "Missing option: tunnel_domain"; exit 1; fi

umask 077
CFG="/data/frpc.toml"

cat > "${CFG}" <<EOF
serverAddr = "${SERVER_ADDR}"
serverPort = ${SERVER_PORT}

transport.tls.enable = ${TLS_ENABLE}

user = "${HA_UUID}"
metadatas.token = "${DEVICE_SECRET}"

[[proxies]]
name = "ha-ui"
type = "http"
localIP = "${LOCAL_IP}"
localPort = ${LOCAL_PORT}
customDomains = ["${TUNNEL_DOMAIN}"]
EOF

bashio::log.info "Starting frpc"
exec frpc -c "${CFG}"

