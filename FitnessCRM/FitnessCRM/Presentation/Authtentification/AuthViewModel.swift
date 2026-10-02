//
//  AuthViewModel.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 30.09.2026.
//
import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .notSignedIn
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var password2: String = ""
    @Published var errorMessage: String? = ""
    
    private let signInUseCase: SignInUseCase
    private let signUpUseCase: SignUpUseCase
    private let signOutUseCase: SignOutUseCase
    private let isAuthentificatedUseCase: IsAuthenticatedUseCase
    private let currentUserIdUseCase: CurrentUserIdUseCase
    
    init(authRepository: any AuthProtocol) {
        //MARK: Auth - UseCases
        self.signInUseCase = SignInUseCase(authRepository: authRepository)
        self.signUpUseCase = SignUpUseCase(authRepository: authRepository)
        self.signOutUseCase = SignOutUseCase(authRepository: authRepository)
        self.isAuthentificatedUseCase = IsAuthenticatedUseCase(authRepository: authRepository)
        self.currentUserIdUseCase = CurrentUserIdUseCase(authRepository: authRepository)
    }
    
    func signUp()  {
        Task {
            do{
                try await signUpUseCase.execute(email: email, password: password)
            } catch let error as AppError{
                errorMessage = error.text
            } catch {
                errorMessage = "404 try again later"
            }
        }
    }
    
    func signIn()  {
        Task {
            do{
                try await signInUseCase.execute(email: email, password: password)
            } catch let error as AppError{
                errorMessage = error.text
            } catch {
                errorMessage = "404 try again later"
            }
        }
    }

    func signOut() async throws {
        try await signOutUseCase.execute()
    }

    func currentUserId() async {
        authState = .isLoading
        if let id = await currentUserIdUseCase.execute() {
            authState = .isSignedIn(id)
        } else {
            authState = .notSignedIn
        }
    }

    func isAuthenticated() async -> Bool {
        await isAuthentificatedUseCase.execute()
    }
}
