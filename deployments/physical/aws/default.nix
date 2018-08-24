{ accessKeyId, domain, region, zone, realDomain, backups ? false, keydir }:

{
  resources = (import ./resources.nix {
    inherit region zone accessKeyId;
  }) // {
    # route53RecordSets = {
    #   rs-ci = { resources, ... }: {
    #     inherit accessKeyId;
    #     zoneName = "${domain}.";
    #     domainName = "ci.${domain}.";
    #     recordType = "CNAME";
    #     recordValues = [ "builder.${domain}" ];
    #   };
    # };
  };

  defaults = { resources, config, lib, ... }: {
    imports = [
      "${import ../../../nixpkgs-src.nix}/nixos/modules/virtualisation/amazon-image.nix"
      (import ./ssl.nix { inherit realDomain keydir; })
    ];
    dscp = { inherit keydir; };

    deployment.route53 = {
      inherit accessKeyId;
      usePublicDNSName = true;
      hostName =  "${config.networking.hostName}.${domain}";
    };

    deployment.targetEnv = "ec2";

    deployment.ec2 = {
      inherit region accessKeyId;
      associatePublicIpAddress = lib.mkDefault true;
      ebsInitialRootDiskSize = lib.mkDefault 50;
      keyPair = resources.ec2KeyPairs.default;
      securityGroupIds = [ resources.ec2SecurityGroups.dscp-sg.name ];
      securityGroups = [];
      subnetId = lib.mkForce resources.vpcSubnets.dscp-subnet;
    };
  };

  witness1 = import ./nodes/witness.nix { inherit realDomain region; num = 1; };
  witness2 = import ./nodes/witness.nix { inherit realDomain region; num = 2; };
  witness3 = import ./nodes/witness.nix { inherit realDomain region; num = 3; };
  builder = import ./nodes/builder.nix;
}
