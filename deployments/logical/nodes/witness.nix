{ n }: { pkgs, lib, config, ... }: {
  # todo: move this to cd profile
  disciplina."witness" = {
    config-file = "${pkgs.writeText "config.yaml" ''
demo:
  core:
    homeParam:
      path: "./tmp/"
    slotDuration: 10000 # 10 s
    genesis:
      genesisSeed: "GromakNaRechke"
      governance:
        type: committeeOpen
        secret: "opencommittee"
        n: 2
      distribution:
        - equal: 1000
        - specific:
          - - "LL4qKn62hrdLh1vkyiidEFLfCaAngaVmtu3ipGVSubhackXS4pXNbeDC"
            - 100
    ''}";
    config-key = "demo";
    bind-port1 = 4010;
    bind-port2 = 4011;
    public-ip = "$(curl http://169.254.169.254/latest/meta-data/public-ipv4)";
    openFirewall = true;
    type = "witness";
    witness = {
      listen = "0.0.0.0:4030";
    } // (lib.optionalAttrs (n < 3) { comm-n = n - 1; });
    # peers = lib.concatMap (nodename: if nodename == name then [] else
    # ["$(getent hosts ${nodes."${nodename}".config.networking.hostName} | awk '{print $1;exit}'):4010:4011"])
    # (lib.attrNames nodes);
  };
  networking.firewall.allowedTCPPorts = [ 4030 80 ];
  services.openssh.ports = lib.mkForce [ 22 ];
  services.nginx = {
    enable = true;
    # openFirewall = true;
    virtualHosts.witness = {
      serverName = config.networking.hostName;
      locations."/".proxyPass = "http://localhost:4030";
    };
  };
}
