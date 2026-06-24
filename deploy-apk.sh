#!/bin/bash

# APK Deployment Script
# This script builds the Flutter APK and copies it to the backend download folder

echo "════════════════════════════════════════════════════════════"
echo "📱 APK Build & Deployment Script"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found!"
    echo "💡 Please run this script from your Flutter project root"
    exit 1
fi

# Step 1: Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean
echo "✅ Clean complete"
echo ""

# Step 2: Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo "✅ Dependencies ready"
echo ""

# Step 3: Build APK
echo "🔨 Building APK (Release mode)..."
flutter build apk --release

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ APK built successfully"
echo ""

# Step 4: Check if APK exists
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at $APK_PATH"
    exit 1
fi

# Get APK size
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo "📊 APK Size: $APK_SIZE"
echo ""

# Step 5: Copy to backend
BACKEND_PATH="backend/public/downloads/app-release.apk"
echo "📋 Copying APK to backend..."

# Create directory if it doesn't exist
mkdir -p backend/public/downloads

cp "$APK_PATH" "$BACKEND_PATH"

if [ $? -ne 0 ]; then
    echo "❌ Failed to copy APK"
    exit 1
fi

echo "✅ APK copied to $BACKEND_PATH"
echo ""

# Step 6: Verify
if [ -f "$BACKEND_PATH" ]; then
    BACKEND_SIZE=$(du -h "$BACKEND_PATH" | cut -f1)
    echo "✅ Verification successful"
    echo "📊 Backend APK Size: $BACKEND_SIZE"
else
    echo "❌ Verification failed - APK not found in backend"
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ APK Deployment Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📝 Next Steps:"
echo "1. Restart your backend server:"
echo "   cd backend && npm start"
echo ""
echo "2. Test the download:"
echo "   curl http://localhost:3000/api/download/apk/info"
echo ""
echo "3. Update website URLs with your server address"
echo ""
echo "🎉 Your APK is ready for download!"
echo "════════════════════════════════════════════════════════════"
