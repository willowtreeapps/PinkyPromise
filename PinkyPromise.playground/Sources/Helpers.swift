import Foundation

public func delay(seconds: NSTimeInterval, block: () -> Void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, Int64(NSTimeInterval(NSEC_PER_SEC) * seconds)),
        dispatch_get_main_queue(),
        block)
}
