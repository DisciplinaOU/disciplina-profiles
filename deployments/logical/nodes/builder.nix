{ config, lib, pkgs, ... }:
let keys = config.dscp.keys; in
{
  # stack2nix <3
  nix.useSandbox = false;

  # Default = slow
  nix.maxJobs = 4;
  nix.buildCores = 0;

  # To copy closures around
  nix.trustedUsers = [ "chris" ];

  # services.buildkite-agent = {
  #   enable = true;
  #   name = "dscp-runner";
  #   package = pkgs.buildkite-agent3;
  #   runtimePackages = with pkgs; [
  #     # Basics
  #     bash nix gnutar gzip
  #     # git checkout fails without this because .gitattributes defines it as clean/smudge filter
  #     git-crypt
  #   ];
  #   tokenPath = toString keys.buildkite-token;
  #   meta-data = "queue=dscp,nix=true,nixops=true";
  #   openssh.privateKeyPath = toString keys.buildkite-ssh-private;
  #   openssh.publicKeyPath = toString keys.buildkite-ssh-public;
  #   extraConfig = ''
  #     shell="${pkgs.bash}/bin/bash -e -c"
  #   '';
  # };

  # Make sure admins can read/write the nixops state file to allow wrapper script access
  # users.extraUsers.buildkite-agent.extraGroups = [ "nixops" ];
  # system.activationScripts.nixops = {
  #   deps = [];
  #   text = ''
  #     chgrp nixops /var/lib/buildkite-agent
  #     chmod g+rwx /var/lib/buildkite-agent

  #     chgrp -R nixops /var/lib/buildkite-agent/.nixops
  #     chmod -R g+rw /var/lib/buildkite-agent/.nixops
  #     chmod g+rwx /var/lib/buildkite-agent/.nixops
  #   '';
  # };


  environment.systemPackages = with pkgs; [
    nixops-git
  ];

  users.extraGroups.nixops = {};
  users.users.nixops = {
    isSystemUser = true;
    group = "nixops";
    # keys: read nixops ephemeral keys
    # users: read nix files from user homes
    extraGroups = [ "keys" "users" ];
    home = "/var/lib/nixops";
    createHome = true;
  };

  security.sudo = {
    extraRules = [
      {
      ##
      # Allow members of the `wheel` group, as well as user `buildkite-agent`
      # to execute `nixops deploy` as the `nixops` user.
      commands = [
        { command = "${pkgs.nixops-git}/bin/nixops deploy *";
          options = [ "SETENV" "NOPASSWD" ]; }
        { command = "${pkgs.nixops-git}/bin/nixops info";
          options = [ "SETENV" "NOPASSWD" ]; }
        { command = "${pkgs.nixops-git}/bin/nixops list";
          options = [ "SETENV" "NOPASSWD" ]; }
        { command = "${pkgs.nixops-git}/bin/nixops check";
          options = [ "SETENV" "NOPASSWD" ]; }
      ];
      groups = [ "wheel" "nixops" ];
      users = [ "buildkite-agent" ];
      runAs = "nixops";
      }
    ];
    extraConfig = ''
      Defaults env_keep+=NIX_PATH
    '';
  };
  system.activationScripts.aws-credentials = {
    deps = [];
    text = ''
      mkdir -p /var/lib/nixops/.aws
      chmod -R go-rwx /var/lib/nixops/.aws
      ln -sf /run/keys/aws-credentials /var/lib/nixops/.aws/credentials
      chown -R nixops:nixops /var/lib/nixops/.aws
    '';
  };

  services.nginx = {
    enable = true;
    upstreams.witness = {
      servers = {
        "http://witness1:4030" = { };
        "http://witness2:4030" = { };
        "http://witness3:4030" = { };
      };
    };
    virtualHosts = {
      witness = {
        default = true;
        locations."/".proxyPass = "http://witness";
      };
    };
  };

  dscp.keys = {
    # buildkite-token =       { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    # buildkite-ssh-private = { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    # buildkite-ssh-public =  { services = [ "buildkite-agent" ]; user = "buildkite-agent"; };
    aws-credentials = { user = "nixops"; shared = false; };
  };
}
