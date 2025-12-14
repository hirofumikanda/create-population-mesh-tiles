# 将来推計人口ラスタタイル生成パイプライン

[250mメッシュ別将来推計人口データ(国土数値情報)](https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-mesh250r6.html)からWebマップ用のタイルセットを生成するパイプラインです。

## 概要

このプロジェクトは、地域ごとに分割された人口データのシェープファイルを統合し、RGB エンコーディングされたラスタータイルに変換します。生成されたタイルはWebマッピングアプリケーションで利用できます。

## 前提条件

- Docker (GDAL および rio-rgbify のコンテナを使用)
- 入力データ: [250mメッシュ別将来推計人口データ(国土数値情報)](https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-mesh250r6.html)のシェープファイル

## ディレクトリ構造

```
.
├── shp/                          # 入力: 地域別シェープファイル配置ディレクトリ
│   ├── 250m_mesh_2024_01.shp
│   ├── 250m_mesh_2024_02.shp
│   └── ...
├── 01_aggregate_shp.sh           # Step 1: シェープファイル統合
├── 02_mk_numerical_png.sh        # Step 2: ラスタライズ・投影変換・RGB化
├── 03_create_tiles.sh            # Step 3: タイル生成
├── run_all.sh                    # 全処理を一括実行
├── 250m_mesh_2024_all.shp        # 出力: 統合シェープファイル
├── 250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif  # 出力: COG形式ラスター
└── tiles_PTN2025_rgb/            # 出力: PNGタイル (zoom 5-10)
    ├── 5/
    ├── 6/
    ├── ...
    └── 10/
```

## 使用方法

### 1. 入力データの準備

地域別の250mメッシュシェープファイルを `shp/` ディレクトリに配置します:

```bash
mkdir -p shp
# shp/ ディレクトリに 250m_mesh_2024_*.shp ファイルを配置
```

ファイル名規則: `250m_mesh_2024_01.shp`, `250m_mesh_2024_02.shp`, ...

### 2. 全処理の実行

```bash
chmod +x run_all.sh
./run_all.sh
```

### 3. 個別ステップの実行

段階的に処理を実行する場合:

```bash
# Step 1: シェープファイルの統合
bash 01_aggregate_shp.sh

# Step 2: ラスタライズと投影変換、RGB エンコーディング
bash 02_mk_numerical_png.sh

# Step 3: タイル生成 (zoom 5-10)
bash 03_create_tiles.sh
```

## 処理フロー

```
入力シェープファイル (shp/*.shp)
  ↓ 01_aggregate_shp.sh
統合シェープファイル (250m_mesh_2024_all.shp, EPSG:6668)
  ↓ 02_mk_numerical_png.sh
  ├→ ラスタライズ (GeoTIFF, UInt32)
  ├→ Web Mercator投影変換 (EPSG:3857)
  ├→ RGB エンコーディング
  └→ COG形式変換 (*_PTN2025_3857_rgb_cog.tif)
  ↓ 03_create_tiles.sh
PNGタイル (tiles_PTN2025_rgb/, zoom 5-10, XYZ形式)
```

## RGB エンコーディング仕様

人口値は RGB の3チャンネルにエンコードされ、PNG画像として保存されます。エンコーディングには `rio-rgbify` を使用し、以下の式で変換されます:

**エンコーディング式:**
```
人口値 (value) = R × 256² + G × 256 + B
             = R × 65536 + G × 256 + B
```

**デコーディング (読み取り時):**
```javascript
// PNG画像から人口値を復元
const population = red * 65536 + green * 256 + blue;
```

- **入力範囲**: 0 〜 16,777,215 (2²⁴ - 1)
- **ベースバリュー**: 0 (rio-rgbify の `-b 0` オプション)
- **インターバル**: 1 (rio-rgbify の `-i 1` オプション)

この方式により、24bit (3チャンネル × 8bit) で最大約1677万の人口値を表現できます。

## 人口属性の変更

デフォルトでは `PTN_2025` (2025年人口) 属性を使用します。別の年次や属性を使用する場合は、`02_mk_numerical_png.sh` を編集してください:

```bash
# 02_mk_numerical_png.sh 内の -a オプションを変更
-a PTN_2025  # ← この部分を変更 (例: PTN_2030)
```

また、出力ファイル名も適宜変更してください。

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| `250m_mesh_2024_all.shp` | 統合された全国シェープファイル |
| `250m_mesh_2024_all_PTN2025.tif` | ラスタライズされたGeoTIFF (EPSG:6668) |
| `250m_mesh_2024_all_PTN2025_3857.tif` | Web Mercator投影変換後のGeoTIFF |
| `250m_mesh_2024_all_PTN2025_3857_rgb.tif` | RGB エンコーディング済みGeoTIFF |
| `250m_mesh_2024_all_PTN2025_3857_rgb_cog.tif` | Cloud Optimized GeoTIFF (最終ラスター) |
| `tiles_PTN2025_rgb/` | PNGタイルディレクトリ (XYZ形式) |

## ライセンス

このプロジェクトのスクリプトはMITライセンスです。
入力データのライセンスについては、[データ提供元の使用許諾条件](https://nlftp.mlit.go.jp/ksj/gml/datalist/KsjTmplt-mesh250r6.html)に従ってください。
