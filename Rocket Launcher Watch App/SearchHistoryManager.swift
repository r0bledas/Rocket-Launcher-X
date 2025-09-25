//
//  SearchHistoryManager.swift
//  Rocket Launcher Watch Watch App
//
//  Created by Raudel Alejandro on 06-09-2025.
//

import Foundation

class SearchHistoryManager: ObservableObject {
    @Published var recentSearches: [String] = []
    private let maxHistoryItems = 5
    private let historyKey = "SearchHistory"
    
    init() {
        loadHistory()
    }
    
    func addSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0 == trimmedQuery }
        
        // Add to beginning
        recentSearches.insert(trimmedQuery, at: 0)
        
        // Keep only max items
        if recentSearches.count > maxHistoryItems {
            recentSearches = Array(recentSearches.prefix(maxHistoryItems))
        }
        
        saveHistory()
    }
    
    func clearHistory() {
        recentSearches.removeAll()
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = history
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}