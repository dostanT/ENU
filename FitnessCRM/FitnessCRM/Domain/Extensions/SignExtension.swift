//
//  SignExtension.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 01.10.2026.
//


extension SignProtocol {
    func checkPassword(email: String, password: String) throws {
        guard email.contains("@") else {
            throw AppError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AppError.weakPassword
        }
    }
}
