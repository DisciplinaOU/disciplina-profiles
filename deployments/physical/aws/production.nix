import ./. rec {
  accessKeyId = "teachmeplease";
  logical-domain = "disciplina.io";
  keydir = "production";
  region = "eu-central-1"; # Frankfurt
  zone = "${region}a";
  production = true;
}
