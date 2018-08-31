final: previous:

let
  inherit (final) callPackage lib;
in

rec {
  derivery = callPackage ./derivery {};

  nixops-git = callPackage ./nixops-git {
    inherit (final.python2Packages) libvirt;
  };

  disciplina = (import (fetchGit { url = "ssh://git@github.com:/DisciplinaOU/disciplina"; ref = "release-alpha"; }));
  # disciplina = (import <disciplina>);
  disciplina-bin = disciplina.disciplina-bin;
  disciplina-faucet-frontend = disciplina.disciplina-faucet-frontend;
  disciplina-witness-frontend = disciplina.disciplina-witness-frontend;
}
