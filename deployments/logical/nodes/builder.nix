{ config, lib, pkgs, ... }:
let keys = config.dscp.keys; in
{
  # stack2nix <3
  nix.useSandbox = false;

  # To copy closures around
  nix.trustedUsers = [ "chris" ];

  services.buildkite-agent = {
    enable = true;
    name = "dscp-runner";
    package = pkgs.buildkite-agent3;
    runtimePackages = with pkgs; [
      # Basics
      bash nix
      # git checkout fails without this because .gitattributes defines it as clean/smudge filter
      git-crypt
    ];
    tokenPath = toString keys.buildkite-token;
    meta-data = "queue=dscp,nix=true,nixops=true";
    openssh.privateKeyPath = toString keys.buildkite-ssh-private;
    openssh.publicKeyPath = toString keys.buildkite-ssh-public;
    extraConfig = ''
      shell="${pkgs.bash}/bin/bash -e -c"
    '';
  };

  dscp.keys = {
    buildkite-token =       { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    buildkite-ssh-private = { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    buildkite-ssh-public =  { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    aws-credentials =   rec { services = [ "buildkite-agent" ]; user = "buildkite-agent"; shared = false; } ;
  };
}
