/*:
 [<< Result](@previous) • [Index](Index)

 # Promise
 
 PinkyPromise's `Promise` type represents an asynchronous operation that produces a value or an error after you start it.

 You start a `Promise<T>` by passing a completion block to the `call` method. When the work completes, it returns the value or error to the completion block as a `Result<T>`.

 There are lots of implementations of Promises out there. This one is intended to be lightweight and hip to the best parts of Swift.

 > Promises will make more sense if you understand [Results](Result) first.

 */

import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

struct ExampleError: Error {}
let someError = ExampleError()

//: Here are some simplistic Promises. When you use the `call` method, they will complete with their given value.

let trivialSuccess: Promise<String> = Promise(value: "8675309")
let trivialFailure: Promise<String> = Promise(error: someError)
let trivialResult: Promise<String> = Promise(result: Result { "Hello, world" })

trivialSuccess.call { result in
    print(result)
}

/*:
 If you have a returning-or-throwing function, you can wrap it in a Promise.
 The promise will run the function and return its success or failure value.
 */

func dashedLine() throws -> String {
    let width = Int(arc4random_uniform(20)) - 10
    guard 0 <= width else {
        throw someError
    }
    return Array(repeating: "-", count: width).joined(separator: "")
}

let dashedLinePromise = Promise.lift(dashedLine)

/*:
 ## Asynchronous operations

 Most of the time you want a Promise to run an asynchronous operation that can succeed or fail.
 
 The usual asynchronous operation pattern on iOS is a function that takes arguments and a completion block, then begins the work. The completion block will receive an optional value and an optional error when the work completes.
 */

func getString(withArgument argument: String, completion: ((String?, Error?) -> Void)?) {
    delay(interval: .seconds(1)) {
        let value = "Completing: \(argument)"
        completion?(value, nil)
    }
}

getString(withArgument: "foo") { value, error in
    if let value = value {
        print(value)
    } else {
        print(String(describing: error))
    }
}

/*:
 This is a loose contract not guaranteed by the compiler. We have only assumed that `error` is not nil when `value` is nil. Here's how you'd write that operation as a Promise, with a tighter contract.
 
 To make a new Promise, you create it with a task. A task is a block that itself has a completion block, usually called `fulfill`. The Promise runs the task to do its work, and when it's done, the task passes a `Result` to `fulfill`. Results must be a success or failure.
 */

func getStringPromise(withArgument argument: String) -> Promise<String> {
    return Promise { fulfill in
        delay(interval: .seconds(2)) {
            let value = "Completing: \(argument)"
            fulfill(Result { value })
        }
    }
}

let stringPromise = getStringPromise(withArgument: "bar")

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
 - `inBackground` to run a Promise in the background, then complete on the main queue.
 - `inDispatchGroup` to run a Promise as a task in a GCD dispatch group.
 - `onResult` to add a step to perform without modifying the result.
 - `onSuccess` to add a step to perform only when successful.
 - `onFailure` to add a step to perform only when failing.

 > Remember that a `Promise` value is an operation that hasn't been started yet and that can produce a value or error. We are transforming operations that haven't been started into other operations that we can start instead.
 */

let intPromise = stringPromise.map { Int($0) }

let stringAndIntPromise = zip(stringPromise, intPromise)

let twoStepPromise = stringPromise.flatMap { string in
    getStringPromise(withArgument: "\(string) baz")
}

let multipleOfTwoPromise = Promise<Int> { fulfill in
    let number = Int(arc4random_uniform(100))
    fulfill(Result {
        if number % 2 == 0 {
            return number
        } else {
            throw someError
        }
    })
}

let complexPromise =
    zip(
        multipleOfTwoPromise.recover { _ in
            return Promise(value: 2)
        },
        getStringPromise(withArgument: "computed in the background")
            .inBackground()
            .map { "\($0) then extended on the main queue" }
    )
    .retry(attemptCount: 3)
    .onResult { result in
        print("Complex promise produced success or failure: \(result)")
    }
    .onSuccess { int, string in
        print("Complex promise succeeded. Multiple of two: \(int), string: \(string)")
    }
    .onFailure { error in
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
}

/*:
 ## PromiseQueue

 Promises of the same type can be run one at a time in a queue.
 */

let stringQueue = PromiseQueue<String>()

//: Use `enqueue` instead of `call` to add promises one at a time and run them immediately.
stringPromise.enqueue(in: stringQueue)
twoStepPromise.enqueue(in: stringQueue)

//: A queue can also make a batch promise that enqueues many promises and returns when the last has finished.
let batchPromise = stringQueue.batch(promises: [stringPromise, twoStepPromise])

batchPromise.call { result in
    print("Batch produced successes or failure: \(result)")

    PlaygroundPage.current.finishExecution()
}

//: [<< Result](@previous) • [Index](Index)
