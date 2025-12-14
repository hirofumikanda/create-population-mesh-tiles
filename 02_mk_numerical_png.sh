#!/bin/bash

set -euo pipefail

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# 入力ファイルの存在チェック
if [ ! -f "250m_mesh_2024_all.shp" ]; then
  error "Input shapefile not found: 250m_mesh_2024_all.shp"
  exit 1
fi

log "Starting rasterization process"

# Step 1: Rasterize
log "Step 1/4: Rasterizing shapefile to GeoTIFF"
if ! docker run --rm -u "$(id -u)":"$(id -g)" -v "$PWD":/work -w /work ghcr.io/osgeo/gdal:alpine-normal-latest \
  gdal_rasterize \
    -a PTN_2025 \
    -tr 0.003125 0.0020833333333333333 \
    -tap \
    -a_nodata 0 \
    -ot UInt32 \
    250m_mesh_2024_all.shp 250m_mesh_2024_all_PTN2025.tif; then
  error "Failed to rasterize shapefile"
  exit 1
fi

if [ ! -f "250m_mesh_2024_all_PTN2025.tif" ]; then
  error "Output file not created: 250m_mesh_2024_all_PTN2025.tif"
  exit 1
fi
log "Successfully created 250m_mesh_2024_all_PTN2025.tif"

# Step 2: Reproject to Web Mercator
log "Step 2/4: Reprojecting to EPSG:3857 (Web Mercator)"
if ! docker run --rm -u "$(id -u)":"$(id -g)" -v "$PWD":/work -w /work ghcr.io/osgeo/gdal:alpine-normal-latest \
  gdalwarp -s_srs EPSG:6668 -t_srs EPSG:3857 \
  -r near \
  -multi -wo NUM_THREADS=ALL_CPUS \
  250m_mesh_2024_all_PTN2025.tif 250m_mesh_2024_all_PTN2025_3857.tif; then
  error "Failed to reproject to EPSG:3857"
  exit 1
fi

if [ ! -f "250m_mesh_2024_all_PTN2025_3857.tif" ]; then
  error "Output file not created: 250m_mesh_2024_all_PTN2025_3857.tif"
  exit 1
fi
log "Successfully created 250m_mesh_2024_all_PTN2025_3857.tif"

# Step 3: RGB encoding
log "Step 3/4: Encoding to RGB"
if ! docker run --rm -u "$(id -u)":"$(id -g)" -ti -v $(pwd):/data helmi03/rio-rgbify \
  -j 1 -b 0 -i 1 \
  250m_mesh_2024_all_PTN2025_3857.tif 250m_mesh_2024_all_PTN2025_3857_rgb.tif; then
  error "Failed to encode to RGB"
  exit 1
fi

if [ ! -f "250m_mesh_2024_all_PTN2025_3857_rgb.tif" ]; then
  error "Output file not created: 250m_mesh_2024_all_PTN2025_3857_rgb.tif"
  exit 1
fi
log "Successfully created 250m_mesh_2024_all_PTN2025_3857_rgb.tif"

# Step 4: Convert to COG
log "Step 4/4: Converting to Cloud Optimized GeoTIFF"
if ! docker run --rm -u "$(id -u)":"$(id -g)" -v "$PWD":/work -w /work ghcr.io/osgeo/gdal:alpine-normal-latest \
  gdal_translate 250m_mesh_2024_all_PTN2025_3857_rgb.tif 250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif \
    -of COG \
    -co COMPRESS=DEFLATE \
    -co BLOCKSIZE=256; then
  error "Failed to convert to COG"
  exit 1
fi

if [ ! -f "250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif" ]; then
  error "Output file not created: 250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif"
  exit 1
fi
log "Successfully created 250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif"

log "Completed: All rasterization steps finished successfully"