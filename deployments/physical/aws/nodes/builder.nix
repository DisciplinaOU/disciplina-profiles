{ domain, faucetUrl, witnessUrl, deploy-target }: { pkgs, lib, config, resources, ... }:

{
  deployment.ec2 = {
    ebsInitialRootDiskSize = 300;
    securityGroups = with resources.ec2SecurityGroups; [
      dscp-http-public-sg
      dscp-ssh-public-sg
      dscp-telegraf-private-sg
    ];
  };

  services.nginx.virtualHosts = {
    alertManager.serverName = "alertmanager.net.${domain}";
    derivery.serverName = "derivery.net.${domain}";
    explorer.serverName = "explorer.${domain}";
    faucet.serverName = "faucet.${domain}";
    grafana.serverName = "grafana.net.${domain}";
    prometheus.serverName = "prometheus.net.${domain}";
    witness.serverName = "witness.${domain}";

    explorer.locations."/".root = "${pkgs.disciplina-explorer-frontend.override { inherit witnessUrl; }}";
    faucet.locations."/".root = "${pkgs.disciplina-faucet-frontend.override { inherit faucetUrl; }}";
  };

  services.buildkite-agent.tags = "nix=true nixops=true queue=dscp deploy-target=${ deploy-target }";
}
