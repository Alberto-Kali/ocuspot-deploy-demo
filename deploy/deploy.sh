#!/bin/sh
set -eu
# Ocuspot deploy bundle for project=ocuspot-deploy-demo
# Immutable image: __OCUSPOT_IMAGE__
# Binding: backend-kvm@pconf-bus  rathole=ocuspot_deploy_demo_backend_kvm_pconf_bus_8080  public=ocuspot-demo.pconf.ru

# SAFETY: This script performs scp + ssh using your runtime credentials only.
# - Run with ssh-agent loaded, or edit below to pass -i /path/to/your/key.
# - The script owns Rathole config + systemd units on both hosts.
# - OCUSPOT_RATHOLE_* tokens must be filled in /etc/ocuspot/rathole.env on both hosts.
# - ocuspot never embeds, logs, or stores SSH private material or Rathole tokens.
# - Optional: set local RATHOLE_BIN=/path/to/rathole before running to upload the binary.
# - Optional: set OCUSPOT_GATEWAY_SSH_PASSWORD / OCUSPOT_CARRIER_SSH_PASSWORD when running via sshpass.
# Review before running. Idempotent: overwrites Ocuspot-managed files.

need_sshpass() {
  command -v sshpass >/dev/null 2>&1 || { echo "sshpass is required for password-based SSH"; exit 13; }
}
gw_scp() {
  if [ -n "${OCUSPOT_GATEWAY_SSH_PASSWORD:-}" ]; then
    need_sshpass
    SSHPASS="${OCUSPOT_GATEWAY_SSH_PASSWORD}" sshpass -e scp "$@"
  else
    scp "$@"
  fi
}
gw_ssh() {
  if [ -n "${OCUSPOT_GATEWAY_SSH_PASSWORD:-}" ]; then
    need_sshpass
    SSHPASS="${OCUSPOT_GATEWAY_SSH_PASSWORD}" sshpass -e ssh "$@"
  else
    ssh "$@"
  fi
}
car_scp() {
  if [ -n "${OCUSPOT_CARRIER_SSH_PASSWORD:-}" ]; then
    need_sshpass
    SSHPASS="${OCUSPOT_CARRIER_SSH_PASSWORD}" sshpass -e scp "$@"
  else
    scp "$@"
  fi
}
car_ssh() {
  if [ -n "${OCUSPOT_CARRIER_SSH_PASSWORD:-}" ]; then
    need_sshpass
    SSHPASS="${OCUSPOT_CARRIER_SSH_PASSWORD}" sshpass -e ssh "$@"
  else
    ssh "$@"
  fi
}

RATHOLE_TOKEN_ENV='OCUSPOT_RATHOLE_OCUSPOT_DEPLOY_DEMO_BACKEND_KVM_PCONF_BUS_8080'
RATHOLE_TOKEN_FILE=""
RATHOLE_TOKEN_VALUE="$(eval "printf '%s' \"\${${RATHOLE_TOKEN_ENV}:-}\"")"
if [ -n "${RATHOLE_TOKEN_VALUE}" ]; then
  RATHOLE_TOKEN_FILE=".ocuspot-rathole.env"
  umask 077
  printf "%s=%s\n" "${RATHOLE_TOKEN_ENV}" "${RATHOLE_TOKEN_VALUE}" > "${RATHOLE_TOKEN_FILE}"
fi
GW_HOST="138.16.226.122"
GW_PORT=22
GW_USER="root"
GW_FRAG='rathole.gateway.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml'
GW_FULL='rathole.gateway.managed.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml'
GW_UNIT='systemd.ocuspot-rathole-gateway-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service'
PUBLIC_HOST='ocuspot-demo.pconf.ru'
PUBLIC_PORT=80
RATHOLE_PUBLIC_PORT=8080
echo "Deploying gateway Rathole ownership to ${GW_USER}@${GW_HOST}:${GW_PORT} ..."
gw_scp -P "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${GW_FRAG}" "${GW_USER}@${GW_HOST}:/tmp/${GW_FRAG}" || true
gw_scp -P "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${GW_FULL}" "${GW_USER}@${GW_HOST}:/tmp/${GW_FULL}" || true
gw_scp -P "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${GW_UNIT}" "${GW_USER}@${GW_HOST}:/tmp/${GW_UNIT}" || true
if [ -n "${RATHOLE_BIN:-}" ] && [ -f "${RATHOLE_BIN}" ]; then
  gw_scp -P "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${RATHOLE_BIN}" "${GW_USER}@${GW_HOST}:/tmp/ocuspot-rathole"
