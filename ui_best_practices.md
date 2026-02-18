# Human–Machine Interface (HMI) Instruction File

## Purpose

This document provides guidance for agents developing or reviewing custom `UIControl`-based components (such as custom buttons or switches) in Xcode for iOS, iPadOS and macOS.

The instructions synthesize Apple's Human Interface Guidelines (HIG) and Swift documentation on color, appearance changes and the Liquid‑Glass interface to ensure accessible, adaptive and platform‑consistent user interfaces.

---

## 1. Color Management

### 1.1 Use semantic system colors wherever possible

- Use system colors (e.g. `labelColor`, `secondaryLabelColor`, `systemFillColor`) rather than fixed RGB values; semantic colors automatically adjust between light and dark appearances.
- Avoid assigning identical colors to controls serving different purposes; colors should convey meaning and maintain clear contrast between interactive elements and surrounding content.

### 1.2 Define custom colors via Asset Catalogs

- When custom hues are required, create color assets in Xcode's asset catalog with light, dark and high‑contrast variants.
- Load these colors using `UIColor(named: "YourColor", in: nil, compatibleWith: traitCollection)` or `NSColor(named:)` to get a dynamic color that adapts automatically to the current appearance.

### 1.3 Provide sufficient contrast

- Ensure controls maintain strong contrast against backgrounds under all appearances and accessibility settings (Dark Mode, High Contrast).
- Test colors under varying brightness, True Tone, and environmental lighting to verify legibility.
- **Do not rely on color alone to convey state changes.** Use shape, iconography, or labels as a secondary indicator alongside color. Check `UIAccessibility.isDifferentiateWithoutColorEnabled` at runtime and add non-color cues (borders, icons, shapes) when it returns `true`. This is required for HIG compliance and for users with color vision deficiencies.
- **Detect High Contrast mode programmatically** via `traitCollection.accessibilityContrast == .high` to apply tighter contrast ratios or bolder borders beyond what semantic colors provide automatically. Register for this trait alongside `UITraitUserInterfaceStyle` when using `registerForTraitChanges`:

```swift
registerForTraitChanges(
    [UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]
) { (self: CustomControl, _) in
    self.updateLayerColors()
}
```

---

## 2. Handling Control States

Custom controls based on `UIControl` should adjust their appearance based on state. The most common states are:

| State | Behaviour/Appearance |
|---|---|
| **Normal** | Base appearance. Use dynamic colors for text and backgrounds that adapt to appearance changes. |
| **Highlighted** (`isHighlighted == true`) | Provide immediate feedback when the user touches the control. Usually by slightly dimming the background, increasing opacity, or adjusting the tint color. |
| **Selected** (`isSelected == true`) | Indicate an on/off or active state. You may change background color or border to reflect selection. |
| **Disabled** (`isEnabled == false`) | Dim the control (lower opacity or use a muted color) and remove interactive feedback. Users should clearly distinguish disabled controls. |
| **Focused** (`isFocused == true`) | Relevant on iPadOS (pointer hover), tvOS (focus engine), and keyboard navigation. Provide a visible focus ring or highlight. Use `UIFocusEffect` or a border change to indicate focus clearly without relying on color alone. |

### Implementation Tips

- Override `isHighlighted`, `isSelected` and `isEnabled` to update colors or alpha values accordingly.
- Avoid using `alpha < 1` for disabled text because semitransparent text can be difficult to read. Instead choose a semantic color like `secondaryLabelColor` or a custom muted variant.
- **Reduce Motion:** When animating state transitions (e.g. a spring scale on highlight, or a crossfade on selection), check `UIAccessibility.isReduceMotionEnabled` and suppress or replace the animation with an instant change when it returns `true`. See Section 11.3 for a full example.
- **Button Shapes:** When `UIAccessibility.buttonShapesEnabled` is `true`, borderless controls must gain a visible outline or underline so their interactive boundary is clear without relying on color or context. See Section 11.4 for guidance.
- **Tint Adjustment:** When the system presents a modal overlay (alert, action sheet, popover), it sets `tintAdjustmentMode = .dimmed` on background views. Override `tintColorDidChange()` to respond and visually dim your control accordingly:

