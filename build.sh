#!/usr/bin/env bash
set -euo pipefail

###
# build.sh — F-Droid
# - Installe scons si absent (requis par la build Android de Godot)
# - Construit godot-lib.aar depuis les sources de Godot
# - Construit l'APK de l'app en utilisant Gradle système (pas le wrapper supprimé par F-Droid)
# - Dépose l'APK final en: build/Aerotap.apk (conforme à ta metadata)
###

# ----------------------- Réglages -----------------------
APP_NAME="Aerotap"                             # nom du fichier apk final
APK_OUT_DIR="build"                            # dossier de sortie attendu par F-Droid
AAR_DST_DIR="android/build/libs/release"       # où ton app cherche l'AAR (flatDir)
GODOT_SRC_DIR="godot-src"

# Référence Godot à utiliser (même commit que dans tes logs)
# Tu peux remplacer par '4.5-stable' si tu préfères le tag:
GODOT_REF="876b290332ec6f2e6d173d08162a02aa7e6ca46d"

# ------------------- Préparation env -------------------
mkdir -p "${APK_OUT_DIR}" "${AAR_DST_DIR}"

export DEBIAN_FRONTEND=noninteractive
if ! command -v scons >/dev/null 2>&1; then
  echo ">> Install scons (requis par Godot)"
  apt-get update -qq
  apt-get install -y -qq scons
fi

# ----------------- 1) Récup Godot src ------------------
if [ ! -d "${GODOT_SRC_DIR}" ]; then
  echo "[1/3] Clone Godot sources..."
  git clone https://github.com/godotengine/godot.git "${GODOT_SRC_DIR}"
fi
pushd "${GODOT_SRC_DIR}" >/dev/null
  git fetch --tags --depth=1
  git checkout -f "${GODOT_REF}"
popd >/dev/null

# ------------- 2) Build godot-lib.aar ------------------
echo "[2/3] Build godot-lib.aar (release)..."
pushd "${GODOT_SRC_DIR}/platform/android/java" >/dev/null
  # Le wrapper Gradle de Godot (PAS celui de ton app) est OK
  chmod +x gradlew
  ./gradlew :lib:assembleRelease
  AAR_BUILT="lib/build/outputs/aar/lib-release.aar"
  test -f "${AAR_BUILT}" || { echo "ERREUR: AAR introuvable (${AAR_BUILT})"; exit 1; }
popd >/dev/null

echo ">> Copie AAR -> ${AAR_DST_DIR}/godot-lib.aar"
cp -f "${GODOT_SRC_DIR}/platform/android/java/${AAR_BUILT}" \
      "${AAR_DST_DIR}/godot-lib.aar"

# --------------- 3) Build APK de l'app -----------------
echo "[3/3] Build APK (release)..."
# F-Droid supprime android/build/gradle/wrapper/gradle-wrapper.jar,
# donc on évite ./gradlew ici et on utilise Gradle système.
if command -v gradle >/dev/null 2>&1; then
  gradle -p android/build assembleRelease --no-daemon
else
  echo "ATTENTION: Gradle système absent, tentative avec ./gradlew (peut échouer sous F-Droid)"
  pushd android/build >/dev/null
    chmod +x gradlew || true
    ./gradlew assembleRelease --no-daemon
  popd >/dev/null
fi

# -------------- 4) Récup l'APK généré ------------------
FOUND_APK="$(find android/build/app/build/outputs/apk -type f -name '*release*.apk' | head -n 1 || true)"

if [ -n "${FOUND_APK}" ]; then
  cp -f "${FOUND_APK}" "${APK_OUT_DIR}/${APP_NAME}.apk"
  echo "OK -> APK: ${APK_OUT_DIR}/${APP_NAME}.apk"
else
  echo "ERREUR: APK release introuvable dans android/build/app/build/outputs/apk"
  find android/build/app/build/outputs -maxdepth 4 -type f -print || true
  exit 1
fi
