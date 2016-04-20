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

    func testMap() {
        // Map success to success
        do {
            let initialPromise = Promise(value: 3)

            var transformWasRun = false
            let promise = initialPromise.map { value -> Int in
                transformWasRun = true
                return value + 10
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(13, result: result, message: "Expected the value to be transformed.")
            }

            XCTAssertTrue(transformWasRun, "Expected the transform closure to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Map failure to failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            var transformWasRun = false
            let promise = initialPromise.map { value -> Int in
                transformWasRun = true
                return value + 10
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertFalse(transformWasRun, "Expected the transform closure not to be called.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }
    
    func testTryMap() {
        // Try-map success to success
        do {
            let initialPromise = Promise(value: 3)

            var transformWasRun = false
            let promise = initialPromise.tryMap { value -> Int in
                transformWasRun = true
                return value + 10
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(13, result: result, message: "Expected the value to be transformed.")
            }

            XCTAssertTrue(transformWasRun, "Expected the transform closure to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Try-map success to failure
        do {
            let initialPromise = Promise(value: 3)
            let expectedError = TestHelpers.uniqueError()

            var transformWasRun = false
            let promise = initialPromise.tryMap { value -> Int in
                transformWasRun = true
                throw expectedError
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertTrue(transformWasRun, "Expected the transform closure to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Try-map failure to failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            var transformWasRun = false
            let promise = initialPromise.tryMap { value -> Int in
                transformWasRun = true
                return value + 10
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertFalse(transformWasRun, "Expected the transform closure not to be called.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }
    
    func testFlatMap() {
        // Flat-map success to success
        do {
            let initialPromise = Promise(value: 3)

            var transformWasRun = false
            let promise = initialPromise.flatMap { value -> Promise<Int> in
                transformWasRun = true
                return Promise(value: value + 10)
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(13, result: result, message: "Expected the value to be transformed.")
            }

            XCTAssertTrue(transformWasRun, "Expected the transform closure to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Flat-map success to failure
        do {
            let initialPromise = Promise(value: 3)
            let expectedError = TestHelpers.uniqueError()

            var transformWasRun = false
            let promise = initialPromise.flatMap { value -> Promise<Int> in
                transformWasRun = true
                return Promise(error: expectedError)
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertTrue(transformWasRun, "Expected the transform closure to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Flat-map failure to failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            var transformWasRun = false
            let promise = initialPromise.flatMap { value -> Promise<Int> in
                transformWasRun = true
                return Promise(value: value + 10)
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertFalse(transformWasRun, "Expected the transform closure not to be called.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }

    func testRecover() {
        // Recover success to success
        do {
            let expectedValue = 3
            let initialPromise = Promise(value: expectedValue)

            var transformWasRun = false
            let promise = initialPromise.recover { error in
                transformWasRun = true
                return Promise(value: 1000)
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the value to stay the same.")
            }

            XCTAssertFalse(transformWasRun, "Expected the transform closure not to be called.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Recover failure to success
        do {
            let initialPromise = Promise<Int>(error: TestHelpers.uniqueError())
            let expectedValue = 1000

            var transformWasRun = false
            let promise = initialPromise.recover { error in
                transformWasRun = true
                return Promise(value: expectedValue)
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the error to be transformed to a default value.")
            }

            XCTAssertTrue(transformWasRun, "Expected the transform closure to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Recover failure to failure
        do {
            let initialPromise = Promise<Int>(error: TestHelpers.uniqueError())
            let expectedError = TestHelpers.uniqueError()

            var transformWasRun = false
            let promise = initialPromise.recover { error in
                transformWasRun = true
                return Promise(error: expectedError)
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertTrue(transformWasRun, "Expected the transform closure to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }

    func testRetry() {
        // Succeed on the first try
        do {
            let expectedValue = 3

            var taskRunCount = 0
            let promise = Promise<Int> { fulfill in
                taskRunCount += 1

                fulfill(Result { expectedValue })
            }

            let attemptCount = 3
            var completionWasRun = false
            promise.retry(attemptCount).call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
            }

            XCTAssertEqual(1, taskRunCount, "Expected the task to succeed on the first try.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
        
        // Succeed on the second try
        do {
            let error1 = TestHelpers.uniqueError()
            let expectedValue = 3
            var results: [Result<Int>] = [Result { throw error1 }, Result { expectedValue }]

            var taskRunCount = 0
            let promise = Promise<Int> { fulfill in
                taskRunCount += 1

                fulfill(results.removeFirst())
            }

            let attemptCount = 3
            var completionWasRun = false
            promise.retry(attemptCount).call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
            }

            XCTAssertEqual(2, taskRunCount, "Expected the task to succeed on the second try.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
        
        // Retry until the all attempts are used up
        do {
            let error1 = TestHelpers.uniqueError()
            let error2 = TestHelpers.uniqueError()
            let expectedError = TestHelpers.uniqueError()
            var results: [Result<Int>] = [Result { throw error1 }, Result { throw error2 }, Result { throw expectedError }]

            var taskRunCount = 0
            let promise = Promise<Int> { fulfill in
                taskRunCount += 1

                fulfill(results.removeFirst())
            }

            let attemptCount = 3
            var completionWasRun = false
            promise.retry(attemptCount).call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertEqual(attemptCount, taskRunCount, "Expected the task to run until it ran out of attempts.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }

    func testInBackground() {
        let expectedValue = 3

        var taskWasRun = false
        let promise = Promise<Int> { fulfill in
            taskWasRun = true

            XCTAssertFalse(NSThread.isMainThread(), "Expected the task to run in the background.")

            fulfill(Result { expectedValue })
        }

        let completionExpectation = expectationWithDescription("Promise completed.")

        promise.inBackground().call { result in
            XCTAssertTrue(taskWasRun, "Expected the task closure to be called.")
            XCTAssertTrue(NSThread.isMainThread(), "Expected the completion block to run on the main thread.")

            TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the error to be transformed to a default value.")

            completionExpectation.fulfill()
        }

        waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testInDispatchGroup() {
        let expectedValue = 3

        var taskWasRun = false
        let promise = Promise<Int> { fulfill in
            taskWasRun = true

            XCTAssertTrue(NSThread.isMainThread(), "Expected the task to run on the main thread.")

            fulfill(Result { expectedValue })
        }

        let group = dispatch_group_create()

        var promiseCompletionWasRun = false
        let groupCompletionExpectation = expectationWithDescription("Dispatch group completed.")

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            XCTAssertTrue(taskWasRun, "Expected the task closure to be called.")
            XCTAssertTrue(promiseCompletionWasRun, "Expected the promise completion block to be called before the group completion block.")

            groupCompletionExpectation.fulfill()
        }

        promise.inDispatchGroup(group).call { result in
            XCTAssertTrue(NSThread.isMainThread(), "Expected the completion block to run on the main thread.")

            TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the error to be transformed to a default value.")

            promiseCompletionWasRun = true
        }

        waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testSuccess() {
        // Succeed
        do {
            let expectedValue = 3
            let initialPromise = Promise(value: expectedValue)

            var successWasRun = false
            let promise = initialPromise.success { value in
                successWasRun = true
                XCTAssertEqual(expectedValue, value, "Expected the given success value.")
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
            }

            XCTAssertTrue(successWasRun, "Expected the success block to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Don't succeed
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            var successWasRun = false
            let promise = initialPromise.success { value in
                successWasRun = true
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertFalse(successWasRun, "Expected the success block not to be called.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }
    
    func testFailure() {
        // Fail
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            var successWasRun = false
            let promise = initialPromise.failure { error in
                successWasRun = true
                XCTAssertEqual(expectedError, error as NSError, "Expected the given error.")
                XCTAssertTrue(expectedError === error as NSError, "Expected the same error, not just an equal error.")
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectFailure(expectedError, result: result)
            }

            XCTAssertTrue(successWasRun, "Expected the failure block to be called immediately.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }

        // Don't fail
        do {
            let expectedValue = 3
            let initialPromise = Promise(value: expectedValue)

            var successWasRun = false
            let promise = initialPromise.failure { error in
                successWasRun = true
            }

            var completionWasRun = false
            promise.call { result in
                completionWasRun = true
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
            }

            XCTAssertFalse(successWasRun, "Expected the failure block not to be called.")
            XCTAssertTrue(completionWasRun, "Expected the completion block to be called immediately.")
        }
    }
    
}
