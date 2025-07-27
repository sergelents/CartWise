# CartWise Reputation System

## Overview

The CartWise reputation system is a comprehensive user ranking and achievement system designed to encourage community contributions in the crowd-sourced shopping app. Users earn points and badges by contributing to the platform, with their reputation level increasing based on their contribution count.

## Features

### 🏆 Reputation Levels
- **Newbie** (0 points) - Just getting started
- **Contributor** (50 points) - Making contributions
- **Helper** (150 points) - Helping the community
- **Expert** (300 points) - Knowledgeable contributor
- **Master** (600 points) - Master of shopping
- **Legend** (1000 points) - Shopping legend
- **Grandmaster** (2000 points) - Ultimate shopping expert

### 🎯 Achievement Badges
- **First Step** - Made your first contribution
- **Price Watcher** - Updated 10 prices
- **Product Scout** - Added 5 new products
- **Reviewer** - Submitted 3 reviews
- **Active Contributor** - Reached 50 contribution points
- **Dedicated Helper** - Reached 100 contribution points
- **Community Expert** - Reached 500 contribution points
- **Daily Helper** - Contributed for 7 consecutive days
- **Versatile Helper** - Contributed in all categories

### 📊 Contribution Types & Points
- **Price Update**: +10 points
- **Product Addition**: +25 points
- **Review Submission**: +15 points
- **Photo Upload**: +20 points
- **Store Review**: +30 points

## Architecture

### Core Components

1. **ReputationManager** (`Utilities/ReputationManager.swift`)
   - Manages reputation levels and achievements
   - Calculates progress and points
   - Defines achievement requirements

2. **ReputationViewModel** (`ViewModel/ReputationViewModel.swift`)
   - Handles Core Data operations
   - Manages user contributions
   - Provides data for UI components

3. **UserEntity** (`Model/UserEntity+CoreDataClass.swift`)
   - Core Data entity with reputation fields
   - Convenience methods for contributions
   - Achievement badge management

4. **ReputationView** (`Views/ReputationView.swift`)
   - Main reputation UI components
   - Level display and progress tracking
   - Achievement showcase

### Data Model

The `UserEntity` includes the following reputation-related fields:

```swift
@NSManaged public var contributionPoints: Int32
@NSManaged public var reputationLevel: String?
@NSManaged public var totalContributions: Int32
@NSManaged public var priceUpdates: Int32
@NSManaged public var productAdditions: Int32
@NSManaged public var reviewsSubmitted: Int32
@NSManaged public var lastContributionDate: Date?
@NSManaged public var achievementBadges: String? // JSON string
```

## Usage

### Adding Contributions

To add a contribution to a user's reputation, use the `ReputationViewModel`:

```swift
// Initialize the view model
let reputationViewModel = ReputationViewModel()

// Load current user
await reputationViewModel.loadCurrentUser()

// Add different types of contributions
await reputationViewModel.addPriceUpdate()
await reputationViewModel.addProductAddition()
await reputationViewModel.addReviewSubmission()
await reputationViewModel.addPhotoUpload()
await reputationViewModel.addStoreReview()
```

### Displaying Reputation

The reputation system is integrated into the `MyProfileView` and can be accessed via:

```swift
// Show reputation view
.sheet(isPresented: $showingReputation) {
    NavigationView {
        ReputationView(reputationViewModel: reputationViewModel)
            .navigationTitle("Reputation")
    }
}
```

### Achievement Notifications

Achievements are automatically checked when contributions are added and displayed via alerts:

```swift
.alert("Achievement Unlocked!", isPresented: $reputationViewModel.showAchievementAlert) {
    Button("Awesome!") { }
} message: {
    if let achievement = reputationViewModel.newAchievement {
        Text("You've earned the '\(achievement.name)' badge!")
    }
}
```

## Integration Points

### Profile Page Integration
- Reputation level badge displayed under username
- "View Reputation" button to access detailed reputation view
- Achievement notifications when earned

### Core Data Integration
- All reputation data persisted in Core Data
- Automatic saving when contributions are added
- User data linked to unique login identifier

### MVVM Architecture
- Follows existing app architecture patterns
- Observable objects for reactive UI updates
- Separation of concerns between data, logic, and presentation

## Testing

A test interface is provided for development and testing:

```swift
// Access test contributions view
.sheet(isPresented: $showingTestContributions) {
    TestContributionView(reputationViewModel: reputationViewModel)
}
```

The test view allows you to:
- Simulate different types of contributions
- View real-time stats updates
- Test achievement unlocking
- Verify reputation level progression

## Customization

### Adding New Achievement Types

1. Add new achievement to `ReputationManager.achievements`:
```swift
Achievement(id: "new_achievement", name: "New Badge", description: "Description", icon: "icon.name", color: .blue, requirement: "Requirement")
```

2. Add achievement check in `ReputationManager.checkAchievements()`:
```swift
if user.someMetric >= threshold && !user.getEarnedBadges().contains("new_achievement") {
    newAchievements.append("new_achievement")
}
```

### Modifying Point Values

Update point values in `ReputationManager.getContributionPoints()`:
```swift
static func getContributionPoints(for action: ContributionAction) -> Int32 {
    switch action {
    case .priceUpdate:
        return 15 // Changed from 10
    // ... other cases
    }
}
```

### Adding New Reputation Levels

Add new levels to `ReputationManager.reputationLevels`:
```swift
ReputationLevel(name: "New Level", minPoints: 2500, color: .indigo, icon: "new.icon", description: "Description")
```

## Future Enhancements

Potential improvements for the reputation system:

1. **Streak Tracking**: Track consecutive days of contribution
2. **Seasonal Events**: Time-limited achievements and bonuses
3. **Community Challenges**: Group-based reputation goals
4. **Leaderboards**: Compare reputation with other users
5. **Rewards System**: Unlock features based on reputation level
6. **Contribution History**: Detailed log of all contributions
7. **Social Features**: Share achievements on social media

## Technical Notes

- All reputation data is stored locally using Core Data
- Achievement badges are stored as JSON strings for flexibility
- The system automatically handles level progression
- UI updates are reactive using SwiftUI's `@Published` properties
- Error handling is implemented for Core Data operations
- The system is designed to be scalable and maintainable 