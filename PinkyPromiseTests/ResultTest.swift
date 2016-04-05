//
//  ResultTest.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 4/4/16.
//
//  The MIT License (MIT)
//  Copyright © 2016 WillowTree, Inc. All rights reserved.
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import XCTest
import Foundation
import PinkyPromise

class ResultTest: XCTestCase {

    private struct Fixtures {
        let object: NSObject
        let error: NSError
        let successfulInt: Result<Int>
        let failedInt: Result<Int>
        let successfulObject: Result<NSObject>
        let failedObject: Result<NSObject>
    }

    private var fixtures: Fixtures!
    
    override func setUp() {
        super.setUp()

        let object = NSObject()
        let anError = NSError(domain: "TestDomain", code: 1, userInfo: nil)

        fixtures = Fixtures(
            object: object,
            error: anError,
            successfulInt: .Success(3),
            failedInt: .Failure(anError),
            successfulObject: .Success(object),
            failedObject: .Failure(anError)
        )
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testValue() {
        do {
            let int = try fixtures.successfulInt.value()
            XCTAssertEqual(3, int, "Expected the same value as supplied to .Success().")

            let object = try fixtures.successfulObject.value()
            XCTAssertEqual(fixtures.object, object, "Expected the same object as supplied to .Success().")
            XCTAssertTrue(fixtures.object === object, "Expected the same object, not just an equal object.")
        } catch {
            XCTFail("Expected not to catch an error.")
        }

        do {
            try fixtures.failedInt.value()
            XCTFail("Expected to throw an error.")
        } catch {
            XCTAssertEqual(fixtures.error, error as NSError, "Expected the same error as supplied to .Failure().")
            XCTAssertTrue(fixtures.error === error as NSError, "Expected the same error, not just an equal error.")
        }

        do {
            try fixtures.failedObject.value()
            XCTFail("Expected to throw an error.")
        } catch {
            XCTAssertEqual(fixtures.error, error as NSError, "Expected the same error as supplied to .Failure().")
            XCTAssertTrue(fixtures.error === error as NSError, "Expected the same error, not just an equal error.")
        }
    }
    
}