```swift
override func tintColorDidChange() {
    super.tintColorDidChange()
    // Reduce icon or label opacity when the system dims background controls
    iconView.alpha = tintAdjustmentMode == .dimmed ? 0.4 : 1.0
}
```

- For `UIButton` subclasses, prefer using the configuration API (iOS 15+) to assign colors and visual states:

```swift
var config = UIButton.Configuration.filled()
config.baseForegroundColor = .label
config.baseBackgroundColor = .tintColor
button.configuration = config
```

This automatically manages state transitions for you.

### 2.1 Event Dispatch

A custom `UIControl` communicates with its owner through the target-action mechanism. Call `sendActions(for:)` at the point where a meaningful interaction completes — do not use closures or delegates in place of this unless you have a specific reason to.

```swift
// Dispatch a value-changed event when the control's internal value changes
override var isSelected: Bool {
    didSet {
        guard isSelected != oldValue else { return }
        sendActions(for: .valueChanged)
    }
}

// Dispatch a touch-up-inside event from accessibilityActivate()
override func accessibilityActivate() -> Bool {
    sendActions(for: .touchUpInside)
    return true
}
```

**`UIAction` (iOS 14+):** Use `addAction(_:for:)` with a `UIAction` closure instead of `addTarget(_:action:for:)`. This avoids the need for `@objc` selectors and keeps the handler co-located with the registration:

```swift
button.addAction(UIAction { [weak self] _ in
    self?.handleConfirm()
}, for: .primaryActionTriggered)
```

Use `.primaryActionTriggered` rather than `.touchUpInside`; it maps to the most appropriate primary action for each platform (tap on iOS, click on Mac Catalyst). For apps targeting iOS 13 or earlier, `addTarget(_:action:for:)` remains the supported approach.

---

## 3. Haptic Feedback

Touch-based interactions should feel physical. Haptic feedback confirms actions and errors without requiring visual attention.

- **Selection:** Use `UISelectionFeedbackGenerator` when a value changes (e.g., slider movement, switch toggle).
- **Impact:** Use `UIImpactFeedbackGenerator` for physical collisions or distinct snaps (e.g., button press).
- **Notification:** Use `UINotificationFeedbackGenerator` for success/error states.

```swift
// Selection change
let selectionFeedback = UISelectionFeedbackGenerator()
selectionFeedback.selectionChanged()

// Impact (e.g., button press)
let impact = UIImpactFeedbackGenerator(style: .medium)
impact.impactOccurred()
```

---

## 4. Pointer Interaction (iPadOS)

On iPadOS, the cursor transforms when hovering over interactive elements. Custom controls must support this to feel native.

- **Implement `UIPointerInteractionDelegate`**: Register a pointer interaction on your control.
- **Define a Style**: Return a `UIPointerStyle` ensuring the cursor snaps to the control or applies a lift effect.

```swift
class CustomControl: UIControl, UIPointerInteractionDelegate {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            let interaction = UIPointerInteraction(delegate: self)
            addInteraction(interaction)
        }
    }

    func pointerInteraction(_ interaction: UIPointerInteraction,
                            styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return UIPointerStyle(effect: .automatic(UITargetedPreview(view: self)))
    }
}
```

---

## 5. Layout & Sizing

Custom controls must communicate their size to the Auto Layout engine and provide an adequate touch target.

- **Intrinsic Content Size:** Override `intrinsicContentSize` to provide a default size based on content (text, icon, padding).
- **Invalidation:** Call `invalidateIntrinsicContentSize()` whenever the content changes (e.g. setting a new title).
- **Size That Fits:** Implement `sizeThatFits(_:)` for non-Auto Layout contexts.
- **Minimum touch target:** Apple's HIG requires a minimum interactive area of 44×44pt. Enforce this in `intrinsicContentSize` even if the visual size is smaller.

```swift
override var intrinsicContentSize: CGSize {
    let width = titleLabel.intrinsicContentSize.width + horizontalPadding * 2
    return CGSize(width: max(width, 44), height: 44)
}

var title: String? {
    didSet { invalidateIntrinsicContentSize() }
}
```

### 5.1 Expanding Touch Targets

When a control's visual size must be smaller than 44×44pt (e.g. a compact icon button), override `point(inside:with:)` to expand the hit area without changing the visual frame:

