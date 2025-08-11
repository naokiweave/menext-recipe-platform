# 動画・画像アップロードガイド

## 📁 フォルダ構成
```
public/
├── videos/          # 動画ファイル
│   ├── recipe_1.mp4
│   ├── recipe_2.mp4
│   └── ...
└── thumbnails/      # サムネイル画像
    ├── 225.jpg      # ✅ アップロード済み
    ├── recipe_2.jpg
    └── ...
```

## 🎥 動画ファイル
- **場所**: `public/videos/` フォルダ
- **命名**: `recipe_1.mp4`, `recipe_2.mp4` など
- **形式**: MP4, MOV, AVI, WebM
- **推奨**: 1280x720 (720p), 2-5 Mbps

## 🖼️ サムネイル画像
- **場所**: `public/thumbnails/` フォルダ
- **命名**: `225.jpg` (既にアップロード済み), `recipe_2.jpg` など
- **形式**: JPG, PNG, WebP
- **推奨**: 1280x720 (16:9), 500KB以下

## 🔧 HTMLでの使用方法
```html
<!-- サムネイル -->
<div style="background-image: url('/thumbnails/225.jpg');">

<!-- 動画 -->
<video src="/videos/recipe_1.mp4" controls></video>
```

## 📝 次にアップロードする場合
1. ファイルを適切なフォルダに配置
2. `index.html` の該当部分を更新
3. ファイル名を正確に指定