# Node. fnm is what actually runs; nvm stays only for the toolchains already
# installed under ~/.nvm. fnm is evaluated last so its shims win on PATH --
# leaving the two to fight over it is how a stale global CLI gets picked up.
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Where install.sh lands pyohei-ai. uv's installer writes ~/.local/bin/env
# with the same check, but that file is generated rather than tracked here, so
# a fresh machine cannot count on it being there to be sourced.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# --use-on-cd switches the node version on entering a directory that pins one.
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd)"
