#!/bin/sh
# Exercises install.sh against a throwaway $HOME, so a run can never touch the
# real one. Called by CI; runnable by hand from anywhere in the tree.
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

HOME=$tmp
export HOME

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# 1. A fresh $HOME gets every target.
"$repo/install.sh" >/dev/null 2>&1 || fail "the first run exited non-zero"
[ -f "$tmp/.zshrc" ] || fail ".zshrc was not installed"
[ -f "$tmp/.local/bin/pyohei-ai" ] || fail "pyohei-ai was not installed"
[ -f "$tmp/.config/nvim/init.lua" ] || fail "the nvim tree was not installed"
[ -f "$tmp/.config/nvim/lsp/gopls.lua" ] || fail "nested nvim files were not installed"
[ -f "$tmp/.claude/CLAUDE.md" ] || fail "CLAUDE.md was not installed"
[ -f "$tmp/.codex/AGENTS.md" ] || fail "AGENTS.md was not installed"

# 2. cp -p is there so a 0700 script does not arrive world-readable. Only the
# executable bit is asserted: git records nothing finer, so after a clone that
# is the only part of the mode this test can hold the copy to.
if [ -x "$repo/.local/bin/pyohei-ai" ] && [ ! -x "$tmp/.local/bin/pyohei-ai" ]; then
  fail "pyohei-ai lost its executable bit on the way over"
fi

# 3. Nothing left to do the second time.
out=$("$repo/install.sh" 2>/dev/null) || fail "the second run exited non-zero"
[ -z "$out" ] || fail "the second run copied again: $out"

# 4. A file edited in $HOME is left alone, and the run says so by failing.
echo '# edited by hand' >> "$tmp/.zshrc"
if "$repo/install.sh" >/dev/null 2>&1; then
  fail "a differing destination did not fail the run"
fi
if ! grep -q 'edited by hand' "$tmp/.zshrc"; then
  fail "a differing destination was overwritten without -f"
fi

# 5. -f is the way through.
"$repo/install.sh" -f >/dev/null 2>&1 || fail "-f exited non-zero"
if grep -q 'edited by hand' "$tmp/.zshrc"; then
  fail "-f left the destination alone"
fi

# 6. A dry run touches nothing, whatever it reports.
echo '# edited again' >> "$tmp/.zshrc"
"$repo/install.sh" -n >/dev/null 2>&1 || true
if ! grep -q 'edited again' "$tmp/.zshrc"; then
  fail "the dry run wrote to the destination"
fi

# 7. An unknown option is refused rather than silently ignored.
if "$repo/install.sh" --nope >/dev/null 2>&1; then
  fail "an unknown option was accepted"
fi

echo "install.sh: 7 checks passed"
