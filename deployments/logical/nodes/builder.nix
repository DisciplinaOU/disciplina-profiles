{ config, lib, pkgs, ... }:
let
  keys = config.dscp.keys;
  ports = {
    grafana = 3000;
    prometheus = 9090;
    exporters = {
      node = 9100;
      nginx = 9113;
    };
    alertManager = 9093;
    telegraf = 9273;
    statsd = 8125;
  };
  rulesFile = pkgs.writeText "rules.yaml" ''
    groups:
    - name: serokell
      rules:

      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: slack
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

      - alert: UnitFailed
        expr: node_systemd_unit_state{state="failed"} == 1
        for: 5m
        labels:
          severity: slack
        annotations:
          summary: "Unit {{ $labels.name }} failed."
          description: "Unit {{ $labels.name }} on instance {{ $labels.instance }} has been down for more than 5 minutes."

      - alert: FSFilling
        expr: (node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes > 0.8
        for: 12h
        labels:
          severity: slack
        annotations:
          summary: "File system on {{ $labels.instance }} is filling up."
          description: "File system {{ $labels.mountpoint }} on {{ $labels.instance }} has been over 80% full for over 12 hours."
  '';
in
{
  # stack2nix <3
  nix.useSandbox = false;

  # Default = slow
  nix.maxJobs = 4;
  nix.buildCores = 0;

  boot.kernel.sysctl = {
    "net.core.somaxconn" = 512;
  };

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

  disciplina.faucet = {
    type = "faucet";
    config-file = "${pkgs.disciplina-bin}/etc/disciplina/configuration.yaml";
    config-key = "clusterCi";
    faucet = {
      listen = "127.0.0.1:4014";
      translatedAmount = 20;
      witnessBackend = "http://witness1:4030";
      genKey = false;
      keyFile = keys.faucet-keyfile;
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ ports.statsd ];

  systemd.services.nginx.serviceConfig = {
    LimitNOFILE = 500000;
    LimitNPROC = 500000;
  };

  services.nginx = {
    enable = true;
    appendConfig = ''
      worker_processes auto;
    '';
    commonHttpConfig = ''
      access_log syslog:server=unix:/dev/log,tag=nginx,severity=info combined;
    '';
    eventsConfig = "worker_connections 16384;";
    upstreams.witness = {
      servers = {
        "witness1:4030" = { };
        "witness2:4030" = { };
        "witness3:4030" = { };
      };
      extraConfig = ''
        ip_hash;
        keepalive 32;
      '';
    };

    upstreams.faucet = {
      servers."localhost:4014" = {};
      extraConfig = ''
        keepalive 32;
      '';
    };
    upstreams.grafana.servers."localhost:${toString ports.grafana}" = {};
    upstreams.prometheus.servers."localhost:${toString ports.prometheus}" = {};
    upstreams.alertManager.servers."localhost:${toString ports.alertManager}" = {};

    virtualHosts = {
      witness = {
        default = true;
        locations."/".proxyPass = "http://witness";
      };

      faucet = {
        locations = {
          # "/api/faucet/v1/index.html".alias = "${pkgs.swagger-ui}.override { baseurl = "/api/faucet/v1/swagger.yaml"; }}/index.html";
          "= /api/faucet/v1/".index = "index.html";
          "/api".proxyPass = "http://faucet";
          # "/".root = "${pkgs.disciplina-faucet-frontend}";
        };
      };

      # explorer.locations."/".root = "${pkgs.disciplina-witness-frontend}";
      grafana.locations."/".proxyPass = "http://grafana";
      prometheus.locations."/".proxyPass = "http://prometheus";
      alertManager.locations."/".proxyPass = "http://alertManager";
    };
  };

  services.prometheus = {
    enable = true;
    listenAddress = "0.0.0.0:${toString ports.prometheus}";
    extraFlags = [
      "--web.enable-admin-api"
    ];
    configText = ''
      global:
        scrape_interval: 15s

      alerting:
        alertmanagers:
        - static_configs:
          - targets:
            - 'localhost:${toString ports.alertManager}'

      rule_files:
        - ${rulesFile}

      scrape_configs:
        - job_name: 'node'
          static_configs:
          - targets:
            - 'builder:${toString ports.exporters.node}'
            - 'witness0:${toString ports.exporters.node}'
            - 'witness1:${toString ports.exporters.node}'
            - 'witness2:${toString ports.exporters.node}'
            - 'witness3:${toString ports.exporters.node}'
        - job_name: 'telegraf'
          static_configs:
          - targets:
            - 'builder:${toString ports.telegraf}'
        - job_name: 'prometheus'
          static_configs:
          - targets:
            - 'builder:${toString ports.prometheus}'
    '';
    alertmanager =
    {
      enable = true;
      # webExternalUrl = with config.services.nginx.virtualHosts.alertManager;
      #   "http${lib.optionalString (enableSSL || onlySSL || addSSL || forceSSL) "s"}://${serverName}/";
      webExternalUrl = "https://alertmanager.net.disciplina.io";

      configuration = {
        global = {
          slack_api_url = "https://hooks.slack.com/services/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";
          smtp_from = "monitoring@serokell.io";
          smtp_smarthost = "smtp.gmail.com:587";
          smtp_hello = "builder.net.disciplina.io";
          smtp_auth_username = "monitoring@serokell.io";
          smtp_auth_password = "mjusezftwgdnpisi";
        };
        receivers = [
          {
            name = "ops";
            slack_configs = [
              {
                send_resolved = true;
                channel = "#devops-alerts";
                username = "prometheus";
              }
            ];
            email_configs = [
              {
                to = "operations@serokell.io";
              }
            ];
          }
        ];

        route = {
          receiver = "ops";
        };
      };
    };

  };

  services.telegraf = {
    enable = true;
    extraConfig = {
      inputs.statsd = {
        service_address = ":${toString ports.statsd}";
        parse_data_dog_tags = true;
        metric_separator = ".";
        # protocol = "udp4";
      };

      outputs.prometheus_client = {
        listen = ":${toString ports.telegraf}";
        ## Interval to expire metrics and not deliver to prometheus, 0 == no expiration
        expiration_interval = "60s";
      };
    };
  };

  services.grafana = {
    enable = true;
    port = ports.grafana;
    addr = "0.0.0.0";
    rootUrl = "https://grafana.net.disciplina.io";
    # extraOptions = {
    #   AUTH_GOOGLE_ENABLED = "true";
    #   AUTH_GOOGLE_ALLOWED_DOMAINS = "serokell.io";
    #   AUTH_GOOGLE_ALLOW_SIGN_UP = "true";
    # };
  };

  # systemd.services.grafana.serviceConfig = {
  #   PermissionsStartOnly = true;
  #   # EnvironmentFile = "/root/grafana.env";
  #   # EnvironmentFile = keys.grafana-env;
  # };

  dscp.keys = {
    # grafana-env     = { user = "grafana"; services = [ "grafana" ]; };
    aws-credentials = { user = "nixops"; shared = false; };
    faucet-keyfile  = { user = "disciplina"; services = [ "disciplina-faucet" ]; };
  };
}
