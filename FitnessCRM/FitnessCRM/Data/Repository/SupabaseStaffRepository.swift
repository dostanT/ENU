//
//  SupabaseStaffRepository.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation
import Supabase

@MainActor
final class SupabaseStaffRepository: StaffProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchCurrent() async throws -> Staff {
        guard let userId = client.auth.currentUser?.id else {
            throw AppError.notAuthenticated
        }
        let dto: StaffDTO = try await client
            .from("staff")
            .select()
            .eq("auth_user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return dto.toDomain()
    }
}
