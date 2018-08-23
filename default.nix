let
  overlay = import ./pkgs {} {};
  nixpkgs = import ./nixpkgs.nix;
  nixpkgs-src = import ./nixpkgs-src.nix;

  eval-machine-info = import "${nixpkgs.nixops-git}/share/nix/nixops/eval-machine-info.nix";

  production-deployment = eval-machine-info {
    nixpkgs = nixpkgs-src;
    system = builtins.currentSystem;
    uuid = "000-000-000-000";
    deploymentName = "production-ci-test";
    args = {};
    networkExprs = [
      ./deployments/logical
      ./deployments/physical/aws/production.nix
    ];
  };

  dscp-servers = nixpkgs.lib.mapAttrs
    (name: node: node.config.system.build.toplevel)
    production-deployment.nodes;
in

(nixpkgs.lib.filterAttrs (n: _: builtins.hasAttr n overlay) nixpkgs)
// { dscp-servers = nixpkgs.recurseIntoAttrs dscp-servers;
     server-configs = production-deployment.nodes; }
