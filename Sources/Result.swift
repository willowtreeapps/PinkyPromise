//
//  Result.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 3/16/16.
//  Copyright © 2016 WillowTree, Inc. All rights reserved.
//

import Foundation

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

    // Keep our error if we have one. Otherwise, transform the success value.
    // Errors thrown during transformation are captured as failure values.
    func map<U>(@noescape transform: (Value) throws -> U) -> Result<U> {
        return flatMap { value in
            let mappedValue = try transform(value)
            return .Success(mappedValue)
        }
    }

    // Keep our error if we have one. Otherwise, produce a new success or failure using the success value.
    // Errors thrown during transformation are captured as failure values.
    func flatMap<U>(@noescape transform: (Value) throws -> Result<U>) -> Result<U> {
        do {
            let successValue = try value()
            let mappedResult = try transform(successValue)
            return mappedResult
        } catch {
            return .Failure(error)
        }
    }

}

func zip<A, B>(resultA: Result<A>, _ resultB: Result<B>) -> Result<(A, B)> {
    return resultA.flatMap { a in
        let b = try resultB.value()
        return .Success(a, b)
    }
}

func zip<A, B, C>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>) -> Result<(A, B, C)> {
    return resultA.flatMap { a in
        let (b, c) = try zip(resultB, resultC).value()
        return .Success(a, b, c)
    }
}

func zip<A, B, C, D>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>, _ resultD: Result<D>) -> Result<(A, B, C, D)> {
    return resultA.flatMap { a in
        let (b, c, d) = try zip(resultB, resultC, resultD).value()
        return .Success(a, b, c, d)
    }
}

func zipArray<T>(results: [Result<T>]) -> Result<[T]> {
    return results.reduce(.Success([])) { (arrayResult, itemResult) in
        return arrayResult.flatMap { array in
            let item = try itemResult.value()
            return .Success(array + [item])
        }
    }
}
