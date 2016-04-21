# PinkyPromise

A tiny Promises library.

## Summary

PinkyPromise is an implementation of [Promises](https://en.wikipedia.org/wiki/Futures_and_promises) for Swift. It consists of two types:

- `Result` - A value or error. `Result` adapts the return-or-throw function pattern for use with asynchronous callbacks.
- `Promise` - An operation that produces a `Result` sometime after it is called. `Promise`s can be composed and sequenced.

## Should I use this?

There are lots of promise libraries. PinkyPromise:

- Is lightweight
- Is tested
- Embraces the Swift language with airtight type system contracts and `throw` / `catch`
- Embraces functional style with immutable values and value transformations
- Is a great way for Objective-C programmers to learn functional style in Swift
- Is easy to extend with your own Promise transformations

PinkyPromise is meant to be a lightweight functional tool that's easy to learn but does a lot of heavy lifting. Fuller-featured implementations include [Result](https://github.com/antitypical/Result) and [PromiseKit](http://promisekit.org).

## Learning

We've written a playground to demonstrate the benefits and usage of PinkyPromise. Please clone the repository and open `PinkyPromise.playground` in Xcode.

A natural next step beyond Results and Promises is the [Observable](https://www.youtube.com/watch?v=looJcaeboBY) type. You might use PinkyPromise as a first step toward learning [RxSwift](https://github.com/ReactiveX/RxSwift), which we recommend.

## Installation

- With Cocoapods: `pod 'PinkyPromise'`
- Manually: Copy the files in the `Sources` folder into your project.

## Tests

We intend to keep PinkyPromise fully unit tested.

You can run tests in Xcode, or use `scan` from [Fastlane Tools](https://fastlane.tools).

## Roadmap

- Carthage?
- More Promise transformations?
- Swift 3?

## Contributing to PinkyPromise

Contributions are welcome. Please see the [Contributing guidelines](CONTRIBUTING.md).

PinkyPromise has adopted the code of conduct defined by the [Contributor Covenant](http://contributor-covenant.org), the same used by the [Swift language](https://swift.org) and countless other open source software teams.
