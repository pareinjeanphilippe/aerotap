#!/usr/bin/env bash
set -euo pipefail

###
# build.sh — F-Droid
# - Installe scons (et python3) si absent
# - Exporte SCONS/SCONS_PATH pour Gradle (Godot)
# - Construit godot-lib.aar
# - Construit l’APK avec Gradle système
# - Dépose build/Aerotap.apk
###

APP_NAME="Aerotap"
APK_OUT_DIR="build"
AAR_DST_DIR="android/build/libs/release"
GODOT_SRC_DIR="godot-src"
# même révision que celle utilisée dans tes logs
GODOT_REF="876b290332ec6f2e6d173d08162a02aa7e6ca46d"

mkdir -p "${APK_OUT_DIR}" "${AAR_DST_DIR}"

# 0) Dépendances pour le runner F-Droid
export DEBIAN_FRONTEND=noninteractive
if ! command -v scons >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq scons python3
fi

# >>> IMPORTANT : donner le chemin de scons à Gradle (Godot)
SCONS_BIN="$(command -v scons || true)"
if [ -z "${SCONS_BIN}" ]; then
  echo "ERREUR: scons introuvable après installation" >&2
  exit 1
fi
export SCONS="${SCONS_BIN}"
export SCONS_PATH="${SCONS_BIN}"
# (Godot accepte l’une ou l’autre, on met les deux)

# 1) Sources Godot
if [ ! -d "${GODOT_SRC_DIR}" ]; then
  echo "[1/3] Clone Godot sources…"
  git clone https://github.com/godotengine/godot.git "${GODOT_SRC_DIR}"
fi
pushd "${GODOT_SRC_DIR}" >/dev/null
  git fetch --tags --depth=1
  git checkout -f "${GODOT_REF}"
popd >/dev/null

# 2) Build de l’AAR Godot
echo "[2/3] Build godot-lib.aar (release)…"
pushd "${GODOT_SRC_DIR}/platform/android/java" >/dev/null
  chmod +x gradlew
  # le wrapper de Godot est OK
  ./gradlew :lib:assembleRelease --no-daemon
  AAR_BUILT="lib/build/outputs/aar/lib-release.aar"
  test -f "${AAR_BUILT}" || { echo "ERREUR: AAR introuvable (${AAR_BUILT})"; exit 1; }
popd >/dev/null

echo ">> Copie AAR -> ${AAR_DST_DIR}/godot-lib.aar"
cp -f "${GODOT_SRC_DIR}/platform/android/java/${AAR_BUILT}" \
      "${AAR_DST_DIR}/godot-lib.aar"

# 3) Build APK de l’app (sans wrapper supprimé par F-Droid)
echo "[3/3] Build APK (release)…"
if command -v gradle >/dev/null 2>&1; then
  gradle -p android/build assembleRelease --no-daemon
else
  echo "ATTENTION: Gradle système absent, tentative avec ./gradlew (peut échouer sous F-Droid)"
  pushd android/build >/dev/null
    chmod +x gradlew || true
    ./gradlew assembleRelease --no-daemon
  popd >/dev/null
fi

# 4) Récupération de l’APK
FOUND_APK="$(find android/build/app/build/outputs/apk -type f -name '*release*.apk' | head -n 1 || true)"
if [ -n "${FOUND_APK}" ]; then
  cp -f "${FOUND_APK}" "${APK_OUT_DIR}/${APP_NAME}.apk"
  echo "OK -> APK: ${APK_OUT_DIR}/${APP_NAME}.apk"
else
  echo "ERREUR: APK release introuvable dans android/build/app/build/outputs/apk"
  find android/build/app/build/outputs -maxdepth 4 -type f -print || true
  exit 1
fi
