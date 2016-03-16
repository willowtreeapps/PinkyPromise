//
//  Promise.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 3/16/16.
//  Copyright © 2016 WillowTree, Inc. All rights reserved.
//

import Foundation

// A task that can resolve to a value or an error asynchronously.

// First, create a Promise, or use firstly() for neatness.
// Use .flatMap to chain additional monadic tasks. Failures skip over mapped tasks.
// Use .success or .failure to process a success or failure value, then continue.
// After building up your composite promise, begin it with .call.
// Use the result enum directly, or call .value() to unwrap it and have failures thrown.

struct Promise<T> {

    typealias Value = T
    typealias Observer = (Result<Value>) -> Void
    typealias Task = (Observer) -> Void

    private let task: Task

    // A promise that produces its result by running an asynchronous task.
    init(task: Task) {
        self.task = task
    }

    // A promise that trivially produces a result.
    init(result: Result<Value>) {
        self.init { fulfill in
            fulfill(result)
        }
    }

    // A promise that trivially succeeds.
    init(value: Value) {
        self.init(result: .Success(value))
    }

    // A promise that trivially fails.
    init(error: ErrorType) {
        self.init(result: .Failure(error))
    }

    // Produces a composite promise that resolves by calling this promise, then transforming its success value.
    func map<U>(transform: Value throws -> U) -> Promise<U> {
        return flatMap { value in
            do {
                let mappedValue = try transform(value)
                return Promise<U>(value: mappedValue)
            } catch {
                return Promise<U>(error: error)
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, passing its result to the next task,
    // then calling the produced promise.
    func flatMap<U>(nextTask: (Value) throws -> Promise<U>) -> Promise<U> {
        // Promise AB's task is the following:
        // Run task A (self.call).
        // If A fails, fail AB.
        // If A succeeds, run task B (nextTask(value).call).
        // If B fails, fail AB.
        // If B succeeds, succeed AB.

        return Promise<U> { fulfill in
            self.call { result in
                switch result {
                case .Failure(let error):
                    fulfill(.Failure(error))
                case .Success(let value):
                    do {
                        let nextPromise = try nextTask(value)
                        nextPromise.call(fulfill)
                    } catch {
                        fulfill(.Failure(error))
                    }
                }
            }
        }
    }

    // Produces a composite promise that resolves by running the next task on a background queue,
    // calling its produced promise on the same background queue, then fulfilling on the main thread.
    func flatMapInBackground<U>(nextTask: (Value) throws -> Promise<U>) -> Promise<U> {
        return flatMap { value in
            return Promise<U> { fulfill in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    do {
                        let nextPromise = try nextTask(value)
                        nextPromise.call { result in
                            dispatch_async(dispatch_get_main_queue()) {
                                fulfill(result)
                            }
                        }
                    } catch {
                        dispatch_async(dispatch_get_main_queue()) {
                            fulfill(.Failure(error))
                        }
                    }
                }
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, then the next, and if successful combines
    // their results in the produced promise.
    func combine<U>(nextTask: () throws -> Promise<U>) -> Promise<(T, U)> {
        return flatMap { value1 in
            return Promise<(T, U)> { fulfill in
                do {
                    let nextPromise = try nextTask()
                    nextPromise.call { (result2: Result<U>) in
                        switch result2 {
                        case .Failure(let error):
                            fulfill(.Failure(error))
                        case .Success(let value2):
                            fulfill(.Success((value1, value2)))
                        }
                    }
                } catch {
                    fulfill(.Failure(error))
                }
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, but also performs another task if successful.
    func success(successTask: (Value) -> Void) -> Promise<Value> {
        return Promise { fulfill in
            self.call { result in
                if case .Success(let value) = result {
                    successTask(value)
                }
                fulfill(result)
            }
        }
    }

    // Produces a composite promise that resolves by calling this promise, but also performs another task if failed.
    func failure(errorTask: (ErrorType) -> Void) -> Promise<Value> {
        return Promise { fulfill in
            self.call { result in
                if case .Failure(let error) = result {
                    errorTask(error)
                }
                fulfill(result)
            }
        }
    }

    // Performs work defined by the promise and eventually calls completion.
    // Promises won't do any work until you call this.
    func call(completion: Observer?) {
        task { result in
            completion?(result)
        }
    }

}

// Immediately runs a closure to lift regular code into Promise context.
func firstly<T>(@noescape firstTask: () -> Promise<T>) -> Promise<T> {
    return firstTask()
}

// Produces a promise that runs two promises simultaneously and unifies their result.
func zip<A, B>(promiseA: Promise<A>, _ promiseB: Promise<B>) -> Promise<(A, B)> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var resultA: Result<A>!
        var resultB: Result<B>!

        dispatch_group_enter(group)
        promiseA.call { result in
            resultA = result
            dispatch_group_leave(group)
        }

        dispatch_group_enter(group)
        promiseB.call { result in
            resultB = result
            dispatch_group_leave(group)
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            fulfill(zip(resultA, resultB))
        }
    }
}

// Produces a promise that runs three promises simultaneously and unifies their result.
func zip<A, B, C>(promiseA: Promise<A>, _ promiseB: Promise<B>, _ promiseC: Promise<C>) -> Promise<(A, B, C)> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var resultA: Result<A>!
        var resultB: Result<B>!
        var resultC: Result<C>!

        dispatch_group_enter(group)
        promiseA.call { result in
            resultA = result
            dispatch_group_leave(group)
        }

        dispatch_group_enter(group)
        promiseB.call { result in
            resultB = result
            dispatch_group_leave(group)
        }

        dispatch_group_enter(group)
        promiseC.call { result in
            resultC = result
            dispatch_group_leave(group)
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            fulfill(zip(resultA, resultB, resultC))
        }
    }
}

// Produces a promise that runs four promises simultaneously and unifies their result.
func zip<A, B, C, D>(promiseA: Promise<A>, _ promiseB: Promise<B>, _ promiseC: Promise<C>, _ promiseD: Promise<D>) -> Promise<(A, B, C, D)> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var resultA: Result<A>!
        var resultB: Result<B>!
        var resultC: Result<C>!
        var resultD: Result<D>!

        dispatch_group_enter(group)
        promiseA.call { result in
            resultA = result
            dispatch_group_leave(group)
        }

        dispatch_group_enter(group)
        promiseB.call { result in
            resultB = result
            dispatch_group_leave(group)
        }

        dispatch_group_enter(group)
        promiseC.call { result in
            resultC = result
            dispatch_group_leave(group)
        }

        dispatch_group_enter(group)
        promiseD.call { result in
            resultD = result
            dispatch_group_leave(group)
        }

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            fulfill(zip(resultA, resultB, resultC, resultD))
        }
    }
}

func zipArray<T>(promises: [Promise<T>]) -> Promise<[T]> {
    return Promise { fulfill in
        let group = dispatch_group_create()

        var results: [Result<T>?] = Array(count: promises.count, repeatedValue: nil)

        for (index, promise) in promises.enumerate() {
            dispatch_group_enter(group)
            promise.call { result in
                results[index] = result
                dispatch_group_leave(group)
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            let unwrappedResults = results.map { $0! }
            fulfill(zipArray(unwrappedResults))
        }
    }
}
