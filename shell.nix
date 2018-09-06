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
  buildInputs = with pkgs; [ nixops-git git-crypt ];

  NIX_PATH = builtins.concatStringsSep ":" [
    "nixpkgs=${toString pkgs.path}"
    "nixpkgs-overlays=${overlays}"
    "dscp-ops=${src}"
    "disciplina=https://github.com/DisciplinaOU/disciplina/archive/master.tar.gz"
    "disciplina-faucet=https://github.com/DisciplinaOU/disciplina-faucet-frontend/archive/master.tar.gz"
    "disciplina-explorer=https://github.com/DisciplinaOU/disciplina-explorer-frontend/archive/master.tar.gz"
  ];
}
