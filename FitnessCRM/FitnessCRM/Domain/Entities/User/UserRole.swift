import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable, Sendable {
    case director
    case manager
    case hostess       // ← исправлено с hostes
    case coach
    case storekeeper   // ← исправлено с cladovchik
    case financer
    case marketer      // ← исправлено с marketolog
    case admin
    case user

    var id: String { rawValue }

    var title: String {
        switch self {
        case .director:    return "Директор сети"
        case .manager:     return "Менеджер по продажам"
        case .hostess:     return "Ресепшн"
        case .coach:       return "Тренер"
        case .storekeeper: return "Кладовщик"
        case .financer:    return "Бухгалтер"
        case .marketer:    return "Маркетолог"
        case .admin:       return "Администратор"
        case .user:        return "Пользователь"
        }
    }
}
