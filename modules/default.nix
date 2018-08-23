{ lib, pkgs, config, name, deploymentName ? "unknown", ... }:

let
  expandUser = name: keys: {
    extraGroups = [ "wheel" ];
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
  disabledModules = [ "services/security/oauth2_proxy.nix" ];
  imports = [
    ../keys
  ];

  environment.systemPackages = with pkgs; [
    binutils
    dnsutils
    gdb
    git
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

  networking.firewall.logRefusedConnections = false; # silence logging of scanners and knockers

  nix.autoOptimiseStore = true; # autodeduplicate files in store

  nixpkgs.overlays = [(import ../pkgs)];

  programs.zsh.enable = true;
  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

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
    options = ''--max-freed "$((15 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))" --delete-older-than 30d'';
  };

  services.nginx = {
    recommendedOptimisation = lib.mkDefault true;
    recommendedProxySettings = lib.mkDefault true;
    recommendedTlsSettings = lib.mkDefault true;
  };

  services.oauth2_proxy = {
    email.domains = [ "disciplina.io" ];
    keyFile = toString config.dscp.keys.oauth2_proxy;
  };

  services.nixosManual.enable = false;

  # Enable Prometheus exporting on all nodes
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true;
    enabledCollectors = [ "systemd" "logind" ];
    extraFlags = ["--collector.textfile.directory /etc/node-exporter"];
  };
  environment.etc."node-exporter/server_info.prom".text = ''
    # HELP nix_desc NixOps deployment info
    # TYPE nix_desc gauge
    nix_desc{deploymentName="${deploymentName}", nodename="${name}", deployer="${builtins.getEnv "USER"}", desc="${gitinfo.description}", rev="${gitinfo.revision}"} 1
  '';

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  dscp.keys = {
    tarsnap = lib.mkIf config.services.tarsnap.enable {
      keyname = "tarsnap/${name}.rw";
      services = map (x: "tarsnap-${x}") (builtins.attrNames config.services.tarsnap.archives);
    };
    oauth2_proxy = lib.mkIf config.services.oauth2_proxy.enable {
      shared = false;
      services = [ "oauth2_proxy" ];
    };
  };

  users.mutableUsers = false;

  users.users = lib.mapAttrs expandUser (import ../keys/ssh.nix);

  nixpkgs.config.allowUnfree = true;

  # nix 2.1pre because memory problems
  nix.package = pkgs.nixUnstable;


  # prompt colors
  programs.bash.promptInit = let
    deployColor = if deploymentName == "production" then "1;31m" else "0;32m";
  in
    ''
      # Provide a nice prompt if the terminal supports it.
      if [ "$TERM" != "dumb" -o -n "$INSIDE_EMACS" ]; then
        PROMPT_COLOR="1;31m"
        let $UID && PROMPT_COLOR="1;32m"
        PS1="\n\[\033[$PROMPT_COLOR\][\u@\h|\[\033[${deployColor}\]${deploymentName}\[\033[$PROMPT_COLOR\]:\w]\\$\[\033[0m\] "
        if test "$TERM" = "xterm"; then
          PS1="\[\033]2;\h:\u:\w\007\]$PS1"
        fi
      fi
    '';

  programs.zsh.promptInit = let
    deployColor = if deploymentName == "production" then "red" else "green";
  in ''
    autoload -U promptinit && promptinit && prompt walters
    if [[ "$TERM" != "dumb" ]]; then
      export PROMPT="%F{${deployColor}}${deploymentName}%f|$PROMPT"
    else
      export PROMPT="${deploymentName}|$PROMPT"
    fi
  '';
}
