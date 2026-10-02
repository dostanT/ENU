import SwiftUI


extension DesignSystem {
    /// Wraps system semantic colors rather than hardcoded hex values — the
    /// specific brand palette (idea.swift §18: "чёрный / белый / один акцент")
    /// is a visual decision for the Мастерская/Workshop tool to specify, not
    /// one to invent here. This still adapts correctly to light/dark and
    /// Increase Contrast today, and swaps cleanly once real tokens exist.
    enum Colors {
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let accent = Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1))
        /// What sits *on* an `accent` fill — the primary button's label. White
        /// in both appearances: it's legible on any accent dark enough to
        /// carry it, which the current one is. The brand's real pairing is the
        /// Мастерская's call, like the rest of this file.
        static let onAccent = Color.white
    }
}
