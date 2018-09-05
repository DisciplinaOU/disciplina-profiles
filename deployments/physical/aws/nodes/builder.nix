{ domain, faucetUrl, witnessUrl, production ? false }: { pkgs, lib, config, resources, ... }:

{
  deployment.ec2 = {
    instanceType = "c5.xlarge";
    ebsInitialRootDiskSize = 300;
    elasticIPv4 = if production then resources.elasticIPs.builder-ip else "";
    securityGroupIds = [
      resources.ec2SecurityGroups.dscp-default-sg.name
      resources.ec2SecurityGroups.dscp-http-public-sg.name
      resources.ec2SecurityGroups.dscp-ssh-public-sg.name
      resources.ec2SecurityGroups.dscp-telegraf-private-sg.name
    ];
  };

  deployment.route53.usePublicDNSName = !production;

  services.nginx.virtualHosts = {
    alertManager.serverName = "alertmanager.net.${domain}";
    derivery.serverName = "derivery.net.${domain}";
    explorer.serverName = "explorer.${domain}";
    faucet.serverName = "faucet.${domain}";
    grafana.serverName = "grafana.net.${domain}";
    prometheus.serverName = "prometheus.net.${domain}";
    witness.serverName = "witness.${domain}";

    explorer.locations."/".root = "${pkgs.disciplina-witness-frontend.override { inherit witnessUrl; }}";
    faucet.locations."/".root = "${pkgs.disciplina-faucet-frontend.override { inherit faucetUrl; }}";
  };


  services.buildkite-agent.meta-data = "nix=true nixops=true queue=dscp-${if production then "production" else "testing"}";

  # TODO: Get Route53 access on TMP cluster
  # deployment.route53.usePublicDNSName = true;
}
