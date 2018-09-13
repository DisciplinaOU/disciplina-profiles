{ lib, pkgs, config, name, deploymentName, ... }:

let
  wheel = [ "chris" "kirelagin" "yegortimoshenko" "yorick" ];
  ops = wheel ++ [ "flyingleafe" "volhovm" ];
  expandUser = _name: keys: {
    extraGroups = (lib.optional (builtins.elem _name wheel) "wheel") ++ (lib.optional (builtins.elem _name ops) "nixops") ++ [ "systemd-journal" ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = keys;
  };
  gitinfo = builtins.readDir ./.. ? ".git" then {
    revision = lib.commitIdFromGitRepo ../.git;
  } else { revision = "unknown"; };
in

{
  imports = [
    ../keys
    ./services/disciplina.nix
    ./services/prometheus.nix
  ];

  environment.systemPackages = with pkgs; [
    binutils
    curl
    dnsutils
    gawk
    gdb
    git
    git-crypt
    gnused
    htop
    iptables
    ldns
    lsof
    mosh
    ncdu
    rxvt_unicode.terminfo
    strace
    sysstat
    tcpdump
    termite.terminfo
    tig
    tmux
    tree
    vim
  ];

  networking.firewall = {
    allowPing = false;
    logRefusedConnections = false;
  };

  nix.autoOptimiseStore = true; # autodeduplicate files in store

  nixpkgs.overlays = [(import ../pkgs)];

  programs.zsh.enable = true;
  programs.mosh.enable = true;

  security.sudo = {
    wheelNeedsPassword = false;
  };
  services.sshguard.enable = true;

  nix.gc = {
    automatic = true;
    # delete so there is 15GB free, and delete very old generations
    # delete-older-than by itself will still delete all non-referenced packages (ie build dependencies)
    options = ''--max-freed "$((15 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))" --delete-older-than 14d'';
  };

  services.nginx = {
    # https://github.com/NixOS/nixpkgs/issues/25485
    appendHttpConfig = ''
      if_modified_since off;
      add_header Last-Modified "";
      etag off;
    '';
    recommendedOptimisation = lib.mkDefault true;
    recommendedProxySettings = lib.mkDefault true;
    recommendedTlsSettings = lib.mkDefault true;
  };
  services.nixosManual.enable = false;

  services.prometheus.exporters = {
    node = {
      enable = true;
      openFirewall = true;
      enabledCollectors = [ "systemd" "logind" ];
      disabledCollectors = [ "timex" ];
      extraFlags = ["--collector.textfile.directory /etc/node-exporter"];
    };
  };
  };
  environment.etc."node-exporter/server_info.prom".text = ''
    # HELP nix_desc NixOps deployment info
    # TYPE nix_desc gauge
    nix_desc{deploymentName="${deploymentName}", nodename="${name}", deployer="${builtins.getEnv "USER"}", rev="${gitinfo.revision}"} 1
  '';

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  users.mutableUsers = false;

  users.extraGroups.nixops = {};
  users.users = lib.mapAttrs expandUser (import ../keys/ssh.nix);

  nixpkgs.config.allowUnfree = true;
}
