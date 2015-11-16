//
//  ExampleProtocols.swift
//  FitureCompletionTests
//
//  Created by Benedikt Terhechte on 16/11/15.
//  Copyright © 2015 Benedikt Terhechte. All rights reserved.
//

import Foundation

public protocol Identifiable {
    var name: String { get }
}

public protocol Accountable {
    var costs: Int { get set }
}