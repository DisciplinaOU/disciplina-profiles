import ./. rec {
  accessKeyId = "teachmeplease";
  # backups = true;
  domain = "disciplina.io";
  # realDomain = "disciplina.io";
  faucetUrl = "https://faucet.disciplina.io";
  witnessUrl = "https://witness.disciplina.io";
  keydir = "production";
  region = "eu-central-1"; # Frankfurt
  zone = "${region}a";
  production = true;
  deploy-target = "production";
}
