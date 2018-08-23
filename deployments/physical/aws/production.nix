import ./. rec {
  accessKeyId = "srk-tmp";
  backups = true;
  domain = "disciplina.io";
  keydir = "production";
  realDomain = "disciplina.io";
  region = "eu-west-2";
  zone = "${region}a";
}