```swift
override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    // Expand the tappable area by 10pt on each side while keeping the visual frame unchanged
    let expandedBounds = bounds.insetBy(dx: -10, dy: -10)
    return expandedBounds.contains(point)
}
```

Use `sizeThatFits(_:)` alongside this when the control is used outside Auto Layout:

```swift
override func sizeThatFits(_ size: CGSize) -> CGSize {
    return CGSize(width: max(intrinsicContentSize.width, 44),
                  height: max(intrinsicContentSize.height, 44))
}
```

---

## 6. Swift Concurrency

Modern UIKit code interacts with Swift Concurrency. UI components are inherently bound to the main thread.

- **`@MainActor`:** Mark your `UIControl` subclasses with `@MainActor` to ensure all state updates and layout changes occur on the main thread, especially when called from async contexts.

```swift
@MainActor
class CustomControl: UIControl {
    // All methods run on the main actor by default
}
```

---

## 7. SF Symbols

SF Symbols are the preferred source for icons in custom controls. They automatically handle dark mode, high-contrast, Dynamic Type scaling, and RTL mirroring — directly supporting the requirements in Sections 1, 10, and 12.

- **Use `UIImage(systemName:)` over custom images** wherever a suitable symbol exists. This eliminates the need to maintain separate light/dark/high-contrast image assets.
- **Symbol configuration:** Use `UIImage.SymbolConfiguration` to match the symbol's weight and scale to adjacent text:

```swift
let config = UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
iconView.image = image
```

- **RTL mirroring:** Most directional symbols (arrows, chevrons) mirror automatically in RTL locales. For symbols that should not mirror, set `imageView.semanticContentAttribute = .forceLeftToRight`.
- **Variable symbols:** For controls that represent a continuous value (signal strength, volume), use variable-value symbols (iOS 16+) to render the appropriate fill level:

```swift
// value is a Double from 0.0 to 1.0
let image = UIImage(systemName: "speaker.wave.3", variableValue: volume)
```

- **Availability:** SF Symbols are available on iOS 13+, macOS 11+, tvOS 13+, and watchOS 6+. For pre-iOS 13 targets, provide a custom image fallback.

---

## 8. Adapting to Appearance Changes

### 8.1 Use dynamic colors

- Colors loaded from asset catalogs or defined as semantic system colors adapt to the system appearance automatically.
- Avoid creating colors from static RGB values because they do not change when the system switches between light and dark modes.

### 8.2 Update colors on trait changes

In custom view subclasses using `CALayer` or drawing code, use `registerForTraitChanges(_:handler:)` (iOS 17+) to respond when appearance traits change. Register for all relevant traits together so the handler is called for both Dark Mode and High Contrast changes:

```swift
class CustomControl: UIControl {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        registerForTraitChanges(
            [UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]
        ) { (self: CustomControl, _) in
            self.updateLayerColors()
        }
    }

    private func updateLayerColors() {
        layer.backgroundColor = UIColor(named: "CustomBackground")?
            .resolvedColor(with: traitCollection).cgColor
    }

    override func updateLayer() {
        updateLayerColors()
    }
}
```

> **Legacy targets (iOS 16 and earlier):** `registerForTraitChanges` requires iOS 17+. For apps that must support iOS 16 or below, consult Apple's [Supporting Dark Mode in Your Interface](https://developer.apple.com/documentation/uikit/supporting-dark-mode-in-your-interface) documentation for the appropriate migration path.

**Cross‑platform support (iOS/Mac Catalyst vs macOS AppKit):**

Use conditional compilation to select the correct base class and API. `traitCollection` is available on iOS, tvOS and Mac Catalyst; macOS AppKit uses `effectiveAppearance`.

```swift
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
typealias PlatformColor = UIColor

class CustomControl: UIControl {
    override func updateLayer() {
        layer.backgroundColor = UIColor(named: "CustomBackground")?
            .resolvedColor(with: traitCollection).cgColor
    }
}
#elseif os(macOS)
import AppKit
typealias PlatformColor = NSColor

class CustomControl: NSControl {
    override func updateLayer() {
        layer?.backgroundColor = NSColor(named: "CustomBackground")?
            .resolvedColor(for: effectiveAppearance).cgColor
    }
}
#endif
```

