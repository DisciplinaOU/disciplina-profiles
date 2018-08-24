{ config, lib, pkgs, ... }:
let keys = config.dscp.keys; in
{
  services.buildkite-agent = {
    enable = true;
    name = "dscp-runner";
    package = pkgs.buildkite-agent3;
    runtimePackages = with pkgs; [ bash nix gnutar gzip ];
    tokenPath = toString keys.buildkite-token;
    meta-data = "queue=dscp,nix=true";
    openssh.privateKeyPath = toString keys.buildkite-ssh-private;
    openssh.publicKeyPath = toString keys.buildkite-ssh-public;
    extraConfig = ''
      shell="${pkgs.bash}/bin/bash -e -c"
    '';
  };
}
