{ config, ... }:

{
  deployment.ec2 = {
    instanceType = "t2.small";
    ebsInitialRootDiskSize = 30;
  };
}