The `resolvedColor(with:)` / `resolvedColor(for:)` methods resolve the color for the current appearance on their respective platforms.

---

## 9. Liquid Glass Style (Glass UI)

The Liquid Glass effect uses translucent backgrounds that pick up the hues of underlying content and environment. When designing custom controls with Liquid Glass:

1. **Transparency:** The material has no inherent color; it samples colors from behind, so avoid adding strong hues.
2. **Minimal Coloring:** Apply color sparingly to accent only primary actions or the most prominent control. Leave other glass surfaces neutral.
3. **Contrast:** Ensure labels and icons remain readable by using contrasting semantic colors (e.g. `labelColor`, `tertiaryLabelColor`) on glass surfaces.
4. **Consistent Resting States:** Maintain a neutral resting state for all controls; avoid accenting all glass elements. Use accent colors only when a control requires emphasis or to reflect a selected/highlighted state.
5. **Accessibility — Reduce Transparency:** Always check `UIAccessibility.isReduceTransparencyEnabled` before applying glass materials. When this setting is active, use an opaque fallback material. This is required by Apple's HIG and ensures usability for users sensitive to visual complexity.

### Implementation example

```swift
struct LiquidButton: View {
    var body: some View {
        Button(action: { /* your action */ }) {
            Text("Continue")
                .padding()
                .background(glassMaterial)
                .foregroundColor(.primary)          // adopts system contrast
                .clipShape(.rect(cornerRadius: 12)) // preferred over .cornerRadius()
        }
    }

    /// Returns an opaque fallback material when Reduce Transparency is enabled,
    /// as required by the HIG.
    private var glassMaterial: Material {
        UIAccessibility.isReduceTransparencyEnabled
            ? .regular           // opaque fallback
            : .ultraThinMaterial // glass material
    }
}
```

`Material.ultraThinMaterial` automatically adapts to the environment on iOS 15+ and macOS 12+. The `glassMaterial` computed property ensures the control degrades gracefully for accessibility.

---

## 10. Cross‑Platform Considerations

- **Platform‑specific imports:** Use conditional compilation (`#if os(...)`) to select `UIColor`/`UIControl` or `NSColor`/`NSControl` as shown in Section 8.2.
- **Trait API availability:** `traitCollection` and `registerForTraitChanges` are available on iOS, tvOS and Mac Catalyst. On macOS AppKit, use `effectiveAppearance` or `appearance` instead.
- **SwiftUI vs UIKit/AppKit:** In SwiftUI, rely on `Color` and `Material` types which automatically adapt to appearance settings. For UIKit/AppKit, follow the guidelines above.
- **tvOS:** This document covers color management and state handling patterns that apply to tvOS, but tvOS-specific concerns — particularly the focus engine (`UIFocusEnvironment`, `UIFocusEffect`) and the absence of touch-based highlighted states — are outside the scope of this document. Consult Apple's [tvOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos) for platform-specific detail.

---

## 11. Accessibility

Custom `UIControl` subclasses do not automatically expose meaningful information to assistive technologies. Each of the following requirements must be addressed explicitly.

### 11.1 VoiceOver and Assistive Technology

VoiceOver reads your control aloud and lets users interact with it by touch or switch. For a custom control to be usable, you must configure its accessibility properties:

- Set `isAccessibilityElement = true` on the control itself and `false` on any decorative child views to prevent VoiceOver from descending into them.
- Set `accessibilityLabel` to a short, localized name describing what the control is (e.g. `"Confirm order"`). Do not include the control type — VoiceOver appends that from `accessibilityTraits`.
- Set `accessibilityHint` to a localized phrase describing what happens when activated (e.g. `"Places your order and returns to the home screen"`). Hints are optional and should be omitted if the label is already self-explanatory.
- Set `accessibilityValue` for controls that express a mutable value (e.g. a toggle's on/off state, or a progress indicator's percentage).
- Set `accessibilityTraits` to reflect the control's role and state. Common values: `.button`, `.selected`, `.notEnabled`, `.adjustable` (for slider-like controls).
- Override `accessibilityActivate()` to handle the VoiceOver double-tap action. Return `true` if the activation was handled; return `false` to let the system fall back to a simulated tap.

