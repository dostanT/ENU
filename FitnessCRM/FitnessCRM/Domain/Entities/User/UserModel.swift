//
//  UserModel.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//

import Foundation



struct UserModel: Identifiable, Codable {
    let id: Int
    let name: UserName
    let dateOfBirth: UserDateOfBitrh
    let role: UserRole
}
