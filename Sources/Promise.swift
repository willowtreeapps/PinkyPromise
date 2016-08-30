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
        self.init(result: .success(value))
    }

    // A promise that trivially fails.
    public init(error: Error) {
        self.init(result: .failure(error))
    }

    // A promise that creates its value or error when called.
    // Lifts the notion of producing a Result into Promise context.
    // Or, lifts a synchonous function into asynchronous context.
    public static func lift(_ produce: @escaping () throws -> Value) -> Promise<Value> {
        return Promise { fulfill in
            fulfill(Result(create: produce))
        }
    }

    // MARK: Promise transformations

    // Produces a composite promise that resolves by calling this promise, then transforming its success value.
    public func map<U>(_ transform: @escaping (Value) -> U) -> Promise<U> {
        return flatMap { value in
            return Promise<U>(value: transform(value))
        }
    }

    // Produces a composite promise that resolves by calling this promise, then transforming its success value.
    // You may transform a success to a failure by throwing an error.
    public func tryMap<U>(_ transform: @escaping (Value) throws -> U) -> Promise<U> {
        return flatMap { value in
            return Promise<U>(result: Result {
                try transform(value)
            })
        }
    }

    // Produces a composite promise that resolves by calling this promise, passing its result to the next task,
    // then calling the produced promise.
    public func flatMap<U>(_ transform: @escaping (Value) -> Promise<U>) -> Promise<U> {
        return Promise<U> { fulfill in
            self.call { result in
                do {
                    let mappedPromise = transform(try result.value())
                    mappedPromise.call(completion: fulfill)
                } catch {
                    fulfill(.failure(error))
                }
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, passing its error to the next task,
    // then calling the produced promise.
    // If this promise succeeds, the transformation is skipped.
    public func recover(_ transform: @escaping (Error) -> Promise<Value>) -> Promise<Value> {
        return Promise { fulfill in
            self.call { (result: Result<Value>) -> Void in
                do {
                    let value = try result.value()
                    fulfill(.success(value))
                } catch {
                    let mappedPromise = transform(error)
                    mappedPromise.call(completion: fulfill)
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
                    case (.success, _), (.failure, 0):
                        fulfill(result)
                    case (.failure, _):
                        attempt(remainingAttempts: remainingAttempts - 1)
                    }
                }
            }

            attempt(remainingAttempts: max(0, attemptCount - 1))
        }
    }

    // Produces a composite promise that resolves by running this promise in the background queue,
    // then fulfills on the main queue.
    public func inBackground() -> Promise<Value> {
        return Promise { fulfill in
            DispatchQueue.global().async {
                self.call { result in
                    DispatchQueue.main.async {
                        fulfill(result)
                    }
                }
            }
        }
    }

    // Produces a composite promise that resolves by participating in a dispatch group while running this promise.
    // The dispatch group is exited only after the completion step.
    public func inDispatchGroup(_ group: DispatchGroup) -> Promise<Value> {
        return Promise { fulfill in
            group.enter()
            self.call { result in
                fulfill(result)
                group.leave()
            }
        }
    }

    // MARK: Result delivery

    // Produces a composite promise that resolves by calling this promise, but also performs another task.
    public func onResult(_ resultTask: @escaping (Result<Value>) -> Void) -> Promise<Value> {
        return Promise { fulfill in
            self.call { result in
                resultTask(result)
                fulfill(result)
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, but also performs another task if successful.
    public func onSuccess(_ successTask: @escaping (Value) -> Void) -> Promise<Value> {
        return onResult { result in
            if case .success(let value) = result {
                successTask(value)
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, but also performs another task if failed.
    public func onFailure(_ failureTask: @escaping (Error) -> Void) -> Promise<Value> {
        return onResult { result in
            if case .failure(let error) = result {
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
public func zip<A, B>(_ promiseA: Promise<A>, _ promiseB: Promise<B>) -> Promise<(A, B)> {
    return Promise { fulfill in
        let group = DispatchGroup()

        var resultA: Result<A>!
        var resultB: Result<B>!

        promiseA.inDispatchGroup(group).call { result in
            resultA = result
        }

        promiseB.inDispatchGroup(group).call { result in
            resultB = result
        }

        group.notify(queue: DispatchQueue.main) {
            fulfill(zip(resultA, resultB))
        }
    }
}

// Produces a promise that runs three promises simultaneously and unifies their result.
public func zip<A, B, C>(_ promiseA: Promise<A>, _ promiseB: Promise<B>, _ promiseC: Promise<C>) -> Promise<(A, B, C)> {
    return Promise { fulfill in
        let group = DispatchGroup()

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

        group.notify(queue: DispatchQueue.main) {
            fulfill(zip(resultA, resultB, resultC))
        }
    }
}

// Produces a promise that runs four promises simultaneously and unifies their result.
public func zip<A, B, C, D>(_ promiseA: Promise<A>, _ promiseB: Promise<B>, _ promiseC: Promise<C>, _ promiseD: Promise<D>) -> Promise<(A, B, C, D)> {
    return Promise { fulfill in
        let group = DispatchGroup()

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

        group.notify(queue: DispatchQueue.main) {
            fulfill(zip(resultA, resultB, resultC, resultD))
        }
    }
}

public func zipArray<T>(_ promises: [Promise<T>]) -> Promise<[T]> {
    return Promise { fulfill in
        let group = DispatchGroup()

        var results: [Result<T>?] = Array(repeating: nil, count: promises.count)

        for (index, promise) in promises.enumerated() {
            promise.inDispatchGroup(group).call { result in
                results[index] = result
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            let unwrappedResults = results.map { $0! }
            fulfill(zipArray(unwrappedResults))
        }
    }
}
