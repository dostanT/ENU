//
//
//  SignInUseCase.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

struct SignOutUseCase: Sendable {
    private let authRepository: AuthProtocol

    init(authRepository: AuthProtocol) {
        self.authRepository = authRepository
    }

    func execute() async throws {
        try await authRepository.signOut()
    }
}
