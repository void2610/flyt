#!/bin/bash

# Flytをビルドして/Applicationsにインストールするスクリプト
# 使い方:
#   ./build-and-install.sh release # リリースビルド
#   ./build-and-install.sh debug   # デバッグビルド

set -e

# ビルド構成を決定（引数でdebugを指定するとデバッグビルド）
if [ "$1" == "debug" ]; then
  CONFIGURATION="Debug"
  echo "🔧 デバッグビルドモード"
elif [ "$1" == "release" ]; then
  CONFIGURATION="Release"
  echo "🚀 リリースビルドモード"
else
  echo "ビルド構成を指定してください。"
  exit 1
fi

# 既存のFlytアプリを終了
echo "🛑 既存のFlytアプリを終了中..."
pkill -x Flyt || true

echo "🔨 ${CONFIGURATION}ビルドを開始..."
xcodebuild -project Flyt.xcodeproj \
  -scheme Flyt \
  -configuration ${CONFIGURATION} \
  build \
  -quiet

echo "📦 /Applicationsにコピー中..."
rm -rf /Applications/Flyt.app
cp -R ~/Library/Developer/Xcode/DerivedData/Flyt-*/Build/Products/${CONFIGURATION}/Flyt.app /Applications/

echo "🔄 アクセシビリティ設定をリセット..."
tccutil reset Accessibility void2610.Flyt

echo "🚀 Flytアプリを起動中..."
open /Applications/Flyt.app

echo "✅ 完了！"
