#!/bin/bash

# CartWise iPhone 16 Simulator Rebuild Script
# This script rebuilds the CartWise app for iPhone 16 simulator and relaunches it

echo "🚀 Starting CartWise iPhone 16 simulator rebuild..."

# Set variables
PROJECT_NAME="CartWise"
SCHEME_NAME="CartWise"
SIMULATOR_NAME="iPhone 16"
BUNDLE_ID="cs467.CartWise.brenna"

# Get the derived data path
DERIVED_DATA_PATH="/Users/brennawilson/Library/Developer/Xcode/DerivedData/CartWise-czapoyrbzwcxwbaxlmgxdybhiuki"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/CartWise.app"

echo "📱 Building for $SIMULATOR_NAME..."

# 1. Build the app for iPhone 16 simulator
xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME_NAME" -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" clean build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🔧 Booting $SIMULATOR_NAME simulator..."

# 2. Boot the iPhone 16 simulator
xcrun simctl boot "$SIMULATOR_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Simulator booted successfully!"
else
    echo "❌ Failed to boot simulator!"
    exit 1
fi

echo "📦 Installing app on simulator..."

# 3. Install the built app on the simulator
xcrun simctl install "$SIMULATOR_NAME" "$APP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ App installed successfully!"
else
    echo "❌ Failed to install app!"
    exit 1
fi

echo "🚀 Launching CartWise app..."

# 4. Launch the app
xcrun simctl launch "$SIMULATOR_NAME" "$BUNDLE_ID"

if [ $? -eq 0 ]; then
    echo "✅ App launched successfully!"
    echo "🎉 CartWise is now running on iPhone 16 simulator!"
else
    echo "❌ Failed to launch app!"
    exit 1
fi

echo "✨ All done! Your updated CartWise app is running on the iPhone 16 simulator." 