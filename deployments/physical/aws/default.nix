{ accessKeyId
  , logical-domain
  , region
  , zone
  , production ? false
  , hasRoute53 ? false
  , keydir }:

let
  dnszones = [ "serokell.review." ];
  lib = (import ../../../nixpkgs.nix {}).lib;
  CNAME = domainName: recordValues: {
    inherit accessKeyId domainName recordValues;
    DNSZone = lib.findFirst (z: lib.hasSuffix z domainName) dnszones;
    zoneName = "${DNSZone}.";
    recordType = "CNAME";
  };
in
{
  resources = (import ./resources.nix {
    inherit region zone accessKeyId production;
  }) // {
    route53RecordSets = if hasRoute53 then {
      rs-faucet   = { resources, nodes, ... }:
        CNAME "faucet.${logical-domain}."   [ nodes.builder.deployment.route53.hostName ];
      rs-explorer = { resources, nodes, ... }:
        CNAME "explorer.${logical-domain}." [ nodes.builder.deployment.route53.hostName ];
      rs-witness  = { resources, nodes, ... }:
        CNAME "witness.${logical-domain}."  [ nodes.builder.deployment.route53.hostName ];
    } else {};
  };

  defaults = { resources, config, lib, name, ... }: {
    imports = [
      "${import ../../../nixpkgs-src.nix}/nixos/modules/virtualisation/amazon-image.nix"
      (import ./ssl.nix { inherit keydir; domain = logical-domain; })
    ];
    dscp = { inherit keydir; };

    deployment.route53 = lib.optionalAttrs (hasRoute53) {
      inherit accessKeyId;
      usePublicDNSName = true;
      hostName = "${name}.${physical-domain}";
    };

    deployment.targetEnv = "ec2";

    deployment.ec2 = with resources; {
      inherit region accessKeyId;
      instanceType = lib.mkDefault "t2.medium";
      # TODO: set unlimited
      associatePublicIpAddress = lib.mkDefault true;
      ebsInitialRootDiskSize = lib.mkDefault 30;
      keyPair = resources.ec2KeyPairs.default;
      securityGroupIds = [ ec2SecurityGroups.dscp-default-sg.name ];
      subnetId = lib.mkForce vpcSubnets.dscp-subnet;
      elasticIPv4 = if production then elasticIPs."${name}-ip" else "";
    };
    networking.domain = logical-domain;
  };

  witness0 = import ./nodes/witness.nix { internal = true; };
  witness1 = import ./nodes/witness.nix { };
  witness2 = import ./nodes/witness.nix { };
  witness3 = import ./nodes/witness.nix { };
  builder  = import ./nodes/builder.nix;
}
