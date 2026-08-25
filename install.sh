#!/bin/sh
# Copy this repository's files into $HOME.
#
# Copy only -- nothing is ever removed. Files that this repository no longer
# tracks (e.g. a renamed script's old name) stay behind and must be deleted
# by hand. Existing files at the destination are overwritten.
#
# Usage:
#   ./install.sh            copy
#   ./install.sh -n         dry run, just print what would be copied

set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Each path is relative to both the repository and $HOME. A directory copies
# the whole tree below it, so nested layouts (.config/nvim/lua/...) survive.
targets='.local/bin .claude/CLAUDE.md .codex/AGENTS.md .config/nvim'

dry_run=0
if [ "${1:-}" = "-n" ]; then
  dry_run=1
fi

install_file() {
  # Underscored because POSIX sh has no `local`: plain src/dst here would
  # clobber the caller's variables of the same name.
  _src=$1
  _dst=$2

  if [ "$dry_run" -eq 1 ]; then
    if [ -e "$_dst" ]; then
      echo "would overwrite $_dst"
    else
      echo "would install   $_dst"
    fi
    return
  fi

  mkdir -p "$(dirname -- "$_dst")"
  # -p keeps the mode, so a 0700 script stays 0700.
  cp -p "$_src" "$_dst"
  echo "installed $_dst"
}

for target in $targets; do
  src="$repo/$target"

  if [ -d "$src" ]; then
    # Walk the tree from inside $src so that each path comes out relative to
    # the target, which is exactly the tail we need under $HOME.
    (CDPATH= cd -- "$src" && find . -type f -print) | while read -r rel; do
      install_file "$src/${rel#./}" "$HOME/$target/${rel#./}"
    done
  elif [ -f "$src" ]; then
    install_file "$src" "$HOME/$target"
  else
    echo "warning: $target is not in the repository" >&2
  fi
done

if [ "$dry_run" -eq 0 ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "warning: $HOME/.local/bin is not on your PATH" >&2 ;;
  esac
fi
