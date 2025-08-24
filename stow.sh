#!/bin/sh -e
# This script is intentionally idempotent so that it can safely "sync" new files
# when run repeatedly without any negative side-effects.

# Within the non-login shell triggered through a git hook via a python service
# the usual $HOME doesn't exist. It also will not point to the correct home
# since this same situation also means the current user would always be root.
PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
P_USER=$(stat -c "%U" "$PROJECT_ROOT")
# Stow internally expects a HOME env var.
U_HOME="$(eval echo "~${P_USER}")"

(cd "$PROJECT_ROOT"/root/home/user/ && find . -maxdepth 4 -type d -exec sudo -u "$P_USER" mkdir -vp "$U_HOME/{}" \;)

(
    export PS4=''; set -xe
    (cd "$PROJECT_ROOT"/root/home/ && sudo -u "$P_USER" stow --verbose=1 --target="$U_HOME" user)
)

has_shown_header=0
find "$U_HOME" -type l 2>/dev/null | while read -r symlink ; do
    true_path=$(realpath -q "$symlink")
    case $true_path in
        "$PROJECT_ROOT"*)
            if [ ! -e "$true_path" ]; then
                if [ $has_shown_header = 0 ]; then
                    echo 'Cleaning up stale symlinks owned by stow.sh...'
                    has_shown_header=1
                fi
                rel_target=$(printf '%s' "$symlink" | sed "s|$U_HOME|~|")
                rel_source=$(readlink "$symlink")
                rm "$symlink"
                echo "UNLINK: $rel_target => $rel_source"
            fi
            ;;
    esac
done

if [ -x "$PROJECT_ROOT"/nonpublic/stow.sh ]; then
    "$PROJECT_ROOT"/nonpublic/stow.sh
fi
