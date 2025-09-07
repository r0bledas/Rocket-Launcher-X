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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Background Color")) {
                    // Color preview
                    HStack {
                        Text("Preview:")
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: backgroundColor))
                            .frame(width: 60, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    
                    // RGB Sliders
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Red: \(Int(redComponent))")
                        Slider(value: $redComponent, in: 0...255, step: 1)
                            .accentColor(.red)
                            .onChange(of: redComponent) { _, _ in
                                updateHexFromRGB()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Green: \(Int(greenComponent))")
                        Slider(value: $greenComponent, in: 0...255, step: 1)
                            .accentColor(.green)
                            .onChange(of: greenComponent) { _, _ in
                                updateHexFromRGB()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blue: \(Int(blueComponent))")
                        Slider(value: $blueComponent, in: 0...255, step: 1)
                            .accentColor(.blue)
                            .onChange(of: blueComponent) { _, _ in
                                updateHexFromRGB()
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
                                    }
                                }
                            
                            Button("Apply") {
                                if isValidHex(customHexInput) {
                                    backgroundColor = customHexInput
                                    updateRGBFromHex()
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
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Section(header: Text("Widget Preview")) {
                    // Widget preview
                    VStack {
                        Text("Widget Preview")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        // Small widget preview
                        VStack(spacing: 8) {
                            Image(systemName: "gear")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            
                            Text("Settings")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 120, height: 120)
                        .background(Color(hex: backgroundColor))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .navigationTitle("Widget Configuration")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            updateRGBFromHex()
        }
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

#Preview {
    WidgetConfigurationView()
} 