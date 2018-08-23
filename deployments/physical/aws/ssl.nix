{ realDomain, keydir }:
{ lib, config, ... }:
with lib;
let cfg = config.services.nginx.ssl-vhosts; in
{
  options.services.nginx.ssl-vhosts = mkOption {
    type = types.listOf types.string;
    default = [];
  };

  config = mkIf (cfg != []) {
    dscp.keys = {
      ssl-key  = {
        shared = false;
        keyname = "ssl/${realDomain}/${realDomain}";
        user = "nginx";
        services = [ "nginx" ];
      };
      ssl-cert = {
        shared = false;
        keyname = "ssl/${realDomain}/fullchain";
        extension = "cer";
        user = "nginx";
        services = [ "nginx" ];
      };
    };

    users.extraUsers.nginx.extraGroups = [ "keys" ];

    services.nginx.virtualHosts = genAttrs cfg (name: {
      forceSSL = true;
      sslCertificate = toString config.serokell.keys.ssl-cert;
      sslCertificateKey = toString config.serokell.keys.ssl-key;
      extraConfig = ''
        add_header Strict-Transport-Security "max-age=31536000" always;
      '';
    });
  };
}
