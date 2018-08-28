import ./. rec {
  accessKeyId = "teachmeplease";
  # backups = true;
  domain = "net.disciplina.io";
  # realDomain = "disciplina.io";
  keydir = "production";
  region = "eu-central-1"; # Frankfurt
  zone = "${region}a";
}
