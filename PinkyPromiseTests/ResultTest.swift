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
        expectSuccess(3, result: fixtures.successfulInt, message: "Expected the same value as supplied to .Success().")
        expectSuccess(fixtures.object, result: fixtures.successfulObject, message: "Expected the same object as supplied to .Success().")
        expectFailure(fixtures.error, result: fixtures.failedInt)
        expectFailure(fixtures.error, result: fixtures.failedObject)
    }

    func testMap() {
        let plusThree: (Int) -> Int = { $0 + 3 }
        let successfulSix = fixtures.successfulInt.map(plusThree)
        let failedSix = fixtures.failedInt.map(plusThree)
        expectSuccess(6, result: successfulSix, message: "Expected 3 + 3 = 6.")
        expectFailure(fixtures.error, result: failedSix)

        let timesTenAsString: (Int) -> String = { String($0 * 10) }
        let successfulThirty = fixtures.successfulInt.map(timesTenAsString)
        let failedThirty = fixtures.failedInt.map(timesTenAsString)
        expectSuccess("30", result: successfulThirty, message: "Expected String(3 * 10) = \"30\".")
        expectFailure(fixtures.error, result: failedThirty)
    }

    // MARK: Helpers

    private func expectSuccess<T: Equatable>(expected: T, result: Result<T>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected, value, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    private func expectFailure<T>(expected: NSError, result: Result<T>) {
        do {
            try result.value()
            XCTFail("Expected to throw an error.")
        } catch {
            XCTAssertEqual(expected, error as NSError, "Expected the same error as supplied to .Failure().")
            XCTAssertTrue(expected === error as NSError, "Expected the same error, not just an equal error.")
        }
    }

}
