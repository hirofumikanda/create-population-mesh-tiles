#!/bin/bash

set -euo pipefail

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# スクリプト開始時刻を記録
start_time=$(date +%s)

log "========================================="
log "Starting population tile creation pipeline"
log "========================================="

# Step 1: シェープファイルの統合
log ""
log "Step 1/3: Aggregating shapefiles"
log "-----------------------------------------"
if [ ! -f "01_aggregate_shp.sh" ]; then
  error "Script not found: 01_aggregate_shp.sh"
  exit 1
fi

if ! bash 01_aggregate_shp.sh; then
  error "Failed to execute 01_aggregate_shp.sh"
  exit 1
fi
log "Step 1/3: Completed successfully"

# Step 2: ラスタライズと投影変換
log ""
log "Step 2/3: Rasterizing and transforming"
log "-----------------------------------------"
if [ ! -f "02_mk_numerical_png.sh" ]; then
  error "Script not found: 02_mk_numerical_png.sh"
  exit 1
fi

if ! bash 02_mk_numerical_png.sh; then
  error "Failed to execute 02_mk_numerical_png.sh"
  exit 1
fi
log "Step 2/3: Completed successfully"

# Step 3: タイル生成
log ""
log "Step 3/3: Generating tiles"
log "-----------------------------------------"
if [ ! -f "03_create_tiles.sh" ]; then
  error "Script not found: 03_create_tiles.sh"
  exit 1
fi

if ! bash 03_create_tiles.sh; then
  error "Failed to execute 03_create_tiles.sh"
  exit 1
fi
log "Step 3/3: Completed successfully"

# 処理時間を計算
end_time=$(date +%s)
elapsed=$((end_time - start_time))
hours=$((elapsed / 3600))
minutes=$(((elapsed % 3600) / 60))
seconds=$((elapsed % 60))

log ""
log "========================================="
log "Pipeline completed successfully!"
log "Total elapsed time: ${hours}h ${minutes}m ${seconds}s"
log "========================================="
