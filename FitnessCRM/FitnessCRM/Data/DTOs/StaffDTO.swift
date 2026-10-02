//
//  StaffDTO.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

struct StaffDTO: Decodable, Sendable {
    let id: UUID
    let authUserId: UUID?
    let fullName: String
    let role: UserRole
    let branchId: Int?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case fullName = "full_name"
        case role
        case branchId = "branch_id"
        case isActive = "is_active"
    }

    func toDomain() -> Staff {
        Staff(
            id: id,
            authUserId: authUserId,
            fullName: fullName,
            role: role,
            branchId: branchId,
            isActive: isActive
        )
    }
}