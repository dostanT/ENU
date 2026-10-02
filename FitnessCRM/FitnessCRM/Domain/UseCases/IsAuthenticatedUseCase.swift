//
//
//  SignInUseCase.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

struct IsAuthenticatedUseCase: Sendable {
    private let authRepository: AuthProtocol

    init(authRepository: AuthProtocol) {
        self.authRepository = authRepository
    }

    func execute() async  -> Bool {
        await authRepository.isAuthenticated()
    }
}
