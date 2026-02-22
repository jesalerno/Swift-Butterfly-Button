/// Accessibility modifiers for ButterflyButton.
///
/// Encapsulates labels, values, and custom actions to expose toggle semantics to assistive technologies.
import SwiftUI

/// Applies accessibility semantics and actions for `ButterflyButton`.
///
/// Combines label, hint, state value, button traits, and a custom named action to toggle the control.
struct ButterflyButtonAccessibilityModifier: ViewModifier {
    /// Indicates whether the button is in the "on" state.
    let isOn: Bool
    /// The accessibility label describing the button.
    let accessibilityLabel: LocalizedStringKey
    /// The accessibility hint providing additional context.
    let accessibilityHint: LocalizedStringKey
    /// The accessibility label for the custom toggle action.
    let accessibilityToggleActionKey: LocalizedStringKey
    /// The localized string representing the "on" state.
    let accessibilityStateOn: LocalizedStringKey
    /// The localized string representing the "off" state.
    let accessibilityStateOff: LocalizedStringKey
    /// The closure to execute when the toggle action is performed.
    let performToggle: () -> Void

    /// Composes accessibility information and actions on the wrapped content.
    ///
    /// - Parameter content: The view to decorate.
    /// - Returns: A view configured with accessibility semantics.
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityValue(Text(isOn ? accessibilityStateOn : accessibilityStateOff))
            .accessibilityHint(Text(accessibilityHint))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: Text(accessibilityToggleActionKey)) {
                performToggle()
            }
            .accessibilityAction {
                performToggle()
            }
    }
}
