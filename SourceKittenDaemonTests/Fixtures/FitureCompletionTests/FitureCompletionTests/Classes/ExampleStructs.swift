//
//  ExampleStructs.swift
//  FitureCompletionTests
//
//  Created by Benedikt Terhechte on 16/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation

public struct Person: Identifiable {
    public let firstName: String
    public let lastName: String
    public let age: Int
    
    public var name: String {
        return"\(firstName) \(lastName)"
    }
    
    public func birthYear() -> Int {
        return NSCalendar.currentCalendar().component(.Year, fromDate: NSDate()) - self.age
    }
    
    
}

public struct Company: Identifiable {
    public let workers: [Person]
    public let name: String
    
    public let products: [Product]
    
    public let mainBuilding: Building?
}

public struct Product: Identifiable, Accountable {
    public let name: String
    public var costs: Int
}

public struct Building: Accountable {
    public var costs: Int
}