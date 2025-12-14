#!/bin/bash

set -euo pipefail

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# 入力ファイルの存在チェック
if [ ! -f "250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif" ]; then
  error "Input file not found: 250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif"
  exit 1
fi

# 既存のタイルディレクトリがあれば削除
if [ -d "tiles_PTN2025_rgb" ]; then
  log "Removing existing tiles directory: tiles_PTN2025_rgb"
  rm -rf tiles_PTN2025_rgb
fi

log "Starting tile generation (zoom levels 5-10)"

if ! docker run --rm -u "$(id -u)":"$(id -g)" -v "$PWD":/work -w /work ghcr.io/osgeo/gdal:alpine-normal-latest \
  gdal2tiles.py \
    -z 5-10 \
    -r near \
    --xyz \
    -w none \
    250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif tiles_PTN2025_rgb; then
  error "Failed to generate tiles"
  exit 1
fi

if [ ! -d "tiles_PTN2025_rgb" ]; then
  error "Output directory not created: tiles_PTN2025_rgb"
  exit 1
fi

log "Successfully created tiles in tiles_PTN2025_rgb directory"

# タイル数をカウント
tile_count=$(find tiles_PTN2025_rgb -name "*.png" -type f 2>/dev/null | wc -l)
log "Generated $tile_count PNG tiles"
log "Completed: Tile generation finished successfully"