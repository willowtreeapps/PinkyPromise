//
//  Result.swift
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

// A model for a success or failure case.
// This type precisely represents the domain of results of a function call that either returns a value of T or throws an error.

// Result<T> is used by Promise<T> to represent success or failure outside the normal flow of synchronous execution.

// Result is a functor and monad; you can map and flatMap.
// map transforms success values into new success values but merely forwards errors.
// flatMap also forwards errors, but transforms to a new Result, meaning it may produce a new failure.
// tryMap transforms success values but can throw errors, which are caught and encoded as new failures.

public enum Result<T> {

    public typealias Value = T

    case Success(Value)
    case Failure(ErrorType)

    // Create a Result by returning a value or throwing an error.
    public init(@noescape create: () throws -> Value) {
        do {
            let value = try create()
            self = .Success(value)
        } catch {
            self = .Failure(error)
        }
    }

    // Unwrap a success value or throw a failure value.
    public func value() throws -> Value {
        switch self {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }

    // Return a failure if we have one.
    // Otherwise, transform the success value into a new success value.
    public func map<U>(@noescape transform: (Value) -> U) -> Result<U> {
        return tryMap(transform)
    }

    // The canonical flatMap.
    // Return a failure if we have one.
    // Otherwise, transform the success value into a new success or failure.
    public func flatMap<U>(@noescape transform: (Value) -> Result<U>) -> Result<U> {
        return tryMap { value in
            try transform(value).value()
        }
    }

    // An error-catching variation on flatMap.
    // Return a failure if we have one.
    // Otherwise, transform the success value into a new success value, or fail if an error is thrown.
    public func tryMap<U>(@noescape transform: (Value) throws -> U) -> Result<U> {
        return Result<U> {
            try transform(try value())
        }
    }

}

// From two Results, return one Result of their values or the first failure.
public func zip<A, B>(resultA: Result<A>, _ resultB: Result<B>) -> Result<(A, B)> {
    return resultA.tryMap { a in
        (a, try resultB.value())
    }
}

// From three Results, return one Result of their values or the first failure.
public func zip<A, B, C>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>) -> Result<(A, B, C)> {
    return zip(resultA, resultB).tryMap { a, b in
        (a, b, try resultC.value())
    }
}

// From four Results, return one Result of their values or the first failure.
public func zip<A, B, C, D>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>, _ resultD: Result<D>) -> Result<(A, B, C, D)> {
    return zip(resultA, resultB, resultC).tryMap { a, b, c in
        (a, b, c, try resultD.value())
    }
}

// From an array of Results, return one Result of an array of their values or the first failure.
public func zipArray<T>(results: [Result<T>]) -> Result<[T]> {
    return results.reduce(Result { [] }) { arrayResult, itemResult in
        arrayResult.tryMap { array in
            array + [try itemResult.value()]
        }
    }
}
