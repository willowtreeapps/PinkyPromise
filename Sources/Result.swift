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

public extension Result where Failure == Error {

    /**
     Transforms a success value into a new successful or failed result.

     If the receiver is a failure, wraps the same error without invoking `transform`.

     - parameter transform: A function that returns a new success value or throws a new error, given a success value.
     - returns: The transformed result or the original failure.

     This is an error-catching variation on `flatMap(_:)`.
     */
    func tryMap<U>(_ transform: (Success) throws -> U) -> Result<U, Error> {
        return Result<U, Error>(catching: {
            try transform(try get())
        })
    }
}

/**
 From two results, returns one result wrapping all their values or the first error.

 - parameter resultA: The first result to repackage.
 - parameter resultB: The second result to repackage.
 - returns: A result wrapping either a tuple of all the given results' success values, or the first error among them.
 */
public func zip<A, B>(_ resultA: Result<A, Error>, _ resultB: Result<B, Error>) -> Result<(A, B), Error> {
    return resultA.tryMap { a in
        (a, try resultB.get())
    }
}

/**
 From three results, returns one result wrapping all their values or the first error.

 - parameter resultA: The first result to repackage.
 - parameter resultB: The second result to repackage.
 - parameter resultC: The third result to repackage.
 - returns: A result wrapping either a tuple of all the given results' success values, or the first error among them.
 */
public func zip<A, B, C>(_ resultA: Result<A, Error>, _ resultB: Result<B, Error>, _ resultC: Result<C, Error>) -> Result<(A, B, C), Error> {
    return zip(resultA, resultB).tryMap { a, b in
        (a, b, try resultC.get())
    }
}

/**
 From four results, returns one result wrapping all their values or the first error.

 - parameter resultA: The first result to repackage.
 - parameter resultB: The second result to repackage.
 - parameter resultC: The third result to repackage.
 - parameter resultD: The fourth result to repackage.
 - returns: A result wrapping either a tuple of all the given results' success values, or the first error among them.
 */
public func zip<A, B, C, D>(_ resultA: Result<A, Error>, _ resultB: Result<B, Error>, _ resultC: Result<C, Error>, _ resultD: Result<D, Error>) -> Result<(A, B, C, D), Error> {
    return zip(resultA, resultB, resultC).tryMap { a, b, c in
        (a, b, c, try resultD.get())
    }
}

/**
 From an array of results, returns one result wrapping all their values or the first error.

 - parameter results: The array of results to repackage.
 - returns: A result wrapping either an array of all the given results' success values, or the first error among them.
 */
public func zipArray<T>(_ results: [Result<T, Error>]) -> Result<[T], Error> {
    return results.reduce(Result(catching: { [] })) { arrayResult, itemResult in
        arrayResult.tryMap { array in
            return array + [try itemResult.get()]
        }
    }
}
