{ config, lib, pkgs, ... }:

{
  users.users.ffxi = {
    isSystemUser = true;
    uid = 1003;
    group = "ffxi";
    extraGroups = [ "docker" ];
    home = "/srv/ffxi";
    description = "FFXI Server user";
  };

  users.groups.ffxi = {
    gid = 1003;
  };

  systemd.tmpfiles.rules = [
    "d /srv/ffxi 0770 ffxi ffxi -"
    "d /srv/ffxi/mysql 0770 ffxi ffxi -"
    "d /srv/ffxi/server/log 0770 ffxi ffxi -"
    "d /srv/ffxi/server/settings 0770 ffxi ffxi -"
    "d /srv/ffxi/server/settings/default 0770 ffxi ffxi -"
    "d /srv/ffxi/server/cert 0770 ffxi ffxi -"
    "f /srv/ffxi/server/public_ip.txt 0660 ffxi ffxi -"
    "f /srv/ffxi/server/ip_update.log 0660 ffxi ffxi -"
    "d /srv/ffxi/bot 0770 ffxi ffxi -"
    "d /srv/ffxi/bot/config 0770 ffxi ffxi -"
    "d /srv/ffxi/bot/output 0770 ffxi ffxi -"
    "d /srv/ffxi/bot/scripts 0770 ffxi ffxi -"
    "f /srv/ffxi/bot/config/bot.yaml 0664 ffxi ffxi -"
    "f /srv/ffxi/bot/config/config.yaml 0664 ffxi ffxi -"
    "f /srv/ffxi/bot/output/custom_items.csv 0664 ffxi ffxi -"
    "f /srv/ffxi/bot/scripts/run.sh 0770 ffxi ffxi -"
    "f /srv/ffxi/mysql/my.cnf 0660 ffxi ffxi -"
  ];

  virtualisation.docker.enable = true;

  systemd.services.docker-ffxi-network = {
    description = "FFXI Docker Network";
    before = [ "docker-ffxi-mysql.service" "docker-ffxi-server.service" "docker-ffxi-admin.service" "docker-ffxi-bot.service" "docker-ffxi-bot-manual.service" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" "docker.service" ];
    after = [ "network-online.target" "docker.service" ];
    serviceConfig = {
      ExecStart = "/bin/sh -c '${pkgs.docker}/bin/docker network inspect lsb >/dev/null 2>&1 || ${pkgs.docker}/bin/docker network create --driver bridge lsb'";
      RemainAfterExit = "yes";
      Type = "oneshot";
    };
  };

  systemd.services.docker-ffxi-mysql = {
    description = "FFXI MariaDB Container";
    after = [ "docker.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.docker}/bin/docker rm -f ffxi-mysql || true";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-mysql --network lsb -v /srv/ffxi/mysql:/var/lib/mysql -v /srv/ffxi/sql:/docker-entrypoint-initdb.d -e MYSQL_ROOT_PASSWORD=${config.secrets.ffxi.mysqlPassword} -e MYSQL_USER=xiuser -e MYSQL_PASSWORD=${config.secrets.ffxi.mysqlPassword} -e MYSQL_DATABASE=xidb --user 1003:1003 mariadb:latest";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-mysql";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "10min";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.docker-ffxi-server = {
    description = "FFXI Game Server Container";
    after = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.docker}/bin/docker rm -f ffxi-server || true";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-server --network lsb -v /srv/ffxi/server/log:/server/log -v /srv/ffxi/server/settings:/app/settings -v /srv/ffxi/server/cert/login.key:/app/login.key -v /srv/ffxi/server/cert/login.cert:/app/login.cert -v /srv/ffxi/server/start.sh:/app/start.sh -p 54230:54230/tcp -p 54230:54230/udp -p 54231:54231/tcp -p 54001:54001/tcp -p 54002:54002/tcp -p 51220:51220/tcp -e DB_HOST=ffxi-mysql -e DB_PORT=3306 -e DB_USER=xiuser -e DB_PASS=${config.secrets.ffxi.mysqlPassword} -e DB_NAME=xidb -e ZONE_IP=192.168.1.200 --user 1003:1003 ffxi-custom:latest /app/start.sh";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-server";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "10min";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.docker-ffxi-admin = {
    description = "FFXI Admin Portal Container";
    after = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.docker}/bin/docker rm -f ffxi-admin || true";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-admin --network lsb -p 8082:8080 -e ADMINER_DEFAULT_SERVER=ffxi-mysql --user 1003:1003 adminer:latest";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-admin";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "10min";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.ffxi-ip-fetch = {
    description = "Fetch and store FFXI public IP from ifconfig.me";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScriptBin "ffxi-ip-fetch" ''
        #!/bin/bash
        echo "DEBUG: Starting ffxi-ip-fetch at $(date)"
        IP_FILE="/srv/ffxi/server/public_ip.txt"
        echo "DEBUG: Checking write permissions for $IP_FILE"
        if [ ! -w "$(dirname "$IP_FILE")" ]; then
            echo "ERROR: No write permission for $(dirname "$IP_FILE")" >&2
            exit 1
        fi
        NEW_IP=$(${pkgs.curl}/bin/curl -s ifconfig.me)
        if [ -z "$NEW_IP" ]; then
            echo "ERROR: Failed to fetch public IP from ifconfig.me" >&2
            exit 1
        fi
        echo "DEBUG: Fetched IP: $NEW_IP"
        echo "$NEW_IP" > "$IP_FILE"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to write IP to $IP_FILE" >&2
            exit 1
        fi
        echo "Stored public IP: $NEW_IP in $IP_FILE"
      ''}/bin/ffxi-ip-fetch";
      User = "ffxi";
      Group = "ffxi";
      StandardOutput = "append:/srv/ffxi/server/ip_update.log";
      StandardError = "append:/srv/ffxi/server/ip_update.log";
    };
  };

  systemd.timers.ffxi-ip-fetch = {
    description = "Timer for fetching FFXI public IP";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
  };

  systemd.services.ffxi-ip-update = {
    description = "Update FFXI zone_settings.zoneip with public IP";
    after = [ "ffxi-ip-fetch.service" "docker-ffxi-mysql.service" ];
    requires = [ "docker-ffxi-mysql.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScriptBin "ffxi-ip-update" ''
        #!/bin/bash
        echo "DEBUG: Starting ffxi-ip-update at $(date)"
        IP_FILE="/srv/ffxi/server/public_ip.txt"
        echo "DEBUG: Checking IP file: $IP_FILE"
        if [ ! -f "$IP_FILE" ]; then
            echo "ERROR: IP file $IP_FILE does not exist" >&2
            exit 1
        fi
        NEW_IP=$(${pkgs.coreutils}/bin/cat "$IP_FILE" 2>/dev/null)
        if [ -z "$NEW_IP" ]; then
            echo "ERROR: IP file $IP_FILE is empty" >&2
            exit 1
        fi
        echo "DEBUG: New IP: $NEW_IP"
        CURRENT_IP=$(${pkgs.docker}/bin/docker exec ffxi-mysql mariadb -h localhost -P 3306 -u xiuser -p${config.secrets.ffxi.mysqlPassword} xidb -e "SELECT zoneip FROM zone_settings LIMIT 1;" | ${pkgs.gnugrep}/bin/grep -v zoneip || echo "")
        echo "DEBUG: Current IP: $CURRENT_IP"
        if [ "$NEW_IP" != "$CURRENT_IP" ]; then
            echo "IP changed from $CURRENT_IP to $NEW_IP, updating zone_settings..."
            ${pkgs.docker}/bin/docker exec ffxi-mysql mariadb -h localhost -P 3306 -u xiuser -p${config.secrets.ffxi.mysqlPassword} xidb -e "UPDATE zone_settings SET zoneip='$NEW_IP'" || {
                echo "ERROR: Failed to update zone_settings" >&2
                exit 1
            }
            echo "Successfully updated zone_settings to $NEW_IP"
        else
            echo "IP unchanged ($CURRENT_IP), no update needed."
        fi
      ''}/bin/ffxi-ip-update";
      User = "ffxi";
      Group = "ffxi";
      StandardOutput = "append:/srv/ffxi/server/ip_update.log";
      StandardError = "append:/srv/ffxi/server/ip_update.log";
    };
  };

  systemd.timers.ffxi-ip-update = {
    description = "Timer for updating FFXI zone_settings.zoneip";
    wantedBy = [ "timers.target" ];
    partOf = [ "ffxi-ip-fetch.service" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
  };

  systemd.services.docker-ffxi-bot = {
    description = "FFXI Auction House Bot Container";
    after = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "/bin/sh -c '${pkgs.docker}/bin/docker rm -f ffxi-bot || true'";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-bot --network lsb -v /srv/ffxi/bot/config:/app/config -v /srv/ffxi/bot/output:/app/output -v /srv/ffxi/bot/scripts:/app/scripts -e FFXIAHBOT_DB_HOST=ffxi-mysql -e FFXIAHBOT_DB_PORT=3306 -e FFXIAHBOT_DB_USER=xiuser -e FFXIAHBOT_DB_PASS=${config.secrets.ffxi.mysqlPassword} -e FFXIAHBOT_DB_NAME=xidb -e BOT_MODE=scheduled --user 1003:1003 ffxiahbot:latest /app/scripts/run.sh";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-bot";
      Restart = "on-failure";
      RestartSec = "5s";
      StartLimitIntervalSec = 60;
      StartLimitBurst = 3;
      TimeoutStartSec = "120min";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.timers.docker-ffxi-bot = {
    description = "Timer for FFXI Auction House Bot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly"; # Runs every Monday at 00:00
      Persistent = true;
    };
  };

  systemd.services.docker-ffxi-bot-manual = {
    description = "FFXI Auction House Bot Manual Run";
    after = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" "network-online.target" ];
    requires = [ "docker.service" "docker-ffxi-mysql.service" "docker-ffxi-network.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = "/bin/sh -c '${pkgs.docker}/bin/docker rm -f ffxi-bot-manual || true'";
      ExecStart = "${pkgs.docker}/bin/docker run --name ffxi-bot-manual --network lsb -v /srv/ffxi/bot/config:/app/config -v /srv/ffxi/bot/output:/app/output -v /srv/ffxi/bot/scripts:/app/scripts -e FFXIAHBOT_DB_HOST=ffxi-mysql -e FFXIAHBOT_DB_PORT=3306 -e FFXIAHBOT_DB_USER=xiuser -e FFXIAHBOT_DB_PASS=${config.secrets.ffxi.mysqlPassword} -e FFXIAHBOT_DB_NAME=xidb -e BOT_MODE=manual --user 1003:1003 ffxiahbot:latest /app/scripts/run.sh";
      ExecStop = "${pkgs.docker}/bin/docker stop ffxi-bot-manual";
      Type = "oneshot";
      TimeoutStartSec = "30min";
      StandardOutput = "journal+console";
      StandardError = "journal+console";
    };
  };

  networking.firewall.allowedTCPPorts = [ 54230 54231 54001 54002 51220 8082 ];
  networking.firewall.allowedUDPPorts = [ 54230 ];
}
