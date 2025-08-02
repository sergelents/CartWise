# Social Feed Implementation

## Overview

The social feed feature allows users to share and view shopping experiences, including price updates, store reviews, product reviews, and general comments. This implementation provides a framework that can later be integrated with cloud services for real-time sharing across all users.

## Features

### Core Functionality
- **Experience Sharing**: Users can post shopping experiences with comments and ratings
- **Experience Types**: 
  - Price Updates (when users find good deals)
  - Store Reviews (feedback about shopping locations)
  - Product Reviews (reviews of specific products)
  - General Comments (any shopping-related content)
- **Comments System**: Users can comment on experiences with ratings
- **Live Feed**: Real-time display of all user experiences
- **Integration Points**: Share experiences from price comparison results

### Data Model

#### ShoppingExperience Entity
- `id`: Unique identifier
- `comment`: User's comment text
- `rating`: Star rating (0-5)
- `type`: Experience type (price_update, store_review, product_review, general)
- `createdAt`: Timestamp
- `user`: Reference to UserEntity
- `groceryItem`: Optional reference to specific product
- `location`: Optional reference to specific store
- `comments`: One-to-many relationship with UserComment

#### UserComment Entity
- `id`: Unique identifier
- `comment`: Comment text
- `rating`: Star rating (0-5)
- `createdAt`: Timestamp
- `user`: Reference to UserEntity
- `experience`: Reference to parent ShoppingExperience

## UI Components

### SocialFeedView
- Main feed display with experience cards
- Pull-to-refresh functionality
- Add experience button
- Empty state with sample data option

### ExperienceCardView
- Displays experience content with user info
- Shows rating, type badge, and related items/locations
- Tap to view details and comments

### AddExperienceView
- Form to create new experiences
- Type selection and rating system
- Comment text editor

### ExperienceDetailView
- Detailed view of experience with all comments
- Add comment functionality
- Rating system for comments

### ShareExperienceView
- Integration point from price comparison
- Pre-filled with price comparison data
- Quick sharing of shopping deals

## Integration Points

### Price Comparison Integration
- "Share Experience" button in PriceComparisonView
- Pre-fills with store and price information
- Allows users to quickly share good deals

### Navigation Integration
- New "Social Feed" tab in main navigation
- Accessible from all main app sections

## Future Cloud Integration

The current implementation is designed for easy cloud integration:

### Data Structure
- All entities have unique IDs for cloud sync
- Timestamps for ordering and conflict resolution
- User relationships for authentication

### API Ready
- ViewModel methods can be easily adapted for API calls
- Local-first architecture with offline capability
- Structured data format for cloud storage

### Features to Add
- Real-time updates across devices
- User authentication and profiles
- Push notifications for new experiences
- Advanced filtering and search
- Photo attachments for experiences
- Location-based experience filtering

## Usage Examples

### Sample Feed Entries
```
03-22 -- SpaghettiO's @Albertsons => $0.89 -- SuperShopper555
03-22 -- "Winco Foods does NOT have enough cashiers today. AVOID" -- Shopaholic
03-22 -- "Found amazing deals at Whole Foods today!" -- DealHunter
```

### Experience Types
- **Price Update**: "Milk is $2.99 at Safeway this week!"
- **Store Review**: "Great customer service at Trader Joe's"
- **Product Review**: "This organic cereal is worth the price"
- **General**: "Shopping tip: Always check the clearance section"

## Technical Implementation

### Core Data Integration
- New entities added to ProductModel.xcdatamodeld
- Relationships with existing UserEntity, GroceryItem, and Location
- Proper deletion rules for data integrity

### ViewModel Architecture
- SocialFeedViewModel manages all feed operations
- ObservableObject pattern for SwiftUI integration
- Error handling and loading states

### SwiftUI Components
- Modern SwiftUI with @StateObject and @ObservedObject
- Sheet presentations for modals
- Pull-to-refresh and navigation integration

## Testing

### Sample Data
- `createSampleData()` method provides test data
- Includes various experience types and ratings
- Demonstrates the full feature set

### Manual Testing
1. Launch app and navigate to Social Feed tab
2. Tap "Add Sample Data" to populate feed
3. Tap on experience cards to view details
4. Add new experiences using the + button
5. Test sharing from price comparison view

## Performance Considerations

- LazyVStack for efficient scrolling
- Core Data fetch requests with proper sorting
- Local storage for offline functionality
- Minimal memory footprint with proper cleanup

## Security & Privacy

- User data stored locally only
- No personal information shared without consent
- Anonymous posting option available
- Future cloud integration will require user authentication 