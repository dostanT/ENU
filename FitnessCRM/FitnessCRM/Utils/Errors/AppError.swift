//
//  AppError.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 25.09.2026.
//

import Foundation

enum AppError: Error {
    case invalidEmail
    case weakPassword
    case notAuthenticated
    
    var text: String {
        switch self {
        case .invalidEmail:
            "Your email is incorrect"
        case .weakPassword:
            "Your password is so weak"
        case .notAuthenticated:
            "You are not authonteficated"
        }
    }
}
