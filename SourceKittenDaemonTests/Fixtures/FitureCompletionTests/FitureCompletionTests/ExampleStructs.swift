//
//  ExampleStructs.swift
//  FitureCompletionTests
//
//  Created by Benedikt Terhechte on 16/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation

public struct Person: Identifiable {
    let firstName: String
    let lastName: String
    let age: Int
    
    var name: String {
        return"\(firstName) \(lastName)"
    }
    
    func birthYear() -> Int {
        return NSCalendar.currentCalendar().component(.Year, fromDate: NSDate()) - self.age
    }
    
    
}

public struct Company: Identifiable {
    let workers: [Person]
    let name: String
    
    let products: [Product]
    
    let mainBuilding: Building?
}

public struct Product: Identifiable, Accountable {
    let name: String
    var costs: Int
}

public struct Building: Accountable {
    var costs: Int
}