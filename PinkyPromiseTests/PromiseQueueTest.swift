//
//  PromiseQueueTest.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 8/19/16.
//
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

            let completionCalled = expectationWithDescription("Completion was called")
            queue.batch(promises).call { result in
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

            let completionCalled = expectationWithDescription("Completion was called")
            queue.batch(promises).call { result in
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

            let completionCalled = expectationWithDescription("Completion was called")
            queue.batch(promises).call { result in
                TestHelpers.expectFailure(expectedError, result: result)
                completionCalled.fulfill()
            }
        }

        // In-order execution
        do {
            let queue = PromiseQueue<Int>()

            let completionCalled = expectationWithDescription("Completion was called")
            queue.batch(sampleBatch()).call { _ in
                completionCalled.fulfill()
            }
        }

        // Empty batch
        do {
            let queue = PromiseQueue<Int>()

            let expectedValues: [Int] = []
            let completionCalled = expectationWithDescription("Completion was called")
            queue.batch([]).call { result in
                TestHelpers.expectSuccess(expectedValues, result: result, message: "Expected an empty list of success values")
                completionCalled.fulfill()
            }
        }

        waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPromise_enqueue_in() {
        let queue = PromiseQueue<Int>()

        for promise in sampleBatch() {
            promise.enqueue(in: queue)
        }
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    // MARK: Helpers

    // A batch of promises that run one at a time, succeed and fail,
    // and validate that they were run one at a time and in order.
    private func sampleBatch() -> [Promise<Int>] {
        var nextValue = 0
        
        return (1...10).flatMap { _ -> [Promise<Int>] in
            let expectedError = TestHelpers.uniqueError()

            let successResultCalled = self.expectationWithDescription("Success result was called")
            let failureResultCalled = self.expectationWithDescription("Failure result was called")
            
            return [
                Promise.lift {
                    nextValue += 1
                    return nextValue
                }.result { result in
                    TestHelpers.expectSuccess(nextValue, result: result, message: "Expected the next success value.")
                    
                    successResultCalled.fulfill()
                },
                Promise.lift {
                    nextValue += 1
                    throw expectedError
                }.result { result in
                    TestHelpers.expectFailure(expectedError, result: result)

                    failureResultCalled.fulfill()
                }
            ]
        }
    }

}
