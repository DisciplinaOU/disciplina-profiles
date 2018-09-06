final: previous:

let
  inherit (final) callPackage lib;
in

rec {
  buildkite-agent3 = callPackage ./buildkite-agent3 {};
  buildkite-agent = final.buildkite-agent3; # todo: fix in nixpkgs

  nixops-git = callPackage ./nixops-git {
    inherit (final.python2Packages) libvirt;
  };

  # disciplina = (import (fetchTarball "https://github.com/DisciplinaOU/disciplina/archive/master.tar.gz"));
  # disciplina-faucet-frontend = callPackage (import "${fetchTarball https://github.com/DisciplinaOU/disciplina-faucet-frontend/archive/master.tar.gz}/release.nix") {};
  # disciplina-explorer-frontend = callPackage (import "${fetchTarball https://github.com/DisciplinaOU/disciplina-explorer-frontend/archive/master.tar.gz}/release.nix") {};

  disciplina = (import <disciplina>);
  disciplina-bin = disciplina.disciplina-bin;
  disciplina-faucet-frontend = callPackage (import <disciplina-faucet/release.nix>) {};
  disciplina-explorer-frontend = callPackage (import <disciplina-explorer/release.nix>) {};
}
