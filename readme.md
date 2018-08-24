# Disciplina Cluster Configuration

[![Build status](https://badge.buildkite.com/cad2c06e89f0d975e7b4242154fe3d40d430de5bd24b565eaf.svg)](https://buildkite.com/serokell/dscp-staging)

The contents of this repository describe and configure the Disciplina cluster.
AWS resource management and system configuration are declared in Nix and
deployed with nixops.

## Warning

Please refrain from making manual changes to any systems in the cluster.
Anything you need done can be done by changing the appropriate Nix declarations
and redeploying with nixops. State inconsistencies will lead to problems! You
have been warned.

## Nix and Nixops

From the Nix homepage:

> Nix is a powerful package manager for Linux and other Unix systems that makes
> package management reliable and reproducible. It provides atomic upgrades and
> rollbacks, side-by-side installation of multiple versions of a package,
> multi-user package management and easy setup of build environments.

From the NixOps manual:

> NixOps is a tool for deploying sets of NixOS Linux machines, either to real
> hardware or to virtual machines. It extends NixOS’s declarative approach to
> system configuration management to networks and adds provisioning.

The net result is something akin to Terraform and Ansible, rolled into one, and
backed by a declarative programming language.

See this simple example of a nixops network that declares a web server running
Apache, and a file server using NFS:

```nix
{
  webserver =
    { deployment.targetEnv = "virtualbox";
      services.httpd.enable = true;
      services.httpd.documentRoot = "/data";
      fileSystems."/data" =
        { fsType = "nfs4";
          device = "fileserver:/"; };
    };

  fileserver =
    { deployment.targetEnv = "virtualbox";
      services.nfs.server.enable = true;
      services.nfs.server.exports = "...";
    };
}
```

## How to use this repository

First, you will need the Nix package manager. It can be installed as standalone
package manager on all Linux systems and on MacOS.

Please visit the [Nix download page](https://nixos.org/nix/download.html) for
instructions.

After this, you should be able to invoke the `nix` command.

There is a file in this repository, `shell.nix` that defines the execution
environment for `nixops` including `nixops` itself, all dependencies, and their
versions. To make use of this environment, run `nix-shell` at the root of the
repository. This will take a while the first time you run it, as nix downloads
and installs (compiling when necessary) any dependencies. Subsequent invocations
will only take a second or two.

## Nixops state

If you are familiar with Ansible, you will know that the biggest reason it's so
slow is that it does not keep state between invocations, and so needs to spend a
lot of time gathering facts about target systems, and you will usually write a
lot of tasks that individually check whether another task needs to actually run.

Nixops avoids this by keeping state between runs. This also means this state
needs to be shared with anyone willing to deploy the cluster using nixops.

The state file is stored on the CI builder node on the TMP EC2 cluster. So the
easiest way to use nixops is to actually not use it at all, and instead just
push new commits to master in this repository. The CI runner will do the work
for you.

Still, there are situations where you will want to do things manually. In this
case, you will want to copy `deployments.nixops` from the CI runner, and specify
the path as `nixops -s /path/to/deployments.nixops <all other args/commands>`.
