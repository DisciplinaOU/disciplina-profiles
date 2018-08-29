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
    cidrBlock = "10.0.44.0/24";
    mapPublicIpOnLaunch = true;
  };

  ec2SecurityGroups.dscp-default-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # Prometheus node exporter
      { fromPort =  9100; toPort =  9100; sourceIp = vpc.dscp-vpc.cidrBlock; }
    ];
  };

  ec2SecurityGroups.dscp-http-public-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # Prometheus node exporter
      { fromPort =  80; toPort =  80; sourceIp = "0.0.0.0/0"; }
      { fromPort = 443; toPort = 443; sourceIp = "0.0.0.0/0"; }
    ];
  };

  ec2SecurityGroups.dscp-ssh-private-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # SSH
      { fromPort =    22; toPort =    22; sourceIp = vpc.dscp-vpc.cidrBlock; }
    ];
  };

  ec2SecurityGroups.dscp-ssh-public-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # SSH
      { fromPort =    22; toPort =    22; sourceIp = "0.0.0.0/0"; }
    ];
  };

  ec2SecurityGroups.dscp-witness-public-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # Disciplina witness
      { fromPort =  4010; toPort =  4010; sourceIp = "0.0.0.0/0"; }
      { fromPort =  4011; toPort =  4011; sourceIp = "0.0.0.0/0"; }
    ];
  };

  ec2SecurityGroups.dscp-witness-private-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # Disciplina witness
      { fromPort =  4010; toPort =  4010; sourceIp = vpc.dscp-vpc.cidrBlock; }
      { fromPort =  4011; toPort =  4011; sourceIp = vpc.dscp-vpc.cidrBlock; }
    ];
  };

  ec2SecurityGroups.dscp-witness-api-public-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # Disciplina witness
      { fromPort =  4030; toPort =  4030; sourceIp = "0.0.0.0/0"; }
    ];
  };

  ec2SecurityGroups.dscp-witness-api-private-sg =
  { resources, lib, ... }:
  {
    inherit region accessKeyId;
    vpcId = resources.vpc.dscp-vpc;
    rules = [
      # Disciplina witness
      { fromPort =  4030; toPort =  4030; sourceIp = vpc.dscp-vpc.cidrBlock; }
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