```swift
class ConfirmButton: UIControl {
    override var isAccessibilityElement: Bool {
        get { true }
        set { }
    }

    override var accessibilityLabel: String? {
        get { String(localized: "confirm_button_label", defaultValue: "Confirm order") }
        set { }
    }

    override var accessibilityHint: String? {
        get { String(localized: "confirm_button_hint",
                     defaultValue: "Places your order and returns to the home screen") }
        set { }
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get { isEnabled ? .button : [.button, .notEnabled] }
        set { }
    }

    override func accessibilityActivate() -> Bool {
        sendActions(for: .touchUpInside)
        return true
    }
}
```

### 11.2 Dynamic Type

Controls that display text must scale with the user's preferred text size. Hardcoded font sizes break this and can make text unreadably small or force critical labels to truncate.

- Use `UIFont.preferredFont(forTextStyle:)` for all labels within a custom control.
- Set `adjustsFontForContentSizeCategory = true` on any `UILabel` or `UITextField` so the font updates automatically when the content size category changes.
- Ensure layout accommodates larger sizes using flexible constraints — see Section 5 for sizing requirements and the minimum touch target rule.

```swift
let titleLabel = UILabel()
titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
titleLabel.adjustsFontForContentSizeCategory = true
titleLabel.numberOfLines = 0   // allow wrapping at large sizes
```

For custom fonts, use `UIFontMetrics` to scale them proportionally:

```swift
let customFont = UIFont(name: "MyBrandFont-Regular", size: 16)!
titleLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: customFont)
titleLabel.adjustsFontForContentSizeCategory = true
```

### 11.3 Reduce Motion

Animated state transitions — such as a spring scale on highlight or a crossfade on selection — can cause discomfort for users with vestibular disorders. Check `UIAccessibility.isReduceMotionEnabled` before running any animation.

```swift
override var isHighlighted: Bool {
    didSet {
        if UIAccessibility.isReduceMotionEnabled {
            // Instant appearance change, no animation
            alpha = isHighlighted ? 0.6 : 1.0
        } else {
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut) {
                self.alpha = self.isHighlighted ? 0.6 : 1.0
            }
        }
    }
}
```

Register for `UIAccessibility.reduceMotionStatusDidChangeNotification` if your control needs to update pre-cached animation configurations when the user toggles this setting mid-session.

### 11.4 Button Shapes

When the user enables **Button Shapes** in Settings → Accessibility → Display & Text Size, borderless interactive controls must display a visible shape (outline, underline, or filled background) so their tap target is identifiable without relying on color or placement context.

```swift
private func updateShapeForAccessibility() {
    if UIAccessibility.buttonShapesEnabled {
        layer.borderWidth = 1.5
        layer.borderColor = UIColor.label.cgColor
        layer.cornerRadius = 8
    } else {
        layer.borderWidth = 0
        layer.borderColor = nil
    }
}
```

Call `updateShapeForAccessibility()` from `updateLayer()` and register for `UIAccessibility.buttonShapesEnabledStatusDidChangeNotification` to respond to runtime changes.

---

## 12. Localization

Localization and accessibility are closely coupled: labels and hints must be translated, and layout must adapt to right-to-left scripts.

### 12.1 Localizing Strings

All user-facing strings — including labels, hints, and values set programmatically — must be localized.

**UIKit:** Use `String(localized:defaultValue:comment:)` (Swift 5.7+) or `NSLocalizedString(_:comment:)` for any string assigned to a control or its accessibility properties:

```swift
// Preferred (Swift 5.7+)
label.text = String(localized: "confirm_button_label", defaultValue: "Confirm order")

// Pre–Swift 5.7 fallback
label.text = NSLocalizedString("confirm_button_label", comment: "Label on the order confirmation button")
```

**SwiftUI:** `Text("string literal")` automatically resolves through `LocalizedStringKey`, so no additional wrapping is needed. Always ensure the matching key exists in your `.strings` or `.xcstrings` file, and add a `comment:` argument for translators:

```swift
Text("confirm_button_label", comment: "Label on the order confirmation button")
```

**Accessibility labels and hints must also be localized.** A non-localized `accessibilityLabel` means VoiceOver reads an untranslated string to users in every non-English locale. Apply `String(localized:)` consistently, as shown in the Section 11.1 example above.

