{
  defaults = {
    deployment.targetEnv = "virtualbox";
    deployment.virtualbox.headless = true;
    dscp.keydir = null;

    services.nginx.commonHttpConfig = ''
      access_log syslog:server=unix:/dev/log;
      error_log stderr debug;
      rewrite_log on;
    '';
  };

  witness1.deployment.virtualbox = {
    memorySize = 2048;
    vcpu = 4;
  };

  witness2.deployment.virtualbox = {
    memorySize = 2048;
    vcpu = 4;
  };

  witness3.deployment.virtualbox = {
    memorySize = 2048;
    vcpu = 4;
  };
}