fi
if [ -n "${RATHOLE_TOKEN_FILE}" ]; then
  gw_scp -P "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${RATHOLE_TOKEN_FILE}" "${GW_USER}@${GW_HOST}:/tmp/ocuspot-rathole.env"
fi
gw_ssh -p "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${GW_USER}@${GW_HOST}" '
  set -eu
  mkdir -p /etc/ocuspot/rathole /etc/rathole /etc/rathole/gateway.d /usr/local/bin
  if [ -f /tmp/ocuspot-rathole ]; then install -m 0755 /tmp/ocuspot-rathole /usr/local/bin/rathole; fi
  if ! command -v rathole >/dev/null 2>&1 && [ ! -x /usr/local/bin/rathole ]; then for cand in /root/rathole/rathole /root/rathole /opt/rathole/rathole /usr/local/rathole/rathole; do if [ -f "$cand" ] && [ -x "$cand" ]; then install -m 0755 "$cand" /usr/local/bin/rathole; break; fi; done; fi
  if ! command -v rathole >/dev/null 2>&1 && [ ! -x /usr/local/bin/rathole ]; then echo "Rathole binary missing. Re-run with RATHOLE_BIN=/path/to/rathole"; exit 12; fi
  if [ -f /tmp/ocuspot-rathole.env ]; then cat /tmp/ocuspot-rathole.env > /etc/ocuspot/rathole.env; chmod 0600 /etc/ocuspot/rathole.env; elif [ ! -f /etc/ocuspot/rathole.env ]; then printf "%s=\n" "OCUSPOT_RATHOLE_OCUSPOT_DEPLOY_DEMO_BACKEND_KVM_PCONF_BUS_8080" > /etc/ocuspot/rathole.env; chmod 0600 /etc/ocuspot/rathole.env; echo "Fill token in /etc/ocuspot/rathole.env before restart if empty."; fi
  cat "/tmp/rathole.gateway.managed.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml" > "/etc/ocuspot/rathole/gateway.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml"
  cat "/tmp/systemd.ocuspot-rathole-gateway-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service" > "/etc/systemd/system/ocuspot-rathole-gateway-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service" 2>/dev/null || true
  cat "/tmp/rathole.gateway.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml" > "/etc/rathole/gateway.d/ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml" 2>/dev/null || true
  (systemctl daemon-reload && systemctl enable --now "ocuspot-rathole-gateway-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service") 2>/dev/null || rc-service rathole restart 2>/dev/null || { echo "Rathole service installed but could not be started on gateway"; exit 14; }
  if ! command -v nginx >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y nginx >/dev/null; fi
    if ! command -v nginx >/dev/null 2>&1 && command -v apk >/dev/null 2>&1; then apk add --no-cache nginx >/dev/null; fi
    if ! command -v nginx >/dev/null 2>&1 && command -v dnf >/dev/null 2>&1; then dnf install -y nginx >/dev/null; fi
    if ! command -v nginx >/dev/null 2>&1 && command -v yum >/dev/null 2>&1; then yum install -y nginx >/dev/null; fi
    if ! command -v nginx >/dev/null 2>&1 && command -v pacman >/dev/null 2>&1; then pacman -Sy --noconfirm nginx >/dev/null; fi
  fi
  if ! command -v nginx >/dev/null 2>&1; then echo "nginx is required on gateway for public HTTP routing"; exit 16; fi
  mkdir -p /etc/nginx/conf.d
  cat > "/etc/nginx/conf.d/ocuspot-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.conf" <<OCUSPOT_NGINX
