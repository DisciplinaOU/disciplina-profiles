{ realDomain, num, region }: { config, ... }:

{
  deployment.ec2 = {
    inherit region;
    instanceType = "t2.small";
    ebsInitialRootDiskSize = 30;
  };
}
