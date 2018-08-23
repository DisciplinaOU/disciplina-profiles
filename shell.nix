let
  pkgs = import ./nixpkgs.nix;
  src = builtins.toString ./.;
  stdenv = pkgs.stdenvNoCC;

  overlays = stdenv.mkDerivation {
    name = "nixpkgs-overlays";
    buildCommand = "mkdir -p $out && ln -s ${src}/pkgs $_";
  };
in

stdenv.mkDerivation {
  name = "dscp-ops-env";
  buildInputs = with pkgs; [ nixops-git sshfs mariadb ];

  NIX_PATH = builtins.concatStringsSep ":" [
    "nixpkgs=${toString pkgs.path}"
    "nixpkgs-overlays=${overlays}"
    "dscp-ops=${src}"
  ];
}
