{
  network.description = "Disciplina Network";
  network.enableRollback = true;
  defaults = import ../../modules;

  builder  = import ./nodes/builder.nix;
  witness1 = import ./nodes/witness.nix { n = 1; };
  witness2 = import ./nodes/witness.nix { n = 2; };
  witness3 = import ./nodes/witness.nix { n = 3; };
}
