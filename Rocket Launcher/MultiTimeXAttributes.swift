//
//  MultiTimeXAttributes.swift
//  Rocket Launcher
//
//  Defines the Live Activity attributes used by the app when starting/stopping
//  the MultiTimeX timer. This type must also exist in the widget extension.
//

import Foundation
import ActivityKit

public struct MultiTimeXAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var endDate: Date
        public var percentComplete: Double
    }

    // Static attributes if needed later (empty for now)
    public init() {}
}



