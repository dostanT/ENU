//
//  SignUpUseCase.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 01.10.2026.
//
import Foundation

struct SignUpUseCase: Sendable, SignProtocol {
    private let authRepository: AuthProtocol

    init(authRepository: AuthProtocol) {
        self.authRepository = authRepository
    }

    func execute(email: String, password: String) async throws {
        try checkPassword(email: email, password: password)
        try await authRepository.signUp(email: email, password: password)
    }
}
