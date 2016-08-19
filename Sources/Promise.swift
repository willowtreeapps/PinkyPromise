//
//  Promise.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 3/16/16.
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

import Foundation

// A task that can resolve to a value or an error asynchronously.

// First, create a Promise, or receive one that wraps an asynchronous task.
// Use .flatMap to chain additional monadic tasks. Failures skip over mapped tasks.
// Use .success or .failure to process a success or failure value, then continue.
// After building up your composite promise, begin it with .call.
// Use Result by switching on its cases, or call .value() to unwrap it and have failures thrown.

public struct Promise<T> {

    public typealias Value = T
    public typealias Observer = (Result<Value>) -> Void
    public typealias Task = (Observer) -> Void

    private let task: Task

    // A promise that produces its result by running an asynchronous task.
    public init(task: Task) {
        self.task = task
    }

    // A promise that trivially produces a result.
    public init(result: Result<Value>) {
        self.init { fulfill in
            fulfill(result)
        }
    }

    // A promise that trivially succeeds.
    public init(value: Value) {
        self.init(result: .Success(value))
    }

    // A promise that trivially fails.
    public init(error: ErrorType) {
        self.init(result: .Failure(error))
    }

    // A promise that creates its value or error when called.
    // Lifts the notion of producing a Result into Promise context.
    // Or, lifts a synchonous function into asynchronous context.
    public static func lift(produce: () throws -> Value) -> Promise<Value> {
        return Promise { fulfill in
            fulfill(Result(create: produce))
        }
    }

    // MARK: Promise transformations

    // Produces a composite promise that resolves by calling this promise, then transforming its success value.
    public func map<U>(transform: (Value) -> U) -> Promise<U> {
        return flatMap { value in
            return Promise<U>(value: transform(value))
        }
    }

    // Produces a composite promise that resolves by calling this promise, then transforming its success value.
    // You may transform a success to a failure by throwing an error.
    public func tryMap<U>(transform: (Value) throws -> U) -> Promise<U> {
        return flatMap { value in
            return Promise<U>(result: Result {
                try transform(value)
            })
        }
    }

    // Produces a composite promise that resolves by calling this promise, passing its result to the next task,
    // then calling the produced promise.
    public func flatMap<U>(transform: (Value) -> Promise<U>) -> Promise<U> {
        return Promise<U> { fulfill in
            self.call { result in
                do {
                    let mappedPromise = transform(try result.value())
                    mappedPromise.call(fulfill)
                } catch {
                    fulfill(.Failure(error))
                }
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, passing its error to the next task,
    // then calling the produced promise.
    // If this promise succeeds, the transformation is skipped.
    public func recover(transform: (ErrorType) -> Promise<Value>) -> Promise<Value> {
        return Promise { fulfill in
            self.call { (result: Result<Value>) -> Void in
                do {
                    let value = try result.value()
                    fulfill(.Success(value))
                } catch {
                    let mappedPromise = transform(error)
                    mappedPromise.call(fulfill)
                }
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise until it succeeds,
    // up to a given number of tries. When `attemptCount` failures occur, the promise produces the final failure.
    // For this to be meaningful you should use an `attemptCount` of at least 2.
    public func retry(attemptCount: Int) -> Promise<Value> {
        return Promise { fulfill in
            func attempt(remainingAttempts: Int) {
                self.call { result in
                    switch (result, remainingAttempts) {
                    case (.Success, _), (.Failure, 0):
                        fulfill(result)
                    case (.Failure, _):
                        attempt(remainingAttempts - 1)
                    }
                }
            }

            attempt(max(0, attemptCount - 1))
        }
    }

    // Produces a composite promise that resolves by running this promise in the background queue,
    // then fulfills on the main queue.
    public func inBackground() -> Promise<Value> {
        return Promise { fulfill in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.call { result in
                    dispatch_async(dispatch_get_main_queue()) {
                        fulfill(result)
                    }
                }
            }
        }
    }

    // Produces a composite promise that resolves by participating in a dispatch group while running this promise.
    // The dispatch group is exited only after the completion step.
    public func inDispatchGroup(group: dispatch_group_t) -> Promise<Value> {
        return Promise { fulfill in
            dispatch_group_enter(group)
            self.call { result in
                fulfill(result)
                dispatch_group_leave(group)
            }
        }
    }

    // MARK: Result delivery

    // Produces a composite promise that resolves by calling this promise, but also performs another task.
    public func result(resultTask: (Result<Value>) -> Void) -> Promise<Value> {
        return Promise { fulfill in
            self.call { result in
                resultTask(result)
                fulfill(result)
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, but also performs another task if successful.
    public func success(successTask: (Value) -> Void) -> Promise<Value> {
        return result { result in
            if case .Success(let value) = result {
                successTask(value)
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, but also performs another task if failed.
    public func failure(failureTask: (ErrorType) -> Void) -> Promise<Value> {
        return result { result in
            if case .Failure(let error) = result {
                failureTask(error)
            }
        }
    }

    // Performs work defined by the promise and eventually calls completion.
    // Promises won't do any work until you call this.
    public func call(completion: Observer) {
        task(completion)
    }

    // Performs work defined by the promise and, if you supplied a completion block, eventually calls it.
    // Promises won't do you any work until you call this.
    public func call(completion: Observer? = nil) {
        task { result in
            completion?(result)
        }
    }

}

// Produces a promise that runs two promises simultaneously and unifies their result.
public func zip<A, B>(promiseA: Promise<A>, _ promiseB: Promise<B>) -> Promise<(A, B)> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var resultA: Result<A>!
        var resultB: Result<B>!

        promiseA.inDispatchGroup(group).call { result in
            resultA = result
        }

        promiseB.inDispatchGroup(group).call { result in
            resultB = result
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            fulfill(zip(resultA, resultB))
        }
    }
}

// Produces a promise that runs three promises simultaneously and unifies their result.
public func zip<A, B, C>(promiseA: Promise<A>, _ promiseB: Promise<B>, _ promiseC: Promise<C>) -> Promise<(A, B, C)> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var resultA: Result<A>!
        var resultB: Result<B>!
        var resultC: Result<C>!

        promiseA.inDispatchGroup(group).call { result in
            resultA = result
        }

        promiseB.inDispatchGroup(group).call { result in
            resultB = result
        }

        promiseC.inDispatchGroup(group).call { result in
            resultC = result
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            fulfill(zip(resultA, resultB, resultC))
        }
    }
}

// Produces a promise that runs four promises simultaneously and unifies their result.
public func zip<A, B, C, D>(promiseA: Promise<A>, _ promiseB: Promise<B>, _ promiseC: Promise<C>, _ promiseD: Promise<D>) -> Promise<(A, B, C, D)> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var resultA: Result<A>!
        var resultB: Result<B>!
        var resultC: Result<C>!
        var resultD: Result<D>!

        promiseA.inDispatchGroup(group).call { result in
            resultA = result
        }

        promiseB.inDispatchGroup(group).call { result in
            resultB = result
        }

        promiseC.inDispatchGroup(group).call { result in
            resultC = result
        }

        promiseD.inDispatchGroup(group).call { result in
            resultD = result
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            fulfill(zip(resultA, resultB, resultC, resultD))
        }
    }
}

public func zipArray<T>(promises: [Promise<T>]) -> Promise<[T]> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var results: [Result<T>?] = Array(count: promises.count, repeatedValue: nil)

        for (index, promise) in promises.enumerate() {
            promise.inDispatchGroup(group).call { result in
                results[index] = result
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            let unwrappedResults = results.map { $0! }
            fulfill(zipArray(unwrappedResults))
        }
    }
}
