{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.epmd;
in

{
  options = {
    services.epmd = {
      enable = mkEnableOption "epmd";

      package = mkOption {
        default = pkgs.erlang;
        type = types.package;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.epmd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/epmd";
      };
    };
  };
}
