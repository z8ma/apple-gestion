#!/usr/bin/env bash
# Vérifie la syntaxe (sans typage) des sources Swift de l'app, des widgets et des tests.
# Utile hors macOS : la compilation complète (SwiftUI, SwiftData) exige Xcode.
# Usage : scripts/swift-parse-check.sh   (utilise `swiftc` local, sinon l'image Docker swift:6.2)
set -euo pipefail
cd "$(dirname "$0")/.."
mapfile -t files < <(git ls-files 'App/*.swift' 'Features/*.swift' 'Shared/*.swift' 'Widgets/*.swift' 'Tests/*.swift' 'Intents/*.swift')
[ ${#files[@]} -eq 0 ] && { echo "Aucun fichier Swift."; exit 0; }
if command -v swiftc >/dev/null 2>&1; then
  swiftc -parse "${files[@]}"
else
  docker run --rm -v "$PWD":/src -w /src swift:6.2 swiftc -parse "${files[@]}"
fi
echo "✓ ${#files[@]} fichiers Swift : syntaxe valide"
