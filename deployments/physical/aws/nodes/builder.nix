{ domain, deploy-target }: { pkgs, lib, config, resources, ... }:

{
  deployment.ec2 = {
    ebsInitialRootDiskSize = 300;
    securityGroupIds = with resources.ec2SecurityGroups; [
      dscp-http-public-sg.name
      dscp-ssh-public-sg.name
      dscp-telegraf-private-sg.name
    ];
  };

  services.nginx.virtualHosts = {
    alertManager.serverName = "alertmanager.net.${domain}";
    explorer.serverName = "explorer.${domain}";
    faucet.serverName = "faucet.${domain}";
    grafana.serverName = "grafana.net.${domain}";
    prometheus.serverName = "prometheus.net.${domain}";
    witness.serverName = "witness.${domain}";
  };

  services.buildkite-agent.tags = "nix=true nixops=true queue=dscp deploy-target=${ deploy-target }";
}
