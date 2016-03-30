# PinkyPromise

A tiny Promises library.

## Summary

PinkyPromise is an experimental implementation of Promises for Swift. It consists of two types:

- `Result` - A value or error. `Result` adapts the return-or-throw function pattern for asynchronous operations with callbacks.
- `Promise` - An operation that produces a `Result` sometime after it is called. `Promise`s can be composed and sequenced.

PinkyPromise is meant to be a lightweight functional tool that does a lot of heavy lifting. A natural next step beyond these two types is an [Observable](https://www.youtube.com/watch?v=looJcaeboBY). You might use PinkyPromise a stepping stone on the way to learning [RxSwift](https://github.com/ReactiveX/RxSwift), which we recommend.

## Documentation

Please see `PinkyPromise.playground` for examples and insight.

## Project Roadmap

- Complete the documentation playground.
- CocoaPods? Carthage?
- More Promise transformations?
