//
//  SupabaseAuthRepository.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation
import Supabase

@MainActor
final class SupabaseAuthRepository: AuthProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }
    
    func signUp(email: String, password: String) async throws{
        try await client.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func currentUserId() async -> UUID? {
        client.auth.currentUser?.id
    }

    /// true если сессия есть И не просрочена. Автоматически обновляет токен, если нужно.
    func isAuthenticated() async -> Bool {
        do {
            let session = try await client.auth.session
            return !session.isExpired
        } catch {
            return false
        }
    }
}
