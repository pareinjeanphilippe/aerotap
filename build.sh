#!/usr/bin/env bash
set -euo pipefail

# --- Réglages ---
VER="4.5"                 
APP="Aerotap"
AAR_OUT="android/build/libs/release"   # dossier où on posera l'AAR
APK_OUT="build"                        # où on mettra l'APK final

mkdir -p "$AAR_OUT" "$APK_OUT"

echo "[1/3] Clone Godot ${VER}..."
git clone --depth=1 --branch ${VER}-stable https://github.com/godotengine/godot.git godot-src

echo "[2/3] Build godot-lib.aar (release)..."
pushd godot-src/platform/android
./gradlew :lib:assembleRelease
popd

# Copie l'AAR local à l'endroit où ton build.gradle le cherche (flatDir libs)
cp godot-src/platform/android/lib/build/outputs/aar/lib-release.aar "${AAR_OUT}/godot-lib.aar"

echo "[3/3] Build APK de ton jeu via Gradle..."
pushd android/build
# utilise l’AAR local (plus aucun dépôt Maven externe)
./gradlew assembleRelease
popd

# Récupère l’APK produit dans ton dossier /build
# (le nom de sortie est déjà géré par ton build.gradle -> android_release.apk)
FOUND_APK=$(find android/build/app/build/outputs/apk -type f -name "*release*.apk" | head -n 1 || true)
if [ -n "${FOUND_APK}" ]; then
  cp "${FOUND_APK}" "${APK_OUT}/${APP}.apk"
  echo "OK -> APK: ${APK_OUT}/${APP}.apk"
else
  echo "ERREUR: APK non trouvé"
  exit 1
fi
