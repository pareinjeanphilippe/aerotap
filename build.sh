#!/usr/bin/env bash
set -euo pipefail

# ----- Réglages -----
VER="4.5"                      # version Godot (ex: 4.5)
APP="Aerotap"
AAR_OUT="android/build/libs/release"
APK_OUT="build"

mkdir -p "$AAR_OUT" "$APK_OUT"

echo "[1/3] Clone Godot ${VER}..."
git clone --depth=1 --branch ${VER}-stable https://github.com/godotengine/godot.git godot-src

echo "[2/3] Build godot-lib.aar (release)..."
pushd godot-src/platform/android/java

# S'assure que le wrapper est exécutable
chmod +x gradlew

# (Optionnel) si l’NDK manque, décommente la ligne suivante
# yes | sdkmanager "ndk;23.1.7779620" >/dev/null

# Construit l’AAR de la lib Godot
./gradlew --no-daemon :lib:assembleRelease

popd

# Copie l’AAR là où le build.gradle le cherche (flatDir libs)
cp godot-src/platform/android/java/lib/build/outputs/aar/lib-release.aar \
   "${AAR_OUT}/godot-lib.aar"

echo "[3/3] Build APK du jeu..."
pushd android/build
./gradlew --no-daemon assembleRelease
popd

# Copie l'APK final à l'endroit attendu par F-Droid
FOUND_APK=$(find android/build/app/build/outputs/apk -type f -name "*release*.apk" | head -n 1 || true)
if [ -n "${FOUND_APK}" ]; then
  cp "${FOUND_APK}" "${APK_OUT}/${APP}.apk"
  echo "OK -> APK: ${APK_OUT}/${APP}.apk"
else
  echo "ERREUR: APK non trouvé"
  exit 1
fi
