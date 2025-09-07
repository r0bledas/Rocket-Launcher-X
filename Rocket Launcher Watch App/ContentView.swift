//
//  ContentView.swift
//  Rocket Launcher Watch Watch App
//
//  Created by Raudel Alejandro on 06-09-2025.
//

import SwiftUI
import AuthenticationServices
import WatchKit

struct ContentView: View {
    @State private var selectedTab = 0 // Default to Web Launcher page
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Web Launcher Page (main homepage)
            WebLauncherView()
                .tag(0)
            
            // MultiTimeX Timer Page (swipe right to access)
            MultiTimeXView()
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

// MARK: - Web Launcher View (Main Homepage)

struct WebLauncherView: View {
    @State private var searchText = ""
    @State private var showingTextInput = false
    @StateObject private var searchHistory = SearchHistoryManager()
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    // Title with better styling
                    Text("Web Launcher")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Main Search Button with improved design
                    Button(action: {
                        presentTextInputController()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                            Text("Search Google")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(22)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                
                Spacer(minLength: 16)
                
                // Content Section
                VStack(spacing: 12) {
                    // History Toggle Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingHistory.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showingHistory ? "clock.fill" : "clock")
                                .font(.system(size: 12))
                            Text("History")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Search History Section
                    if showingHistory {
                        VStack(spacing: 8) {
                            if !searchHistory.recentSearches.isEmpty {
                                HStack {
                                    Text("Recent")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Clear") {
                                        withAnimation {
                                            searchHistory.clearHistory()
                                        }
                                    }
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                                }
                                
                                LazyVStack(spacing: 4) {
                                    ForEach(searchHistory.recentSearches.prefix(3), id: \.self) { search in
                                        Button(search) {
                                            performGoogleSearchDirectly(with: search)
                                            withAnimation {
                                                showingHistory = false
                                            }
                                        }
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(white: 0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            } else {
                                Text("No recent searches")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Navigation Hint
                HStack(spacing: 4) {
                    Text("Timer")
                        .font(.system(size: 10, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 16)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Native Text Input
    
    private func presentTextInputController() {
        WKInterfaceDevice.current().play(.click)
        
        // Use WKExtension's presentTextInputController for native watchOS keyboard
        WKExtension.shared().visibleInterfaceController?.presentTextInputController(
            withSuggestions: ["weather", "news", "restaurants", "directions"],
            allowedInputMode: .allowEmoji
        ) { result in
            if let resultArray = result,
               let textResult = resultArray.first as? String,
               !textResult.isEmpty {
                // Perform Google search directly with the input
                performGoogleSearchDirectly(with: textResult)
            }
        }
    }
    
    private func performGoogleSearchDirectly(with query: String) {
        // Add to search history
        searchHistory.addSearch(query)
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "https://www.google.com/search?q=\(encodedQuery)"
        
        guard let websiteURL = URL(string: searchURL) else { return }
        
        let session = ASWebAuthenticationSession(url: websiteURL, callbackURLScheme: nil) { _, _ in }
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }
}

// MARK: - MultiTimeX Timer View

struct MultiTimeXView: View {
    @State private var targetTime = Date()
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var initialTimeInterval: TimeInterval = 0
    @State private var currentTime = Date()
    @State private var showingCompletionAlert = false
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    
    var progress: Double {
        guard initialTimeInterval > 0 else { return 0 }
        return 1 - (timeRemaining / initialTimeInterval)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isRunning {
                    // Running Timer UI
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Timer Display
                        VStack(spacing: 12) {
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(timeRemaining > 0 ? .white : .red)
                                .minimumScaleFactor(0.7)
                                .contentTransition(.numericText())
                                .animation(.smooth, value: timeRemaining)
                            
                            Text("until \(timeFormatter.string(from: targetTime))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // Progress Ring
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: progress)
                                    .stroke(
                                        timeRemaining > 0 ? 
                                        LinearGradient(colors: [.green, .blue], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom),
                                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                    )
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.smooth(duration: 0.3), value: progress)
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Stop Button
                        Button(action: {
                            stopTimer()
                            triggerHapticFeedback()
                        }) {
                            Text("Stop Timer")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .cornerRadius(22)
                                .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                } else {
                    // Modern Timer Setup UI - Complete Redesign
                    ScrollView {
                        VStack(spacing: 12) {
                            // Title
                            Text("Timer")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            // Selected Time Display (Prominent)
                            Text(formatSelectedTime())
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            
                            // Time Selector Wheels Section
                            VStack(spacing: 6) {
                                HStack(spacing: 12) {
                                    // Hours Wheel
                                    VStack(spacing: 4) {
                                        Picker("", selection: $selectedHours) {
                                            ForEach(0..<24, id: \.self) { hour in
                                                Text("\(hour)")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .tag(hour)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 45, height: 70)
                                        .clipped()
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                        
                                        Text("Hours")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Minutes Wheel
                                    VStack(spacing: 4) {
                                        Picker("", selection: $selectedMinutes) {
                                            ForEach(0..<60, id: \.self) { minute in
                                                Text("\(minute)")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .tag(minute)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 45, height: 70)
                                        .clipped()
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                        
                                        Text("Minutes")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Seconds Wheel
                                    VStack(spacing: 4) {
                                        Picker("", selection: $selectedSeconds) {
                                            ForEach(0..<60, id: \.self) { second in
                                                Text("\(second)")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                    .tag(second)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(width: 45, height: 70)
                                        .clipped()
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.gray.opacity(0.1))
                                        )
                                        
                                        Text("Seconds")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            
                            // Preset Buttons Section
                            VStack(spacing: 6) {
                                Text("Quick Set")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 12) {
                                    ForEach([
                                        (title: "5m", minutes: 5),
                                        (title: "10m", minutes: 10),
                                        (title: "15m", minutes: 15)
                                    ], id: \.title) { preset in
                                        Button(preset.title) {
                                            setPresetTime(minutes: preset.minutes)
                                            triggerHapticFeedback()
                                        }
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 35, height: 35)
                                        .background(
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                                )
                                        )
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            
                            // Large Start Button
                            Button(action: {
                                startTimerWithCustomTime()
                                triggerHapticFeedback()
                            }) {
                                Text("Start")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        Capsule()
                                            .fill(
                                                totalTimeInSeconds > 0 ? 
                                                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                                LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                            )
                                    )
                                    .shadow(
                                        color: totalTimeInSeconds > 0 ? .green.opacity(0.4) : .clear,
                                        radius: 6,
                                        x: 0,
                                        y: 2
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(totalTimeInSeconds == 0)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                            
                            // Navigation Hint
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 7))
                                Text("Web")
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Time's Up!", isPresented: $showingCompletionAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
    
    // Computed property for total time validation
    private var totalTimeInSeconds: Int {
        selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        
        if timeRemaining <= 0 {
            showingCompletionAlert = true
        }
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
        WKInterfaceDevice.current().play(.click)
    }
    
    private func formatSelectedTime() -> String {
        String(format: "%02d:%02d:%02d", selectedHours, selectedMinutes, selectedSeconds)
    }
    
    private func setPresetTime(minutes: Int) {
        let totalSeconds = minutes * 60
        selectedHours = totalSeconds / 3600
        selectedMinutes = (totalSeconds % 3600) / 60
        selectedSeconds = totalSeconds % 60
    }
    
    private func startTimerWithCustomTime() {
        let totalSeconds = selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds
        if totalSeconds > 0 {
            targetTime = Date().addingTimeInterval(Double(totalSeconds))
            timeRemaining = targetTime.timeIntervalSinceNow
            initialTimeInterval = timeRemaining
            isRunning = true
            
            let updateInterval = 0.1
            
            timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
                withAnimation {
                    timeRemaining = targetTime.timeIntervalSinceNow
                    currentTime = Date()
                    
                    if timeRemaining <= 0 {
                        WKInterfaceDevice.current().play(.notification)
                        stopTimer()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
