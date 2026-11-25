import Synchronization
import Foundation

final class DateProviderStub: Sendable {
    private let current: Mutex<Date>
    
    init(now: Date = Date(timeIntervalSince1970: 0)) {
        current = Mutex(now)
    }
    
    var now: Date {
        current.withLock { $0 }
    }
    
    func advance(by seconds: TimeInterval) {
        current.withLock { $0 += seconds }
    }
}
