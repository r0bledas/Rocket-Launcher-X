//
//  WidgetConfigurationView.swift
//  Rocket Launcher Widget
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import SwiftUI
import WidgetKit

struct WidgetConfigurationView: View {
    @State private var backgroundColor = "#242424"
    @State private var redComponent: Double = 36
    @State private var greenComponent: Double = 36
    @State private var blueComponent: Double = 36
    @State private var customHexInput = "#242424"
    
    // Debounce work item
    @State private var saveWorkItem: DispatchWorkItem?
    
    // App Group ID
    let appGroupID = "group.rocketlauncher"
    
    var body: some View {
        NavigationView {
            Form {
                // New Full Widget Preview Section
                Section(header: Text("Preview")) {
                    WidgetPreviewView(backgroundColor: backgroundColor)
                        .frame(height: 400) // Adjust height to fit content
                        .listRowInsets(EdgeInsets()) // Remove default padding
                }
                
                Section(header: Text("Background Color")) {
                    // RGB Sliders
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Red: \(Int(redComponent))")
                        Slider(value: $redComponent, in: 0...255, step: 1)
                            .accentColor(.red)
                            .onChange(of: redComponent) { _, _ in
                                updateHexFromRGB()
                                debouncedSave()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Green: \(Int(greenComponent))")
                        Slider(value: $greenComponent, in: 0...255, step: 1)
                            .accentColor(.green)
                            .onChange(of: greenComponent) { _, _ in
                                updateHexFromRGB()
                                debouncedSave()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blue: \(Int(blueComponent))")
                        Slider(value: $blueComponent, in: 0...255, step: 1)
                            .accentColor(.blue)
                            .onChange(of: blueComponent) { _, _ in
                                updateHexFromRGB()
                                debouncedSave()
                            }
                    }
                    
                    // Custom Hex Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Hex Color:")
                        HStack {
                            TextField("Enter hex color", text: $customHexInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: customHexInput) { _, newValue in
                                    if isValidHex(newValue) {
                                        backgroundColor = newValue
                                        updateRGBFromHex()
                                        debouncedSave()
                                    }
                                }
                            
                            Button("Force Refresh") {
                                if isValidHex(customHexInput) {
                                    backgroundColor = customHexInput
                                    updateRGBFromHex()
                                    saveSettings()
                                }
                            }
                            .disabled(!isValidHex(customHexInput))
                        }
                    }
                    
                    // Preset Button
                    Button("Set to #242424") {
                        backgroundColor = "#242424"
                        redComponent = 36
                        greenComponent = 36
                        blueComponent = 36
                        customHexInput = "#242424"
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Widget Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Force Refresh") {
                        saveSettings()
                    }
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        if let savedColor = userDefaults?.string(forKey: "WidgetBackgroundColor") {
            backgroundColor = savedColor
            customHexInput = savedColor
            updateRGBFromHex()
        }
    }
    
    private func saveSettings() {
        let userDefaults = UserDefaults(suiteName: appGroupID)
        userDefaults?.set(backgroundColor, forKey: "WidgetBackgroundColor")
        
        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()
        
        // Optional: Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func debouncedSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem {
            saveSettings()
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }
    
    private func updateHexFromRGB() {
        let hex = String(format: "#%02X%02X%02X", Int(redComponent), Int(greenComponent), Int(blueComponent))
        backgroundColor = hex
        customHexInput = hex
    }
    
    private func updateRGBFromHex() {
        let hex = backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        switch hex.count {
        case 3: // RGB (12-bit)
            redComponent = Double((int >> 8) * 17)
            greenComponent = Double((int >> 4 & 0xF) * 17)
            blueComponent = Double((int & 0xF) * 17)
        case 6: // RGB (24-bit)
            redComponent = Double(int >> 16)
            greenComponent = Double(int >> 8 & 0xFF)
            blueComponent = Double(int & 0xFF)
        default:
            redComponent = 36
            greenComponent = 36
            blueComponent = 36
        }
    }
    
    private func isValidHex(_ hex: String) -> Bool {
        let hexRegex = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        return hex.range(of: hexRegex, options: .regularExpression) != nil
    }
}

struct WidgetPreviewView: View {
    let backgroundColor: String
    
    var body: some View {
        ZStack {
            Color(hex: backgroundColor)
            
            VStack(spacing: 20) {
                // Top Section: Calendar
                HStack(alignment: .top) {
                    // Date Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("20")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Thursday, 20")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Text("November 20...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("324/365")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // Mini Calendar Grid
                    VStack(spacing: 4) {
                        // Header
                        HStack(spacing: 4) {
                            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 15)
                            }
                        }
                        
                        // Grid (Mock)
                        ForEach(0..<5) { row in
                            HStack(spacing: 4) {
                                ForEach(0..<7) { col in
                                    if row == 2 && col == 4 { // The "20th"
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 15, height: 15)
                                            .overlay(Text("20").font(.system(size: 8)).foregroundColor(.white))
                                    } else {
                                        Text("\(row * 7 + col + 1)")
                                            .font(.system(size: 8))
                                            .foregroundColor(.white.opacity(0.8))
                                            .frame(width: 15)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Bottom Section: Apps
                VStack(alignment: .leading, spacing: 12) {
                    PreviewAppRow(icon: "safari", name: "Safari", color: .blue)
                    PreviewAppRow(icon: "magnifyingglass", name: "Google", color: .green) // Approximate
                    PreviewAppRow(icon: "phone.circle.fill", name: "WhatsApp", color: .green)
                    PreviewAppRow(icon: "camera.fill", name: "Instagram", color: .purple) // Approximate
                    PreviewAppRow(icon: "music.note", name: "TikTok", color: .black) // Approximate
                    PreviewAppRow(icon: "play.rectangle.fill", name: "YouTube", color: .red)
                    PreviewAppRow(icon: "hifispeaker.fill", name: "Spotify", color: .green)
                    PreviewAppRow(icon: "sparkles", name: "Gemini", color: .blue)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
}

struct PreviewAppRow: View {
    let icon: String
    let name: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .foregroundColor(color)
                .background(Color.white)
                .cornerRadius(8)
            
            Text(name)
                .font(.system(size: 24, weight: .bold)) // Large text as per image
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    WidgetConfigurationView()
} 