import SwiftUI

extension DesignSystem {
    /// Semantic text styles only — every case scales with Dynamic Type
    /// (CLAUDE.md → Accessibility). No fixed point sizes.
    enum Typography {
        static let timerDisplay = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let stateLabel = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body = Font.system(.body)
        static let caption = Font.system(.caption)
    }
}
