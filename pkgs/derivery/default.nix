{ stdenv, rebar3, writeShellScriptBin }:

with stdenv.lib;

let
  closure = {
  "ranch" = builtins.fetchGit {
    url = "https://github.com/ninenines/ranch";
    rev = "55c2a9d623454f372a15e99721a37093d8773b48";
  };

  "jsone" = builtins.fetchGit {
    url = "https://github.com/sile/jsone";
    rev = "b0b037df7c1a8ee99c9f1bd124cd72e550a87936";
  };

  "cowlib" = builtins.fetchGit {
    url = "https://github.com/ninenines/cowlib";
    rev = "3ef5b48a028bb66f82b452c98ae515903096641c";
  };

  "cowboy" = builtins.fetchGit {
    url = "https://github.com/ninenines/cowboy";
    rev = "8d49ae3dda5b4274e55d2f4e5a5b4da0515b5a10";
  };

  "gun" = builtins.fetchGit {
    url = "https://github.com/ninenines/gun";
    rev = "eb84f7ecab15dbcd5fd64d45e236a47b17b6b20e";
  };
};

  fakeGit = writeShellScriptBin ''git'' ''cat rev || true'';

  linkPackage = name: src: ''
    mkdir -p _build/default/lib/${name}/ebin
    cp -rs ${src}/. $_/..
    echo ${src.rev} > $_/rev
  '';
in

stdenv.mkDerivation {
  name = ''rebar3-release'';
  src = builtins.fetchGit {
    url = "https://github.com/serokell/derivery";
    ref = "20180430.052243";
  };

  buildInputs = [ fakeGit rebar3 ];

  configurePhase = concatStrings (mapAttrsToList linkPackage closure);
  buildPhase = ''rebar3 release --dev-mode false --include-erts false'';
  installPhase = ''mv _build/default/rel/* $out'';
}
