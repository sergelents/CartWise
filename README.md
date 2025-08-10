# CartWise

A crowd-sourced shopping iOS application that helps users manage shopping lists, compare prices, and discover products with barcode scanning and social features.

## 🚀 Features

### 📱 Core Shopping Features
- **Shopping List Management**: Add, remove, and organize items in your shopping list
- **Barcode Scanning**: Scan product barcodes to quickly add items
- **Price Tracking**: Manual price entry
- **Category Organization**: Browse products by categories
- **Favorites**: Save frequently purchased items

### 💰 Price Management
- **Manual Price Entry**: Users can manually enter prices when adding new items
- **Price Display**: Individual item prices displayed in shopping list
- **Total Calculation**: Real-time calculation of total shopping list cost
- **Local Price Comparison**: Compare prices across different stores using local user data

### 🏪 Store & Location Features
- **Store Management**: Add and manage different store locations
- **Location-based Shopping**: Organize items by store location
- **Price Comparison**: Compare total costs across different stores

### 🏷️ Product Organization
- **Tag System**: Categorize products with custom tags
- **Brand Tracking**: Track product brands and companies
- **Category Filtering**: Browse products by categories
- **Search Functionality**: Search through your products and tags

### 📸 Image & Visual Features
- **Product Images**: Automatic image fetching from Amazon API
- **Offline Image Storage**: Images cached locally for offline access
- **Visual Product Cards**: Beautiful product display with images and details

### 👥 Social Features
- **User Reputation System**: Build reputation through helpful contributions
- **Social Feed**: Share shopping experiences and tips
- **Community Features**: Connect with other shoppers (in-progress)

## 📋 Prerequisites

### System Requirements
- **macOS**: 12.0 (Monterey) or later
- **Xcode**: 15.0 or later
- **iOS**: 16.0 or later (for device deployment)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 10GB free space

### Required Accounts
- **Apple Developer Account**: Free account for simulator, paid for device deployment
- **Git**: For cloning the repository

## 🛠️ Installation & Setup

### 1. Install Xcode

#### Option A: App Store (Recommended)
1. Open the **App Store** on your Mac
2. Search for "Xcode"
3. Click **Get** or **Install**
4. Wait for download and installation (may take 30+ minutes)

#### Option B: Apple Developer Website
1. Visit [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Download Xcode from the **Downloads** section
4. Install the downloaded `.xip` file

### 2. Install Command Line Tools
```bash
xcode-select --install
```

### 3. Clone the Repository
```bash
git clone https://github.com/sergelents/CartWise.git
cd CartWise
```

### 4. Open the Project
1. Open **Xcode**
2. Click **Open a project or file**
3. Navigate to the `CartWise` folder
4. Select `CartWise.xcodeproj`
5. Click **Open**

## 🎮 Running the App

### Option 1: iOS Simulator (Recommended for Development)

#### Quick Start
1. In Xcode, select your target device from the toolbar:
   - **iPhone 16** (recommended)
   - **iPhone 15 Pro**
   - **iPhone 14**
   - Any other iOS simulator

2. Click the **Play** button (▶️) or press `Cmd + R`

3. The simulator will launch automatically with your app

#### Using the Rebuild Script
The project includes a convenient rebuild script:
```bash
chmod +x rebuild_simulator.sh
./rebuild_simulator.sh
```

### Option 2: Physical iOS Device

#### Setup for Device Deployment
1. **Connect your iPhone** to your Mac with a USB cable

2. **Trust the computer** on your iPhone if prompted

3. **In Xcode**:
   - Select your iPhone from the device dropdown
   - Click the **Play** button (▶️)

4. **On your iPhone**:
   - Go to **Settings > General > VPN & Device Management**
   - Find your Apple ID/Developer certificate
   - Tap **Trust**

#### Troubleshooting Device Issues
- **"Untrusted Developer"**: Trust the certificate in Settings
- **Build fails**: Check that your Apple ID is signed in Xcode
- **App won't install**: Restart both Xcode and your iPhone

### Option 3: Multiple Simulators
You can run multiple simulators simultaneously:
1. **Hardware > Device > iOS** in the simulator menu
2. Select different device types
3. Each simulator runs independently

## 🔧 Configuration

### Bundle Identifier
The app uses the bundle identifier: `cs467.CartWise`

To change it:
1. Select the project in Xcode's navigator
2. Select the **CartWise** target
3. Go to **General** tab
4. Change **Bundle Identifier**

### Development Team
1. In Xcode, select the project
2. Select the **CartWise** target
3. Go to **Signing & Capabilities**
4. Select your **Team** (Apple ID)

## 📱 App Features Walkthrough

### Getting Started
1. **Launch the app** - You'll see the main shopping interface
2. **Add your first item**:
   - Tap the **+** button
   - Use barcode scanner or manual entry
   - Add price and store information

### Key Features to Try
- **Barcode Scanning**: Tap the camera icon to scan product barcodes
- **Price Comparison**: View total costs across different stores
- **Tag System**: Add custom tags to organize products
- **Favorites**: Star frequently used items
- **Social Feed**: Share shopping experiences

## 🐛 Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean build folder
Cmd + Shift + K

# Clean and rebuild
Cmd + Shift + K, then Cmd + R
```

#### Simulator Issues
```bash
# Reset simulator
xcrun simctl erase all

# List available simulators
xcrun simctl list devices
```

#### Xcode Issues
- **Xcode crashes**: Restart Xcode and your Mac
- **Slow performance**: Close other apps, increase RAM allocation
- **Build hangs**: Clean build folder and restart Xcode

### Performance Tips
- Use **iPhone 16** simulator for best performance
- Close unnecessary apps while developing
- Restart Xcode if it becomes sluggish

## 📚 Development Resources

### Documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Core Data Programming Guide](https://developer.apple.com/documentation/coredata)

### Useful Commands
```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 16"

# Install app on simulator
xcrun simctl install booted /path/to/app

# Launch app
xcrun simctl launch booted cs467.CartWise.brenna
```

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Contact the development team for assistance

---

**Happy Shopping! 🛒✨**
