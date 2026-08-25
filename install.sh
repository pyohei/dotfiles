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
# the files directly inside it, not the tree below it.
targets='.local/bin .claude/CLAUDE.md .codex/AGENTS.md'

dry_run=0
if [ "${1:-}" = "-n" ]; then
  dry_run=1
fi

install_file() {
  src=$1
  dst=$2

  if [ "$dry_run" -eq 1 ]; then
    if [ -e "$dst" ]; then
      echo "would overwrite $dst"
    else
      echo "would install   $dst"
    fi
    return
  fi

  mkdir -p "$(dirname -- "$dst")"
  # -p keeps the mode, so a 0700 script stays 0700.
  cp -p "$src" "$dst"
  echo "installed $dst"
}

for target in $targets; do
  src="$repo/$target"

  if [ -d "$src" ]; then
    for file in "$src"/*; do
      [ -f "$file" ] || continue
      install_file "$file" "$HOME/$target/$(basename -- "$file")"
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
