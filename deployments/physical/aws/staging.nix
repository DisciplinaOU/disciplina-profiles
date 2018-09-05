import ./. rec {
  accessKeyId = "srk-staging";
  domain = "dscp.serokell.review";
  realDomain = "dscp.serokell.review"; # TODO: issues. should be CNAME'd
  faucetUrl = "http://faucet.dscp.serokell.review";
  witnessUrl = "http://witness.dscp.serokell.review";
  keydir = "testing";
  region = "eu-west-2";
  zone = "${region}a";
  queue = "dscp-staging";
}
