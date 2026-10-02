//
//  SignInUseCase.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

struct SignInUseCase: Sendable, SignProtocol {
    private let authRepository: AuthProtocol

    init(authRepository: AuthProtocol) {
        self.authRepository = authRepository
    }

    func execute(email: String, password: String) async throws {
        try checkPassword(email: email, password: password)
        try await authRepository.signIn(email: email, password: password)
    }
}
