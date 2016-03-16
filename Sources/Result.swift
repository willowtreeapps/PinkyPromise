//
//  Result.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 3/16/16.
//  Copyright © 2016 WillowTree, Inc. All rights reserved.
//

import Foundation

enum Result<T> {

    typealias SuccessType = T

    case Failure(ErrorType)
    case Success(SuccessType)

    // Unwrap a success value or throw a failure value.
    func value() throws -> SuccessType {
        switch self {
        case .Failure(let error):
            throw error
        case .Success(let value):
            return value
        }
    }

    func map<U>(@noescape transform: (SuccessType) throws -> U) -> Result<U> {
        switch self {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let value):
            do {
                let transformedValue = try transform(value)
                return .Success(transformedValue)
            } catch {
                return .Failure(error)
            }
        }
    }

    func flatMap<U>(@noescape transform: (SuccessType) throws -> Result<U>) -> Result<U> {
        switch self {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let value):
            do {
                return try transform(value)
            } catch {
                return .Failure(error)
            }
        }
    }

}

func zip<A, B>(resultA: Result<A>, _ resultB: Result<B>) -> Result<(A, B)> {
    switch resultA {
    case .Failure(let error):
        return .Failure(error)
    case .Success(let a):
        switch resultB {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let b):
            return .Success(a, b)
        }
    }
}

func zip<A, B, C>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>) -> Result<(A, B, C)> {
    switch resultA {
    case .Failure(let error):
        return .Failure(error)
    case .Success(let a):
        switch zip(resultB, resultC) {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let b, let c):
            return .Success(a, b, c)
        }
    }
}

func zip<A, B, C, D>(resultA: Result<A>, _ resultB: Result<B>, _ resultC: Result<C>, _ resultD: Result<D>) -> Result<(A, B, C, D)> {
    switch resultA {
    case .Failure(let error):
        return .Failure(error)
    case .Success(let a):
        switch zip(resultB, resultC, resultD) {
        case .Failure(let error):
            return .Failure(error)
        case .Success(let b, let c, let d):
            return .Success(a, b, c, d)
        }
    }
}

func zipArray<T>(results: [Result<T>]) -> Result<[T]> {
    return results.reduce(.Success([])) { (arrayResult, itemResult) in
        return arrayResult.flatMap { array in
            switch itemResult {
            case .Failure(let error):
                return .Failure(error)
            case .Success(let item):
                return .Success(array + [item])
            }
        }
    }
}
