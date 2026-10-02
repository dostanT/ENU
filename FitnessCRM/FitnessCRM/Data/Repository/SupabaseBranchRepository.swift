//
//  SupabaseBranchRepository.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//


import Foundation
import Supabase

@MainActor
final class SupabaseBranchRepository: BranchProtocol {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchAll() async throws -> [Branch] {
        let rows: [Branch] = try await client
            .from("branches")
            .select()
            .order("code", ascending: true)
            .execute()
            .value
        return rows
    }
}
