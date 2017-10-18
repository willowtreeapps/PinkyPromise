//
//  PromiseQueueTest.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 8/19/16.
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

class PromiseQueueTest: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testInit() {
        // Nothing to test.
    }

    func testBatch() {
        // Success
        do {
            let queue = PromiseQueue<Int>()

            let expectedValue1 = 1
            let promise1 = Promise(value: expectedValue1)

            let expectedValue2 = 2
            let promise2 = Promise(value: expectedValue2)

            let promises = [promise1, promise2]

            let completionCalled = expectation(description: "Completion was called")
            queue.batch(promises: promises).call { result in
                TestHelpers.expectSuccess([expectedValue1, expectedValue2], result: result, message: "Expected an array with all success values.")
                completionCalled.fulfill()
            }
        }

        // Success, then failure
        do {
            let queue = PromiseQueue<Int>()

            let expectedError = TestHelpers.uniqueError()
            let promise1 = Promise<Int>(error: expectedError)

            let successValue = 3
            let promise2 = Promise(value: successValue)

            let promises = [promise1, promise2]

            let completionCalled = expectation(description: "Completion was called")
            queue.batch(promises: promises).call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }
        }

        // Failure, then success
        do {
            let queue = PromiseQueue<Int>()

            let successValue = 3
            let promise1 = Promise(value: successValue)

            let expectedError = TestHelpers.uniqueError()
            let promise2 = Promise<Int>(error: expectedError)

            let promises = [promise1, promise2]

            let completionCalled = expectation(description: "Completion was called")
            queue.batch(promises: promises).call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }
        }

        // In-order execution
        do {
            let queue = PromiseQueue<Int>()

            let completionCalled = expectation(description: "Completion was called")
            queue.batch(promises: sampleBatch()).call { _ in
                completionCalled.fulfill()
            }
        }

        // Empty batch
        do {
            let queue = PromiseQueue<Int>()

            let expectedValues: [Int] = []
            let completionCalled = expectation(description: "Completion was called")
            queue.batch(promises: []).call { result in
                TestHelpers.expectSuccess(expectedValues, result: result, message: "Expected an empty list of success values")
                completionCalled.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPromise_enqueue_in() {
        let queue = PromiseQueue<Int>()

        for promise in sampleBatch() {
            promise.enqueue(in: queue)
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: Helpers

    // A batch of promises that run one at a time, succeed and fail,
    // and validate that they were run one at a time and in order.
    fileprivate func sampleBatch() -> [Promise<Int>] {
        var nextValue = 0
        
        return (1...10).flatMap { _ -> [Promise<Int>] in
            let expectedError = TestHelpers.uniqueError()

            let successResultCalled = self.expectation(description: "Success result was called")
            let failureResultCalled = self.expectation(description: "Failure result was called")
            
            return [
                Promise.lift {
                    nextValue += 1
                    return nextValue
                }.onResult { result in
                    TestHelpers.expectSuccess(nextValue, result: result, message: "Expected the next success value.")
                    
                    successResultCalled.fulfill()
                },
                Promise.lift {
                    nextValue += 1
                    throw expectedError
                }.onResult { result in
                    TestHelpers.expectFailure(expectedError, result: result)

                    failureResultCalled.fulfill()
                }
            ]
        }
    }

}
