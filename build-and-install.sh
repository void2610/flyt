#!/bin/bash

# Flytをビルドして/Applicationsにインストールするスクリプト

set -e

# 既存のFlytアプリを終了
echo "🛑 既存のFlytアプリを終了中..."
pkill -x Flyt || true

echo "🔨 リリースビルドを開始..."
xcodebuild -project Flyt.xcodeproj \
  -scheme Flyt \
  -configuration Release \
  build \
  -quiet

echo "📦 /Applicationsにコピー中..."
rm -rf /Applications/Flyt.app
cp -R ~/Library/Developer/Xcode/DerivedData/Flyt-*/Build/Products/Release/Flyt.app /Applications/

echo "🔄 アクセシビリティ設定をリセット..."
tccutil reset Accessibility void2610.Flyt

echo "🚀 Flytアプリを起動中..."
open /Applications/Flyt.app

echo "✅ 完了！"
