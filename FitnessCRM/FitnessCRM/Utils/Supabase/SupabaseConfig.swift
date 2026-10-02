//
//  SupabaseConfig.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

enum SupabaseConfig {
    static var url: String {
        guard let value = Bundle.main.infoDictionary?["SupabaseURL"] as? String else {
            fatalError("SupabaseURL not found in Info.plist")
        }
        return value
    }

    static var publishableKey: String {
        guard let value = Bundle.main.infoDictionary?["SupabasePublishableKey"] as? String else {
            fatalError("SupabasePublishableKey not found in Info.plist")
        }
        return value
    }
}