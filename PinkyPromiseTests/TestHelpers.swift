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

enum TestHelpers {

    static var lastErrorCode = 0

    static func uniqueError() -> NSError {
        lastErrorCode += 1
        return NSError(domain: "Test", code: lastErrorCode, userInfo: nil)
    }

    static func expectSuccess<T: Equatable>(_ expected: T, result: Result<T>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected, value, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    static func expectSuccess<A: Equatable, B: Equatable>(_ expected: (A, B), result: Result<(A, B)>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected.0, value.0, message)
            XCTAssertEqual(expected.1, value.1, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    static func expectSuccess<A: Equatable, B: Equatable, C: Equatable>(_ expected: (A, B, C), result: Result<(A, B, C)>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected.0, value.0, message)
            XCTAssertEqual(expected.1, value.1, message)
            XCTAssertEqual(expected.2, value.2, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    static func expectSuccess<A: Equatable, B: Equatable, C: Equatable, D: Equatable>(_ expected: (A, B, C, D), result: Result<(A, B, C, D)>, message: String) {
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

    static func expectSuccess<T: Equatable>(_ expected: [T], result: Result<[T]>, message: String) {
        do {
            let value = try result.value()
            XCTAssertEqual(expected, value, message)
        } catch {
            XCTFail("Expected not to catch an error.")
        }
    }

    static func expectFailure<T>(_ expected: NSError, result: Result<T>) {
        do {
            _ = try result.value()
            XCTFail("Expected to throw an error.")
        } catch {
            XCTAssertEqual(expected, error as NSError, "Expected the given error.")
            XCTAssertTrue(expected === error as NSError, "Expected the same error, not just an equal error.")
        }
    }

}
