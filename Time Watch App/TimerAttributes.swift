import SwiftUI
#if canImport(ActivityKit)
import ActivityKit

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var progress: Double
        var targetTime: Date
    }
    
    var timerName: String
}
#endif 