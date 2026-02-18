import SwiftUI

/// Applies accessibility semantics and actions for ButterflyButton.
struct ButterflyButtonAccessibilityModifier: ViewModifier {
    let isOn: Bool
    let accessibilityLabel: LocalizedStringKey
    let accessibilityHint: LocalizedStringKey
    let accessibilityToggleActionKey: LocalizedStringKey
    let accessibilityStateOn: LocalizedStringKey
    let accessibilityStateOff: LocalizedStringKey
    let performToggle: () -> Void

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
