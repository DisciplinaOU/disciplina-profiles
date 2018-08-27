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
      bash nix gnutar gzip
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

  # Make sure admins can read/write the nixops state file to allow wrapper script access
  users.extraGroups.nixops = {};
  users.extraUsers.buildkite-agent.extraGroups = [ "nixops" ];
  system.activationScripts.nixops = {
    deps = [];
    text = ''
      chgrp nixops /var/lib/buildkite-agent
      chmod g+rwx /var/lib/buildkite-agent

      chgrp -R nixops /var/lib/buildkite-agent/.nixops
      chmod -R g+rw /var/lib/buildkite-agent/.nixops
      chmod g+rwx /var/lib/buildkite-agent/.nixops
    '';
  };

  dscp.keys = {
    buildkite-token =       { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    buildkite-ssh-private = { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    buildkite-ssh-public =  { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    aws-credentials =   rec { services = [ "buildkite-agent" ]; user = "buildkite-agent"; shared = false; } ;
  };
}
