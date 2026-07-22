#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run as root: sudo ./scripts/install.sh" >&2
  exit 1
fi

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PAGER_USER=${SUDO_USER:-${PAGER_USER:-daniel}}
PAGER_GROUP=${PAGER_GROUP:-$PAGER_USER}
PAGER_HOME=$(getent passwd "$PAGER_USER" | cut -d: -f6)
if [[ -z "$PAGER_HOME" ]]; then
  echo "Could not resolve home directory for user $PAGER_USER" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx rtl-sdr multimon-ng python3

install -d -m 775 -o "$PAGER_USER" -g "$PAGER_GROUP" /var/lib/pager
install -d -m 755 /etc/pager-sdr-web
install -d -m 755 /var/www/pager-ui

if [[ ! -f /etc/pager-sdr-web/pager.env ]]; then
  sed     -e "s/^PAGER_USER=.*/PAGER_USER=$PAGER_USER/"     -e "s/^PAGER_GROUP=.*/PAGER_GROUP=$PAGER_GROUP/"     -e "s#^WORKDIR=.*#WORKDIR=$PAGER_HOME#"     "$REPO_DIR/config/pager.env.example" > /etc/pager-sdr-web/pager.env
  chmod 664 /etc/pager-sdr-web/pager.env
  chown "$PAGER_USER":"$PAGER_GROUP" /etc/pager-sdr-web/pager.env
fi

install -m 755 "$REPO_DIR/scripts/pager-clean-filter.py" /usr/local/bin/pager-clean-filter.py
install -m 755 "$REPO_DIR/scripts/pager-health-check.sh" /usr/local/bin/pager-health-check.sh
install -m 755 "$REPO_DIR/scripts/run-pager-decode.sh" /usr/local/bin/run-pager-decode.sh

sed \
  -e "s#__PAGER_USER__#$PAGER_USER#" \
  -e "s#__PAGER_GROUP__#$PAGER_GROUP#" \
  -e "s#__WORKDIR__#$PAGER_HOME#" \
  "$REPO_DIR/systemd/pager-decode.service" > /etc/systemd/system/pager-decode.service
chmod 644 /etc/systemd/system/pager-decode.service
install -m 644 "$REPO_DIR/systemd/pager-health.service" /etc/systemd/system/pager-health.service
install -m 644 "$REPO_DIR/systemd/pager-health.timer" /etc/systemd/system/pager-health.timer

install -m 644 "$REPO_DIR/web/index.html" /var/www/pager-ui/index.html
install -m 644 "$REPO_DIR/web/favicon.svg" /var/www/pager-ui/favicon.svg

install -m 644 "$REPO_DIR/nginx/pager-sdr-web.conf" /etc/nginx/sites-available/pager-sdr-web
ln -sf /etc/nginx/sites-available/pager-sdr-web /etc/nginx/sites-enabled/pager-sdr-web
rm -f /etc/nginx/sites-enabled/default

systemctl daemon-reload
systemctl enable --now pager-decode.service
systemctl enable --now pager-health.timer
nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo "Installed. Edit /etc/pager-sdr-web/pager.env if frequency or SDR settings need changing."
