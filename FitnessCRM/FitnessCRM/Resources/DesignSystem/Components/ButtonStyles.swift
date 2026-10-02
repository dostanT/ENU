import SwiftUI

/// HIG's minimum size of anything you tap (CLAUDE.md → Accessibility). Held
/// here rather than as a token: it's the platform's rule, not a brand choice.
private let minimumTapTarget: CGFloat = 44

/// How heavy the outline of a selected chip is — the one line weight in the app,
/// so it lives beside the only style that draws one.
private let selectedOutlineWidth: CGFloat = 2

extension DesignSystem {
    /// The buttons of the app (CLAUDE.md → Design System). Every one of them
    /// is a role below, drawn from `Colors`, `Typography`, `Spacing` and
    /// `Radius`: a view says how loudly a button should ask to be pressed and
    /// doesn't pick a font, a padding or a fill of its own — so changing a
    /// token changes every button, which the system's own styles (drawn in the
    /// asset catalog's `AccentColor`, not in `Colors.accent`) never would.
    ///
    /// Use it as `.buttonStyle(.primary)`, `.secondary` or `.tertiary`.
    struct EmphasizedButtonStyle: ButtonStyle {
        enum Emphasis {
            /// The one thing a screen most wants you to do.
            case primary
            /// A real alternative to it.
            case secondary
            /// Available, but quiet — closer to a label than to a button.
            case tertiary
        }

        let emphasis: Emphasis

        func makeBody(configuration: ButtonStyleConfiguration) -> some View {
            EmphasizedButtonBody(configuration: configuration, emphasis: emphasis)
        }
    }

    /// A tappable row inside a list or form: no chrome of its own — the row's
    /// content carries the look — but the whole row is the target, and
    /// pressing it gives the same feedback as any other button here.
    ///
    /// Use it as `.buttonStyle(.row)`.
    struct RowButtonStyle: ButtonStyle {
        func makeBody(configuration: ButtonStyleConfiguration) -> some View {
            RowButtonBody(configuration: configuration)
        }
    }

    /// A button that is nothing but a symbol — the ‹ › that steps a Timeline
    /// period. Drawn in the primary text color — the accent is a light green, which
    /// as a thin chevron on a white screen is all but invisible — and never smaller
    /// than the platform's minimum tap target (CLAUDE.md → Accessibility), so no
    /// view has to name a size of its own.
    ///
    /// Use it as `.buttonStyle(.icon)`.
    struct IconButtonStyle: ButtonStyle {
        func makeBody(configuration: ButtonStyleConfiguration) -> some View {
            IconButtonBody(configuration: configuration)
        }
    }

    /// A tile you can press, and that can be the selected one of several — the
    /// Timeline's four figures. Its fill (`Colors.surface`) is what says it's a
    /// button and not a line of text; the selected tile is also outlined in the
    /// accent. Outlined, not colored: text drawn in the accent can't be relied on to
    /// be legible. The tile is as tall as what's in it, and never below the
    /// platform's minimum tap target.
    ///
    /// Use it as `.buttonStyle(.chip(isSelected: …))`.
    struct ChipButtonStyle: ButtonStyle {
        let isSelected: Bool

        func makeBody(configuration: ButtonStyleConfiguration) -> some View {
            ChipButtonBody(configuration: configuration, isSelected: isSelected)
        }
    }
}

extension ButtonStyle where Self == DesignSystem.EmphasizedButtonStyle {
    static var primary: Self { .init(emphasis: .primary) }
    static var secondary: Self { .init(emphasis: .secondary) }
    static var tertiary: Self { .init(emphasis: .tertiary) }
}

extension ButtonStyle where Self == DesignSystem.RowButtonStyle {
    static var row: Self { .init() }
}

extension ButtonStyle where Self == DesignSystem.IconButtonStyle {
    static var icon: Self { .init() }
}

extension ButtonStyle where Self == DesignSystem.ChipButtonStyle {
    static func chip(isSelected: Bool) -> Self { .init(isSelected: isSelected) }
}

// A separate `View` (rather than modifiers inline in `makeBody`) because the
// disabled state lives in the environment, which a `ButtonStyle` itself can't
// read — the view it returns can.
private struct EmphasizedButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let emphasis: DesignSystem.EmphasizedButtonStyle.Emphasis
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(font)
            .foregroundStyle(labelColor)
            .padding(.vertical, .spacingM)
            .frame(maxWidth: .infinity, minHeight: minimumTapTarget)
            .background(fill, in: shape)
            .contentShape(shape)
            .opacity(opacity)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: .radiusMedium, style: .continuous)
    }

    private var font: Font {
        switch emphasis {
        case .primary, .secondary: DesignSystem.Typography.stateLabel
        case .tertiary: DesignSystem.Typography.body
        }
    }

    // Text on the secondary and tertiary levels is `primaryText` /
    // `secondaryText`, not `accent`, on purpose: those two adapt to light and
    // dark on their own, so the label is legible whatever the accent is.
    private var labelColor: Color {
        switch emphasis {
        case .primary: DesignSystem.Colors.onAccent
        case .secondary: DesignSystem.Colors.primaryText
        case .tertiary: DesignSystem.Colors.secondaryText
        }
    }

    private var fill: Color {
        switch emphasis {
        case .primary: DesignSystem.Colors.accent
        case .secondary: DesignSystem.Colors.secondaryText
        case .tertiary: .clear
        }
    }

    private var opacity: Double {
        guard isEnabled else { return DesignSystem.Opacity.disabled }
        return configuration.isPressed ? DesignSystem.Opacity.pressed : 1
    }
}

private struct RowButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(opacity)
    }

    private var opacity: Double {
        guard isEnabled else { return DesignSystem.Opacity.disabled }
        return configuration.isPressed ? DesignSystem.Opacity.pressed : 1
    }
}

private struct IconButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .foregroundStyle(DesignSystem.Colors.primaryText)
            .frame(minWidth: minimumTapTarget, minHeight: minimumTapTarget)
            .contentShape(Rectangle())
            .opacity(opacity)
    }

    private var opacity: Double {
        guard isEnabled else { return DesignSystem.Opacity.disabled }
        return configuration.isPressed ? DesignSystem.Opacity.pressed : 1
    }
}

private struct ChipButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .padding(.spacingS)
            .frame(minHeight: minimumTapTarget)
            .background(DesignSystem.Colors.secondaryText, in: shape)
            .overlay {
                if isSelected {
                    shape.strokeBorder(DesignSystem.Colors.accent, lineWidth: selectedOutlineWidth)
                }
            }
            .contentShape(shape)
            .opacity(opacity)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: .radiusSmall, style: .continuous)
    }

    private var opacity: Double {
        guard isEnabled else { return DesignSystem.Opacity.disabled }
        return configuration.isPressed ? DesignSystem.Opacity.pressed : 1
    }
}
