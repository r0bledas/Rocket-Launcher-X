import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
import WidgetKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            TimerActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    TimerExpandedView(context: context)
                }
            } compactLeading: {
                Text(timeString(from: context.state.timeRemaining))
                    .font(.system(size: 14, weight: .bold))
            } compactTrailing: {
                ProgressView(value: context.state.progress)
                    .tint(context.state.timeRemaining > 0 ? .green : .red)
            } minimal: {
                ProgressView(value: context.state.progress)
                    .tint(context.state.timeRemaining > 0 ? .green : .red)
            }
        }
        .supplementalActivityFamilies([.small]) // Add support for Smart Stack
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let absInterval = abs(timeInterval)
        let hours = Int(absInterval) / 3600
        let minutes = Int(absInterval) / 60 % 60
        let seconds = Int(absInterval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct TimerActivityView: View {
    @Environment(\.activityFamily) var activityFamily
    let context: ActivityViewContext<TimerAttributes>
    
    var body: some View {
        switch activityFamily {
        case .small: // Smart Stack view
            VStack {
                Text(timeString(from: context.state.timeRemaining))
                    .font(.system(size: 28, weight: .bold))
                ProgressView(value: context.state.progress)
                    .tint(context.state.timeRemaining > 0 ? .green : .red)
            }
            .padding()
        default: // Lock Screen view
            VStack {
                Text(timeString(from: context.state.timeRemaining))
                    .font(.system(size: 34, weight: .bold))
                
                Text("until \(timeFormatter.string(from: context.state.targetTime))")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                ProgressView(value: context.state.progress)
                    .tint(context.state.timeRemaining > 0 ? .green : .red)
                    .padding(.horizontal)
            }
            .padding()
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let absInterval = abs(timeInterval)
        let hours = Int(absInterval) / 3600
        let minutes = Int(absInterval) / 60 % 60
        let seconds = Int(absInterval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct TimerExpandedView: View {
    let context: ActivityViewContext<TimerAttributes>
    
    var body: some View {
        VStack {
            Text(timeString(from: context.state.timeRemaining))
                .font(.system(size: 28, weight: .bold))
            Text("until \(timeFormatter.string(from: context.state.targetTime))")
                .font(.caption)
                .foregroundColor(.gray)
            ProgressView(value: context.state.progress)
                .tint(context.state.timeRemaining > 0 ? .green : .red)
        }
        .padding()
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let absInterval = abs(timeInterval)
        let hours = Int(absInterval) / 3600
        let minutes = Int(absInterval) / 60 % 60
        let seconds = Int(absInterval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
#endif 