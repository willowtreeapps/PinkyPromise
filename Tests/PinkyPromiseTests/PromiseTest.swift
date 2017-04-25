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
            let taskCalled = expectation(description: "Task was called")
            let promise = Promise<Int> { fulfill in
                fulfill(result)
                taskCalled.fulfill()
            }

            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given task's return value.")
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Create with failing task
        do {
            let expectedError = TestHelpers.uniqueError()
            let result = Result<String> { throw expectedError }
            let taskCalled = expectation(description: "Task was called")
            let promise = Promise<String> { fulfill in
                fulfill(result)
                taskCalled.fulfill()
            }

            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }
    
    func testInit_result() {
        // Create with successful result
        do {
            let expectedValue = "Hi there"
            let result = Result { expectedValue }
            let promise = Promise(result: result)

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given result.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Create with failed result
        do {
            let expectedError = TestHelpers.uniqueError()
            let result = Result<String> { throw expectedError }
            let promise = Promise(result: result)

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testInit_value() {
        let expectedValue = [3, 6, 9]        
        let promise = Promise(value: expectedValue)

        let completionCalled = expectation(description: "Completion was called")
        promise.call { result in
            TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given value.")
            completionCalled.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testInit_error() {
        let expectedError = TestHelpers.uniqueError()        
        let promise = Promise<[String: Int]>(error: expectedError)

        let completionCalled = expectation(description: "Completion was called")
        promise.call { result in
            TestHelpers.expectFailure(expectedError, result: result)
            completionCalled.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testLift() {
        // Success
        do {
            let expectedValue = "someValue"
            let promise = Promise.lift {
                expectedValue
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given value.")
                completionCalled.fulfill()
            }
        }

        // Failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let promise = Promise.lift {
                throw expectedError
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testMap() {
        // Map success to success
        do {
            let initialPromise = Promise(value: 3)

            let transformCalled = expectation(description: "Transform was called")
            let promise = initialPromise.map { value -> Int in
                transformCalled.fulfill()
                return value + 10
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(13, result: result, message: "Expected the value to be transformed.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Map failure to failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            let promise = initialPromise.map { value -> Int in
                XCTFail("Expected the transform closure not to be called.")
                return value + 10
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }
    
    func testTryMap() {
        // Try-map success to success
        do {
            let initialPromise = Promise(value: 3)

            let transformCalled = expectation(description: "Transform was called")
            let promise = initialPromise.tryMap { value -> Int in
                transformCalled.fulfill()
                return value + 10
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(13, result: result, message: "Expected the value to be transformed.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Try-map success to failure
        do {
            let initialPromise = Promise(value: 3)
            let expectedError = TestHelpers.uniqueError()

            let transformCalled = expectation(description: "Transform was called")
            let promise = initialPromise.tryMap { value -> Int in
                transformCalled.fulfill()
                throw expectedError
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Try-map failure to failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            let promise = initialPromise.tryMap { value -> Int in
                XCTFail("Expected the transform closure not to be called.")
                return value + 10
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }
    
    func testFlatMap() {
        // Flat-map success to success
        do {
            let initialPromise = Promise(value: 3)

            let transformCalled = expectation(description: "Transform was called")
            let promise = initialPromise.flatMap { value -> Promise<Int> in
                transformCalled.fulfill()
                return Promise(value: value + 10)
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(13, result: result, message: "Expected the value to be transformed.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Flat-map success to failure
        do {
            let initialPromise = Promise(value: 3)
            let expectedError = TestHelpers.uniqueError()

            let transformCalled = expectation(description: "Transform was called")
            let promise = initialPromise.flatMap { value -> Promise<Int> in
                transformCalled.fulfill()
                return Promise(error: expectedError)
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Flat-map failure to failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            let promise = initialPromise.flatMap { value -> Promise<Int> in
                XCTFail("Expected the transform closure not to be called.")
                return Promise(value: value + 10)
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testRecover() {
        // Recover success to success
        do {
            let expectedValue = 3
            let initialPromise = Promise(value: expectedValue)

            let promise = initialPromise.recover { error in
                XCTFail("Expected the transform closure not to be called.")
                return Promise(value: 1000)
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the value to stay the same.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Recover failure to success
        do {
            let initialPromise = Promise<Int>(error: TestHelpers.uniqueError())
            let expectedValue = 1000

            let transformCalled = expectation(description: "Transform was called")
            let promise = initialPromise.recover { error in
                transformCalled.fulfill()
                return Promise(value: expectedValue)
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the error to be transformed to a default value.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Recover failure to failure
        do {
            let initialPromise = Promise<Int>(error: TestHelpers.uniqueError())
            let expectedError = TestHelpers.uniqueError()

            let transformCalled = expectation(description: "Transform was called")
            let promise = initialPromise.recover { error in
                transformCalled.fulfill()
                return Promise(error: expectedError)
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
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
            let completionCalled = expectation(description: "Completion was called")
            promise.retry(attemptCount: attemptCount).call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
                completionCalled.fulfill()
            }

            XCTAssertEqual(1, taskRunCount, "Expected the task to succeed on the first try.")
            waitForExpectations(timeout: 1.0, handler: nil)
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
            let completionCalled = expectation(description: "Completion was called")
            promise.retry(attemptCount: attemptCount).call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
                completionCalled.fulfill()
            }

            XCTAssertEqual(2, taskRunCount, "Expected the task to succeed on the second try.")
            waitForExpectations(timeout: 1.0, handler: nil)
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
            let completionCalled = expectation(description: "Completion was called")
            promise.retry(attemptCount: attemptCount).call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            XCTAssertEqual(attemptCount, taskRunCount, "Expected the task to run until it ran out of attempts.")
            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testInBackground() {
        let expectedValue = 3

        let taskCalled = expectation(description: "Task was called")
        let promise = Promise<Int> { fulfill in
            taskCalled.fulfill()

            XCTAssertFalse(Thread.isMainThread, "Expected the task to run in the background.")

            fulfill(Result { expectedValue })
        }

        let completionCalled = expectation(description: "Promise completed.")

        promise.inBackground().call { result in
            XCTAssertTrue(Thread.isMainThread, "Expected the completion block to run on the main thread.")

            TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the error to be transformed to a default value.")

            completionCalled.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testInDispatchGroup() {
        let expectedValue = 3

        let taskCalled = expectation(description: "Task was called")
        let promise = Promise<Int> { fulfill in
            XCTAssertTrue(Thread.isMainThread, "Expected the task to run on the main thread.")

            fulfill(Result { expectedValue })

            taskCalled.fulfill()
        }

        let group = DispatchGroup()

        let promiseCompletionCalled = expectation(description: "Promise completed.")
        let groupCompletionCalled = expectation(description: "Dispatch group completed.")

        group.notify(queue: DispatchQueue.main) {
            groupCompletionCalled.fulfill()
        }

        promise.inDispatchGroup(group).call { result in
            XCTAssertTrue(Thread.isMainThread, "Expected the completion block to run on the main thread.")

            TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the error to be transformed to a default value.")

            promiseCompletionCalled.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testResult() {
        // With success
        do {
            let expectedValue = 3
            let initialPromise = Promise(value: expectedValue)
            
            let resultCalled = expectation(description: "Result block was called")
            let promise = initialPromise.onResult { result in
                TestHelpers.expectSuccess(3, result: result, message: "Expected the given success value.")
                resultCalled.fulfill()
            }
            
            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
                completionCalled.fulfill()
            }
            
            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // With failure
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            let resultCalled = expectation(description: "Failure block was called")
            let promise = initialPromise.onResult { result in
                TestHelpers.expectFailure(expectedError, result: result)
                resultCalled.fulfill()
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testSuccess() {
        // Succeed
        do {
            let expectedValue = 3
            let initialPromise = Promise(value: expectedValue)

            let successCalled = expectation(description: "Success block was called")
            let promise = initialPromise.onSuccess { value in
                XCTAssertEqual(expectedValue, value, "Expected the given success value.")
                successCalled.fulfill()
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Don't succeed
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            let promise = initialPromise.onSuccess { value in
                XCTFail("Expected the success block not to be called.")
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }
    
    func testFailure() {
        // Fail
        do {
            let expectedError = TestHelpers.uniqueError()
            let initialPromise = Promise<Int>(error: expectedError)

            let failureCalled = expectation(description: "Failure block was called")
            let promise = initialPromise.onFailure { error in
                XCTAssertEqual(expectedError, error as NSError, "Expected the given error.")
                XCTAssertTrue(expectedError === error as NSError, "Expected the same error, not just an equal error.")
                failureCalled.fulfill()
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Don't fail
        do {
            let expectedValue = 3
            let initialPromise = Promise(value: expectedValue)

            let promise = initialPromise.onFailure { error in
                XCTFail("Expected the failure block not to be called.")
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                TestHelpers.expectSuccess(expectedValue, result: result, message: "Expected the given success value.")
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testCall_completion() {
        let expectedResult = 3

        let taskCalled = expectation(description: "Task was called")
        let promise = Promise<Int> { fulfill in
            fulfill(Result { expectedResult })

            taskCalled.fulfill()
        }

        let completionCalled = expectation(description: "Completion was called")
        promise.call { result in
            completionCalled.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCall_optionalCompletion() {
        // Completion is called when included
        do {
            let expectedResult = 3

            let taskCalled = expectation(description: "Task was called")
            let promise = Promise<Int> { fulfill in
                fulfill(Result { expectedResult })

                taskCalled.fulfill()
            }

            let completionCalled = expectation(description: "Completion was called")
            promise.call { result in
                completionCalled.fulfill()
            }

            waitForExpectations(timeout: 1.0, handler: nil)
        }

        // Even without a completion block, the work is done
        do {
            let expectedResult = 3

            let taskCalled = expectation(description: "Task was called")
            let promise = Promise<Int> { fulfill in
                fulfill(Result { expectedResult })

                taskCalled.fulfill()
            }

            promise.call()

            waitForExpectations(timeout: 1.0, handler: nil)
        }
    }

    func testZip() {
        let error1 = TestHelpers.uniqueError()
        let error2 = TestHelpers.uniqueError()
        let error3 = TestHelpers.uniqueError()
        let error4 = TestHelpers.uniqueError()

        let success1: Promise<Int> = Promise(value: 1)
        let success2: Promise<String> = Promise(value: "hi")
        let success3: Promise<Int> = Promise(value: 3)
        let success4: Promise<String> = Promise(value: "bye")

        let failure1: Promise<Int> = Promise(error: error1)
        let failure2: Promise<String> = Promise(error: error2)
        let failure3: Promise<Int> = Promise(error: error3)
        let failure4: Promise<String> = Promise(error: error4)

        func callAndTestCompletion<T>(_ promise: Promise<T>, completion outerCompletion: @escaping (Result<T>) -> Void) {
            let completionCalled = expectation(description: "Completed")
            promise.call { result in
                outerCompletion(result)
                completionCalled.fulfill()
            }
        }

        callAndTestCompletion(zip(success1, success2)) {
            TestHelpers.expectSuccess((1, "hi"), result: $0, message: "Expected to zip 1 and \"hi\" into (1, \"hi\").")
        }
        callAndTestCompletion(zip(success1, failure2)) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zip(failure1, success2)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, failure2)) {
            TestHelpers.expectFailure(error1, result: $0)
        }

        callAndTestCompletion(zip(success1, success2, success3)) {
            TestHelpers.expectSuccess((1, "hi", 3), result: $0, message: "Expected to zip 1, \"hi\", and 3 into (1, \"hi\", 3).")
        }
        callAndTestCompletion(zip(success1, success2, failure3)) {
            TestHelpers.expectFailure(error3, result: $0)
        }
        callAndTestCompletion(zip(success1, failure2, success3)) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zip(success1, failure2, failure3)) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zip(failure1, success2, success3)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, success2, failure3)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, failure2, success3)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, failure2, failure3)) {
            TestHelpers.expectFailure(error1, result: $0)
        }

        callAndTestCompletion(zip(success1, success2, success3, success4)) {
            TestHelpers.expectSuccess((1, "hi", 3, "bye"), result: $0, message: "Expected to zip 1, \"hi\", 3, and \"bye\" into (1, \"hi\", 3, \"bye\").")
        }
        callAndTestCompletion(zip(success1, success2, success3, failure4)) {
            TestHelpers.expectFailure(error4, result: $0)
        }
        callAndTestCompletion(zip(success1, success2, failure3, success4)) {
            TestHelpers.expectFailure(error3, result: $0)
        }
        callAndTestCompletion(zip(success1, success2, failure3, failure4)) {
            TestHelpers.expectFailure(error3, result: $0)
        }
        callAndTestCompletion(zip(success1, failure2, success3, success4)) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zip(success1, failure2, success3, failure4)) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zip(success1, failure2, failure3, success4)) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zip(success1, failure2, failure3, failure4)) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zip(failure1, success2, success3, success4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, success2, success3, failure4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, success2, failure3, success4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, success2, failure3, failure4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, failure2, success3, success4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, failure2, success3, failure4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, failure2, failure3, success4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zip(failure1, failure2, failure3, failure4)) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testZipArray() {
        let error1 = TestHelpers.uniqueError()
        let error2 = TestHelpers.uniqueError()
        let error3 = TestHelpers.uniqueError()

        let success1: Promise<Int> = Promise(value: 112)
        let success2: Promise<Int> = Promise(value: -15)
        let success3: Promise<Int> = Promise(value: 3)

        let failure1: Promise<Int> = Promise(error: error1)
        let failure2: Promise<Int> = Promise(error: error2)
        let failure3: Promise<Int> = Promise(error: error3)

        func callAndTestCompletion<T>(_ promise: Promise<T>, completion outerCompletion: @escaping (Result<T>) -> Void) {
            let completionCalled = expectation(description: "Completed")
            promise.call { result in
                outerCompletion(result)
                completionCalled.fulfill()
            }
        }

        callAndTestCompletion(zipArray([success1, success2, success3])) {
            TestHelpers.expectSuccess([112, -15, 3], result: $0, message: "Expected to zip 112, -15, and 3 into [112, -15, 3].")
        }
        callAndTestCompletion(zipArray([success1, success2, failure3])) {
            TestHelpers.expectFailure(error3, result: $0)
        }
        callAndTestCompletion(zipArray([success1, failure2, success3])) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zipArray([success1, failure2, failure3])) {
            TestHelpers.expectFailure(error2, result: $0)
        }
        callAndTestCompletion(zipArray([failure1, success2, success3])) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zipArray([failure1, success2, failure3])) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zipArray([failure1, failure2, success3])) {
            TestHelpers.expectFailure(error1, result: $0)
        }
        callAndTestCompletion(zipArray([failure1, failure2, failure3])) {
            TestHelpers.expectFailure(error1, result: $0)
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

}
