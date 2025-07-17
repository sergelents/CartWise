#!/bin/bash

# CartWise Rebuild Script
# This script rebuilds the CartWise iOS app on iPhone 16 simulator and updates the simulator

echo "🚀 Starting CartWise rebuild process..."

# Navigate to project directory
cd /Users/brennawilson/Desktop/CartWise

echo "📁 Changed to project directory: $(pwd)"

# Clean and build the project for iPhone 16 simulator
echo "🔨 Building CartWise for iPhone 16 simulator..."

xcodebuild -project CartWise.xcodeproj \
           -scheme CartWise \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           clean build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    
    echo "📱 Updating iPhone 16 simulator..."
    
    # Shutdown simulator if running
    echo "🔄 Shutting down iPhone 16 simulator..."
    xcrun simctl shutdown "iPhone 16" 2>/dev/null || true
    
    # Boot simulator
    echo "🚀 Booting iPhone 16 simulator..."
    xcrun simctl boot "iPhone 16"
    
    # Find the latest build
    echo "🔍 Finding latest build..."
    LATEST_BUILD=$(find /Users/brennawilson/Library/Developer/Xcode/DerivedData -name "CartWise.app" -type d | grep -v Index.noindex | tail -1)
    
    if [ -z "$LATEST_BUILD" ]; then
        echo "❌ Could not find CartWise.app build"
        exit 1
    fi
    
    echo "📦 Found build at: $LATEST_BUILD"
    
    # Uninstall old app
    echo "🗑️  Uninstalling old CartWise app..."
    xcrun simctl uninstall booted cs467.CartWise.brenna 2>/dev/null || true
    
    # Install new app
    echo "📲 Installing new CartWise app..."
    xcrun simctl install booted "$LATEST_BUILD"
    
    # Open simulator
    echo "🖥️  Opening Simulator app..."
    open -a Simulator
    
    echo ""
    echo "✅ Simulator updated successfully!"
    echo "📱 CartWise app is now installed and ready to use"
    echo ""
    echo "The simulator should open automatically. If not, you can:"
    echo "1. Open Simulator app manually"
    echo "2. Select iPhone 16 from the device menu"
    echo "3. Look for CartWise on the home screen"
    echo ""
    echo "If you don't see the app, try:"
    echo "- Swiping down to search and typing 'CartWise'"
    echo "- Or restarting the simulator (Device → Erase All Content and Settings)"
else
    echo "❌ Build failed! Please check the error messages above."
    exit 1
fi 