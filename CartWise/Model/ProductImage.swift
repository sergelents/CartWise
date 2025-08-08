//
//  ProductImage.swift
//  CartWise
//
//  Created by Kelly Yong on 8/4/25.
//  Enhanced with AI assistance from Cursor AI.
//

import Foundation
import CoreData
import UIKit

@objc(ProductImage)
public class ProductImage: NSManagedObject {

}

extension ProductImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductImage> {
        return NSFetchRequest<ProductImage>(entityName: "ProductImage")
    }

    @NSManaged public var id: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var imageURL: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var groceryItem: GroceryItem?

    convenience init(context: NSManagedObjectContext, id: String, imageURL: String?, imageData: Data? = nil) {
        self.init(context: context)
        self.id = id
        self.imageURL = imageURL
        self.imageData = imageData
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Helper method to get UIImage from imageData
    var uiImage: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }

    // Helper method to set UIImage to imageData
    func setImage(_ image: UIImage) {
        self.imageData = image.jpegData(compressionQuality: 0.8)
        self.updatedAt = Date()
    }
}
