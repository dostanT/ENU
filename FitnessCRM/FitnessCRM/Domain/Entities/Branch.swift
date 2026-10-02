//
//  Branch.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

struct Branch: Identifiable, Codable, Sendable, Hashable {
    let id: Int
    let code: String        // "01", "02", "03"
    let name: String        // "Филиал на Абая"
    let address: String?
}