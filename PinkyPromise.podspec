Pod::Spec.new do |s|
  s.name             = "PinkyPromise"
  s.version          = "0.6.0"
  s.summary          = "A tiny Promises library."
  s.description      = <<-DESC
                       PinkyPromise is a lightweight tool for coordinating asynchronous code.

                       It consists mainly of a Promise type, which represents a task,
                       and a Result type, which represents success or failure.
                       These are immutable values that can be transformed in functional style.

                       Result encodes the return-or-throw pattern common in synchronous code
                       such that asynchronous completion blocks can use that pattern,
                       with a much tighter contract than (AnyObject?, ErrorType?) -> Void.

                       Promise separates the events of creating an asynchronous operation with
                       arguments, and starting it with a completion block. Since it is a value,
                       you can add more steps by making composite Promises.

                       PinkyPromise is worth using if you don't want a complex framework
                       or if you're just getting started with functional patterns.
                       A suitable step up from PinkyPromise is RxSwift's Observables.
                       DESC
  s.homepage         = "https://github.com/willowtreeapps/PinkyPromise"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Kevin Conner" => "connerk@gmail.com" }
  s.social_media_url = "https://twitter.com/connerk"
  s.platforms        = { :ios => "8.0", :osx => "10.10", :tvos => "9.0" }
  s.source           = { :git => "https://github.com/willowtreeapps/PinkyPromise.git", :tag => s.version.to_s }
  s.source_files     = "Sources", "Sources/**/*.{swift}"
  s.swift_version    = "4.0"
end
