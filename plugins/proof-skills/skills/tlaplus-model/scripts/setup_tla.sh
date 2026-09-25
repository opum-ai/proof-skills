#!/usr/bin/env bash
# Install TLA+ tools into a user-level cache (no sudo, nothing system-wide).
#
#   setup_tla.sh [--nightly] [--with-jre] [--dir DIR]
#
#   --nightly   use the nightly tla2tools.jar instead of the pinned release
#   --with-jre  if no Java 11+ is on PATH, download a portable Temurin 21 JRE into DIR
#   --dir DIR   install location (default: $PROOF_SKILLS_TOOLS or ~/.cache/proof-skills)
#
# Afterwards tlc.sh finds everything automatically.
set -euo pipefail
TLA_VERSION="v1.8.0"
DIR="${PROOF_SKILLS_TOOLS:-$HOME/.cache/proof-skills}"
NIGHTLY=0; WITH_JRE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --nightly) NIGHTLY=1 ;;
    --with-jre) WITH_JRE=1 ;;
    --dir) DIR="$2"; shift ;;
    -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done
mkdir -p "$DIR"; cd "$DIR"

have_java() { java -version >/dev/null 2>&1; }
if ! have_java && ! ls -d "$DIR"/jre/*/ >/dev/null 2>&1; then
  if [ "$WITH_JRE" = 1 ]; then
    case "$(uname -s)" in Darwin) os=mac ;; Linux) os=linux ;; *) echo "unsupported OS for --with-jre" >&2; exit 1 ;; esac
    case "$(uname -m)" in arm64|aarch64) arch=aarch64 ;; x86_64|amd64) arch=x64 ;; *) echo "unsupported arch" >&2; exit 1 ;; esac
    echo "Downloading Temurin 21 JRE ($os/$arch) into $DIR/jre ..."
    mkdir -p jre
    curl -fsSL "https://api.adoptium.net/v3/binary/latest/21/ga/$os/$arch/jre/hotspot/normal/eclipse" -o jre.tgz
    tar xzf jre.tgz -C jre && rm jre.tgz
  else
    echo "No Java 11+ found. Install one (macOS: brew install --cask temurin; Debian/Ubuntu:" >&2
    echo "apt install openjdk-21-jre-headless) or re-run with --with-jre for a portable copy." >&2
    exit 1
  fi
fi

if [ "$NIGHTLY" = 1 ]; then
  url="https://nightly.tlapl.us/dist/tla2tools.jar"
else
  url="https://github.com/tlaplus/tlaplus/releases/download/$TLA_VERSION/tla2tools.jar"
fi
echo "Downloading tla2tools.jar from $url"
curl -fsSL "$url" -o tla2tools.jar.tmp && mv tla2tools.jar.tmp tla2tools.jar
echo "Downloading CommunityModules-deps.jar"
curl -fsSL "https://github.com/tlaplus/CommunityModules/releases/latest/download/CommunityModules-deps.jar" \
  -o CommunityModules-deps.jar.tmp && mv CommunityModules-deps.jar.tmp CommunityModules-deps.jar

echo "Installed in $DIR:"
ls -1 "$DIR"
