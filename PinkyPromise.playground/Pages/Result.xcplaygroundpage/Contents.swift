/*:
 [Index](Index) • [Promise >>](@next)

 # Result

 PinkyPromise's `Result` type represents, in one value, the concept of a returned value or a thrown error. `Result` makes success and failure handling code easy to write. In particular, it forms a tight contract between an asynchronous operation and its completion callback. `Result` is based on the Either type from functional languages and the Result type from the [Result framework](https://github.com/antitypical/Result).
 */

import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

struct ExampleError: Error {}
let someError = ExampleError()

//: First, here are some values that a Result can be. Note that for each `Result<T>`, you can have either a value of `T` or an error.

let successfulString: Result<String> = .success("Hello, world")
let failedString:     Result<String> = .failure(someError)

let successfulVoid: Result<Void> = .success()
let failedVoid:     Result<Void> = .failure(someError)

//: You can `switch` to handle both cases.

switch successfulString {
case .success(let value):
    print("Success case: \(value)")
case .failure(let error):
    print("Failure case: \(error)")
}

print()

/*:
 > Look at the Debug console to see what's printed.
 
 But it's even more Swifty to use the return-and-throw pattern to create Results and read their values and errors.
 You can use a special initializer to create a Result with a returning-or-throwing function. Then you can call `value`, which returns the value or throws the error.

 Here we create two Results and then print their values, without ever writing enum cases or switch statements.
 */

let successfulIntArray = Result { [1, 2, 3, 4] }
let failedIntArray = Result<[Int]> { throw someError }

do {
    print(try successfulIntArray.value())
} catch {
    print(error)
}

do {
    print(try failedIntArray.value())
} catch {
    print(error)
}

print()

/*:
 With this initializer and the `value` function, our code is simple and compact. Creating a Result encodes a returned value or thrown error, and then `value` can return or throw in a new context.
 
 > `init(create:)` and `value` are like other frameworks' `materialize` and `dematerialize`.
 */

print(successfulString)
print(successfulVoid)

print(failedString)
print(failedVoid)

print()

/*:
 ## Value transformations

 A Result can be transformed in useful ways:

 - `zip` to combine many Results into one Result of a tuple or array.
 - `map` to transform successful values by returning values. (`Result` is a functor.)
 - `flatMap` to transform successful values by returning success or failure results. (`Result` is a monad.)
 - `tryMap` to transform successful values by returning values or throwing errors.
 */

let stringAndIntArray = zip(successfulString, successfulIntArray)

let stringLength = successfulString.map { $0.lengthOfBytes(using: .utf8) }

let sumOfIntsAsString = successfulIntArray.map { intArray in
    intArray.reduce(0, +)
}.map { sum in
    "The sum is: \(sum)"
}

let firstInt: Result<Int> = successfulIntArray.flatMap { intArray in
    return Result {
        if let first = intArray.first {
            return first
        } else {
            throw someError
        }
    }
}

let dataInFile = successfulString.tryMap { path in
    try NSData(contentsOfFile: path, options: [])
}

print(stringAndIntArray)
print(stringLength)
print(sumOfIntsAsString)
print(firstInt)
print(dataInFile)

print()

/*:
 > All these transformations pass the first failure all the way to the end. This is just like any thrown error in a set of `try`s will go to the `catch` without doing any work in between. It's also just like Swift's optional chaining skips to the end upon finding any `nil`. In fact, `Optional` is just like `Result` when you don't care what the error is.

 ## How `Result` improves asynchronous code

 Asynchronous operations in iOS code often expect completion blocks. Those completion blocks communicate a success value or a failure. Such a block might be of type `(T?, ErrorType?) -> Void`. Both arguments are optional, because only one or the other is expected. But this is a loose contract. It requires that we unwrap both optional arguments. It also leads us to assume that exactly one argument is `nil`, rather than checking. The compiler will check that the values passed back are the right types, but it won't check anything else. If your project contains a lot of completion blocks for lots of asynchronous operations, your project may contain a lot of error-prone boilerplate.

 Synchronous operations (regular function calls) can avoid this problem because they have two ways to produce a value: `return` and `throw`. The Swifty thing to do is for a failable function to either return its value or throw an error. No optionals are involved, and only one or the other case will happen. Writing code to handle both cases is straightforward. This is a nice strict contract, but it doesn't solve our problem for asynchronous operations. You can only throw errors up the call stack, not down into a completion block.

 `Result<T>` is an `enum` with two cases: `.Success(T)` and `.Failure(ErrorType)`. These are the same two cases as above, but they are expressed in a single value that can be sent back to a completion block. Instead of a completion block type of `(T?, ErrorType?) -> Void`, you can use `(Result<T>) -> Void`. There are no optionals to unwrap, no possibility of getting both or neither, and the compiler will still require you to handle both cases.

 Let's use `Result` in an asynchronous context with a completion block, where `throw` can't be used to return an error. Here, our function is like a network request function, and our completion block neatly handles two cases.
 */

func getJSONAndParseValue(completion: ((Result<Int>) -> Void)?) {
    delay(interval: .seconds(3)) {
        // Suppose we did a network request to get this response body from an API.
        let jsonStringResult = Result { "{ \"key\": 101 }" }

        let parsedValueResult: Result<Int> = jsonStringResult.tryMap { jsonString in
            // Interpret the response body as JSON.

            // Fail if the string wasn't encodable in UTF-8.
            guard let data = jsonString.data(using: .utf8) else {
                throw someError
            }

            // Fail if the data isn't valid JSON.
            return try JSONSerialization.jsonObject(with: data, options: [])
        }.tryMap { (jsonValue: Any) in
            // Parse the expected value from JSON.

            // Fail if it's not the right format.
            guard let dictionary = jsonValue as? NSDictionary, let value = dictionary["key"] as? Int else {
                throw someError
            }

            return value
        }

        completion?(parsedValueResult)
    }
}

print("Asynchronous operation starting.")
getJSONAndParseValue { result in
    print("Asynchronous operation completed:")
    do {
        print(try result.value())
    } catch {
        print(error)
    }

    PlaygroundPage.current.finishExecution()
}

//: Even though the asynchronous operation can't `throw` an error into the completion block, it can `throw` to construct a failing Result. We can also `catch` to handle that same failure. By precisely describing what it means to throw an error, `Result<T>` lets us work cleanly across asynchronous boundaries.

//: [Index](Index) • [Promise >>](@next)
