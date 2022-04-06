//
//  Product.swift
//  AnyVcNavigator
//
//  Created by Hasan Hüseyin Ali Gül on 3.04.2022.
//  Copyright © 2022 Arjun Baru. All rights reserved.
//

import Foundation
class Product {
    static var sharedInstance = Product(data: ["ProductName" : "ProductName"])
    
    var productBarcode:String!
    var productName:String!
    var productCount:Double!
    var productPrice:Double!
    
    init(data: [String : Any]){
        productName = data["ProductName"] as? String ?? ""
        productCount = Double(data["ProductCount"] as? String ?? "")
        productPrice = Double(data["ProductPrice"] as? String ?? "")
        productBarcode = data["ProductBarcode"] as? String ?? ""

        
    }

}
