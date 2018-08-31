# Generated with rebar32nix
{ stdenv, rebar3 ? null, writeShellScriptBin }:

with stdenv.lib;

let
  closure = {
    ranch = builtins.fetchGit {
      url = "https://github.com/ninenines/ranch";
      rev = "8eaae552ec520605b7f4b0e5943256d2b5e3621c";
    };

    jsone = builtins.fetchGit {
      url = "https://github.com/sile/jsone";
      rev = "b23d312a5ed051ea7ad0989a9f2cb1a9c3f9a502";
    };

    cowlib = builtins.fetchGit {
      url = "https://github.com/ninenines/cowlib";
      rev = "56a3fee151340212c1b7a92344e4ece07fc15010";
    };

    cowboy = builtins.fetchGit {
      url = "https://github.com/ninenines/cowboy";
      rev = "28d3515d716d32d1700fa21e904c613c139d4019";
    };

    gun = builtins.fetchGit {
      url = "https://github.com/ninenines/gun";
      rev = "e49f8af96da160b0417d21d5550fedd216acc263";
    };
  };

  fakeGit = writeShellScriptBin "git" "cat rev || true";

  linkPackage = name: src: ''
    mkdir -p _build/default/lib/${name}/ebin
    cp -rs ${src}/. $_/..
    echo ${src.rev} > $_/rev
  '';
in

stdenv.mkDerivation {
  name = "rebar3-release";
  src = builtins.fetchGit {
    url = "https://github.com/serokell/derivery";
    rev = "f6983904acf551635e1f4686e662bab49c3cb8d6";
  };

  buildInputs = [ fakeGit rebar3 ];

  configurePhase = concatStrings (mapAttrsToList linkPackage closure);
  buildPhase = "rebar3 release --dev-mode false --include-erts false";
  installPhase = "mv _build/default/rel/* $out";
}
