{ internal ? false }: { config, lib, resources, ... }:

{
  deployment.ec2 = {
    instanceType = "t2.small";
    ebsInitialRootDiskSize = 30;
    usePrivateIpAddress = lib.mkIf internal true;
    securityGroupIds = [ resources.ec2SecurityGroups.dscp-ssh-private-sg.name ]
      ++ (if internal then
      [ resources.ec2SecurityGroups.dscp-witness-private-sg.name ]
      else
      [ resources.ec2SecurityGroups.dscp-witness-public-sg.name ]);
  };
}
