//
//  Result.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 3/16/16.
//  Copyright © 2016 WillowTree, Inc. All rights reserved.
//

import Foundation

// A model for a success or failure case.
// This type precisely represents the domain of results of a function call that either returns a value of T or throws an error.

// Result<T> is used by Promise<T> to represent success or failure outside the normal flow of synchronous execution.

// Result is a functor and monad; you can map and flatMap.
// map transforms success values but merely forwards errors.
// flatMap also forwards errors, but transforms to a new Result, meaning a success may be transformed a failure.
// flatMap's transformation closure can return a failure result, but it can also throw to produce the same effect.
// map's transformation closure cannot throw, since map should never transform a success to a failure.

enum Result<T> {

    typealias Value = T

    case Failure(ErrorType)
    case Success(Value)

    // Unwrap a success value or throw a failure value.
    func value() throws -> Value {
        switch self {
        case .Failure(let error):
            throw error
        case .Success(let value):
            return value
        }
    }

    // Return a failure if we have one.
    // Otherwise, transform the success value into a new success value.
    func map<U>(@noescape transform: (Value) -> U) -> Result<U> {
        return catchMap(transform)
    }

    // The canonical flatMap.
    // Return a failure if we have one.
    // Otherwise, transform the success value into a new success or failure.
    func flatMap<U>(@noescape transform: (Value) -> Result<U>) -> Result<U> {
        return catchMap { value in
            let mappedResult = transform(value)
            let mappedValue = try mappedResult.value()
            return mappedValue
        }
    }

    // An error-catching variation on flatMap.
    // Return a failure if we have one.
    // Otherwise, transform the success value into a new success value, or fail if an error if thrown.
    func catchMap<U>(@noescape transform: (Value) throws -> U) -> Result<U> {
        do {
            let successValue = try value()
            let mappedValue = try transform(successValue)
            return .Success(mappedValue)
        } catch {
            return .Failure(error)
        }
    }

}

// From two Results, return one Result of their values or the first failure.
func zip<A, B>(resultA: Result<A>, _ resultB: Result<B>) -> Result<(A, B)> {
    return resultA.catchMap { a in
        let b = try resultB.value()
        return (a, b)
    }
}

// From three Results, return one Result of their values or the first failure.
func zip<A, B, C>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>) -> Result<(A, B, C)> {
    return zip(resultA, resultB).catchMap { a, b in
        let c = try resultC.value()
        return (a, b, c)
    }
}

// From four Results, return one Result of their values or the first failure.
func zip<A, B, C, D>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>, _ resultD: Result<D>) -> Result<(A, B, C, D)> {
    return zip(resultA, resultB, resultC).catchMap { a, b, c in
        let d = try resultD.value()
        return (a, b, c, d)
    }
}

// From an array of Results, return one Result of an array of their values or the first failure.
func zipArray<T>(results: [Result<T>]) -> Result<[T]> {
    return results.reduce(.Success([])) { (arrayResult, itemResult) in
        return arrayResult.catchMap { array in
            let item = try itemResult.value()
            return (array + [item])
        }
    }
}
