//
//  AuthState.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 30.09.2026.
//
import Foundation

enum AuthState {
    case isSignedIn(UUID)
    case notSignedIn
    case isLoading
}