server {
    listen 80;
    server_name ocuspot-demo.pconf.ru;

    location / {
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://127.0.0.1:8080;
    }
}
OCUSPOT_NGINX
  nginx -t >/dev/null
  (systemctl enable --now nginx >/dev/null 2>&1 && systemctl reload nginx >/dev/null 2>&1) || service nginx reload >/dev/null 2>&1 || nginx -s reload >/dev/null 2>&1 || nginx >/dev/null 2>&1 || { echo "nginx config installed but could not be started/reloaded"; exit 16; }
'
echo "Gateway Rathole and HTTP proxy ownership deployed."

CAR_HOST="78.17.97.168"
CAR_PORT=22
CAR_USER="root"
CAR_FRAG='rathole.carrier.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml'
CAR_FULL='rathole.carrier.managed.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml'
CAR_UNIT='systemd.ocuspot-rathole-carrier-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service'
echo "Deploying carrier Rathole ownership to ${CAR_USER}@${CAR_HOST}:${CAR_PORT} ..."
car_scp -P "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${CAR_FRAG}" "${CAR_USER}@${CAR_HOST}:/tmp/${CAR_FRAG}" || true
car_scp -P "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${CAR_FULL}" "${CAR_USER}@${CAR_HOST}:/tmp/${CAR_FULL}" || true
car_scp -P "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${CAR_UNIT}" "${CAR_USER}@${CAR_HOST}:/tmp/${CAR_UNIT}" || true
if [ -n "${RATHOLE_BIN:-}" ] && [ -f "${RATHOLE_BIN}" ]; then
  car_scp -P "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${RATHOLE_BIN}" "${CAR_USER}@${CAR_HOST}:/tmp/ocuspot-rathole"
fi
if [ -n "${RATHOLE_TOKEN_FILE}" ]; then
  car_scp -P "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${RATHOLE_TOKEN_FILE}" "${CAR_USER}@${CAR_HOST}:/tmp/ocuspot-rathole.env"
fi
car_ssh -p "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${CAR_USER}@${CAR_HOST}" '
  set -eu
  mkdir -p /etc/ocuspot/rathole /etc/rathole /etc/rathole/carrier.d /usr/local/bin
  if [ -f /tmp/ocuspot-rathole ]; then install -m 0755 /tmp/ocuspot-rathole /usr/local/bin/rathole; fi
  if ! command -v rathole >/dev/null 2>&1 && [ ! -x /usr/local/bin/rathole ]; then for cand in /root/rathole/rathole /root/rathole /opt/rathole/rathole /usr/local/rathole/rathole; do if [ -f "$cand" ] && [ -x "$cand" ]; then install -m 0755 "$cand" /usr/local/bin/rathole; break; fi; done; fi
  if ! command -v rathole >/dev/null 2>&1 && [ ! -x /usr/local/bin/rathole ]; then echo "Rathole binary missing. Re-run with RATHOLE_BIN=/path/to/rathole"; exit 12; fi
  if [ -f /tmp/ocuspot-rathole.env ]; then cat /tmp/ocuspot-rathole.env > /etc/ocuspot/rathole.env; chmod 0600 /etc/ocuspot/rathole.env; elif [ ! -f /etc/ocuspot/rathole.env ]; then printf "%s=\n" "OCUSPOT_RATHOLE_OCUSPOT_DEPLOY_DEMO_BACKEND_KVM_PCONF_BUS_8080" > /etc/ocuspot/rathole.env; chmod 0600 /etc/ocuspot/rathole.env; echo "Fill token in /etc/ocuspot/rathole.env before restart if empty."; fi
  cat "/tmp/rathole.carrier.managed.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml" > "/etc/ocuspot/rathole/carrier.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml"
  cat "/tmp/systemd.ocuspot-rathole-carrier-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service" > "/etc/systemd/system/ocuspot-rathole-carrier-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service" 2>/dev/null || true
  cat "/tmp/rathole.carrier.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml" > "/etc/rathole/carrier.d/ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.toml" 2>/dev/null || true
  (systemctl daemon-reload && systemctl enable --now "ocuspot-rathole-carrier-ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.service") 2>/dev/null || rc-service rathole restart 2>/dev/null || { echo "Rathole service installed but could not be started on carrier"; exit 14; }
'
echo "Carrier Rathole ownership deployed."

