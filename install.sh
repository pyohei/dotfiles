#!/bin/sh
# Copy this repository's .local/bin scripts into ~/.local/bin.
#
# Copy only -- nothing is ever removed. Files that this repository no longer
# tracks (e.g. a renamed script's old name) stay behind and must be deleted
# by hand.
#
# Usage:
#   ./install.sh            copy
#   ./install.sh -n         dry run, just print what would be copied

set -eu

src_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.local/bin" && pwd)
dst_dir="$HOME/.local/bin"

dry_run=0
if [ "${1:-}" = "-n" ]; then
  dry_run=1
fi

if [ "$dry_run" -eq 0 ]; then
  mkdir -p "$dst_dir"
fi

for src in "$src_dir"/*; do
  [ -f "$src" ] || continue

  name=$(basename "$src")
  dst="$dst_dir/$name"

  if [ "$dry_run" -eq 1 ]; then
    if [ -e "$dst" ]; then
      echo "would overwrite $dst"
    else
      echo "would install   $dst"
    fi
    continue
  fi

  # -p keeps the mode, so a 0700 script stays 0700.
  cp -p "$src" "$dst"
  echo "installed $dst"
done

if [ "$dry_run" -eq 0 ]; then
  case ":$PATH:" in
    *":$dst_dir:"*) ;;
    *) echo "warning: $dst_dir is not on your PATH" >&2 ;;
  esac
fi
