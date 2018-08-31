{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.derivery;
in

{
  options = {
    services.derivery = {
      enable = mkEnableOption "Derivery, a Nix CI/CD";

      autoRebuild = mkEnableOption "Enable continuous delivery";

      configPath = mkOption {
        description = "Path to OTP config";
        type = types.string;
      };

      home = mkOption {
        default = "/var/lib/derivery";
        type = types.string;
      };

      package = mkOption {
        default = pkgs.derivery;
        type = types.package;
      };

      sshKeyPath = mkOption {
        description = "Path to SSH key";
        type = types.string;
      };

      virtualHost = mkOption {
        default = "derivery";
	type = types.nullOr types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    services.epmd.enable = true;

    services.nginx.virtualHosts = mkIf (cfg.virtualHost != null) {
      "${cfg.virtualHost}".locations."/".proxyPass = "http://localhost:50493";
    };

    systemd.services.derivery = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "epmd.service" ];
      environment = {
        ERL_FLAGS = "-config /tmp/derivery.config";
        GIT_SSH_COMMAND = "ssh -i /run/derivery-ssh-key -o StrictHostKeyChecking=no";
        NIX_PATH = "ssh-key=/run/derivery-ssh-key:${config.environment.sessionVariables.NIX_PATH}";
      };
      preStart = ''
        install -m 400 -o derivery ${cfg.configPath} /tmp/derivery.config
        install -m 040 -g nixbld ${cfg.sshKeyPath} /run/derivery-ssh-key
      '';
      path = with pkgs; [
        erlang
        git
        gnutar
        gzip
        nixUnstable
        openssh
        which
      ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/derivery -noinput";
        PermissionsStartOnly = true;
        PrivateTmp = true;
        SupplementaryGroups = [ "nixbld" ];
        User = "derivery";
      };
    };

    systemd.services.derivery-rebuild = {
      environment = config.nix.envVars // {
        inherit (config.environment.sessionVariables) NIX_PATH;
        inherit (config.systemd.services.derivery.environment) GIT_SSH_COMMAND;
        HOME = "/root";
      };

      path = [
        config.nix.package.out
        pkgs.git
        pkgs.gnutar
        pkgs.xz.bin
      ];

      restartIfChanged = false;

      serviceConfig = {
        ExecStart = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch";
        Type = "oneshot";
      };
    };

    systemd.paths.derivery-rebuild = mkIf cfg.autoRebuild {
      wantedBy = [ "paths.target" ];

      pathConfig = {
        PathChanged = cfg.home;
        Unit = "derivery-rebuild.service";
      };
    };

    users.users.derivery = {
      createHome = true;
      home = cfg.home;
    };

    system.activationScripts.derivery-home-perms = lib.stringAfter [ "users" ] ''
      chmod 755 ${cfg.home}
    '';
  };
}