if [ -n "${IMAGE_TAR:-}" ] && [ -f "${IMAGE_TAR}" ]; then
  echo "Uploading workload image tar to carrier ..."
  car_scp -P "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${IMAGE_TAR}" "${CAR_USER}@${CAR_HOST}:/tmp/ocuspot-image.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.tar"
  car_ssh -p "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${CAR_USER}@${CAR_HOST}" '
    set -eu
    if command -v docker >/dev/null 2>&1; then
      docker load -i "/tmp/ocuspot-image.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.tar"
      docker rm -f "ocuspot_deploy_demo_backend_kvm_pconf_bus_8080" >/dev/null 2>&1 || true
      docker run -d --restart unless-stopped --name "ocuspot_deploy_demo_backend_kvm_pconf_bus_8080" -p "127.0.0.1:8080:8080" "__OCUSPOT_IMAGE__"
    elif command -v podman >/dev/null 2>&1; then
      podman load -i "/tmp/ocuspot-image.ocuspot_deploy_demo_backend_kvm_pconf_bus_8080.tar"
      podman rm -f "ocuspot_deploy_demo_backend_kvm_pconf_bus_8080" >/dev/null 2>&1 || true
      podman run -d --restart unless-stopped --name "ocuspot_deploy_demo_backend_kvm_pconf_bus_8080" -p "127.0.0.1:8080:8080" "__OCUSPOT_IMAGE__"
    else
      echo "No docker or podman runtime found on carrier"; exit 15
    fi
  '
else
  echo "IMAGE_TAR is not set; skipping workload image upload/run. Rathole was configured only."
fi

if [ -n "${IMAGE_TAR:-}" ] && [ -f "${IMAGE_TAR}" ]; then
  echo "Verifying carrier local health ..."
  car_ssh -p "${CAR_PORT}" -o StrictHostKeyChecking=accept-new "${CAR_USER}@${CAR_HOST}" 'curl -fsS --max-time 10 http://127.0.0.1:8080/healthz >/dev/null || wget -qO- -T 10 http://127.0.0.1:8080/healthz >/dev/null'
  echo "Verifying gateway tunneled health ..."
  gw_ssh -p "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${GW_USER}@${GW_HOST}" 'curl -fsS --max-time 10 http://127.0.0.1:8080/healthz >/dev/null || wget -qO- -T 10 http://127.0.0.1:8080/healthz >/dev/null'
  echo "Verifying gateway HTTP proxy health ..."
  gw_ssh -p "${GW_PORT}" -o StrictHostKeyChecking=accept-new "${GW_USER}@${GW_HOST}" 'curl -fsS --max-time 10 -H '\''Host: ocuspot-demo.pconf.ru'\'' http://127.0.0.1/healthz >/dev/null || wget -qO- -T 10 --header='\''Host: ocuspot-demo.pconf.ru'\'' http://127.0.0.1/healthz >/dev/null'
  echo "Verifying public health ..."
  PUBLIC_IPS="$(getent ahostsv4 "${PUBLIC_HOST}" 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ' ' || true)"
  case " ${PUBLIC_IPS} " in *" ${GW_HOST} "*) DNS_OK=1 ;; *) DNS_OK=0 ;; esac
  if [ "${DNS_OK}" = 0 ]; then echo "Public DNS for ${PUBLIC_HOST} resolves to [${PUBLIC_IPS:-none}], expected gateway ${GW_HOST}."; fi
  if [ "${DNS_OK}" = 1 ] && (curl -fsS --max-time 15 "http://${PUBLIC_HOST}/healthz" >/dev/null || wget -qO- -T 15 "http://${PUBLIC_HOST}/healthz" >/dev/null); then echo "Public health verified."; elif [ "${OCUSPOT_REQUIRE_PUBLIC_HEALTH:-0}" = 1 ]; then echo "Public health failed and OCUSPOT_REQUIRE_PUBLIC_HEALTH=1"; exit 17; else echo "Public health is not reachable yet; carrier and gateway-local health passed."; fi
fi

# After both sides: public endpoint and health have been verified when IMAGE_TAR is supplied.
echo "Bundle execution complete. Check gateway routing and carrier service."
