# FFXI Private Server with NixOS and Docker

This repository provides a NixOS-based configuration for running a [LandSandBoat](https://github.com/LandSandBoat/server) Final Fantasy XI (FFXI) private server with an optional [ffxiahbot](https://github.com/AdamGagorik/ffxiahbot) for price scrubbing and automation, using Docker containers. It includes NixOS modules, Dockerfiles, scripts, and configuration files for a reproducible setup.

## Features
- LandSandBoat FFXI server with MariaDB database.
- Adminer for database management.
- ffxiahbot for automated price scrubbing and data refilling.
- Dynamic DNS (DDNS) support for public access.
- NixOS modules for declarative configuration.

## Prerequisites
- NixOS (recommended: 24.11 or later).
- Docker (recommended: 24.x or later).
- `openssl` for generating self-signed certificates.
- Basic knowledge of NixOS and Docker.

## Directory Structure

ffxi-nixos-config/
├── configuration.nix       # Main NixOS configuration
├── modules/               # NixOS modules
│   ├── ffxi.nix
│   ├── ddns.nix
│   ├── secrets.nix
├── docker/                # Dockerfiles
│   ├── server/Dockerfile
│   ├── bot/Dockerfile
├── scripts/               # Startup scripts
│   ├── server/start.sh
│   ├── bot/run.sh
├── config/                # Configuration files
│   ├── mysql/my.cnf
│   ├── bot/
│   │   ├── bot.yaml
│   │   ├── config.yaml
│   │   ├── custom_items.csv
│   ├── server/
│   │   ├── settings/
│   │   │   ├── logging.lua
│   │   │   ├── login.lua
│   │   │   ├── main.lua
│   │   │   ├── map.lua
│   │   │   ├── network.lua
│   │   │   ├── search.lua
│   │   ├── cert/
│   │   │   ├── login.key
│   │   │   ├── login.cert
├── README.md


Make sure you got Docker setup first in your nixos configuration so you can prepare the images for the rest of the configuration. 
Build Docker Images
Build the server and bot images:

docker build -t ffxi-custom:latest docker/server
docker build -t ffxiahbot:latest docker/bot

## Setup Instructions

### 1. Clone the Repository
```bash

2. Generate Self-Signed Certificates
Generate certificates for the server:

openssl req -x509 -newkey rsa:2048 -keyout config/server/cert/login.key -out config/server/cert/login.cert -days 365 -nodes

3. Configure Secrets
Edit modules/secrets.nix to set your MySQL password:

4. Configure Network Settings

<BS>Edit config/server/settings/network.lua to set:
SQL_PASSWORD: Your MySQL password.

ZONE_IP: Your public IP or domain (e.g., from DDNS). Or local if you you keep it private.

<BS>Edit modules/ddns.nix to enable DDNS if using a dynamic IP:
ffxi.ddns.enable = true;
ffxi.ddns.url = "https://your-ddns-provider/update";
ffxi.ddns.headers = [ "Authorization: Bearer your-token" ];
ffxi.ddns.interface = "eth0";


5. Customize Lua Settings
Modify config/server/settings/*.lua files as needed (see LandSandBoat documentation).

6. Configure Bot (Optional)
Edit config/bot/config.yaml to set the MySQL password.
Customize config/bot/bot.yaml for bot tasks (e.g., scrub, refill).

7. Apply NixOS Configuration
Depends on your situdation, apped your condifuration.nix with the required lines.
You need to check the modules for what you are going to use. ffxi.nix needs a small update @ ZONE_IP=
You need to decide if you are using the bot and ddns part. I might make changes later to this repo to repesent different setup choices.

Copy configuration.nix and modules/ to /etc/nixos/:
sudo cp -r modules /etc/nixos/
sudo cp configuration.nix /etc/nixos/

Post install / config.

Start Services
The services (ffxi-mysql, ffxi-server, ffxi-admin, ffxi-bot, ffxi-bot-manual) start automatically via ffxi.nix. Check status:

systemctl status docker-ffxi-*

Access the Server
Game Server: Connect using an FFXI client to your ZONE_IP on ports 54230, 54231, etc.

Admin Portal: Access Adminer at http://<your-ip>:8082.

Optional Components
Bot: The ffxiahbot (docker-ffxi-bot, docker-ffxi-bot-manual) is optional for price automation.
systemctl start docker-ffxi-bot-manual use the exmaple files to get your AH filled with desired items

DDNS: Enable in ddns.nix for dynamic IP updates.

Troubleshooting
Check logs: /srv/ffxi/server/log/*.log, /srv/ffxi/bot/output/.

Verify database: docker exec -it ffxi-mysql mysql -u xiuser -p xidb.

Ensure ports are open: sudo netstat -tuln.

Contributing
Submit issues or pull requests to improve this setup. See CONTRIBUTING.md (#) for guidelines.
License
MIT License (or choose your preferred license).
```




















