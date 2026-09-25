#!/usr/bin/env bash
# Report which formal-methods toolchains are available. Writes nothing.
# Usage: doctor.sh [tools-dir]   (tools-dir defaults to $PROOF_SKILLS_TOOLS or ~/.cache/proof-skills)
set -u
TOOLS="${1:-${PROOF_SKILLS_TOOLS:-$HOME/.cache/proof-skills}}"
ok()   { printf '  \033[32mok\033[0m    %-22s %s\n' "$1" "$2"; }
miss() { printf '  \033[33mmiss\033[0m  %-22s %s\n' "$1" "$2"; }

echo "TLA+"
PJ="$(find "$TOOLS/jre" -type f -path '*/bin/java' 2>/dev/null | head -1)"
if java -version >/dev/null 2>&1; then
  ok java "$(java -version 2>&1 | head -1)"
elif [ -n "$PJ" ]; then
  ok java "portable: $PJ"
else
  miss java "JDK 11+ (brew install --cask temurin / apt install openjdk-21-jre-headless) or setup_tla.sh --with-jre"
fi
if [ -f "$TOOLS/tla2tools.jar" ]; then ok tla2tools.jar "$TOOLS/tla2tools.jar"
else miss tla2tools.jar "run tlaplus-model/scripts/setup_tla.sh"; fi
if [ -f "$TOOLS/CommunityModules-deps.jar" ]; then ok CommunityModules "$TOOLS/CommunityModules-deps.jar"
else miss CommunityModules "optional; run tlaplus-model/scripts/setup_tla.sh"; fi
command -v apalache-mc >/dev/null 2>&1 && ok apalache-mc "$(command -v apalache-mc)" || miss apalache-mc "optional (symbolic/bounded checks)"
command -v quint >/dev/null 2>&1 && ok quint "$(quint --version 2>/dev/null)" || miss quint "optional: npm i -g @informalsystems/quint"

echo "Lean 4"
if command -v elan >/dev/null 2>&1 || [ -x "$HOME/.elan/bin/elan" ]; then
  E=$(command -v elan || echo "$HOME/.elan/bin/elan"); ok elan "$("$E" --version 2>/dev/null)"
else miss elan "run lean-model/scripts/setup_lean.sh"; fi
if command -v lake >/dev/null 2>&1 || [ -x "$HOME/.elan/bin/lake" ]; then ok lake "found"
else miss lake "installed with elan"; fi

echo "Other"
command -v python3 >/dev/null 2>&1 && ok python3 "$(python3 --version 2>&1)" || miss python3 "needed by helper scripts"
command -v git >/dev/null 2>&1 && ok git "$(git --version)" || miss git ""
