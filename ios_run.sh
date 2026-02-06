#!/bin/bash
set -e

ROOT="/Users/hsiangyuhsieh/Documents/AI/app/food-ai-app"
FRONTEND="$ROOT/frontend"
IOS="$FRONTEND/ios"

cd "$FRONTEND"
echo "[1/5] git pull"
git pull origin main

echo "[2/5] flutter clean"
flutter clean

echo "[3/5] flutter pub get"
flutter pub get

echo "[4/5] pod install"
cd "$IOS"
pod install

cd "$FRONTEND"
echo "[5/5] flutter run -d ios"
flutter run -d ios
