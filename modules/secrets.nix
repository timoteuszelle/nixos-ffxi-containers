{ config, pkgs, lib, ... }:

with lib; {
  options.secrets = mkOption {
    type = types.attrs;
    default = { };
    description = "Secret configuration values.";
  };
  config.secrets = {
    cloudflare = {
      email = "your@email.address";
      apiToken = "you_api_token";
      myDomainName = "your.domain";
      myDomainNamePlay = "your.fqd.name";
    };
    ffxi = {
      oysqlRootPassword = "db_root_pwd";
      mysqlPassword = "db_user_pwd";
    };

  }
};
