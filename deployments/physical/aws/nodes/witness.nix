{ internal ? false }: { config, lib, resources, ... }:

{
  deployment.ec2 = {
    instanceType = "c5.xlarge";
    ebsInitialRootDiskSize = 30;
    # Witness nodes don't allow SSH on public interface
    usePrivateIpAddress = true;
    securityGroupIds = [
      resources.ec2SecurityGroups.dscp-ssh-private-sg.name
      resources.ec2SecurityGroups.dscp-default-sg.name
      ]
      ++ (if internal then
      [
        resources.ec2SecurityGroups.dscp-witness-private-sg.name
        resources.ec2SecurityGroups.dscp-witness-api-private-sg.name
      ]
      else
      [
        resources.ec2SecurityGroups.dscp-witness-public-sg.name
        resources.ec2SecurityGroups.dscp-witness-api-public-sg.name
      ]);
  };
}
