# CartWise Reputation System Implementation

## Overview
The CartWise reputation system has been successfully implemented to incentivize users to contribute price updates by providing a gamified progression system. Users who regularly update prices gain levels and recognition within the shopping community.

## 🏗️ **Architecture Components**

### Core Files Created/Modified:

1. **`CartWise/Model/ReputationSystem.swift`** - Level definitions and progression logic
2. **`CartWise/Model/ReputationManager.swift`** - User reputation tracking and updates
3. **`CartWise/Views/ReputationCardView.swift`** - UI for displaying user reputation
4. **`CartWise/Views/MyProfileView.swift`** - Added reputation tab
5. **`CartWise/Views/PriceComparisonView.swift`** - Added shopper attribution
6. **`CartWise/Model/Product.swift`** - Updated StorePrice and LocalStorePrice models
7. **`CartWise/Repository/Repository.swift`** - Updated price comparison logic
8. **`CartWise/Model/CoreDataContainer.swift`** - Added shopper attribution functions
9. **`CartWise/Views/CategoryItemsView.swift`** - Added reputation updates

## 📊 **Level System**

### 6 Shopper Levels
| Level | Name | Icon | Color | Min Updates | Description |
|-------|------|------|-------|-------------|-------------|
| 1 | New Shopper | cart.badge.plus | Gray | 0+ | Just getting started with price updates |
| 2 | Regular Shopper | cart.fill | Green | 10+ | Consistently helping the community |
| 3 | Smart Shopper | cart.circle.fill | Blue | 25+ | A trusted source for price information |
| 4 | Expert Shopper | cart.badge.checkmark | Orange | 50+ | Highly reliable price updates |
| 5 | Master Shopper | crown.fill | Yellow | 100+ | The ultimate price update authority |
| 6 | Legendary Shopper | star.circle.fill | Pink | 200+ | A legend in the shopping community |

## 🔄 **Reputation Tracking**

### Automatic Updates
When a user updates a product price, the system automatically:
1. Increments their update count
2. Recalculates their level based on new total
3. Updates their level in Core Data
4. Associates the price update with their username

### Price Attribution
Each price update is tracked with:
- **User ID** - Who made the update
- **Timestamp** - When the update occurred
- **Location** - Where the price was updated
- **Store** - Which store the price is for

## 🎨 **User Interface**

### Profile Page - New Reputation Tab
- **Current Level Badge** - Icon and color representing user's level
- **Level Name & Description** - Clear indication of status
- **Update Statistics** - Total number of price updates made
- **Progress Bar** - Visual progress toward next level
- **Next Level Info** - How many more updates needed

### Price Comparison Integration
When users view price comparisons, they can see:
- **Which shopper** last updated each price
- **When** the price was last updated
- **Store information** for each price

## 🗄️ **Data Models**

### Updated Models:
- **`StorePrice`** - Added `itemShoppers: [String: String]?`
- **`LocalStorePrice`** - Added `itemShoppers: [String: String]?`
- **`GroceryItemPrice`** - Already had `updatedBy: String?` field

### Core Data Integration:
- **`UserEntity`** - Already had `updates: Int32` and `level: String?` fields
- **`GroceryItemPrice`** - Already had `updatedBy: String?` field

## 🔧 **Key Features Implemented**

### 1. **Automatic Reputation Updates**
- No manual intervention required
- Real-time level progression
- Persistent storage in Core Data

### 2. **Visual Progression Feedback**
- Clear level indicators
- Progress bars and animations
- Color-coded level system

### 3. **Community Transparency**
- Shopper attribution on all prices
- Timestamp tracking for updates
- Store and location information

### 4. **Gamification Elements**
- Multiple achievement levels
- Clear progression path
- Visual rewards (icons, colors)
- Progress tracking

### 5. **Quality Assurance**
- Level validation logic
- Data integrity checks
- Error handling for edge cases

## 🎮 **Gamification Benefits**

### User Motivation
- **Achievement** - Clear goals and milestones
- **Recognition** - Public attribution for contributions
- **Progression** - Visible advancement through levels
- **Community** - Part of a larger shopping community

### Quality Incentives
- **Accuracy** - Users want to provide good data to maintain reputation
- **Consistency** - Regular updates improve level standing
- **Helpfulness** - Contributing helps the entire community

## 📱 **User Experience Flow**

1. **User adds/updates a price** → System tracks the update
2. **Reputation automatically updates** → Level recalculated
3. **UI reflects new status** → Progress bars, level badges update
4. **Price comparison shows attribution** → Other users see who updated prices
5. **Community benefits** → All users get better price data

## 🛡️ **Data Integrity**

### Validation
- **Update count validation** - Ensures accurate tracking
- **Level consistency** - Prevents level calculation errors
- **User attribution** - Maintains proper credit assignment

### Error Handling
- **Graceful degradation** if reputation data is missing
- **Default values** for new users
- **Recovery mechanisms** for data corruption

## 🔮 **Future Enhancements**

### Potential Additions
- **Badges** for specific achievements (most updates in a week, etc.)
- **Leaderboards** showing top contributors
- **Special privileges** for high-level users
- **Verification system** for price accuracy
- **Community voting** on price updates

### Technical Improvements
- **Real-time notifications** for level ups
- **Social sharing** of achievements
- **Advanced analytics** for user engagement
- **API endpoints** for reputation data

---

**System Status**: ✅ Fully Implemented 
**Last Updated**: December 2024 
**Maintainer**: CartWise Development Team

## 🚀 **Getting Started**

1. **Build and run the app**
2. **Navigate to Profile tab**
3. **Select the new "Reputation" tab**
4. **Update some product prices** to see reputation progression
5. **View price comparisons** to see shopper attribution

The reputation system is now fully integrated into the CartWise app and will automatically track user contributions and provide gamified feedback to encourage community participation. 