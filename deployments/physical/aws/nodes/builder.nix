{ config, ... }:

{
  deployment.ec2 = {
    instanceType = "t2.xlarge";
    ebsInitialRootDiskSize = 300;
  };
}
