import SwiftUI

struct RootView: View {
    
    private let appContainer: AppContainer
    @StateObject private var rootVM: RootViewModel
    @StateObject private var authVM: AuthViewModel
    
    init(appContainer: AppContainer) {
        self.appContainer = appContainer
        self._authVM = StateObject(wrappedValue: AuthViewModel(authRepository: appContainer.authRepository))
        self._rootVM = StateObject(wrappedValue: RootViewModel())
    }
    
    var body: some View {
        switch authVM.authState {
        case .isSignedIn(let uUID):
            NavigationSplitView {
                List(TabEnum.allCases, selection: $rootVM.selectedTab) { item in
                    NavigationLink(value: item) {
                        Label(item.title, systemImage: item.icon)
                    }
                }
                .navigationTitle("Меню")
            } detail: {
                bodyView
            }
        case .notSignedIn:
            AuthView(authVM: authVM)
        case .isLoading:
            ProgressView {
                Text("Loading Your Auth")
            }
        }
    }
}

extension RootView {
    @ViewBuilder
    private var bodyView: some View {
        switch rootVM.selectedTab {
        case .dashboard:
            DashboardView()
        case .branches:
            BranchesView()
        case .staff:
            StafView()
        case .directories:
            DirectoriesView()
        case .clients:
            ClientsView()
        case .memberships:
            MembershipsView()
        case .payments:
            PaymentsView()
        case .promotions:
            PromotionsView()
        case .schedule:
            ScheduleView()
        case .workouts:
            WorkoutsView()
        case .turnstile:
            TurnstileView()
        case .warehouse:
            WarehouseView()
        case .shop:
            ShopView()
        case .reports:
            ReportsView()
        case .audit:
            AuditView()
        case .notifications:
            NotificationsView()
        case .settings:
            SettingsView()
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard, clients, workouts, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Главная"
        case .clients:   return "Клиенты"
        case .workouts:  return "Тренировки"
        case .settings:  return "Настройки"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .clients:   return "person.2"
        case .workouts:  return "figure.run"
        case .settings:  return "gear"
        }
    }
}
