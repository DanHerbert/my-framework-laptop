#!/bin/sh -e
# This script is intentionally idempotent so that it can safely "sync" new files
# when run repeatedly without any negative side-effects.

# Within the non-login shell triggered through a git hook via a python service
# the usual $HOME doesn't exist. It also will not point to the correct home
# since this same situation also means the current user would always be root.
PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
P_USER=$(stat -c "%U" "$PROJECT_ROOT")
# Stow internally expects a HOME env var.
U_HOME="$(getent passwd "$P_USER" | cut -d: -f6)"

(cd "$PROJECT_ROOT"/root/home/user/ && find . -maxdepth 4 -type d -exec sudo -u "$P_USER" mkdir -vp "$U_HOME/{}" \;)

( export PS4=''; set -xe
(cd "$PROJECT_ROOT"/root/home/; sudo -u "$P_USER" stow --verbose=1 --target="$U_HOME" user)
)

if [ -x "$PROJECT_ROOT"/nonpublic/stow.sh ]; then
    "$PROJECT_ROOT"/nonpublic/stow.sh
fi