### 12.2 Right-to-Left (RTL) Layout

Arabic, Hebrew, Persian and other RTL languages require controls to mirror their layout. Failure to support RTL results in reversed button orders, misaligned icons, and broken text alignment.

**Use leading/trailing constraints, not left/right.** Auto Layout's leading and trailing edges automatically flip in RTL locales; left/right edges do not:

```swift
// Correct — adapts to RTL automatically
NSLayoutConstraint.activate([
    iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
    titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
    titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
])
```

**Use `NSDirectionalEdgeInsets` instead of `UIEdgeInsets`** for padding that should mirror in RTL. `UIEdgeInsets` uses fixed left/right values; `NSDirectionalEdgeInsets` uses leading/trailing:

```swift
config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
```

**Mirror directional icons** using `imageFlippedForRightToLeftLayoutDirection()` for icons that imply a direction (arrows, chevrons, play/back indicators). Non-directional icons (checkmarks, star ratings) should not be mirrored. Note that SF Symbols handle this automatically — see Section 7.

**Set `semanticContentAttribute`** on custom controls to declare their layout direction intent. Most controls should use `.unspecified` (the default, which mirrors automatically). Use `.forceLeftToRight` or `.forceRightToLeft` only for controls whose content is inherently directional regardless of locale (e.g. a media player scrubber):

```swift
// Most controls — mirror automatically
control.semanticContentAttribute = .unspecified

// Media scrubber — always left-to-right regardless of locale
scrubber.semanticContentAttribute = .forceLeftToRight
```

---

## 13. Checklist for Agents

1. **Define Colors:** Use semantic system colors or asset catalog colors with light/dark/high-contrast variants. Avoid fixed RGB values.
2. **Support Color-Blind Users:** Do not rely on color alone to convey state. Add secondary indicators (shape, icons, borders) and check `UIAccessibility.isDifferentiateWithoutColorEnabled` at runtime.
3. **Detect High Contrast:** Register for `UITraitAccessibilityContrast` alongside `UITraitUserInterfaceStyle` and apply tighter contrast when `traitCollection.accessibilityContrast == .high`.
4. **Implement All Control States:** Provide visual feedback for normal, highlighted, selected, disabled, and focused states. Override `tintColorDidChange()` to respond when the system dims background controls.
5. **Dispatch Events Correctly:** Use `sendActions(for:)` to notify targets of state changes. Use `addAction(_:for:)` with `UIAction` (iOS 14+) to register handlers without `@objc` selectors.
6. **Add Haptic Feedback:** Use the appropriate `UIFeedbackGenerator` subclass to confirm interactions tactilely.
7. **Support Pointer (iPadOS):** Implement `UIPointerInteractionDelegate` to provide cursor snapping and hover effects.
8. **Define Sizing:** Override `intrinsicContentSize` and call `invalidateIntrinsicContentSize()` on content changes. Enforce a minimum touch target of 44×44pt; use `point(inside:with:)` to expand the hit area for visually smaller controls.
9. **Enforce Main Actor:** Mark the class with `@MainActor` to ensure all UI updates run on the main thread.
10. **Adapt to Appearance:** Use `registerForTraitChanges` (iOS 17+), registering for both `UITraitUserInterfaceStyle` and `UITraitAccessibilityContrast`. For apps supporting iOS 16 or earlier, refer to Apple's Supporting Dark Mode documentation for the appropriate legacy approach.
11. **Ensure Cross-Platform Compilation:** Use `#if os(...)` guards to select the correct base class (`UIControl` vs `NSControl`) and color resolution API (`traitCollection` vs `effectiveAppearance`).
12. **Use SF Symbols:** Prefer `UIImage(systemName:)` over custom assets for icons. Use `UIImage.SymbolConfiguration` to match text style, and rely on automatic RTL mirroring and Dark Mode adaptation.
13. **Use Liquid Glass Carefully:** Check `UIAccessibility.isReduceTransparencyEnabled` and fall back to an opaque material. Keep glass surfaces neutral and accent primary controls sparingly.
14. **Configure VoiceOver:** Set `isAccessibilityElement`, `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`, and `accessibilityTraits` on every custom control. Override `accessibilityActivate()`. Always localize these strings.
15. **Support Dynamic Type:** Use `UIFont.preferredFont(forTextStyle:)` or `UIFontMetrics` for custom fonts. Set `adjustsFontForContentSizeCategory = true` on all labels.
16. **Respect Reduce Motion:** Wrap animated state transitions in a `isReduceMotionEnabled` check and substitute instant appearance changes when motion is reduced.
17. **Support Button Shapes:** Draw a visible border or outline when `UIAccessibility.buttonShapesEnabled` is `true`. Register for the status-change notification.
18. **Localize All Strings:** Use `String(localized:defaultValue:comment:)` or `NSLocalizedString` in UIKit. In SwiftUI, `Text("key")` resolves via `LocalizedStringKey` — ensure keys exist in your strings file. Accessibility labels and hints must be localized.
19. **Support RTL Layout:** Use leading/trailing constraints and `NSDirectionalEdgeInsets`. Mirror directional custom images with `imageFlippedForRightToLeftLayoutDirection()`. Use SF Symbols where possible as they mirror automatically.
20. **Test Thoroughly:** Verify appearance and behaviour under Dark Mode, High Contrast, Reduce Transparency, Reduce Motion, Differentiate Without Color, Button Shapes, larger Dynamic Type sizes, and RTL pseudolanguage. Use Accessibility Inspector to validate VoiceOver labels, traits, and traversal order.

