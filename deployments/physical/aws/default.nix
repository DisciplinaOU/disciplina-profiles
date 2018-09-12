{ accessKeyId
  , domain ? null
  , realDomain ? null
  , DNSZone ? null
  , region
  , zone
  , backups ? false
  , production ? false
  , keydir, faucetUrl
  , deploy-target
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

  defaults = { resources, config, lib, name, ... }: {
    imports = [
      "${import ../../../nixpkgs-src.nix}/nixos/modules/virtualisation/amazon-image.nix"
      (import ./ssl.nix { inherit realDomain keydir; })
    ];
    dscp = { inherit keydir; };

    deployment.route53 = lib.optionalAttrs (realDomain != null) {
      inherit accessKeyId;
      usePublicDNSName = !production;
      hostName =  "${config.networking.hostName}.net.${realDomain}";
    };

    deployment.targetEnv = "ec2";

    deployment.ec2 = with resources; {
      inherit region accessKeyId;
      instanceType = lib.mkDefault "c5.xlarge";
      associatePublicIpAddress = lib.mkDefault true;
      ebsInitialRootDiskSize = lib.mkDefault 30;
      keyPair = resources.ec2KeyPairs.default;
      securityGroupIds = [ ec2SecurityGroups.dscp-default-sg.name ];
      subnetId = lib.mkForce vpcSubnets.dscp-subnet;
      elasticIPv4 = if production then elasticIPs."${name}-ip" else "";
    };
  };

  witness0 = import ./nodes/witness.nix { n = 0; internal = true; };
  witness1 = import ./nodes/witness.nix { n = 1; };
  witness2 = import ./nodes/witness.nix { n = 2; };
  witness3 = import ./nodes/witness.nix { n = 3; };
  builder  = import ./nodes/builder.nix { inherit domain faucetUrl witnessUrl deploy-target; };
}
