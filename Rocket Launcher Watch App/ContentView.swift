//
//  ContentView.swift
//  Rocket Launcher Watch App
//
//  Created by Raudel Alejandro on 06-09-2025.
//

import SwiftUI
import AuthenticationServices
import WatchKit

// MARK: - watchOS Compatible Activity Indicator
struct ActivityIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                .frame(width: 40, height: 40)
            
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0 // Default to Web Launcher

    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Web Launcher Page (main homepage)
            WebLauncherView()
                .tag(0)
            
            // MultiTimeX Timer Page
            MultiTimeXView()
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea(.all, edges: .all)
    }
}

// MARK: - Web Launcher View (Main Homepage)

struct WebLauncherView: View {
    @State private var searchText = ""
    @State private var showingTextInput = false
    @StateObject private var searchHistory = SearchHistoryManager()
    @State private var showingHistory = false
    @State private var isLoading = false // Add loading state
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
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
                                        VStack(spacing: 6) {
                                            Text("Recent")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary)
                                            
                                            Button(action: {
                                                withAnimation {
                                                    searchHistory.clearHistory()
                                                }
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(PlainButtonStyle())
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
                    .frame(minHeight: showingHistory ? nil : 200)
                }
                .scrollDisabled(!showingHistory)
                .navigationTitle("")
                .navigationBarHidden(true)
                
                // Fullscreen Loading Overlay
                if isLoading {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        // watchOS compatible loading indicator
                        ActivityIndicatorView()
                        
                        Text("Loading...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // MARK: - Native Text Input
    
    private func presentTextInputController() {
        WKInterfaceDevice.current().play(.click)
        
        // Add 0.5 second delay before showing loading overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = true
            }
        }
        
        // Use WKExtension's presentTextInputController for direct keyboard input
        WKExtension.shared().visibleInterfaceController?.presentTextInputController(
            withSuggestions: nil,
            allowedInputMode: .allowEmoji
        ) { result in
            if let resultArray = result,
               let textResult = resultArray.first as? String,
               !textResult.isEmpty {
                // Perform Google search directly with the input
                performGoogleSearchDirectly(with: textResult)
            } else {
                // Hide loading if user cancels or doesn't enter text
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLoading = false
                    }
                }
            }
        }
    }
    
    private func performGoogleSearchDirectly(with query: String) {
        // Loading overlay is already showing, so no need to show it again
        
        // Add to search history
        searchHistory.addSearch(query)
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "https://www.google.com/search?q=\(encodedQuery)"
        
        guard let websiteURL = URL(string: searchURL) else { 
            // Hide loading if URL is invalid
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
            }
            return 
        }
        
        let session = ASWebAuthenticationSession(url: websiteURL, callbackURLScheme: nil) { _, _ in
            // Hide loading overlay when session completes or fails
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isLoading = false
                }
            }
        }
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
    @State private var selectedDay = 0 // 0 for today, 1 for tomorrow
    
    var progress: Double {
        guard initialTimeInterval > 0 else { return 0 }
        return 1 - (timeRemaining / initialTimeInterval)
    }
    
    // Computed property to check if selected time is valid (in the future)
    private var isSelectedTimeValid: Bool {
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
            return adjustedTargetTime.timeIntervalSinceNow > 0
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isRunning {
                    // Running Timer UI
                    VStack(spacing: 8) {
                        Spacer()
                        
                        // Timer Display
                        VStack(spacing: 8) {
                            Text(timeString(from: timeRemaining))
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(timeRemaining > 0 ? .white : .red)
                                .minimumScaleFactor(0.6)
                                .contentTransition(.numericText())
                                .animation(.smooth, value: timeRemaining)
                            
                            Text("until \(timeFormatter.string(from: targetTime))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // Progress Bar
                            VStack(spacing: 4) {
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
                                .frame(height: 12)
                                .cornerRadius(6)
                                .frame(width: 140)
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 4)
                        }
                        
                        Spacer()
                        
                        // Stop Button
                        Button(action: {
                            stopTimer()
                            triggerHapticFeedback()
                        }) {
                            Text("Stop Timer")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    Capsule()
                                        .fill(LinearGradient(colors: [Color.red, Color.red.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                )
                                .shadow(color: .red.opacity(0.3), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                } else {
                    // MultiTimeX Setup UI (matching main app)
                    VStack(spacing: 8) { // Reduced from 12 to 8
                        // Title - Left aligned and positioned lower
                        HStack {
                            Text("MultiTimeX")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16) // Reduced from 24 to 16
                        
                        VStack(spacing: 8) { // Reduced from 12 to 8
                            // Day Selector - Using watchOS compatible approach
                            HStack(spacing: 8) {
                                Button(action: {
                                    selectedDay = 0
                                    triggerHapticFeedback()
                                }) {
                                    Text("Today")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(selectedDay == 0 ? .white : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(selectedDay == 0 ? Color.blue : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.blue, lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    selectedDay = 1
                                    triggerHapticFeedback()
                                }) {
                                    Text("Tomorrow")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(selectedDay == 1 ? .white : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 28)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(selectedDay == 1 ? Color.blue : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.blue, lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 16)
                            
                            // Target Time Picker - Custom implementation to avoid third wheel
                            VStack(spacing: 4) {
                                Text("Target Time (24h)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 8) {
                                    // Hours Picker (0-23)
                                    Picker("Hours", selection: Binding(
                                        get: { Calendar.current.component(.hour, from: targetTime) },
                                        set: { newHour in
                                            let components = Calendar.current.dateComponents([.year, .month, .day, .minute], from: targetTime)
                                            if let newDate = Calendar.current.date(from: DateComponents(
                                                year: components.year,
                                                month: components.month,
                                                day: components.day,
                                                hour: newHour,
                                                minute: components.minute
                                            )) {
                                                targetTime = newDate
                                            }
                                        }
                                    )) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            Text(String(format: "%02d", hour))
                                                .font(.system(size: 20, weight: .medium))
                                                .tag(hour)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 50, height: 80)
                                    .clipped()
                                    
                                    Text(":")
                                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    
                                    // Minutes Picker (0-59)
                                    Picker("Minutes", selection: Binding(
                                        get: { Calendar.current.component(.minute, from: targetTime) },
                                        set: { newMinute in
                                            let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: targetTime)
                                            if let newDate = Calendar.current.date(from: DateComponents(
                                                year: components.year,
                                                month: components.month,
                                                day: components.day,
                                                hour: components.hour,
                                                minute: newMinute
                                            )) {
                                                targetTime = newDate
                                            }
                                        }
                                    )) {
                                        ForEach(0..<60, id: \.self) { minute in
                                            Text(String(format: "%02d", minute))
                                                .font(.system(size: 20, weight: .medium))
                                                .tag(minute)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 50, height: 80)
                                    .clipped()
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Start Button with validation
                            Button(action: {
                                if isSelectedTimeValid {
                                    startTimer()
                                    triggerPositiveHapticFeedback()
                                } else {
                                    triggerNegativeHapticFeedback()
                                }
                            }) {
                                Text("Start Timer")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        Capsule()
                                            .fill(isSelectedTimeValid ?
                                                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom) :
                                                LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                            )
                                    )
                                    .shadow(
                                        color: isSelectedTimeValid ? .green.opacity(0.4) : .clear,
                                        radius: 3,
                                        x: 0,
                                        y: 1
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: isSelectedTimeValid)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!isSelectedTimeValid)
                            .padding(.horizontal, 16)
                        }
                        
                        Spacer()
                        
                        // Navigation Hint
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 7))
                            Text("Web")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.bottom, 12)
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
    
    // MARK: - MultiTimeX Timer Functions
    
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
                        
                        if timeRemaining <= 0 {
                            WKInterfaceDevice.current().play(.notification)
                            stopTimer()
                        }
                    }
                }
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
    
    private func triggerPositiveHapticFeedback() {
        WKInterfaceDevice.current().play(.success)
    }
    
    private func triggerNegativeHapticFeedback() {
        WKInterfaceDevice.current().play(.failure)
    }
}

#Preview {
    ContentView()
}
