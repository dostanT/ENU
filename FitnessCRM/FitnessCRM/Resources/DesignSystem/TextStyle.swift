import SwiftUI

extension DesignSystem {
    /// The roles text plays in this app — each is one of `Typography`'s
    /// fonts. Naming the role is the point: a view says *what* the text is,
    /// and `DesignSystem` decides how that looks, instead of every view
    /// picking a font and a color on its own (CLAUDE.md → Design System).
    enum TextRole {
        /// The big countdown / count-up digits. Always monospaced digits, so
        /// they don't jitter as they tick.
        case timerDisplay
        /// A short label or figure that anchors a screen or a group: WORK,
        /// Paused, Time's up, a Timeline total.
        case stateLabel
        /// Ordinary text.
        case body
        /// Small supporting detail beside or under other text.
        case caption
    }

    /// Which of `Colors`' text colors a piece of text takes.
    enum TextColor {
        case primary
        case secondary
        /// Draws the eye — used sparingly (idea.swift §18: "один акцент").
        case accent
    }

    struct TextStyleModifier: ViewModifier {
        let role: TextRole
        let color: TextColor
        let monospacedDigits: Bool

        @ViewBuilder
        func body(content: Content) -> some View {
            let styled = content
                .font(role.font)
                .foregroundStyle(color.value)
            if role == .timerDisplay || monospacedDigits {
                styled.monospacedDigit()
            } else {
                styled
            }
        }
    }
}

extension DesignSystem.TextRole {
    var font: Font {
        switch self {
        case .timerDisplay: DesignSystem.Typography.timerDisplay
        case .stateLabel: DesignSystem.Typography.stateLabel
        case .body: DesignSystem.Typography.body
        case .caption: DesignSystem.Typography.caption
        }
    }
}

extension DesignSystem.TextColor {
    var value: Color {
        switch self {
        case .primary: DesignSystem.Colors.primaryText
        case .secondary: DesignSystem.Colors.secondaryText
        case .accent: DesignSystem.Colors.accent
        }
    }
}

extension View {
    /// Sets this text's font and color from `DesignSystem`, by role — the one
    /// way feature views style text. `monospacedDigits` is for text whose
    /// digits change while it's on screen (a live "Paused for …"); the
    /// `.timerDisplay` role always has it.
    ///
    /// Not for system chrome — Form section headers, navigation titles, tab
    /// bar labels stay the system's (CLAUDE.md → Design System).
    func textStyle(
        _ role: DesignSystem.TextRole,
        color: DesignSystem.TextColor = .primary,
        monospacedDigits: Bool = false
    ) -> some View {
        modifier(DesignSystem.TextStyleModifier(role: role, color: color, monospacedDigits: monospacedDigits))
    }
}
