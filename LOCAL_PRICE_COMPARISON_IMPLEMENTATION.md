# Local Price Comparison Implementation Guide

## Overview

This document explains how to implement local price comparison functionality using the new Core Data model relationships without requiring API calls.

## Current Model Relationships

The Core Data model includes the following entities and relationships:

### GroceryItem Entity
- `prices`: One-to-many relationship with `GroceryItemPrice`
- `locations`: Many-to-many relationship with `Location`
- `tags`: Many-to-many relationship with `Tag`

### GroceryItemPrice Entity
- `groceryItem`: Many-to-one relationship with `GroceryItem`
- `location`: Many-to-one relationship with `Location`
- `store`: String attribute for store name
- `price`: Double attribute for price value
- `currency`: String attribute for currency

### Location Entity
- `groceryItems`: Many-to-many relationship with `GroceryItem`
- `prices`: One-to-many relationship with `GroceryItemPrice`

## Implementation Steps

### 1. Core Data Container Methods

Add these methods to `CoreDataContainer.swift`:

```swift
// Price-related methods
func fetchPricesForProduct(_ product: GroceryItem) async throws -> [GroceryItemPrice]
func createPrice(id: String, price: Double, currency: String, store: String, product: GroceryItem, location: Location?) async throws -> GroceryItemPrice
func updatePrice(_ price: GroceryItemPrice) async throws
func deletePrice(_ price: GroceryItemPrice) async throws
func fetchPricesByStore(_ store: String) async throws -> [GroceryItemPrice]
func fetchPricesByLocation(_ location: Location) async throws -> [GroceryItemPrice]
func getLocalPriceComparison(for products: [GroceryItem], stores: [String]) async throws -> LocalPriceComparisonResult
```

### 2. Repository Protocol

Add to `ProductRepositoryProtocol`:

```swift
func getLocalPriceComparison(for shoppingList: [GroceryItem], stores: [String]) async throws -> LocalPriceComparisonResult
```

### 3. Repository Implementation

Implement the local price comparison in `ProductRepository`:

```swift
func getLocalPriceComparison(for shoppingList: [GroceryItem], stores: [String]) async throws -> LocalPriceComparisonResult {
    var storePrices: [LocalStorePrice] = []
    
    for store in stores {
        var totalPrice: Double = 0.0
        var availableItems = 0
        var unavailableItems = 0
        var itemPrices: [String: Double] = [:]
        
        for item in shoppingList {
            guard let productName = item.productName else { continue }
            
            // Check if the item has a price and matches the store
            if let itemStore = item.store, itemStore.lowercased() == store.lowercased() {
                let price = item.price
                if price > 0 {
                    totalPrice += price
                    availableItems += 1
                    itemPrices[productName] = price
                } else {
                    unavailableItems += 1
                }
            } else {
                // If no store match, check if item has any price
                if item.price > 0 {
                    totalPrice += item.price
                    availableItems += 1
                    itemPrices[productName] = item.price
                } else {
                    unavailableItems += 1
                }
            }
        }
        
        let storePrice = LocalStorePrice(
            store: store,
            totalPrice: totalPrice,
            currency: "USD",
            availableItems: availableItems,
            unavailableItems: unavailableItems,
            itemPrices: itemPrices
        )
        
        storePrices.append(storePrice)
    }
    
    // Find the best store
    let bestStorePrice = storePrices.min { $0.totalPrice < $1.totalPrice }
    let bestStore = bestStorePrice?.store
    let bestTotalPrice = bestStorePrice?.totalPrice ?? 0.0
    
    return LocalPriceComparisonResult(
        storePrices: storePrices,
        bestStore: bestStore,
        bestTotalPrice: bestTotalPrice,
        bestCurrency: "USD",
        totalItems: shoppingList.count,
        availableItems: storePrices.map { $0.availableItems }.max() ?? 0
    )
}
```

### 4. ViewModel Method

Add to `ProductViewModel`:

```swift
func loadLocalPriceComparison(stores: [String] = ["Amazon", "Walmart"]) async {
    let shoppingListProducts = try? await repository.fetchListProducts()
    
    guard let shoppingList = shoppingListProducts, !shoppingList.isEmpty else {
        priceComparison = nil
        return
    }
    
    isLoadingPriceComparison = true
    errorMessage = nil
    
    do {
        let localComparison = try await repository.getLocalPriceComparison(for: shoppingList, stores: stores)
        
        // Convert LocalPriceComparisonResult to PriceComparison for compatibility
        let storePrices = localComparison.storePrices.map { localStorePrice in
            StorePrice(
                store: Store(rawValue: localStorePrice.store) ?? .amazon,
                totalPrice: localStorePrice.totalPrice,
                currency: localStorePrice.currency,
                availableItems: localStorePrice.availableItems,
                unavailableItems: localStorePrice.unavailableItems,
                itemPrices: localStorePrice.itemPrices
            )
        }
        
        let comparison = PriceComparison(
            storePrices: storePrices,
            bestStore: localComparison.bestStore != nil ? Store(rawValue: localComparison.bestStore!) : nil,
            bestTotalPrice: localComparison.bestTotalPrice,
            bestCurrency: localComparison.bestCurrency,
            totalItems: localComparison.totalItems,
            availableItems: localComparison.availableItems
        )
        
        priceComparison = comparison
    } catch {
        errorMessage = "Failed to load local price comparison: \(error.localizedDescription)"
    }
    
    isLoadingPriceComparison = false
}
```

### 5. User Interface

Update `PriceComparisonView.swift` to include store selection:

```swift
struct PriceComparisonView: View {
    @State private var selectedStores: Set<String> = ["Amazon", "Walmart"]
    @State private var availableStores = ["Amazon", "Walmart", "Target", "Kroger", "Safeway", "Whole Foods"]
    
    var body: some View {
        VStack {
            // Store Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Stores to Compare:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(availableStores, id: \.self) { store in
                        StoreToggleButton(
                            store: store,
                            isSelected: selectedStores.contains(store),
                            onToggle: { isSelected in
                                if isSelected {
                                    selectedStores.insert(store)
                                } else {
                                    selectedStores.remove(store)
                                }
                            }
                        )
                    }
                }
                
                Button("Compare Local Prices") {
                    Task {
                        await onLocalComparison()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedStores.isEmpty)
            }
            
            // Existing price comparison display
            // ... rest of the view
        }
    }
}
```

## Benefits of Local Price Comparison

1. **No API Dependencies**: Works entirely with local data
2. **Faster Performance**: No network calls required
3. **Offline Capability**: Functions without internet connection
4. **User Control**: Users can select which stores to compare
5. **Data Persistence**: Prices are stored locally and persist between app sessions

## Data Flow

1. User adds products to shopping list with prices and store information
2. User selects stores to compare prices from
3. System queries local database for prices matching selected stores
4. System calculates totals and identifies best store
5. Results are displayed in the UI

## Future Enhancements

1. **Price History**: Track price changes over time
2. **Location-based Pricing**: Use location data for store-specific pricing
3. **Price Alerts**: Notify users when prices drop
4. **Bulk Price Import**: Allow users to import price data from receipts or other sources
5. **Price Sharing**: Allow users to share price data with others

## Testing

To test the implementation:

1. Add products to shopping list with different prices and stores
2. Select different store combinations
3. Verify that the best price calculation is correct
4. Test with empty shopping lists
5. Test with products that have no price data

This implementation provides a solid foundation for local price comparison functionality while leveraging the existing Core Data model relationships. 