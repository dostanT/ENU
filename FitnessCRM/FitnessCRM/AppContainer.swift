//
//  AppContainer.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 01.10.2026.
//
import Combine

@MainActor
final class AppContainer {
    let authRepository: any AuthProtocol
    
    init(authRepository: any AuthProtocol) {
        self.authRepository = authRepository
    }
    
    func makeRootViewModel() -> RootViewModel {
        RootViewModel()
    }
    
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel(authRepository: authRepository)
    }
}
