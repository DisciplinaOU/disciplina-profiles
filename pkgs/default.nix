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

  disciplina = (import (fetchGit { url = "ssh://git@github.com:/DisciplinaOU/disciplina"; ref = "master"; }));
  # disciplina = (import <disciplina>);
  disciplina-bin = disciplina.disciplina-bin;
  disciplina-faucet-frontend = callPackage (import "${fetchGit { url = "ssh://git@github.com:/DisciplinaOU/disciplina-faucet-frontend"; }}/release.nix") {};
  disciplina-witness-frontend = callPackage (import "${fetchGit { url = "ssh://git@github.com:/DisciplinaOU/disciplina-explorer-frontend"; }}/release.nix") {};
}
