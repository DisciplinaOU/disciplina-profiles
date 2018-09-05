import ./. rec {
  accessKeyId = "srk-staging";
  domain = "dscp206.dscp.serokell.review";
  realDomain = "dscp206.dscp.serokell.review";
  DNSZone = "serokell.review";
  faucetUrl = "http://faucet.dscp206.dscp.serokell.review";
  witnessUrl = "http://witness.dscp206.dscp.serokell.review";
  keydir = "testing";
  region = "eu-west-2";
  zone = "${region}a";
  queue = "dscp-pr-206";
}
