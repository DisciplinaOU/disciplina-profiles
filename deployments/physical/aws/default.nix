{ accessKeyId
  , domain ? null
  , realDomain ? null
  , DNSZone ? null
  , region
  , zone
  , backups ? false
  , production ? false
  , keydir, faucetUrl
  , queue
  , witnessUrl }:

{
  resources = (import ./resources.nix {
    inherit region zone accessKeyId production;
  }) // {
    route53RecordSets = if (DNSZone != null) then {
      rs-faucet = { resources, ... }: {
        inherit accessKeyId;
        zoneName = "${DNSZone}.";
        domainName = "faucet.${domain}.";
        recordType = "CNAME";
        recordValues = [ "builder.net.${domain}" ];
      };
      rs-explorer = { resources, ... }: {
        inherit accessKeyId;
        zoneName = "${DNSZone}.";
        domainName = "explorer.${domain}.";
        recordType = "CNAME";
        recordValues = [ "builder.net.${domain}" ];
      };
      rs-witness = { resources, ... }: {
        inherit accessKeyId;
        zoneName = "${DNSZone}.";
        domainName = "witness.${domain}.";
        recordType = "CNAME";
        recordValues = [ "builder.net.${domain}" ];
      };
    } else {};
  };

  defaults = { resources, config, lib, ... }: {
    imports = [
      "${import ../../../nixpkgs-src.nix}/nixos/modules/virtualisation/amazon-image.nix"
      (import ./ssl.nix { inherit realDomain keydir; })
    ];
    dscp = { inherit keydir; };

    deployment.route53 = {
      inherit accessKeyId;
      usePublicDNSName = lib.mkDefault false;
      hostName =  "${config.networking.hostName}.net.${realDomain}";
    };

    deployment.targetEnv = "ec2";

    deployment.ec2 = {
      inherit region accessKeyId;
      associatePublicIpAddress = lib.mkDefault true;
      ebsInitialRootDiskSize = lib.mkDefault 50;
      keyPair = resources.ec2KeyPairs.default;
      securityGroupIds = [ resources.ec2SecurityGroups.dscp-default-sg.name ];
      securityGroups = [];
      subnetId = lib.mkForce resources.vpcSubnets.dscp-subnet;
    };
  };

  witness0 = import ./nodes/witness.nix { inherit production; n = 0; internal = true; };
  witness1 = import ./nodes/witness.nix { inherit production; n = 1; };
  witness2 = import ./nodes/witness.nix { inherit production; n = 2; };
  witness3 = import ./nodes/witness.nix { inherit production; n = 3; };
  builder  = import ./nodes/builder.nix { inherit domain faucetUrl witnessUrl production queue; };
}
