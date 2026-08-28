#!/bin/sh
# Copy this repository's files into $HOME.
#
# Copy only -- nothing is ever removed. Files that this repository no longer
# tracks (e.g. a renamed script's old name) stay behind and must be deleted
# by hand.
#
# A destination that already differs from the repository is left alone rather
# than overwritten, so edits made directly in $HOME are never lost to a run
# that was meant to be routine. -f is the way to say the repository wins.
#
# Usage:
#   ./install.sh            copy, refusing to overwrite differing files
#   ./install.sh -n         dry run, just print what would be copied
#   ./install.sh -f         overwrite differing files as well
#   ./install.sh -h         show this message

set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# Each path is relative to both the repository and $HOME. A directory copies
# the whole tree below it, so nested layouts (.config/nvim/lua/...) survive.
targets='.zshrc .local/bin .claude/CLAUDE.md .codex/AGENTS.md .config/herdr .config/nvim .config/yazi'

usage() {
  # The comment block at the top of this file, minus the shebang and the
  # leading '# '. It stops at the first line that is not a comment, so editing
  # the block does not also mean editing a line number here.
  sed -n '2,/^[^#]/p' "$0" | sed -e '/^[^#]/d' -e 's/^#//' -e 's/^ //'
}

dry_run=0
force=0

for arg in "$@"; do
  case $arg in
    -n) dry_run=1 ;;
    -f) force=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown option $arg (try -h)" >&2; exit 2 ;;
  esac
done

# A directory target is walked by a pipeline, which puts the loop in a
# subshell, so a shell variable counting conflicts would not survive it. The
# file is shared, so record them there instead.
conflicts=$(mktemp)
trap 'rm -f "$conflicts"' EXIT INT TERM

install_file() {
  # Underscored because POSIX sh has no `local`: plain src/dst here would
  # clobber the caller's variables of the same name.
  _src=$1
  _dst=$2

  if [ -e "$_dst" ]; then
    # Content only. Mode is not compared: cp -p sets it on every copy that
    # happens, and there is no portable way to read it back.
    if cmp -s -- "$_src" "$_dst"; then
      [ "$dry_run" -eq 1 ] && echo "unchanged       $_dst"
      return 0
    fi

    if [ "$force" -eq 0 ]; then
      echo "$_dst" >> "$conflicts"
      echo "differs         $_dst" >&2
      return 0
    fi
  fi

  if [ "$dry_run" -eq 1 ]; then
    if [ -e "$_dst" ]; then
      echo "would overwrite $_dst"
    else
      echo "would install   $_dst"
    fi
    return 0
  fi

  mkdir -p "$(dirname -- "$_dst")"
  # -p keeps the mode, so a 0700 script stays 0700.
  cp -p "$_src" "$_dst"
  echo "installed       $_dst"
}

# shellcheck disable=SC2086  # $targets is a space-separated list on purpose.
for target in $targets; do
  src="$repo/$target"

  if [ -d "$src" ]; then
    # Walk the tree from inside $src so that each path comes out relative to
    # the target, which is exactly the tail we need under $HOME.
    (CDPATH='' cd -- "$src" && find . -type f -print) | while read -r rel; do
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

if [ -s "$conflicts" ]; then
  count=$(wc -l < "$conflicts" | tr -d ' ')
  echo >&2
  echo "install.sh: left $count file(s) alone because \$HOME has its own version." >&2
  echo "Diff one with: diff \$HOME/<path> $repo/<path>" >&2
  echo "Re-run with -f to let the repository win." >&2
  exit 1
fi
