#!/usr/bin/env bash
set -euo pipefail

###
# build.sh — F-Droid
# - Installe scons (et python3) si absent
# - Construit godot-lib.aar
# - Construit l’APK avec Gradle système
# - Dépose build/Aerotap.apk
###

APP_NAME="Aerotap"
APK_OUT_DIR="build"
AAR_DST_DIR="android/build/libs/release"
GODOT_SRC_DIR="godot-src"
# Même révision que celle utilisée dans tes logs
GODOT_REF="876b290332ec6f2e6d173d08162a02aa7e6ca46d"

mkdir -p "${APK_OUT_DIR}" "${AAR_DST_DIR}"

# 0) Dépendances pour le runner F-Droid
export DEBIAN_FRONTEND=noninteractive
echo "[0/3] Vérification des dépendances SCons..."
if ! command -v scons >/dev/null 2>&1 || ! command -v python3 >/dev/null 2>&1; then
  echo "SCons ou Python non trouvé. Installation via apt-get..."
  apt-get update -qq
  # Installation de scons, python3 et d'un paquet python souvent nécessaire (distutils)
  apt-get install -y -qq scons python3 python3-distutils
fi

# >>> Rétablissement et ajustement de l'exportation explicite :
# Nous exportons le chemin du binaire ET le chemin du répertoire parent pour maximiser la visibilité dans Gradle.
SCONS_BIN="$(command -v scons || true)"
if [ -z "${SCONS_BIN}" ]; then
  echo "ERREUR: scons introuvable après vérification du PATH." >&2
  exit 1
fi

SCONS_DIR="$(dirname "${SCONS_BIN}")"

echo "SCons est disponible à: ${SCONS_BIN}"
# Exportation explicite :
export SCONS="${SCONS_BIN}" 
export SCONS_EXECUTABLE="${SCONS_BIN}" 
# Ajout de SCONS_PATH pointant vers le répertoire (une convention Godot)
export SCONS_PATH="${SCONS_DIR}"


# 1) Sources Godot
if [ ! -d "${GODOT_SRC_DIR}" ]; then
  echo "[1/3] Clone Godot sources..."
  git clone https://github.com/godotengine/godot.git "${GODOT_SRC_DIR}"
fi
pushd "${GODOT_SRC_DIR}" >/dev/null
  # Utilisation d'un fetch ciblé et d'un reset pour garantir la bonne révision, même si le dossier existait
  git fetch --tags --depth=1 origin "${GODOT_REF}"
  git reset --hard "${GODOT_REF}"
popd >/dev/null

# 2) Build de l’AAR Godot
echo "[2/3] Build godot-lib.aar (release)..."
pushd "${GODOT_SRC_DIR}/platform/android/java" >/dev/null
  chmod +x gradlew
  # Le wrapper de Godot est OK
  ./gradlew :lib:assembleRelease --no-daemon
  AAR_BUILT="lib/build/outputs/aar/lib-release.aar"
  test -f "${AAR_BUILT}" || { echo "ERREUR: AAR introuvable (${AAR_BUILT})"; exit 1; }
popd >/dev/null

echo ">> Copie AAR -> ${AAR_DST_DIR}/godot-lib.aar"
cp -f "${GODOT_SRC_DIR}/platform/android/java/${AAR_BUILT}" \
      "${AAR_DST_DIR}/godot-lib.aar"

# 3) Build APK de l’app (sans wrapper supprimé par F-Droid)
echo "[3/3] Build APK (release)..."
# Exécuter Gradle à partir de la racine pour une meilleure gestion des chemins relatifs
if command -v gradle >/dev/null 2>&1; then
  # Si le gradle système est disponible (moins courant sous F-Droid)
  gradle -p android/build assembleRelease --no-daemon
else
  # On utilise le gradlew du projet Android principal si le gradle système n'est pas là
  pushd android/build >/dev/null
    chmod +x gradlew || true
    # Exécution du wrapper Gradle du projet Android principal
    ./gradlew assembleRelease --no-daemon
  popd >/dev/null
fi

# 4) Récupération de l’APK
FOUND_APK="$(find android/build/app/build/outputs/apk/release -type f -name 'app-release.apk' | head -n 1 || true)"
if [ -z "${FOUND_APK}" ]; then
  # Fallback au cas où le nom change
  FOUND_APK="$(find android/build/app/build/outputs/apk -type f -name '*release*.apk' | head -n 1 || true)"
fi

if [ -n "${FOUND_APK}" ]; then
  cp -f "${FOUND_APK}" "${APK_OUT_DIR}/${APP_NAME}.apk"
  echo "OK -> APK: ${APK_OUT_DIR}/${APP_NAME}.apk"
else
  echo "ERREUR: APK release introuvable dans android/build/app/build/outputs/apk"
  # Afficher l'arborescence pour debug
  find android/build/app/build/outputs -maxdepth 4 -type f -print || true
  exit 1
fi
