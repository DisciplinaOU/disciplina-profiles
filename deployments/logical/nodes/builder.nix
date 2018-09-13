{ config, lib, pkgs, nodes, ... }:
let
  keys = config.dscp.keys;
  ports = {
    prometheus = 9090;
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
  nix = {
    # stack2nix <3
    useSandbox = false;

    # Default = slow
      maxJobs = 4;
      buildCores = 0;

      binaryCaches = [
        "https://cache.nixos.org"
        "https://serokell.cachix.org"
      ];
      binaryCachePublicKeys = [
        "serokell-1:aIojg2Vxgv7MkzPJoftOO/I8HKX622sT+c0fjnZBLj0="
        "serokell.cachix.org-1:5DscEJD6c1dD1Mc/phTIbs13+iW22AVbx0HqiSb+Lq8="
      ];
  };

    boot.kernel.sysctl = {
      "net.core.somaxconn" = 512;
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
              "/".root = "${pkgs.disciplina-faucet-frontend}";
            };
          };

          explorer.locations = {
            "/api".proxyPass = "http://witness";
            "/".root = "${pkgs.disciplina-explorer-frontend}";
          };
      
          prometheus.locations."/".proxyPass = "http://localhost:${toString ports.prometheus}";
        };
      };

      services.prometheus = {
        enable = true;
        listenAddress = "0.0.0.0:${toString ports.prometheus}";
        extraFlags = [
          "--web.enable-admin-api"
        ];
        configText = pkgs.writeText "prometheus.yaml" (builtins.toJSON {
          global = { scrape_interval = "15s"; };
          alerting.alertmanagers = [ {
            static_config.targets = [ "alertmanager.serokell.io" ];
            scheme = "https";
            basic_auth = {
              username = "alertmanager";
              password_file = toString keys.alertmanager_token;
            };
          } ];
          rule_files = [ "${rulesFile}" ];
          scrape_configs = [
            { job_name = "node";
              static_configs.targets =
                lib.mapAttrsToList
                  (name: node: "${name}:${toString node.config.services.prometheus.exporters.node.port}")
                  nodes; }
            { job_name = "telegraf";
              static_configs.targets = ["localhost:${toString ports.telegraf}"] }
            { job_name = "prometheus";
              static_configs.targets = ["localhost:${toString ports.prometheus}"] }
          ];
        });
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

      dscp.keys = {
        alertmanager-token =    { services = [ "alertmanager" ]; user = "alertmanager"; };
        faucet-keyfile  = { user = "disciplina"; services = [ "disciplina-faucet" ]; };
      };
}
