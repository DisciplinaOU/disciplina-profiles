{ pkgs, lib, config, resources, ... }:

{
  deployment.ec2 = {
    securityGroupIds = with resources.ec2SecurityGroups; [
      dscp-http-public-sg.name
      dscp-ssh-public-sg.name
      dscp-telegraf-private-sg.name
    ];
  };

  services.nginx.virtualHosts = {
    explorer.serverName = "explorer.${config.networking.domain}";
    faucet.serverName = "faucet.${config.networking.domain}";
    prometheus.serverName = "prometheus.${config.networking.domain}";
    witness.serverName = "witness.${config.networking.domain}";
  };
}
