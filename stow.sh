#!/bin/sh
# This script is intentionally idempotent so that it can safely "sync" new files
# when run repeatedly without any negative side-effects.

# is_sourced borrowed from https://stackoverflow.com/a/28776166
is_sourced() {
    if [ -n "$INSIDE_UPDATE_SCRIPT" ]; then
        return 0
    fi
    if [ -n "$ZSH_VERSION" ]; then
        case $ZSH_EVAL_CONTEXT in *:file:*) return 0 ;; esac
    else # Add additional POSIX-compatible shell names here, if needed.
        case ${0##*/} in dash | -dash | bash | -bash | ksh | -ksh | sh | -sh) return 0 ;; esac
    fi
    return 1 # NOT sourced.
}

if is_sourced; then
    echo 'Script must not be sourced'
    unset is_sourced
    return 1
fi
unset is_sourced

if ! command -v stow >/dev/null 2>&1; then
    echo 'GNU stow is not installed. All package managers call this "stow".'
    return 1
fi

set -e

# Within the non-login shell triggered through a git hook via a python service
# the usual $HOME doesn't exist. It also will not point to the correct home
# since this same situation also means the current user would always be root.
PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
P_USER=$(stat -c "%U" "$PROJECT_ROOT" 2>/dev/null || stat -f "%Su" "$PROJECT_ROOT")
# Stow internally expects a HOME env var.
U_HOME="$(eval echo "~${P_USER}")"

(cd "$PROJECT_ROOT"/root/home/user/ && find . -maxdepth 4 -type d -exec sudo -u "$P_USER" mkdir -vp "$U_HOME/{}" \;)

(
    export PS4=''; set -x
    cd "$PROJECT_ROOT"/root/home/ && sudo -u "$P_USER" stow --verbose=1 --target="$U_HOME" user
)

# The pruned directory option lines below are technically not required, but will
# speed up this command quite a bit if the lines included.
has_shown_header=0
find "$U_HOME"/.* \
        -path "$U_HOME/.cache" -type d -prune -o \
        -path "$U_HOME/.local/state/cargo" -type d -prune -o \
        -path "$U_HOME/.local/state/rustup" -type d -prune -o \
        -path "$U_HOME/.local/state/golang" -type d -prune -o \
        -path "$U_HOME/.local/share/Steam" -type d -prune -o \
        -type l -print 2>/dev/null | while read -r symlink; do
    true_path=$(realpath -q "$symlink" || true)
    case $true_path in
        "$PROJECT_ROOT"*)
            if [ -L "$symlink" ] && [ ! -e "$true_path" ]; then
                if [ $has_shown_header = 0 ]; then
                    echo 'Cleaning up broken symlinks owned by stow.sh ...'
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
