//
//  AuthRepository.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation

protocol AuthProtocol: Sendable {
    func signUp(email: String, password: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() async throws
    func currentUserId() async -> UUID?
    func isAuthenticated() async -> Bool
}
