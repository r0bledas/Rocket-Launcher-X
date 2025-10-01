//
//  RocketLauncherLiveActivity.swift
//  Rocket Launcher Widget
//
//  Live Activity UI for the MultiTimeX timer.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct MultiTimeXLiveActivityView: View {
    let context: ActivityViewContext<MultiTimeXAttributes>

    private var timeRemaining: TimeInterval {
        max(0, context.state.endDate.timeIntervalSinceNow)
    }

    private var percent: Double {
        min(1.0, max(0.0, context.state.percentComplete))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(format(timeRemaining))
                    .font(.system(size: 34, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    ProgressView(value: percent)
                        .progressViewStyle(.linear)
                    Text("\(Int(percent * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
    }

    private func format(_ interval: TimeInterval) -> String {
        let absInterval = Int(max(0, interval))
        let hours = absInterval / 3600
        let minutes = (absInterval / 60) % 60
        let seconds = absInterval % 60
        if hours > 0 { return String(format: "%02d:%02d:%02d", hours, minutes, seconds) }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct MultiTimeXLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MultiTimeXAttributes.self) { context in
            MultiTimeXLiveActivityView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("MultiTimeX")
                        .font(.callout).bold()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatFull(max(0, context.state.endDate.timeIntervalSinceNow)))
                        .monospacedDigit()
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        ProgressView(value: min(1.0, max(0.0, context.state.percentComplete)))
                            .progressViewStyle(.linear)
                        Text("\(Int(min(1.0, max(0.0, context.state.percentComplete)) * 100))%")
                            .font(.footnote)
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                Text("⏱")
            } compactTrailing: {
                Text(formatShort(context.state.endDate.timeIntervalSinceNow))
                    .monospacedDigit()
            } minimal: {
                Text(formatShort(context.state.endDate.timeIntervalSinceNow))
                    .monospacedDigit()
            }
        }
    }

    private func formatFull(_ interval: TimeInterval) -> String {
        let absInterval = Int(max(0, interval))
        let hours = absInterval / 3600
        let minutes = (absInterval / 60) % 60
        let seconds = absInterval % 60
        if hours > 0 { return String(format: "%02d:%02d:%02d", hours, minutes, seconds) }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatShort(_ interval: TimeInterval) -> String {
        let s = Int(max(0, interval))
        let m = (s / 60) % 60
        let h = s / 3600
        if h > 0 { return String(format: "%dh", h) }
        if m > 0 { return String(format: "%dm", m) }
        return String(format: "%ds", s)
    }
}


