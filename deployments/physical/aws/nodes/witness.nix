{ n, internal ? false, production ? false }: { config, lib, resources, ... }:

{
  deployment.ec2 = {
    elasticIPv4 = lib.mkIf internal (lib.mkForce "");

    # Witness nodes don't allow SSH on public interface
    usePrivateIpAddress = true;
    securityGroupIds = with resources.ec2SecurityGroups; (
      [ dscp-ssh-private-sg.name ]
      ++ (if internal then
      [ dscp-witness-private-sg.name dscp-witness-api-private-sg.name ]
      else
      [ dscp-witness-public-sg.name dscp-witness-api-public-sg.name ]
    ));
  };

}
