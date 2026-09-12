#!/bin/bash
# SessionStart: report whether the four expected tools are available.
# Never blocks a session - always exits 0, makes no network calls, changes nothing.
set -uo pipefail

missing=()
report=()

# --- Claude Code plugins (authoritative: the CLI's own list) ---
plugins=""
if command -v claude >/dev/null 2>&1; then
  plugins=$(claude plugin list 2>/dev/null)
fi

check_plugin() {  # name, install-target
  if printf '%s' "$plugins" | grep -qi -- "$1"; then
    report+=("$1 ok")
  else
    report+=("$1 MISSING")
    missing+=("  $1   claude plugin install $2")
  fi
}
check_plugin "ponytail"     "ponytail@ponytail"
check_plugin "agent-skills" "agent-skills@addy-agent-skills"

# --- graphify: a Python CLI (PyPI package is 'graphifyy'), not a plugin ---
if command -v graphify >/dev/null 2>&1; then
  report+=("graphify ok")
else
  report+=("graphify MISSING")
  missing+=("  graphify   pip install graphifyy")
fi

# --- OmniRoute: a self-hosted LLM gateway, detected by configured endpoint ---
if [ -n "${OMNIROUTE_BASE_URL:-}" ] || [ -n "${OMNIROUTE_API_KEY:-}" ]; then
  report+=("omniroute ok")
else
  report+=("omniroute unconfigured")
  missing+=("  omniroute  self-hosted service; set OMNIROUTE_BASE_URL to point at it")
fi

if [ ${#missing[@]} -eq 0 ]; then
  echo "[tooling] all four present: ${report[*]}"
else
  printf '[tooling] %s\n' "$(printf '%s; ' "${report[@]}" | sed 's/; $//')"
  printf '%s\n' "${missing[@]}"
fi
exit 0
