//
//  PromiseTest.swift
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
import PinkyPromise

class PromiseTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testInit_task() {
        // Create with successful task
        do {
            let expectedValue = 3
            let result = Result { expectedValue }
            var taskWasRun = false
            let promise = Promise<Int> { fulfill in
                taskWasRun = true
                fulfill(result)
            }

            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given task's return value.")
            }

            XCTAssertTrue(taskWasRun, "Expected the given task to be run.")
        }

        // Create with failing task
        do {
            let expectedError = TestHelpers.uniqueError()
            let result = Result<String> { throw expectedError }
            var taskWasRun = false
            let promise = Promise<String> { fulfill in
                taskWasRun = true
                fulfill(result)
            }

            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertTrue(taskWasRun, "Expected the given task to be run.")
        }
    }
    
    func testInit_result() {
        // Create with successful result
        do {
            let expectedValue = "Hi there"
            let result = Result { expectedValue }
            let promise = Promise(result: result)

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given result.")
            }

            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Create with failed result
        do {
            let expectedError = TestHelpers.uniqueError()
            let result = Result<String> { throw expectedError }
            let promise = Promise(result: result)

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }

    func testInit_value() {
        let expectedValue = [3, 6, 9]        
        let promise = Promise(value: expectedValue)

        var completionWasRun = false
        promise.call { result in
            completionWasRun = true
            TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given value.")
        }

        XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
    }

    func testInit_error() {
        let expectedError = TestHelpers.uniqueError()        
        let promise = Promise<[String: Int]>(error: expectedError)

        var completionWasRun = false
        promise.call { result in
            completionWasRun = true
            TestHelpers.expectFailure(expectedError, result: result)
        }

        XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
    }

}
