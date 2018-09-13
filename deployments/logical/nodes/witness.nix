{ n }: { pkgs, lib, config, nodes, name, ... }:
let keys = config.dscp.keys; in
{
  # todo: move this to cd profile
  disciplina.witness = {
    config-key = "alpha";
    public-ip = "$(curl http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null)";
    openFirewall = true;
    type = "witness";
    witness = {
      comm-n = n;
      comm-sec = "$(cat ${toString keys.committee-secret})";
    };
    peers = lib.concatMap (nodename: if (nodename == name || !(lib.hasPrefix "witness" nodename)) then []
              else ["$(getent hosts ${nodename} | awk '{print $1}'):4010:4011"]) (lib.attrNames nodes);
  };

  services.journald = {
    rateLimitBurst = 0;
    rateLimitInterval = "0";
  };

  dscp.keys = {
    committee-secret = { services = [ "disciplina-witness" ]; user = "disciplina"; };
  };
}
