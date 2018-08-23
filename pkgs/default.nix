final: previous:

let
  inherit (final) callPackage lib;
in

rec {
  nixops-git = callPackage ./nixops-git {
    inherit (final.python2Packages) libvirt;
  };

  disciplina = (import (fetchGit { url = "ssh://git@github.com:/DisciplinaOU/disciplina"; ref = "release-alpha"; })).disciplina-bin;
}
