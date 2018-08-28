{ domain }: { config, resources, ... }:

{
  deployment.ec2 = {
    instanceType = "t2.xlarge";
    ebsInitialRootDiskSize = 300;
    securityGroupIds = [ resources.ec2SecurityGroups.dscp-ssh-public-sg.name ];
  };

  services.nginx.virtualHosts = {
    witness.serverName = "${config.networking.hostName}.${domain}";
  };

  # TODO: Get Route53 access on TMP cluster
  # deployment.route53.usePublicDNSName = true;
}
