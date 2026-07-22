# Deployment guide

## 1. Hardware

- Raspberry Pi or other Debian-family Linux host
- RTL-SDR USB dongle
- network access for browser clients

## 2. Install

```bash
sudo ./scripts/install.sh
```

The installer will:

- install required apt packages
- create `/etc/pager-sdr-web`
- install scripts into `/usr/local/bin`
- install the static UI into `/var/www/pager-ui`
- install systemd units
- install nginx site config
- enable and start `pager-decode.service`, `pager-health.timer`, and `nginx`

## 3. Configure frequency and SDR settings

Edit:

```bash
sudo nano /etc/pager-sdr-web/pager.env
```

Key values:

- `RTL_FREQUENCY` - pager frequency, e.g. `148.7125M`
- `RTL_DEVICE` - SDR index from `rtl_test`
- `RTL_GAIN` - blank for auto, or numeric gain
- `POCSAG_MODES` - default `POCSAG512 POCSAG1200 POCSAG2400`
- `DEDUP_WINDOW` - duplicate suppression window in seconds
- `WEB_PORT` - nginx listen port metadata reference; if you change this, also update the nginx site file

## 4. Validate

```bash
sudo systemctl status pager-decode pager-health.timer nginx --no-pager
curl -fsS http://127.0.0.1:8000/ >/dev/null && echo UI_OK
curl -fsS http://127.0.0.1:8000/data/health.json
```

## 5. Useful commands

```bash
sudo journalctl -u pager-decode -f
sudo systemctl restart pager-decode
sudo systemctl restart pager-health.timer
sudo nginx -t && sudo systemctl reload nginx
```

## 6. SDR driver conflict note

Some Debian/Raspberry Pi installs auto-load DVB drivers that can grab the RTL-SDR. If `rtl_test` or `rtl_fm` cannot access the device, create:

```bash
sudo tee /etc/modprobe.d/rtl-sdr-blacklist.conf >/dev/null <<'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF
sudo reboot
```

## 7. Troubleshooting

### No messages in UI
- check `sudo systemctl status pager-decode`
- check `sudo journalctl -u pager-decode -n 100 --no-pager`
- confirm `rtl_fm` and `multimon-ng` are installed
- confirm frequency and SDR index are correct

### UI loads but health stays degraded
- check `/var/lib/pager/health.json`
- verify `pager-health.timer` is active
- verify `pidof rtl_fm` and `pidof multimon-ng`

### Port 8000 conflict
- edit `nginx/pager-sdr-web.conf`
- reinstall or copy the updated site file to `/etc/nginx/sites-available/pager-sdr-web`
- run `sudo nginx -t && sudo systemctl reload nginx`
