import Foundation
#if canImport(ActivityKit)
import ActivityKit

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<TimerAttributes>?
    
    func startActivity(targetTime: Date, initialTimeRemaining: TimeInterval) {
        let attributes = TimerAttributes(timerName: "Timer")
        let state = TimerAttributes.ContentState(
            timeRemaining: initialTimeRemaining,
            progress: 0.0,
            targetTime: targetTime
        )
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
        } catch {
            print("Error starting live activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(timeRemaining: TimeInterval, progress: Double) {
        Task {
            let state = TimerAttributes.ContentState(
                timeRemaining: timeRemaining,
                progress: progress,
                targetTime: activity?.attributes.targetTime ?? Date()
            )
            
            await activity?.update(using: state)
        }
    }
    
    func stopActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
            activity = nil
        }
    }
}
#endif 