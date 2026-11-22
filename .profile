# shellcheck shell=sh
# Read by sh and bash login shells; zsh reads .zprofile instead. Both files
# sourced here are written by installers (rustup and uv) rather than tracked in
# this repository, so each is guarded for a machine that lacks it.
if [ -f "$HOME/.cargo/env" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.cargo/env"
fi
if [ -f "$HOME/.local/bin/env" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.local/bin/env"
fi
