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
        let successfulNumberString: Result<String>
        let successfulJSONArrayString: Result<String>
        let failedString: Result<String>

        let integerFormatter: NSNumberFormatter
    }

    private var fixtures: Fixtures!
    
    override func setUp() {
        super.setUp()

        let object = NSObject()
        let error = uniqueError()

        let integerFormatter = NSNumberFormatter()
        integerFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        integerFormatter.maximumFractionDigits = 0

        fixtures = Fixtures(
            object: object,
            error: error,
            successfulInt: .Success(3),
            failedInt: .Failure(error),
            successfulObject: .Success(object),
            failedObject: .Failure(error),
            successfulNumberString: .Success("123"),
            successfulJSONArrayString: .Success("[1, 2, 3]"),
            failedString: .Failure(error),
            integerFormatter: integerFormatter
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

    func testFlatMap() {
        let parseError = uniqueError()

        let stringAsInt: (String) -> Result<Int> = { string in
            if let number = self.fixtures.integerFormatter.numberFromString(string) as? Int {
                return .Success(number)
            } else {
                return .Failure(parseError)
            }
        }

        let successfulNumberParse = fixtures.successfulNumberString.flatMap(stringAsInt)
        let failedArrayParse = fixtures.successfulJSONArrayString.flatMap(stringAsInt)
        let sameFailedString = fixtures.failedString.flatMap(stringAsInt)

        expectSuccess(123, result: successfulNumberParse, message: "Expected to parse \"123\" as 123.")
        expectFailure(parseError, result: failedArrayParse)
        expectFailure(fixtures.error, result: sameFailedString)
    }

    func testTryMap() {
        let encodeDataError = uniqueError()
        let parseJSONError = uniqueError()
        let castToIntArrayError = uniqueError()

        let jsonStringAsIntSet: (String) throws -> Set<Int> = { string in
            guard let data = string.dataUsingEncoding(NSUTF8StringEncoding) else {
                throw encodeDataError
            }

            let object: AnyObject
            do {
                object = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            } catch {
                throw parseJSONError
            }

            guard let array = object as? [Int] else {
                throw castToIntArrayError
            }

            return Set(array)
        }

        let successfulSetParse: Result<Set<Int>> = fixtures.successfulJSONArrayString.tryMap(jsonStringAsIntSet)
        let failedNumberParse = fixtures.successfulNumberString.tryMap(jsonStringAsIntSet)
        let sameFailedString = fixtures.failedString.tryMap(jsonStringAsIntSet)

        expectSuccess([1, 2, 3] as Set<Int>, result: successfulSetParse, message: "Expected to parse \"[1, 2, 3]\" as [1, 2, 3].")
        expectFailure(parseJSONError, result: failedNumberParse)
        expectFailure(fixtures.error, result: sameFailedString)
    }

    func testZip() {
        let error1 = uniqueError()
        let error2 = uniqueError()
        let error3 = uniqueError()
        let error4 = uniqueError()

        let success1: Result<Int> = .Success(1)
        let success2: Result<String> = .Success("hi")
        let success3: Result<Int> = .Success(3)
        let success4: Result<String> = .Success("bye")

        let failure1: Result<Int> = .Failure(error1)
        let failure2: Result<String> = .Failure(error2)
        let failure3: Result<Int> = .Failure(error3)
        let failure4: Result<String> = .Failure(error4)

        expectSuccess((1, "hi"), result: zip(success1, success2), message: "Expected to zip 1 and \"hi\" into (1, \"hi\").")
        expectFailure(error2, result: zip(success1, failure2))
        expectFailure(error1, result: zip(failure1, success2))
        expectFailure(error1, result: zip(failure1, failure2))

        expectSuccess((1, "hi", 3), result: zip(success1, success2, success3), message: "Expected to zip 1, \"hi\", and 3 into (1, \"hi\", 3).")
        expectFailure(error3, result: zip(success1, success2, failure3))
        expectFailure(error2, result: zip(success1, failure2, success3))
        expectFailure(error2, result: zip(success1, failure2, failure3))
        expectFailure(error1, result: zip(failure1, success2, success3))
        expectFailure(error1, result: zip(failure1, success2, failure3))
        expectFailure(error1, result: zip(failure1, failure2, success3))
        expectFailure(error1, result: zip(failure1, failure2, failure3))

        expectSuccess((1, "hi", 3, "bye"), result: zip(success1, success2, success3, success4), message: "Expected to zip 1, \"hi\", 3, and \"bye\" into (1, \"hi\", 3, \"bye\").")
        expectFailure(error4, result: zip(success1, success2, success3, failure4))
        expectFailure(error3, result: zip(success1, success2, failure3, success4))
        expectFailure(error3, result: zip(success1, success2, failure3, failure4))
        expectFailure(error2, result: zip(success1, failure2, success3, success4))
        expectFailure(error2, result: zip(success1, failure2, success3, failure4))
        expectFailure(error2, result: zip(success1, failure2, failure3, success4))
        expectFailure(error2, result: zip(success1, failure2, failure3, failure4))
        expectFailure(error1, result: zip(failure1, success2, success3, success4))
        expectFailure(error1, result: zip(failure1, success2, success3, failure4))
        expectFailure(error1, result: zip(failure1, success2, failure3, success4))
        expectFailure(error1, result: zip(failure1, success2, failure3, failure4))
        expectFailure(error1, result: zip(failure1, failure2, success3, success4))
        expectFailure(error1, result: zip(failure1, failure2, success3, failure4))
        expectFailure(error1, result: zip(failure1, failure2, failure3, success4))
        expectFailure(error1, result: zip(failure1, failure2, failure3, failure4))
    }

    func testZipArray() {
        let error1 = uniqueError()
        let error2 = uniqueError()
        let error3 = uniqueError()

        let success1: Result<Int> = .Success(112)
        let success2: Result<Int> = .Success(-15)
        let success3: Result<Int> = .Success(3)

        let failure1: Result<Int> = .Failure(error1)
        let failure2: Result<Int> = .Failure(error2)
        let failure3: Result<Int> = .Failure(error3)

        expectSuccess([112, -15, 3], result: zipArray([success1, success2, success3]), message: "Expected to zip 112, -15, and 3 into ([112, -15, 3]).")
        expectFailure(error3, result: zipArray([success1, success2, failure3]))
        expectFailure(error2, result: zipArray([success1, failure2, success3]))
        expectFailure(error2, result: zipArray([success1, failure2, failure3]))
        expectFailure(error1, result: zipArray([failure1, success2, success3]))
        expectFailure(error1, result: zipArray([failure1, success2, failure3]))
        expectFailure(error1, result: zipArray([failure1, failure2, success3]))
        expectFailure(error1, result: zipArray([failure1, failure2, failure3]))
    }

    // MARK: Helpers

    private var lastErrorCode = 0

    private func uniqueError() -> NSError {
        lastErrorCode += 1
        return NSError(domain: "Test", code: lastErrorCode, userInfo: nil)
    }

    private func expectSuccess<T: Equatable>(expected: T, result: Result<T>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected, value, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    private func expectSuccess<A: Equatable, B: Equatable>(expected: (A, B), result: Result<(A, B)>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected.0, value.0, message)
            XCTAssertEqual(expected.1, value.1, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    private func expectSuccess<A: Equatable, B: Equatable, C: Equatable>(expected: (A, B, C), result: Result<(A, B, C)>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected.0, value.0, message)
            XCTAssertEqual(expected.1, value.1, message)
            XCTAssertEqual(expected.2, value.2, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    private func expectSuccess<A: Equatable, B: Equatable, C: Equatable, D: Equatable>(expected: (A, B, C, D), result: Result<(A, B, C, D)>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected.0, value.0, message)
            XCTAssertEqual(expected.1, value.1, message)
            XCTAssertEqual(expected.2, value.2, message)
            XCTAssertEqual(expected.3, value.3, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    private func expectSuccess<T: Equatable>(expected: [T], result: Result<[T]>, message: String) {
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
