# Read by every zsh, interactive or not: scripts, `zsh -c`, and the shells that
# agents and Herdr panes run commands in. rustup writes ~/.cargo/env to put
# ~/.cargo/bin on PATH, but that file is generated rather than tracked here, so
# a machine without Rust must not print an error from every one of those shells.
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
