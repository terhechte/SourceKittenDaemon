//
//  SwiftXPCTests.swift
//  SwiftXPCTests
//
//  Created by JP Simard on 10/29/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import XCTest
import SwiftXPC

func testEqualityOfXPCRoundtrip(object: XPCRepresentable) {
    if object as XPCRepresentable? == nil {
        XCTFail("Source object is nil")
    }

    let xpcObject = toXPCGeneral(object)
    XCTAssertNotNil(xpcObject, "XPC object is nil")

    let outObject = fromXPCGeneral(xpcObject!)
    if outObject == nil {
        XCTFail("XPC-converted object is nil")
    }

    XCTAssertTrue(object == outObject!, "Object \(object) was not equal to result \(outObject)")
}

class SwiftXPCTests: XCTestCase {

    func testStrings() {
        testEqualityOfXPCRoundtrip("")
        testEqualityOfXPCRoundtrip("Hello world!")
    }

    func testNumbers() {
        testEqualityOfXPCRoundtrip(0)
        testEqualityOfXPCRoundtrip(1)
        testEqualityOfXPCRoundtrip(-1)
        testEqualityOfXPCRoundtrip(42.1)
        testEqualityOfXPCRoundtrip(Int64(42))
        testEqualityOfXPCRoundtrip(UInt64(42))
        testEqualityOfXPCRoundtrip(true)
        testEqualityOfXPCRoundtrip(false)
        testEqualityOfXPCRoundtrip(kCFBooleanFalse)
    }

    func testDates() {
        testEqualityOfXPCRoundtrip(NSDate())
        testEqualityOfXPCRoundtrip(NSDate(timeIntervalSince1970: 20))
        testEqualityOfXPCRoundtrip(NSDate(timeIntervalSince1970: 2_000_000))
        testEqualityOfXPCRoundtrip(NSDate(timeIntervalSince1970: 2_000_000_000))
        testEqualityOfXPCRoundtrip(NSDate(timeIntervalSince1970: 10))
        testEqualityOfXPCRoundtrip(NSDate(timeIntervalSince1970: -10))
        testEqualityOfXPCRoundtrip(NSDate(timeIntervalSince1970: 10_000))
        testEqualityOfXPCRoundtrip(NSDate(timeIntervalSince1970: -10_000))
    }

    func testArrays() {
        // Empty
        testEqualityOfXPCRoundtrip([] as XPCArray)

        // Complete
        // TODO: Test Array, Dictionary
        testEqualityOfXPCRoundtrip([
            "string",
            NSDate(),
            NSData(),
            UInt64(0),
            Int64(0),
            0.0,
            false,
            NSFileHandle(fileDescriptor: 0),
            NSUUID(UUIDBytes: [UInt8](count: 16, repeatedValue: 0))
            ] as XPCArray)
    }

    func testDictionaries() {
        // Empty
        testEqualityOfXPCRoundtrip([:] as XPCDictionary)

        // Complete
        // TODO: Test Array, Dictionary
        testEqualityOfXPCRoundtrip([
            "String": "string",
            "Date": NSDate(),
            "Data": NSData(),
            "UInt64": UInt64(0),
            "Int64": Int64(0),
            "Double": 0.0,
            "Bool": false,
            "FileHandle": NSFileHandle(fileDescriptor: 0),
            "Uuid": NSUUID(UUIDBytes: [UInt8](count: 16, repeatedValue: 0))
            ] as XPCDictionary)
    }
}
