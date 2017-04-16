import Foundation

public func delay(interval: DispatchTimeInterval, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + interval, execute: block)
}
