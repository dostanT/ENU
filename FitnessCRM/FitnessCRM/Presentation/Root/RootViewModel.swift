//
//  RootViewModel.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//

import Foundation
import Combine



@MainActor
final class RootViewModel: ObservableObject {
    @Published var selectedTab: TabEnum = .dashboard
    
}
