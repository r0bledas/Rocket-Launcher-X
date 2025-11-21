//
//  Rocket_Launcher_Watch_App_Extension.swift
//  Rocket Launcher Watch App Extension
//
//  Created by Raudel Alejandro on 21-11-2025.
//

import AppIntents

struct Rocket_Launcher_Watch_App_Extension: AppIntent {
    static var title: LocalizedStringResource { "Rocket Launcher Watch App Extension" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