---

By following these instructions, agents will create controls that remain legible, accessible, and correctly localized across Apple platforms, and support dynamic appearance changes while utilizing the modern Liquid Glass aesthetic.

---

## References

1. [Color | Apple Developer Documentation](https://developer.apple.com/design/human-interface-guidelines/color)
2. [Supporting Dark Mode in your interface | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/supporting-dark-mode-in-your-interface)
3. [UIControl.State | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uicontrol/state-swift.struct)
4. [Color (Liquid Glass) | Apple Developer Documentation](https://developer.apple.com/design/human-interface-guidelines/color#Liquid-Glass-color)
5. [registerForTraitChanges(_:handler:) | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uitraitenvironment/registerfortraitchanges(_:handler:))
6. [UIFocusEnvironment | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uifocusenvironment)
7. [isDifferentiateWithoutColorEnabled | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiaccessibility/isdifferentiatewithoutcolorenabled)
8. [isReduceTransparencyEnabled | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiaccessibility/isreducetransparencyenabled)
9. [tvOS Human Interface Guidelines | Apple Developer Documentation](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos)
10. [Accessibility for UIKit | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/accessibility-for-uikit)
11. [accessibilityLabel | Apple Developer Documentation](https://developer.apple.com/documentation/objectivec/nsobject/accessibilitylabel)
12. [accessibilityTraits | Apple Developer Documentation](https://developer.apple.com/documentation/objectivec/nsobject/accessibilitytraits)
13. [Scaling Fonts Automatically | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uifont/scaling-fonts-automatically)
14. [UIFontMetrics | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uifontmetrics)
15. [isReduceMotionEnabled | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiaccessibility/isreducemotionenabled)
16. [buttonShapesEnabled | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiaccessibility/buttonshapesenabled)
17. [UITraitAccessibilityContrast | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uitraitaccessibilitycontrast)
18. [Localization | Apple Developer Documentation](https://developer.apple.com/documentation/xcode/localization)
19. [NSDirectionalEdgeInsets | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/nsdirectionaledgeinsets)
20. [semanticContentAttribute | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiview/semanticcontentattribute)
21. [imageFlippedForRightToLeftLayoutDirection() | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiimage/imageflippedforrighttoleftlayoutdirection())
22. [UIFeedbackGenerator | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uifeedbackgenerator)
23. [UIPointerInteraction | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uipointerinteraction)
24. [intrinsicContentSize | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiview/1622600-intrinsiccontentsize)
25. [point(inside:with:) | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiview/point(inside:with:))
26. [Concurrency in UIKit | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/concurrency_in_uikit)
27. [UIAction | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiaction)
28. [tintColorDidChange() | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiview/tintcolordidchange())
29. [SF Symbols | Apple Developer Documentation](https://developer.apple.com/design/human-interface-guidelines/sf-symbols)
30. [UIImage.SymbolConfiguration | Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiimage/symbolconfiguration)
