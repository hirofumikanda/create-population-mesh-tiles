#!/bin/bash

set -euo pipefail

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# shpディレクトリの存在チェック
if [ ! -d "shp" ]; then
  error "shp directory not found"
  exit 1
fi

# シェープファイルの存在チェック
shp_count=$(find shp -name "250m_mesh_2024_*.shp" -type f | wc -l)
if [ "$shp_count" -eq 0 ]; then
  error "No shapefile found in shp directory"
  exit 1
fi

log "Found $shp_count shapefile(s) in shp directory"

# 1つ目を新規作成
first_shp="shp/250m_mesh_2024_01.shp"
if [ ! -f "$first_shp" ]; then
  error "First shapefile not found: $first_shp"
  exit 1
fi

log "Creating 250m_mesh_2024_all.shp from $first_shp"
if ! ogr2ogr 250m_mesh_2024_all.shp "$first_shp"; then
  error "Failed to create 250m_mesh_2024_all.shp"
  exit 1
fi
log "Successfully created 250m_mesh_2024_all.shp"

# 2つ目以降を append
append_count=0
for shp in shp/250m_mesh_2024_*.shp; do
  if [ "$shp" != "$first_shp" ]; then
    log "Appending: $shp"
    if ! ogr2ogr -update -append 250m_mesh_2024_all.shp "$shp" -nln 250m_mesh_2024_all; then
      error "Failed to append $shp"
      exit 1
    fi
    append_count=$((append_count + 1))
  fi
done

log "Successfully appended $append_count shapefile(s)"
log "Completed: 250m_mesh_2024_all.shp created with $((append_count + 1)) shapefile(s)"
