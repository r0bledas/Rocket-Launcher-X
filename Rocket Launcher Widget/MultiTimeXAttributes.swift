//
//  MultiTimeXAttributes.swift
//  Rocket Launcher Widget
//
//  Mirror of the ActivityKit attributes so the widget can render
//  the Live Activity for the MultiTimeX timer.
//

import Foundation
import ActivityKit

public struct MultiTimeXAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var endDate: Date
        public var percentComplete: Double
    }

    public init() {}
}



