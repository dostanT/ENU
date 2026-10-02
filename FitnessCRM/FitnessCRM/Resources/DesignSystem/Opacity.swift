extension DesignSystem {
    /// How far a control fades to say what state it's in. Provisional, the
    /// way `Colors` is: values that mirror the feel of the system's own
    /// controls until the Мастерская specifies real ones. Custom button styles
    /// need them because, unlike the system's, they draw their own feedback.
    enum Opacity {
        static let pressed: Double = 0.7
        static let disabled: Double = 0.4
    }
}
