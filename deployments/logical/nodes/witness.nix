{ n }: { pkgs, lib, config, nodes, ... }: {
  # todo: move this to cd profile
  disciplina."witness" = {
    config-file = "${pkgs.writeText "config.yaml" ''
demo: &demo
  core: &demo-core
    slotDuration: 10000 # 10 s
    genesis: &demo-genesis
      genesisSeed: "GromakNaRechke"
      governance:
        type: committeeOpen
        secret: "opencommittee"
        n: 4
      distribution:
        - equal: 1000
        - specific:
          - # faucet
            - "LL4qKn62hrdLh1vkyiidEFLfCaAngaVmtu3ipGVSubhackXS4pXNbeDC"
            - 100

alpha:
  <<: *demo
  core:
    <<: *demo-core
    slotDuration: 20000 # 20s
    genesis:
      <<: *demo-genesis
      genesisSeed: "disciplina-alpha"
      governance:
        type: committeeClosed
        participants:
          - "LL4qKmQ2bqfmZzVwFYWVtgcFM2Gbku3vD8zrsq7wSGxcHHeG2Sg2dMF7"
          - "LL4qKrReykH2tVzJ3URSd3iq77Bhua5rbdHvjQ92VLnUMyXY7vp5YbAV"
          - "LL4qKq3Q31CurnN2DRKuC6iim3JQc46cnT6fL3V6qJAi979zV4zKM34J"
          - "LL4qKsoarNjaVHLxM8pD5Yoo5kwsEeUWm8E5iACF993t3R41yYbuwa6a"
      distribution:
        - equal: 4
        - specific:
          - # faucet
            - "LL4qKkm96QnsHmNpYPrfRmToHEZfYForxUKwtJ8CmnbGwzN4TpP4gPx8"
            - 20000000
    ''}";
    config-key = "alpha";
    public-ip = "$(curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)";
    openFirewall = true;
    type = "witness";
    witness = {
      comm-n = n;
    };
    # peers = [
    #   "witness0:4010:4011"
    #   "witness1:4010:4011"
    #   "witness2:4010:4011"
    #   "witness3:4010:4011"
    # ];
    peers = lib.concatMap (nodename: if (nodename == "witness${toString n}" || !(lib.hasPrefix nodename "witness")) then [] else
    ["$(getent hosts ${nodes."${nodename}".config.networking.hostName} | awk '{print $1;exit}'):4010:4011"])
    (lib.attrNames nodes);
  };
  networking.firewall.allowedTCPPorts = [ 4030 80 ];
  services.openssh.ports = lib.mkForce [ 22 ];
  services.nginx = {
    enable = true;
    virtualHosts.witness = {
      serverName = config.networking.hostName;
      locations."/".proxyPass = "http://localhost:4030";
    };
  };
}
