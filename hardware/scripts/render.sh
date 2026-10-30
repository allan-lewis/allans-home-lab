#!/usr/bin/env bash
set -euo pipefail

# Render OpenSCAD models under hardware/ to STL (and optionally PNG previews).
#
# Usage: render.sh [target] [preview]
#   target   path to a .scad file or directory, relative to hardware/ (default: all models)
#   preview  "yes" to also render a PNG preview next to each STL (default: no)

HW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HW_DIR"

target="${1:-.}"
preview="${2:-no}"

# Locate OpenSCAD: explicit override, PATH, then macOS app bundles
if [[ -n "${OPENSCAD:-}" ]]; then
  openscad="$OPENSCAD"
elif command -v openscad >/dev/null 2>&1; then
  openscad="$(command -v openscad)"
elif [[ -x "/Applications/OpenSCAD (Nightly).app/Contents/MacOS/OpenSCAD" ]]; then
  openscad="/Applications/OpenSCAD (Nightly).app/Contents/MacOS/OpenSCAD"
elif [[ -x "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]]; then
  openscad="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
else
  echo "OpenSCAD not found. Install with: brew install --cask openscad@snapshot" >&2
  exit 1
fi

# Shared modules (lib/) are importable via OPENSCADPATH
export OPENSCADPATH="$HW_DIR/lib${OPENSCADPATH:+:$OPENSCADPATH}"

# Printable models are every .scad outside lib/, reference/ and build/
models=()
while IFS= read -r model; do
  models+=("$model")
done < <(
  find "$target" -name '*.scad' \
    -not -path '*/lib/*' \
    -not -path '*/reference/*' \
    -not -path '*/build/*' \
    | sed 's|^\./||' | sort
)

if [[ ${#models[@]} -eq 0 ]]; then
  echo "No models found under hardware/$target" >&2
  exit 1
fi

for model in "${models[@]}"; do
  out="build/${model%.scad}"
  mkdir -p "$(dirname "$out")"

  echo "==> $model"
  "$openscad" --backend=manifold -o "$out.stl" "$model"

  if [[ "$preview" == "yes" ]]; then
    "$openscad" --backend=manifold --render --autocenter --viewall \
      --imgsize=1200,600 --colorscheme=Tomorrow -o "$out.png" "$model"
  fi
done
