{ lib, pkgs, config, ... }:
let
  disciplina-options = { name, ... }: {
    options = with lib; with types; {
      config-file = mkOption { type = string; };
      config-key = mkOption { type = string; };
      bind-port1 = mkOption { type = int; default = 4010; };
      bind-port2 = mkOption { type = int; default = 4011; };
      public-ip = mkOption { type = string; };
      bind-host = mkOption { type = nullOr string; default = "*"; };
      debug = mkEnableOption "debug";
      extraArgs = mkOption { type = listOf string; default = []; };
      openFirewall = mkEnableOption "firewall port opening";
      package = mkOption { type = package; default = pkgs.disciplina; };
      peers = mkOption {
        type = listOf string; default = [];
      };
      faucet = {
        listen = mkOption { type = nullOr string; default = null; };
        genKey = mkOption { type = bool; default = true; };
        translatedAmount = mkOption { type = int; example = 20; };
        witnessBackend = mkOption { type = string; example = "127.0.01:4020"; };
        dryRun = mkEnableOption "dry run (do not communicate to backend)";
      };
      educator = {
        bot = {
          enable = mkEnableOption "educator bot";
          delay = mkOption { type = string; default = "3s"; };
          seed = mkOption { type = nullOr string;  default = null; };
        };
        listen = mkOption { type = nullOr string; default = null; };
        genKey = mkOption { type = bool; default = true; };
      };
      type = mkOption {
        type = enum [ "educator" "witness" "faucet" ];
      };
      witness = {
        listen = mkOption { type = nullOr string; default = "0.0.0.0:4030"; example = "127.0.0.1:4030"; };
        genKey = mkOption { type = bool; default = true; };
        comm-n = mkOption { type = nullOr int; default = null; example = 1; };
        comm-sec = mkOption { type = nullOr string; default = null; example = "MAV5Q5xJNB5z3zkLMK8S"; };
      };
    };
  };
in
{
  options.disciplina = with lib; mkOption {
    type = with types; attrsOf (submodule disciplina-options);
    default = {};
  };
  config.users.users = lib.mkIf (config.disciplina != {}) {
    disciplina = {
      home = "/var/lib/disciplina";
      createHome = true;
      isSystemUser = true;
      extraGroups = [ "keys" ];
    };
  };
  config.systemd.services = lib.mkMerge (lib.mapAttrsToList (name: cfg:
  let
    args = with cfg; let state = "/var/lib/disciplina/${name}"; in
    [ "--config ${config-file}"
      "--config-key ${config-key}"
      "--log-dir /var/log/disciplina/${name}" ]
      ++ (if (type == "witness" || type == "educator") then [
        "--db-path ${state}/witness.db"
        "--bind ${public-ip}:${toString bind-port1}:${toString bind-port2}"
        "--bind-internal '${bind-host}:${toString bind-port1}:${toString bind-port2}'"
        "--witness-keyfile ${state}/witness.key" ]
        ++ (builtins.map (f: "--peer ${f}") peers)
        ++ (lib.optional (!isNull witness.listen) "--witness-listen ${witness.listen}")
        ++ (lib.optional witness.genKey "--witness-gen-key")
        ++ (lib.optional (!isNull witness.comm-n) "--comm-n ${toString witness.comm-n}")
        ++ (lib.optional (!isNull witness.comm-sec) "--comm-sec ${toString witness.comm-sec}")
        else [])
      ++ (if (type == "educator") then ([
        "--educator-keyfile ${state}/educator.key"
        "--sql-path ${state}/educator.db"
      ]
        ++ (lib.optional (!isNull educator.listen) "--student-listen ${educator.listen}")
        ++ (lib.optional educator.genKey "--educator-gen-key")
      ) else [])
        ++ (lib.optionals educator.bot.enable ([
        "--educator-bot"
        "--educator-bot-delay ${educator.bot.delay}"
        ] ++ (lib.optional (educator.bot.seed != null) "--educator-bot-seed ${educator.bot.seed}")))
      ++ (if (type == "faucet") then [
        "--translated-amount ${toString faucet.translatedAmount}"
        "--faucet-listen ${faucet.listen}"
        "--witness-backend ${faucet.witnessBackend}"
        "--faucet-keyfile ${state}/faucet.key"
      ]
        ++ (lib.optional faucet.genKey "--faucet-gen-key")
        ++ (lib.optional faucet.dryRun "--dry-run")
      else []);
  in
  with cfg; {
    "disciplina-${name}" = {
      wantedBy = [ "multi-user.target" ];
      script = "dscp-${type} ${lib.concatStringsSep " " (args ++ extraArgs)}";
      after = [ "network.target" ];
      requires = [ "network.target" ];
      path = with pkgs; [ package curl getent gawk ];
      serviceConfig = {
        StateDirectory = "disciplina";
        LogsDirectory = "disciplina";
        User = "disciplina";
        WorkingDirectory = "-/var/lib/disciplina/${name}";
      };
      preStart = ''
        mkdir -p /var/lib/disciplina/${name} /var/log/disciplina/${name}
      '';
    };
  }) config.disciplina);
  config.networking.firewall = lib.mkMerge (lib.mapAttrsToList (name: cfg: with cfg; {
    allowedTCPPorts = lib.mkIf (openFirewall && type != "faucet") [
      bind-port1 bind-port2
    ];
  }) config.disciplina);
}
