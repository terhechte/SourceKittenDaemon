//
//  CompletionTarget.swift
//  FitureCompletionTests
//
//  Created by Benedikt Terhechte on 16/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation

let person1 = Person(firstName: "Carl", lastName: "Berand", age: 40)
let person2 = Person(firstName: "John", lastName: "Doe", age: 30)
let person3 = Person(firstName: "Mark", lastName: "Pragma", age: 20)

let product1 = Product(name: "SuperSoaker2000", costs: 10)
let product2 = Product(name: "SuperSoaker3000", costs: 20)

let building = Building(costs: 10000)

let company1 = Company(workers: [person1, person2, person3], name: "Soakers Ltd", products: [product1, product2], mainBuilding: building)

let company2: Identifiable = Company(workers: [], name: "Company", products: [], mainBuilding: nil)

public func costs(c: Accountable) -> Int {
    return c.costs
}

