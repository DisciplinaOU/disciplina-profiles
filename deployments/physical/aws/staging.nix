import ./. rec {
  accessKeyId = "srk-staging";
  domain = "dscp.serokell.review";
  realDomain = "dscp.serokell.review"; # TODO: issues. should be CNAME'd
  keydir = "testing";
  region = "eu-west-2";
  zone = "${region}a";
}
