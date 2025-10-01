#!/usr/bin/env bash
set -euo pipefail

APP="Aerotap"
OUT="build"
mkdir -p "$OUT"

# Télécharge Godot headless (version à fixer selon celle que tu utilises)
VER="4.3"
wget -q https://downloads.tuxfamily.org/godotengine/${VER}/Godot_v${VER}-linux.x86_64.zip
unzip -o Godot_v${VER}-linux.x86_64.zip
chmod +x Godot_v${VER}-linux.x86_64

# Export APK Android (utilise le preset "Android" défini dans export_presets.cfg)
./Godot_v${VER}-linux.x86_64 --headless --path . \
  --export-release "Android" "$OUT/${APP}.apk"
