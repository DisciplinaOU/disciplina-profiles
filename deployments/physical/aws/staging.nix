import ./. rec {
  accessKeyId = "srk-staging";
  logical-domain = "dscp.serokell.review";
  keydir = "testing";
  region = "eu-west-2";
  zone = "${region}a";
  hasRoute53 = true;
}
