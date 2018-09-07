{ n, internal ? false, production ? false }: { config, lib, resources, ... }:

{
  deployment.ec2 = {
    elasticIPv4 = lib.mkIf internal (lib.mkForce "");

    # Witness nodes don't allow SSH on public interface
    usePrivateIpAddress = true;
    securityGroups = with resources.ec2SecurityGroups; (
      [ dscp-ssh-private-sg ]
      ++ (if internal then
      [ dscp-witness-private-sg dscp-witness-api-private-sg ]
      else
      [ dscp-witness-public-sg dscp-witness-api-public-sg ]
    ));
  };

}
