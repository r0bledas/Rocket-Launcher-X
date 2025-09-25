//
//  WidgetSetupView.swift
//  Rocket Launcher
//
//  Created by Raudel Alejandro on 19-07-2025.
//

import SwiftUI

struct WidgetSetupView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Widget Setup Guide")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Learn how to add and configure Rocket Launcher widgets")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)
                    
                    // Step 1
                    SetupStepView(
                        number: "1",
                        title: "Add Widget to Home Screen",
                        description: "Long press on your home screen, tap the '+' button, and search for 'Rocket Launcher'",
                        icon: "plus.square"
                    )
                    
                    // Step 2
                    SetupStepView(
                        number: "2",
                        title: "Choose from Widget #1 to #5",
                        description: "Select any of the available widgets to add to your home screen.",
                        icon: "square.grid.2x2"
                    )
                    
                    // Step 3
                    SetupStepView(
                        number: "3",
                        title: "Configure Widget in App",
                        description: "Open Rocket Launcher and use the 'Configure Widget' and 'Widgets' buttons to customize appearance and app slots.",
                        icon: "slider.horizontal.3"
                    )
                    
                    // Step 4
                    SetupStepView(
                        number: "4",
                        title: "Enable Reduce Motion (Optional)",
                        description: "Go to Settings > Accessibility > Motion and turn on 'Reduce Motion' for the black screen effect",
                        icon: "accessibility"
                    )
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        TipView(
                            icon: "lightbulb",
                            text: "Widgets work best with 'Reduce Motion' enabled for the intended black screen effect"
                        )
                        
                        TipView(
                            icon: "bolt",
                            text: "Tap any app name in the widget to launch it instantly"
                        )
                        
                        TipView(
                            icon: "gear",
                            text: "You can have multiple widgets, each with its own set of apps"
                        )
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct SetupStepView: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.leading, 24)
            }
        }
    }
}

struct WidgetTypeCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct TipView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    WidgetSetupView()
} 