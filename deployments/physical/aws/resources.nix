{ region, accessKeyId, zone }:

rec {
  vpc.dscp-vpc = {
    inherit region accessKeyId;
    instanceTenancy = "default";
    enableDnsSupport = true;
    enableDnsHostnames = true;
    cidrBlock = "10.0.0.0/16";
  };

  vpcSubnets.dscp-subnet =
  { resources, lib, ... }:
  {
    inherit region accessKeyId zone;
    vpcId = resources.vpc.dscp-vpc;
    cidrBlock = "10.0.0.0/19";
    mapPublicIpOnLaunch = true;
  };

  ec2SecurityGroups.dscp-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      { fromPort =    22; toPort =    22; sourceIp = "0.0.0.0/0"; }
      { fromPort =    80; toPort =    80; sourceIp = "0.0.0.0/0"; }
      { fromPort =   443; toPort =   443; sourceIp = "0.0.0.0/0"; }
      # Witness node
      { fromPort =  4010; toPort =  4010; sourceIp = "0.0.0.0/0"; }
      # prometheus node exporter
      # TODO: allow from Jupiter
      { fromPort =  9100; toPort =  9100; sourceIp = vpc.dscp-vpc.cidrBlock; }
      # mosh
      { fromPort = 60000; toPort = 60010; protocol = "udp"; sourceIp = "0.0.0.0/0"; }
    ];
  };

  vpcRouteTables.dscp-route-table =
  { resources, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
  };

  vpcRouteTableAssociations.dscp-assoc =
  { resources, ... }:
  {
    inherit region accessKeyId;
    subnetId = resources.vpcSubnets.dscp-subnet;
    routeTableId = resources.vpcRouteTables.dscp-route-table;
  };

  vpcInternetGateways.dscp-igw =
  { resources, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
  };

  vpcRoutes.dscp-route =
  { resources, ... }:
  {
    inherit region accessKeyId;
    routeTableId = resources.vpcRouteTables.dscp-route-table;
    destinationCidrBlock = "0.0.0.0/0";
    gatewayId = resources.vpcInternetGateways.dscp-igw;
  };
  ec2KeyPairs.default = {
    name = "dscp-kp";
    inherit accessKeyId region;
  };
}
