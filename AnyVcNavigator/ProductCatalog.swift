//
//  ProductCatalog.swift
//  AnyVcNavigator
//
//  Created by Hasan Hüseyin Ali Gül on 3.04.2022.
//  Copyright © 2022 Arjun Baru. All rights reserved.
//
import Foundation

struct ProductCatalog {
    private var products: [String: [String: AnyObject]]?

    init() {
        var format = PropertyListSerialization.PropertyListFormat.xml
        if let path = Bundle.main.path(forResource: "ProductCatalog", ofType: "plist"),
            let xml = FileManager.default.contents(atPath: path) {
            products = try? PropertyListSerialization.propertyList(from: xml,
                                                                   options: .mutableContainersAndLeaves,
                                                                   format: &format) as? [String: [String: AnyObject]]
        }
    }

    public func item(forKey key: String) -> Product? {
        // If no items were loaded, return nil for every product.
        guard let products = products else { return nil }

        if let data = products[key] {
            return Product(data: data)
        }

        return nil
    }
}

