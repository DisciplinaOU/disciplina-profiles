{ domain, faucetUrl, witnessUrl }: { pkgs, config, resources, ... }:

{
  deployment.ec2 = {
    instanceType = "c5.xlarge";
    ebsInitialRootDiskSize = 300;
    elasticIPv4 = resources.elasticIPs.builder-ip;
    securityGroupIds = [
      resources.ec2SecurityGroups.dscp-default-sg.name
      resources.ec2SecurityGroups.dscp-ssh-public-sg.name
      resources.ec2SecurityGroups.dscp-http-public-sg.name
      resources.ec2SecurityGroups.dscp-telegraf-private-sg.name
    ];
  };

  services.nginx.virtualHosts = {
    witness.serverName = "witness.${domain}";
    faucet.serverName = "faucet.${domain}";
    explorer.serverName = "explorer.${domain}";
    grafana.serverName = "grafana.net.${domain}";
    prometheus.serverName = "prometheus.net.${domain}";
    alertManager.serverName = "alertmanager.net.${domain}";

    faucet.locations."/".root = "${pkgs.disciplina-faucet-frontend.override { inherit faucetUrl; }}";
    explorer.locations."/".root = "${pkgs.disciplina-witness-frontend.override { inherit witnessUrl; }}";
  };

  # TODO: Get Route53 access on TMP cluster
  # deployment.route53.usePublicDNSName = true;
}
