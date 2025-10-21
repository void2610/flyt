#!/bin/bash

# Flytをビルドして/Applicationsにインストールするスクリプト

set -e

echo "🔨 リリースビルドを開始..."
xcodebuild -project Flyt.xcodeproj \
  -scheme Flyt \
  -configuration Release \
  build \
  -quiet

echo "📦 /Applicationsにコピー中..."
rm -rf /Applications/Flyt.app
cp -R ~/Library/Developer/Xcode/DerivedData/Flyt-*/Build/Products/Release/Flyt.app /Applications/

echo "アクセシビリティ設定をリセット"
tccutil reset Accessibility void2610.Flyt

echo "✅ 完了！ /Applications/Flyt.appを起動してください"
echo "💡 Control+I でメモウィンドウを開きます"
