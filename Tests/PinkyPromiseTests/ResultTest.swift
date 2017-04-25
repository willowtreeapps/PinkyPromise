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

    fileprivate struct Fixtures {
        let object: NSObject
        let error: NSError

        let successfulInt: Result<Int>
        let failedInt: Result<Int>
        let successfulObject: Result<NSObject>
        let failedObject: Result<NSObject>
        let successfulNumberString: Result<String>
        let successfulJSONArrayString: Result<String>
        let failedString: Result<String>

        let integerFormatter: NumberFormatter
    }

    fileprivate var fixtures: Fixtures!
    
    override func setUp() {
        super.setUp()

        let object = NSObject()
        let error = TestHelpers.uniqueError()

        let integerFormatter = NumberFormatter()
        integerFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        integerFormatter.maximumFractionDigits = 0

        fixtures = Fixtures(
            object: object,
            error: error,
            successfulInt: .success(3),
            failedInt: .failure(error),
            successfulObject: .success(object),
            failedObject: .failure(error),
            successfulNumberString: .success("123"),
            successfulJSONArrayString: .success("[1, 2, 3]"),
            failedString: .failure(error),
            integerFormatter: integerFormatter
        )
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testInit_create() {
        TestHelpers.expectSuccess(3, result: Result { return 3 }, message: "Expected the same value as returned.")
        TestHelpers.expectSuccess(fixtures.object, result: Result { return self.fixtures.object }, message: "Expected the same object as returned.")
        TestHelpers.expectFailure(fixtures.error, result: Result<Int> { throw self.fixtures.error })
        TestHelpers.expectFailure(fixtures.error, result: Result<NSObject> { throw self.fixtures.error })
    }

    func testValue() {
        TestHelpers.expectSuccess(3, result: fixtures.successfulInt, message: "Expected the same value as supplied to .Success().")
        TestHelpers.expectSuccess(fixtures.object, result: fixtures.successfulObject, message: "Expected the same object as supplied to .Success().")
        TestHelpers.expectFailure(fixtures.error, result: fixtures.failedInt)
        TestHelpers.expectFailure(fixtures.error, result: fixtures.failedObject)
    }

    func testMap() {
        let plusThree: (Int) -> Int = { $0 + 3 }
        let successfulSix = fixtures.successfulInt.map(plusThree)
        let failedSix = fixtures.failedInt.map(plusThree)
        TestHelpers.expectSuccess(6, result: successfulSix, message: "Expected 3 + 3 = 6.")
        TestHelpers.expectFailure(fixtures.error, result: failedSix)

        let timesTenAsString: (Int) -> String = { String($0 * 10) }
        let successfulThirty = fixtures.successfulInt.map(timesTenAsString)
        let failedThirty = fixtures.failedInt.map(timesTenAsString)
        TestHelpers.expectSuccess("30", result: successfulThirty, message: "Expected String(3 * 10) = \"30\".")
        TestHelpers.expectFailure(fixtures.error, result: failedThirty)
    }

    func testFlatMap() {
        let parseError = TestHelpers.uniqueError()

        let stringAsInt: (String) -> Result<Int> = { string in
            if let number = self.fixtures.integerFormatter.number(from: string) as? Int {
                return .success(number)
            } else {
                return .failure(parseError)
            }
        }

        let successfulNumberParse = fixtures.successfulNumberString.flatMap(stringAsInt)
        let failedArrayParse = fixtures.successfulJSONArrayString.flatMap(stringAsInt)
        let sameFailedString = fixtures.failedString.flatMap(stringAsInt)

        TestHelpers.expectSuccess(123, result: successfulNumberParse, message: "Expected to parse \"123\" as 123.")
        TestHelpers.expectFailure(parseError, result: failedArrayParse)
        TestHelpers.expectFailure(fixtures.error, result: sameFailedString)
    }

    func testTryMap() {
        let encodeDataError = TestHelpers.uniqueError()
        let parseJSONError = TestHelpers.uniqueError()
        let castToIntArrayError = TestHelpers.uniqueError()

        let jsonStringAsIntSet: (String) throws -> Set<Int> = { string in
            guard let data = string.data(using: String.Encoding.utf8) else {
                throw encodeDataError
            }

            let object: Any
            do {
                object = try JSONSerialization.jsonObject(with: data, options: [])
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

        TestHelpers.expectSuccess([1, 2, 3] as Set<Int>, result: successfulSetParse, message: "Expected to parse \"[1, 2, 3]\" as [1, 2, 3].")
        TestHelpers.expectFailure(parseJSONError, result: failedNumberParse)
        TestHelpers.expectFailure(fixtures.error, result: sameFailedString)
    }

    func testZip() {
        let error1 = TestHelpers.uniqueError()
        let error2 = TestHelpers.uniqueError()
        let error3 = TestHelpers.uniqueError()
        let error4 = TestHelpers.uniqueError()

        let success1: Result<Int> = .success(1)
        let success2: Result<String> = .success("hi")
        let success3: Result<Int> = .success(3)
        let success4: Result<String> = .success("bye")

        let failure1: Result<Int> = .failure(error1)
        let failure2: Result<String> = .failure(error2)
        let failure3: Result<Int> = .failure(error3)
        let failure4: Result<String> = .failure(error4)

        TestHelpers.expectSuccess((1, "hi"), result: zip(success1, success2), message: "Expected to zip 1 and \"hi\" into (1, \"hi\").")
        TestHelpers.expectFailure(error2, result: zip(success1, failure2))
        TestHelpers.expectFailure(error1, result: zip(failure1, success2))
        TestHelpers.expectFailure(error1, result: zip(failure1, failure2))

        TestHelpers.expectSuccess((1, "hi", 3), result: zip(success1, success2, success3), message: "Expected to zip 1, \"hi\", and 3 into (1, \"hi\", 3).")
        TestHelpers.expectFailure(error3, result: zip(success1, success2, failure3))
        TestHelpers.expectFailure(error2, result: zip(success1, failure2, success3))
        TestHelpers.expectFailure(error2, result: zip(success1, failure2, failure3))
        TestHelpers.expectFailure(error1, result: zip(failure1, success2, success3))
        TestHelpers.expectFailure(error1, result: zip(failure1, success2, failure3))
        TestHelpers.expectFailure(error1, result: zip(failure1, failure2, success3))
        TestHelpers.expectFailure(error1, result: zip(failure1, failure2, failure3))

        TestHelpers.expectSuccess((1, "hi", 3, "bye"), result: zip(success1, success2, success3, success4), message: "Expected to zip 1, \"hi\", 3, and \"bye\" into (1, \"hi\", 3, \"bye\").")
        TestHelpers.expectFailure(error4, result: zip(success1, success2, success3, failure4))
        TestHelpers.expectFailure(error3, result: zip(success1, success2, failure3, success4))
        TestHelpers.expectFailure(error3, result: zip(success1, success2, failure3, failure4))
        TestHelpers.expectFailure(error2, result: zip(success1, failure2, success3, success4))
        TestHelpers.expectFailure(error2, result: zip(success1, failure2, success3, failure4))
        TestHelpers.expectFailure(error2, result: zip(success1, failure2, failure3, success4))
        TestHelpers.expectFailure(error2, result: zip(success1, failure2, failure3, failure4))
        TestHelpers.expectFailure(error1, result: zip(failure1, success2, success3, success4))
        TestHelpers.expectFailure(error1, result: zip(failure1, success2, success3, failure4))
        TestHelpers.expectFailure(error1, result: zip(failure1, success2, failure3, success4))
        TestHelpers.expectFailure(error1, result: zip(failure1, success2, failure3, failure4))
        TestHelpers.expectFailure(error1, result: zip(failure1, failure2, success3, success4))
        TestHelpers.expectFailure(error1, result: zip(failure1, failure2, success3, failure4))
        TestHelpers.expectFailure(error1, result: zip(failure1, failure2, failure3, success4))
        TestHelpers.expectFailure(error1, result: zip(failure1, failure2, failure3, failure4))
    }

    func testZipArray() {
        let error1 = TestHelpers.uniqueError()
        let error2 = TestHelpers.uniqueError()
        let error3 = TestHelpers.uniqueError()

        let success1: Result<Int> = .success(112)
        let success2: Result<Int> = .success(-15)
        let success3: Result<Int> = .success(3)

        let failure1: Result<Int> = .failure(error1)
        let failure2: Result<Int> = .failure(error2)
        let failure3: Result<Int> = .failure(error3)

        TestHelpers.expectSuccess([112, -15, 3], result: zipArray([success1, success2, success3]), message: "Expected to zip 112, -15, and 3 into [112, -15, 3].")
        TestHelpers.expectFailure(error3, result: zipArray([success1, success2, failure3]))
        TestHelpers.expectFailure(error2, result: zipArray([success1, failure2, success3]))
        TestHelpers.expectFailure(error2, result: zipArray([success1, failure2, failure3]))
        TestHelpers.expectFailure(error1, result: zipArray([failure1, success2, success3]))
        TestHelpers.expectFailure(error1, result: zipArray([failure1, success2, failure3]))
        TestHelpers.expectFailure(error1, result: zipArray([failure1, failure2, success3]))
        TestHelpers.expectFailure(error1, result: zipArray([failure1, failure2, failure3]))
    }

}
