//
//  ContentView.swift
//  Time Watch App
//
//  Created by Raudel Alejandro on 07-02-2025.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var targetTime = Date()
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var initialTimeInterval: TimeInterval = 0
    @State private var currentTime = Date()
    @State private var isLowPowerMode = false
    @State private var showingCompletionAlert = false
    @State private var selectedHour = Calendar.current.component(.hour, from: Date())
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date())
    
    var progress: Double {
        guard initialTimeInterval > 0 else { return 0 }
        return 1 - (timeRemaining / initialTimeInterval)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isRunning {
                    VStack(spacing: 8) {
                        HStack {
                            Toggle("", isOn: $isLowPowerMode)
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                                .frame(width: 40)
                            Text("LPM")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 65, weight: .bold))
                            .foregroundColor(timeRemaining > 0 ? .white : .red)
                            .minimumScaleFactor(0.6)
                            .contentTransition(isLowPowerMode ? .identity : .numericText())
                            .animation(isLowPowerMode ? nil : .smooth, value: timeRemaining)
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
                                    .animation(isLowPowerMode ? nil : .smooth(duration: 0.3), value: progress)
                            }
                        }
                        .frame(height: 8)
                        .cornerRadius(4)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .contentTransition(isLowPowerMode ? .identity : .numericText())
                            .animation(isLowPowerMode ? nil : .smooth, value: progress)
                            .padding(.top, -2)
                        
                        HStack {
                            Spacer()
                            Text("Made by Ra-Rauw!")
                                .font(.system(size: 8))
                                .foregroundColor(.gray.opacity(0.7))
                            Spacer()
                        }
                        .padding(.top, -4)
                        
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            stopTimer()
                        }) {
                            Text("Stop")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .padding(.top, 0)
                    }
                    .padding()
                } else {
                    VStack {
                        Spacer()  // Add space at top
                        
                        VStack(spacing: 8) {
                            Text("Select target time")
                                .font(.system(size: 16))
                                .padding(.top, 45)
                            
                            HStack(spacing: 4) {
                                Picker("Hour", selection: $selectedHour) {
                                    ForEach(0..<24) { hour in
                                        Text(String(format: "%02d", hour))
                                            .tag(hour)
                                            .font(.system(size: 28, weight: .medium))
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70)
                                .frame(height: 90)
                                .clipped()
                                
                                Text(":")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Picker("Minute", selection: $selectedMinute) {
                                    ForEach(0..<60) { minute in
                                        Text(String(format: "%02d", minute))
                                            .tag(minute)
                                            .font(.system(size: 28, weight: .medium))
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70)
                                .frame(height: 90)
                                .clipped()
                            }
                            .padding(.top, -4)
                            .padding(.bottom, 10)
                            
                            Button(action: {
                                WKInterfaceDevice.current().play(.click)
                                startTimer()
                            }) {
                                Text("Start")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                            .padding(.bottom, 8)
                            
                            Text("Made by Ra-Rauw!")
                                .font(.system(size: 8))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.bottom, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        
                        Spacer()  // Keep this to push content up
                    }
                    .padding(.vertical, 8)  // Reduced vertical padding
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .alert("War is Over!", isPresented: $showingCompletionAlert) {
                Button("OK", role: .cancel) {
                    WKInterfaceDevice.current().play(.click)
                }
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
        // Create target time from selected hour and minute
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = selectedHour
        components.minute = selectedMinute
        targetTime = Calendar.current.date(from: components) ?? Date()
        
        // If target time is in the past, add 24 hours
        if targetTime < Date() {
            targetTime = Calendar.current.date(byAdding: .day, value: 1, to: targetTime) ?? Date()
        }
        
        timeRemaining = targetTime.timeIntervalSinceNow
        initialTimeInterval = timeRemaining
        isRunning = true
        currentTime = Date()
        
        let updateInterval = isLowPowerMode ? 1.0 : 0.1
        
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            if isLowPowerMode {
                timeRemaining = targetTime.timeIntervalSinceNow
                currentTime = Date()
                
                #if canImport(ActivityKit)
                LiveActivityManager.shared.updateActivity(timeRemaining: timeRemaining, progress: progress)
                #endif
                
                if timeRemaining <= 0 {
                    WKInterfaceDevice.current().play(.notification)
                    stopTimer()
                }
            } else {
                withAnimation {
                    timeRemaining = targetTime.timeIntervalSinceNow
                    currentTime = Date()
                    
                    #if canImport(ActivityKit)
                    LiveActivityManager.shared.updateActivity(timeRemaining: timeRemaining, progress: progress)
                    #endif
                    
                    if timeRemaining <= 0 {
                        WKInterfaceDevice.current().play(.notification)
                        stopTimer()
                    }
                }
            }
        }
        
        #if canImport(ActivityKit)
        LiveActivityManager.shared.startActivity(targetTime: targetTime, initialTimeRemaining: timeRemaining)
        #endif
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
        return formatter
    }()
}

#Preview {
    ContentView()
}
