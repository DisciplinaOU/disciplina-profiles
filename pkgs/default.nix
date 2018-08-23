final: previous:

let
  inherit (final) callPackage lib;
in

{
  nixops-git = callPackage ./nixops-git {
    inherit (final.python2Packages) libvirt;
  };
}
