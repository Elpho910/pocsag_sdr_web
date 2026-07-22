# pocsag-sdr-web

A lightweight Raspberry Pi + RTL-SDR + nginx web frontend for replacing the classic Windows + PDW POCSAG monitoring stack with a cheap SDR dongle and a browser.


## What it does

- decodes POCSAG pager traffic with `rtl_fm` + `multimon-ng`
- filters empty/junk lines and timestamps received messages
- suppresses duplicate statewide/network fan-out pages for 60 seconds
- writes to a shared log file for multi-user browser viewing
- serves a simple mobile-friendly web UI with keyword highlights and relative timestamps
- publishes a lightweight health JSON for dashboards and monitoring
- runs under `systemd` with automatic restart
- serves the UI through `nginx`

## Architecture

```text
RTL-SDR dongle
  -> rtl_fm
  -> multimon-ng
  -> pager-clean-filter.py
  -> /var/lib/pager/messages.log
  -> nginx static UI + /data/messages.log + /data/health.json
  -> browser clients
```

## Tested stack

- Raspberry Pi OS / Debian-family hosts
- nginx
- rtl-sdr
- multimon-ng
- Python 3

## Repository layout

- `web/` - static browser UI and favicon
- `scripts/` - decoder runner, cleaner, and health script
- `systemd/` - service/timer units
- `nginx/` - example nginx site config
- `config/` - sample environment file
- `docs/` - deployment and operations notes

## Quick start

```bash
Clone the repo
cd pager-sdr-web
sudo ./scripts/install.sh
sudo nano /etc/pager-sdr-web/pager.env
sudo systemctl restart pager-decode pager-health.timer nginx
```

Then browse to:

- `http://<host-ip>:8000`

## Default runtime paths

- UI root: `/var/www/pager-ui`
- log file: `/var/lib/pager/messages.log`
- health JSON: `/var/lib/pager/health.json`
- config: `/etc/pager-sdr-web/pager.env`

## Main tunables

Edit `/etc/pager-sdr-web/pager.env`:

- `RTL_FREQUENCY=148.7125M`
- `RTL_DEVICE=0`
- `RTL_GAIN=` blank for automatic gain
- `RTL_SAMPLE_RATE=22050`
- `DEDUP_WINDOW=60`
- `WEB_PORT=8000`

## Notes

- This project is currently focused on **POCSAG** workflows.
- The static UI reads the last several hundred lines from the shared log, newest first.
- If your SDR is grabbed by DVB kernel drivers, see `docs/DEPLOYMENT.md` for the blacklist note.

## Future features when I get time

- optional docker packaging
- configurable listen port generation for nginx
- export/search features in the UI
- sample screenshots and club documentation
