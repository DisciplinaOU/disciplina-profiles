{
  network.description = "Disciplina Network";
  network.enableRollback = true;
  defaults = import ../../modules;

  witness = import ./nodes/witness.nix;
}
