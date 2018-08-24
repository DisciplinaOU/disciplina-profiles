{ config, ... }:

{
  deployment.ec2 = {
    instanceType = "t2.xlarge";
    ebsInitialRootDiskSize = 300;
  };
  # TODO: Get Route53 access on TMP cluster
  # deployment.route53.usePublicDNSName = true;
}
