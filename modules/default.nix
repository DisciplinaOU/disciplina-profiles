{ lib, pkgs, config, name, deploymentName ? "unknown", ... }:

let
  wheel = [ "chris" "kirelagin" "yegortimoshenko" "yorick" ];
  ops = wheel ++ [ "flyingleafe" "volhovm" ];
  expandUser = _name: keys: {
    extraGroups = (lib.optional (builtins.elem _name wheel) "wheel") ++ (lib.optional (builtins.elem _name ops) "nixops") ++ [ "systemd-journal" ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = keys;
  };
  getGitRev = pkgs.stdenv.mkDerivation {
    name = "get-git-revision";
    src = ./..;
    buildInputs = [ pkgs.git pkgs.git-crypt ];
    buildCommand = ''
      cd $src
      (echo {
      echo description = \"$(git describe --all --dirty)\"";"
      echo revision = \"$(git rev-parse --verify HEAD)\"";"
      echo }) > $out
    '';
  };
  GITDESC = builtins.getEnv "GITDESC";
  # try the environment variables (set by the wrapper/ci) first, fall back to getGitRev if a .git dir exists
  gitinfo = if GITDESC == "" && builtins.readDir ./.. ? ".git" then import "${getGitRev}" else {
    description = GITDESC;
    revision = builtins.getEnv "GITREV";
  };
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
    extraRules = [
      {
      commands = [
        { command = "${pkgs.systemd}/bin/systemctl start disciplina-*";
          options = [ "NOPASSWD" ]; }
        { command = "${pkgs.systemd}/bin/systemctl stop disciplina-*";
          options = [ "NOPASSWD" ]; }
        { command = "${pkgs.systemd}/bin/systemctl restart disciplina-*";
          options = [ "NOPASSWD" ]; }
      ];
      groups = [ "wheel" "nixops" ];
      runAs = "root";
      }
    ];
  };

  services.fail2ban = {
    enable = true;
    # Ban repeat offenders longer:
    jails.recidive = ''
      filter = recidive
      action = iptables-allports[name=recidive]
      maxretry = 5
      bantime = 604800 ; 1 week
      findtime = 86400 ; 1 day
    '';
    jails.DEFAULT = ''
      ignoreip = 127.0.0.1/8 84.81.255.167
    '';
    jails.ssh-iptables = ''
      maxretry = 10
      mode     = aggressive
    '';
  };

  nix.gc = {
    automatic = true;
    # delete so there is 15GB free, and delete very old generations
    # delete-older-than by itself will still delete all non-referenced packages (ie build dependencies)
    options = ''--max-freed "$((15 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))" --delete-older-than 14d'';
  };

  # https://github.com/NixOS/nix/issues/1964
  nix.extraOptions = ''
    tarball-ttl = 0
  '';

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
      enabledCollectors = [ "systemd" ];
      disabledCollectors = [ "timex" ];
    };
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  users.mutableUsers = false;

  users.extraGroups.nixops = {};
  users.users = lib.mapAttrs expandUser (import ../keys/ssh.nix);

  nixpkgs.config.allowUnfree = true;
}
