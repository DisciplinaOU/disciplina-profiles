{ internal ? false }: { config, lib, resources, ... }:

{
  deployment.ec2 = {
    instanceType = "t2.small";
    ebsInitialRootDiskSize = 30;
    # Witness nodes don't allow SSH on public interface
    usePrivateIpAddress = true;
    securityGroupIds = [ resources.ec2SecurityGroups.dscp-ssh-private-sg.name ]
      ++ (if internal then
      [ resources.ec2SecurityGroups.dscp-witness-private-sg.name ]
      else
      [ resources.ec2SecurityGroups.dscp-witness-public-sg.name ]);
  };
}
