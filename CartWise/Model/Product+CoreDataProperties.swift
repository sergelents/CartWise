//
//  Product+CoreDataProperties.swift
//  CartWise
//
//  Created by Serg Tsogtbaatar on 7/7/25.
//
//

import Foundation
import CoreData


extension Product {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }

    @NSManaged public var barcode: String?
    @NSManaged public var brands: String?
    @NSManaged public var categories: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var imageURL: String?
    @NSManaged public var ingredients: String?
    @NSManaged public var name: String?
    @NSManaged public var nutritionGrade: String?
    @NSManaged public var updatedAt: Date?

}

extension Product {
    convenience init(context: NSManagedObjectContext, barcode: String, name: String, brands: String? = nil, imageURL: String? = nil, nutritionGrade: String? = nil, categories: String? = nil, ingredients: String? = nil) {
        self.init(context: context)
        self.barcode = barcode
        self.name = name
        self.brands = brands
        self.imageURL = imageURL
        self.nutritionGrade = nutritionGrade
        self.categories = categories
        self.ingredients = ingredients
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension Product : Identifiable {

}
