#!/usr/bin/env bash
NIXOPS_OPTIONS='-I ssh-key=/var/lib/nixops/.ssh/id_rsa'
SLEEP='15m'
sudo -u nixops -- sh -c 'nixops deploy $NIXOPS_OPTIONS --include witness0 builder; sleep $SLEEP; nixops deploy $NIXOPS_OPTIONS --exclude witness0 builder'
