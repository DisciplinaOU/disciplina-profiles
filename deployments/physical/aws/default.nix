{ accessKeyId, domain ? null, region, zone, realDomain ? null, backups ? false, keydir }:

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

    deployment.route53 = lib.mkIf (realDomain != null) {
      inherit accessKeyId;
      usePublicDNSName = lib.mkDefault false;
      hostName =  "${config.networking.hostName}.${realDomain}";
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

  witness0 = import ./nodes/witness.nix { internal = true; };
  witness1 = import ./nodes/witness.nix { };
  witness2 = import ./nodes/witness.nix { };
  witness3 = import ./nodes/witness.nix { };
  builder = import ./nodes/builder.nix { inherit domain; };
}
