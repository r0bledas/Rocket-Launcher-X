//
//  ContentView.swift
//  MultiTimeX
//
//  Created by Raudel Alejandro on 07-02-2025.
//

import SwiftUI
import AudioToolbox

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    func startActivity(targetTime: Date, initialTimeRemaining: TimeInterval) {
        // Implement if needed for iOS Live Activities
    }
    
    func updateActivity(timeRemaining: TimeInterval, progress: Double) {
        // Implement if needed for iOS Live Activities
    }
    
    func stopActivity() {
        // Implement if needed for iOS Live Activities
    }
}

struct ContentView: View {
    @State private var targetTime = Date()
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var initialTimeInterval: TimeInterval = 0
    @State private var currentTime = Date()
    @State private var showingCompletionAlert = false
    @State private var selectedDay = 0 // 0 for today, 1 for tomorrow
    
    var progress: Double {
        guard initialTimeInterval > 0 else { return 0 }
        return 1 - (timeRemaining / initialTimeInterval)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isRunning {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 94, weight: .bold))
                            .foregroundColor(timeRemaining > 0 ? .white : .red)
                            .minimumScaleFactor(0.6)
                            .contentTransition(.numericText())
                            .animation(.smooth, value: timeRemaining)
                            .padding(.top, 5)
                        
                        Text("until \(timeFormatter.string(from: targetTime))")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding(.top, -8)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .foregroundColor(.gray.opacity(0.3))
                                
                                Rectangle()
                                    .foregroundColor(timeRemaining > 0 ? .green : .red)
                                    .frame(width: geometry.size.width * progress)
                                    .animation(.smooth(duration: 0.3), value: progress)
                            }
                        }
                        .frame(height: 8)
                        .cornerRadius(4)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .contentTransition(.numericText())
                            .animation(.smooth, value: progress)
                            .padding(.top, -2)
                        
                        Button(action: {
                            stopTimer()
                            triggerHapticFeedback()
                        }) {
                            Text("Stop Timer")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 25) {
                            Text("Select Target Time")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Picker("Day", selection: $selectedDay) {
                                Text("Today").tag(0)
                                Text("Tomorrow").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 40)
                            
                            DatePicker("Target Time",
                                     selection: $targetTime,
                                     displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                startTimer()
                                triggerHapticFeedback()
                            }) {
                                Text("Start Timer")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 20)
                        
                        Spacer()
                    }
                }
                Text("Made by Ra-Rauw!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .alert("Time's Up!", isPresented: $showingCompletionAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .onAppear {
            // Keep the timer update for internal use
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
    
    private func startTimer() {
        // Adjust target time based on selected day
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: targetTime)
        if selectedDay == 1 { // If tomorrow is selected
            if let today = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                let tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)
                components.year = tomorrowComponents.year
                components.month = tomorrowComponents.month
                components.day = tomorrowComponents.day
            }
        } else { // If today is selected
            let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.year = todayComponents.year
            components.month = todayComponents.month
            components.day = todayComponents.day
        }
        
        if let adjustedTargetTime = Calendar.current.date(from: components) {
            // Only start if the target time is in the future
            if adjustedTargetTime.timeIntervalSinceNow > 0 {
                targetTime = adjustedTargetTime
                timeRemaining = targetTime.timeIntervalSinceNow
                initialTimeInterval = timeRemaining
                isRunning = true
                currentTime = Date()
                
                let updateInterval = 0.1
                
                timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                    withAnimation {
                        timeRemaining = targetTime.timeIntervalSinceNow
                        currentTime = Date()
                        
                        #if canImport(ActivityKit)
                        LiveActivityManager.shared.updateActivity(timeRemaining: timeRemaining, progress: progress)
                        #endif
                        
                        if timeRemaining <= 0 {
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                            stopTimer()
                        }
                    }
                }
                
                #if canImport(ActivityKit)
                LiveActivityManager.shared.startActivity(targetTime: targetTime, initialTimeRemaining: timeRemaining)
                #endif
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        if timeRemaining <= 0 {
            showingCompletionAlert = true
        }
        
        #if canImport(ActivityKit)
        LiveActivityManager.shared.stopActivity()
        #endif
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let absInterval = abs(timeInterval)
        let hours = Int(absInterval) / 3600
        let minutes = Int(absInterval) / 60 % 60
        let seconds = Int(absInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter
    }()
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    ContentView()
}

