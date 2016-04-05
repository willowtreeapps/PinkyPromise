/*:
 [<< Result](@previous) • [Index](Index)

 # Promise
 
 PinkyPromise's `Promise` type represents an asynchronous operation that produces a value or an error after you start it.

 You start a `Promise<T>` by passing a completion block to the `call` method. When the work completes, it returns the value or error to the completion block as a `Result<T>`.

 There are lots of implementations of Promises out there. This one is intended to be lightweight and hip to the best parts of Swift.

 > Promises will make more sense if you understand [Results](Result) first.

 */

import Foundation
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
let someError = NSError(domain: "ExampleDomain", code: 101, userInfo: nil)

//: Here are some simplistic Promises. When you use the `call` method, they will complete with their given value.

let trivialSuccess: Promise<String> = Promise(value: "8675309")
let trivialFailure: Promise<String> = Promise(error: someError)
let trivialResult: Promise<String> = Promise(result: .Success("Hello, world"))

trivialSuccess.call { result in
    print(result)
}

/*:
 ## Asynchronous operations

 Most of the time you want a Promise to run an asynchronous operation that can succeed or fail.
 
 The usual asynchronous operation pattern on iOS is a function that takes arguments and a completion block, then begins the work. The completion block will receive an optional value and an optional error when the work completes.
 */

func getStringWithArgument(argument: String, completion: ((String?, ErrorType?) -> Void)?) {
    delay(1.0) {
        let value = "Completing: \(argument)"
        completion?(value, nil)
    }
}

getStringWithArgument("foo") { value, error in
    if let value = value {
        print(value)
    } else {
        print(error)
    }
}

/*:
 This is a loose contract not guaranteed by the compiler. We have only assumed that `error` is not nil when `value` is nil. Here's how you'd write that operation as a Promise, with a tighter contract.
 
 To make a new Promise, you create it with a task. A task is a block that itself has a completion block, usually called `fulfill`. The Promise runs the task to do its work, and when it's done, the task passes a `Result` to `fulfill`. Results must be a success or failure.
 */

func getStringPromiseWithAgument(argument: String) -> Promise<String> {
    return Promise { fulfill in
        delay(2.0) {
            let value = "Completing: \(argument)"
            fulfill(.Success(value))
        }
    }
}

let stringPromise = getStringPromiseWithAgument("bar")

/*:
 `stringPromise` has captured its task, and the task has captured the argument. It is an operation waiting to begin. So with Promises you can create operations and then start them later. You can start them more than once, or not at all.
 
 Next, we ask `stringPromise` to run by passing a completion block to the `call` method. `call` runs the task and routes the Result back to the completion block. When the Promise completes, our completion block will receive the Result.
*/

stringPromise.call { result in
    do {
        print(try result.value())
    } catch {
        print(error)
    }
}

/*:
 As we've seen, with Promises, supplying the arguments and supplying the completion block are separate events. The greatest strength of a Promise is that in between those two events, the Promise is a value.

 ## Value transformations

 Just like `Result` values, we can transform `Promise` values in useful ways:
 
 - `zip` to combine many Promises into one Promise that produces a tuple or array.
 - `map` to transform a produced success value. (`Promise` is a functor.)
 - `flatMap` to transform a produced success value by running a whole new Promise that can succeed or fail. (`Promise` is a monad.)
 - `recover` to handle a failure by running another Promise that might succeed.
 - `retry` to repeat the Promise until it's successful, or until a failure count is reached.
 - `background` to run a Promise in the background, then complete on the main queue.
 - `success` to add a step to perform only when successful.
 - `failure` to add a step to perform only when failing.
 
 > Remember that a `Promise` value is an operation that hasn't been started yet and that can produce a value or error. We are transforming operations that haven't been started into other operations that we can start instead.
 */

let intPromise = stringPromise.map { Int($0) }

let stringAndIntPromise = zip(stringPromise, intPromise)

let twoStepPromise = stringPromise.flatMap { string in
    getStringPromiseWithAgument("\(string) baz")
}

let multipleOfTwoPromise = Promise<Int> { fulfill in
    let number = Int(arc4random_uniform(100))
    if number % 2 == 0 {
        fulfill(.Success(number))
    } else {
        fulfill(.Failure(someError))
    }
}

let complexPromise =
    zip(
        multipleOfTwoPromise.recover { _ in
            return Promise(value: 2)
        },
        getStringPromiseWithAgument("computed in the background")
            .background()
            .map { "\($0) then extended on the main queue" }
    )
    .retry(3)
    .success { int, string in
        print("Complex promise succeeded. Multiple of two: \(int), string: \(string)")
    }
    .failure { error in
        print("Complex promise failed: \(error)")
    }

/*:
 Each of these transformations produced a new Promise but did not start it.
 
 When we transformed Results, the transformation always used the success or failure value of the first Result to produce the new Result. Transforming a Promise dosen't mean running it right away to get its Result. It means creating a second Promise that runs the first Promise as part of its own task.

 That means that all those nested calls that produced `complexPromise` haven't done any work. They've just described one big task to be done. Next we'll call that Promise and see what it produces.
 
 > If you thought this last Promise was complicated, imagine writing it with nested completion blocks! Because Promises are composable, transformable values, we can rely on transformations and just write one completion block.
*/

complexPromise.call { result in
    do {
        print(try result.value())
    } catch {
        print(error)
    }

    XCPlaygroundPage.currentPage.finishExecution()
}

//: [<< Result](@previous) • [Index](Index)
