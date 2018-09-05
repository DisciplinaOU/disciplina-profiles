#!/usr/bin/env bash
set -euo pipefail

DEPLOYMENT="${1:-default}"
TARGET=$(nixops info -d "$DEPLOYMENT" --plain --no-eval | awk 'BEGIN { FS="\t" } /builder/ { print $5}')
SRCDIR="$HOME/dev/serokell/tmp/builder-state"
BASEDIR='/var/lib/nixops'

# Upload nixops state. WARNING: destructive
ssh "$TARGET" sudo -u nixops nixops list | grep -o "$DEPLOYMENT" && ssh "$TARGET" sudo -u nixops nixops delete -d "$DEPLOYMENT" --force
nixops export -d "$DEPLOYMENT" | ssh "$TARGET" sudo -u nixops nixops import -d "$DEPLOYMENT"

# Upload ssh-key for nixops user
scp keys/derivery-ssh.key "$TARGET":
ssh "$TARGET" "sudo mkdir -p $BASEDIR/.ssh; \
               sudo mv -f derivery-ssh.key $BASEDIR/.ssh/id_rsa; \
               sudo chown -R nixops:nixops $BASEDIR/.ssh; \
               sudo chmod -R go+rwx $BASEDIR/.ssh"

# Upload custom gpg-keyring
scp -r "$SRCDIR/.gnupg" "$TARGET":gnupg
ssh "$TARGET" "sudo rm -rf $BASEDIR/.gnupg; \
               sudo mv -f gnupg $BASEDIR/.gnupg; \
               sudo chown nixops:nixops $BASEDIR/.gnupg; \
               sudo chmod -R go-rwx $BASEDIR/.gnupg"

# Symlink AWS credentials
ssh "$TARGET" "sudo mkdir -p $BASEDIR/.aws; \
               sudo ln -sf /run/keys/aws-credentials $BASEDIR/.aws/credentials; \
               sudo chown -R nixops:nixops $BASEDIR/.aws; \
               sudo chmod -R go-rwx $BASEDIR/.aws"
