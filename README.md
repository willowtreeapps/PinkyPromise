# PinkyPromise

A tiny Promises library.

## Summary

PinkyPromise is an experimental implementation of Promises for Swift. It consists of two types:

- `Result` - A value or error. `Result` adapts the return-or-throw function pattern for asynchronous operations with callbacks.
- `Promise` - An operation that produces a `Result` sometime after it is called. `Promise`s can be composed and sequenced.

Please see `PinkyPromise.playground` for examples and insight.

PinkyPromise is meant to be a lightweight functional tool that does a lot of heavy lifting. A natural next step beyond these two types is an [Observable](https://www.youtube.com/watch?v=looJcaeboBY). You might use PinkyPromise as a stepping stone on the way to learning [RxSwift](https://github.com/ReactiveX/RxSwift), which we recommend.

## Installation

- With Cocoapods: `pod 'PinkyPromise'`
- Manually: Copy the files in the `Sources` folder into your project.

## Tests

We intend to keep PinkyPromise fully unit tested.

You can run tests in Xcode, or use `scan` from [Fastlane Tools](https://fastlane.tools).

## Project Roadmap

- Carthage?
- More Promise transformations?

## Contributing to PinkyPromise

Contributions are welcome. Please see the [Contributing guidelines](CONTRIBUTING.md).

PinkyPromise has adopted the code of conduct defined by the [Contributor Covenant](http://contributor-covenant.org), the same used by the [Swift language](https://swift.org) and countless other open source software teams.
