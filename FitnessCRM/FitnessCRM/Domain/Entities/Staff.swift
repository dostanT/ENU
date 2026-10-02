//
//  Staff.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

struct Staff: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let authUserId: UUID?
    let fullName: String
    let role: UserRole
    let branchId: Int?
    let isActive: Bool
}