{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/ffxi.nix
    ./modules/ddns.nix
    ./modules/secrets.nix
  ];

  # Enable Docker
  virtualisation.docker.enable = true;

  # Basic networking (adjust as needed)
  networking.hostName = "ffxi-server";
  networking.firewall.allowedTCPPorts = [ 54230 54231 54001 54002 51220 8082 ];
  networking.firewall.allowedUDPPorts = [ 54230 ];

  # Ensure ffxi user has access to Docker
  users.users.ffxi.extraGroups = [ "docker" ];

  # Optional: Enable SSH for remote access
  services.openssh.enable = true;

  # System packages (optional, for convenience)
  environment.systemPackages = with pkgs; [ docker git openssl ];

}
