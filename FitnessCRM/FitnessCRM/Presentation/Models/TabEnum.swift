//
//  TabEnum.swift
//  FitnessCRM
//
//  Created by Dostan Turlybek on 24.09.2026.
//

import Foundation

enum TabEnum: String, CaseIterable, Identifiable {

    // M0 — основа
    case dashboard
    case branches
    case staff
    case directories     // справочники: виды абонементов, категории товаров

    // M1 — клиенты и абонементы
    case clients
    case memberships
    case payments
    case promotions

    // M2, M3, M4 — расписание, тренировки, посещения
    case schedule
    case workouts
    case turnstile

    // M5 — склад и магазин
    case warehouse
    case shop

    // M7 — отчёты
    case reports
    case audit

    // M8, M0 — уведомления и настройки
    case notifications
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:     return "Дашборд"
        case .branches:      return "Филиалы"
        case .staff:         return "Сотрудники"
        case .directories:   return "Справочники"
        case .clients:       return "Клиенты"
        case .memberships:   return "Абонементы"
        case .payments:      return "Платежи"
        case .promotions:    return "Акции"
        case .schedule:      return "Расписание"
        case .workouts:      return "Тренировки"
        case .turnstile:     return "Турникет"
        case .warehouse:     return "Склад"
        case .shop:          return "Магазин"
        case .reports:       return "Отчёты"
        case .audit:         return "Аудит"
        case .notifications: return "Уведомления"
        case .settings:      return "Настройки"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:     return "house"
        case .branches:      return "building.2"
        case .staff:         return "person.3"
        case .directories:   return "book.closed"
        case .clients:       return "person.2"
        case .memberships:   return "ticket"
        case .payments:      return "creditcard"
        case .promotions:    return "gift"
        case .schedule:      return "calendar"
        case .workouts:      return "figure.run"
        case .turnstile:     return "door.left.hand.open"
        case .warehouse:     return "shippingbox"
        case .shop:          return "cart"
        case .reports:       return "chart.bar"
        case .audit:         return "doc.text.magnifyingglass"
        case .notifications: return "bell"
        case .settings:      return "gear"
        }
    }

    /// Какие роли видят этот раздел в боковом меню.
    /// UI-фильтр; настоящая защита — RLS-политики в БД.
    var allowedRoles: Set<UserRole> {
        switch self {
        case .dashboard:
            return [.director, .financer, .marketer, .admin, .user]

        case .branches, .staff, .directories, .audit:
            return [.director, .admin]

        case .clients, .memberships:
            return [.director, .manager, .hostess]

        case .payments:
            return [.director, .manager, .hostess, .financer]

        case .promotions:
            return [.director, .marketer]

        case .schedule:
            return [.director, .manager, .hostess, .coach]

        case .workouts:
            return [.director, .coach]

        case .turnstile:
            return [.hostess]

        case .warehouse:
            return [.director, .storekeeper]

        case .shop:
            return [.director, .hostess, .storekeeper]

        case .reports:
            return [.director, .financer, .marketer]

        case .notifications, .settings:
            return Set(UserRole.allCases)
        }
    }
}
