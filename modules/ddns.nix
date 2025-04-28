{ config, pkgs, ... }:
{
  system.activationScripts.ddclientConfig = {
    text = ''
      mkdir -p /home/tim/ddns
      echo "protocol=cloudflare
      use=web, web=ifconfig.me
      server=api.cloudflare.com/client/v4
      password=${config.secrets.cloudflare.apiToken}
      zone=${config.secrets.cloudflare.myDomainName}
      ${config.secrets.cloudflare.cloudMyDomainName}
      daemon=300
      verbose=yes
      timeout=60

      protocol=cloudflare
      use=web, web=ifconfig.me
      server=api.cloudflare.com/client/v4
      password=${config.secrets.cloudflare.apiToken}
      zone=${config.secrets.cloudflare.myDomainNamePlay}
      ${config.secrets.cloudflare.playMyDomainName}
      daemon=300
      verbose=yes
      timeout=60" > /home/tim/ddns/ddclient.conf
      chown 911:911 /home/tim/ddns/ddclient.conf
      chmod 600 /home/tim/ddns/ddclient.conf
      chown tim:users /home/tim/ddns
      chmod 755 /home/tim/ddns
    '';
    deps = [];
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      ddns = {
        image = "lscr.io/linuxserver/ddclient:latest";
        autoStart = true;
        user = "911:911";
        volumes = [ "/home/tim/ddns:/config" ];
        environment = {
          "TZ" = "Europe/Amsterdam";
          "PUID" = "911";
          "PGID" = "911";
        };
        extraOptions = [ "--user=911:911" ];
      };
    };
  };
}
