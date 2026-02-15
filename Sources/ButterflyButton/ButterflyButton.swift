// Copyright 2026 John Salerno.

import OSLog
import SwiftUI

@MainActor
/// A flip-style SwiftUI toggle control with gesture-driven animation.
public struct ButterflyButton: View {
    private enum UIConstants {
        static let defaultSideLength: CGFloat = 60
        static let defaultSpinDuration: TimeInterval = 2.0
        static let minimumHitSize: CGFloat = 44
        static let labelPadding: CGFloat = 2
        static let controlOpacityWhenDisabled: CGFloat = 0.72
    }

    private enum MotionConstants {
        static let reducedMotionDownScale: CGFloat = 0.92
        static let reducedMotionPhaseDuration: TimeInterval = 0.2
        static let reducedMotionTotalDuration: TimeInterval = 0.4
        static let externalStateMinimumDuration: TimeInterval = 0.1
        static let minimumHalfTurnDuration: TimeInterval = 0.05
    }

    @Binding public var isOn: Bool

    public var sideLength: CGFloat = UIConstants.defaultSideLength
    public var labelPlacement: LabelPlacement = .auto
    public var style: ButterflyButtonStyle = .init()

    public var spinDecelerationDuration: TimeInterval = UIConstants.defaultSpinDuration
    public var spinSpeed: Double = ButterflyValidation.defaultSpinSpeed
    public var enableFlickPhysics: Bool = true
    public var hapticsEnabled: Bool = true

    public var onSpinBegan: (() -> Void)? = nil
    public var onSpinCompleted: ((_ isOn: Bool) -> Void)? = nil
    public var onSpinEnded: ((_ isOn: Bool) -> Void)? = nil

    private var outerLabel: AnyView?

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rotationDegrees: Double = 0
    @State private var pulseScale: CGFloat = 1
    @State private var coordinator = ButterflyInteractionCoordinator()

    private let logger = Logger(subsystem: "com.yourorg.ButterflyButton", category: "control")

    /// Stores validated and resolved render values for a single frame.
    private struct ResolvedValues {
        let clampedSide: CGFloat
        let clampedStroke: CGFloat
        let validDuration: TimeInterval
        let theme: ButterflyTheme
        let medallionDiameter: CGFloat
        let rotationAxis: ButterflyRotationAxis
    }

    /// Creates a `ButterflyButton` with default medallion labels.
    ///
    /// - Parameters:
    ///   - isOn: Bound on/off state.
    ///   - sideLength: Side length in points.
    ///   - labelPlacement: Label position relative to the control.
    ///   - style: Visual style values.
    ///   - spinDecelerationDuration: Spin animation duration.
    ///   - spinSpeed: Spin speed multiplier.
    ///   - enableFlickPhysics: Enables velocity-based spin boost.
    ///   - hapticsEnabled: Reserved haptics toggle.
    ///   - onSpinBegan: Called when a spin starts.
    ///   - onSpinCompleted: Called after `isOn` updates from spin completion.
    ///   - onSpinEnded: Called at the end of a spin sequence.
    public init(
        isOn: Binding<Bool>,
        sideLength: CGFloat = 60,
        labelPlacement: LabelPlacement = .auto,
        style: ButterflyButtonStyle = .init(),
        spinDecelerationDuration: TimeInterval = 2.0,
        spinSpeed: Double = 1.0,
        enableFlickPhysics: Bool = true,
        hapticsEnabled: Bool = true,
        onSpinBegan: (() -> Void)? = nil,
        onSpinCompleted: ((_ isOn: Bool) -> Void)? = nil,
        onSpinEnded: ((_ isOn: Bool) -> Void)? = nil
    ) {
        self._isOn = isOn
        self.sideLength = sideLength
        self.labelPlacement = labelPlacement
        self.style = style
        self.spinDecelerationDuration = spinDecelerationDuration
        self.spinSpeed = spinSpeed
        self.enableFlickPhysics = enableFlickPhysics
        self.hapticsEnabled = hapticsEnabled
        self.onSpinBegan = onSpinBegan
        self.onSpinCompleted = onSpinCompleted
        self.onSpinEnded = onSpinEnded
        self.outerLabel = nil
    }

    /// Creates a `ButterflyButton` with a custom outer label view.
    ///
    /// - Parameters:
    ///   - isOn: Bound on/off state.
    ///   - sideLength: Side length in points.
    ///   - labelPlacement: Label position relative to the control.
    ///   - style: Visual style values.
    ///   - spinDecelerationDuration: Spin animation duration.
    ///   - spinSpeed: Spin speed multiplier.
    ///   - enableFlickPhysics: Enables velocity-based spin boost.
    ///   - hapticsEnabled: Reserved haptics toggle.
    ///   - onSpinBegan: Called when a spin starts.
    ///   - onSpinCompleted: Called after `isOn` updates from spin completion.
    ///   - onSpinEnded: Called at the end of a spin sequence.
    ///   - label: Builder for the outer label content.
    public init(
        isOn: Binding<Bool>,
        sideLength: CGFloat = 60,
        labelPlacement: LabelPlacement = .auto,
        style: ButterflyButtonStyle = .init(),
        spinDecelerationDuration: TimeInterval = 2.0,
        spinSpeed: Double = 1.0,
        enableFlickPhysics: Bool = true,
        hapticsEnabled: Bool = true,
        onSpinBegan: (() -> Void)? = nil,
        onSpinCompleted: ((_ isOn: Bool) -> Void)? = nil,
        onSpinEnded: ((_ isOn: Bool) -> Void)? = nil,
        @ViewBuilder label: () -> some View
    ) {
        self._isOn = isOn
        self.sideLength = sideLength
        self.labelPlacement = labelPlacement
        self.style = style
        self.spinDecelerationDuration = spinDecelerationDuration
        self.spinSpeed = spinSpeed
        self.enableFlickPhysics = enableFlickPhysics
        self.hapticsEnabled = hapticsEnabled
        self.onSpinBegan = onSpinBegan
        self.onSpinCompleted = onSpinCompleted
        self.onSpinEnded = onSpinEnded
        self.outerLabel = AnyView(label())
    }

    public var body: some View {
        let resolved = resolvedValues

        return OuterLabelView(
            sideLength: resolved.clampedSide,
            labelPadding: UIConstants.labelPadding,
            placement: labelPlacement,
            effectiveRTL: layoutDirection == .rightToLeft,
            label: outerLabel,
            mount: controlSurface(resolved: resolved)
        )
        .onAppear { handleAppear(resolved: resolved) }
        .onChange(of: isOn) { _, newValue in
            handleExternalStateChange(newValue: newValue)
        }
        .opacity(isEnabled ? 1.0 : UIConstants.controlOpacityWhenDisabled)
    }

    private var resolvedValues: ResolvedValues {
        let clampedSide = ButterflyValidation.clampedSideLength(sideLength)
        let clampedStroke = ButterflyValidation.clampedMountStrokeWidth(style.mountStrokeWidth, sideLength: clampedSide)
        let validDuration = ButterflyValidation.validSpinDuration(spinDecelerationDuration)

        let theme = ButterflyTheme.resolve(
            colorScheme: colorScheme,
            contrast: colorSchemeContrast,
            isEnabled: isEnabled,
            mountStrokeColor: style.mountStrokeColor,
            axleColor: style.axleColor,
            medallionTopColor: style.medallionTopColor,
            medallionBottomColor: style.medallionBottomColor,
            medallionEdgeColor: style.medallionEdgeColor,
            medallionLabelColor: style.medallionLabelColor
        )

        return ResolvedValues(
            clampedSide: clampedSide,
            clampedStroke: clampedStroke,
            validDuration: validDuration,
            theme: theme,
            medallionDiameter: ButterflyValidation.medallionDiameter(sideLength: clampedSide, strokeWidth: clampedStroke),
            rotationAxis: ButterflyValidation.rotationAxis(for: style.axleOrientation)
        )
    }

    /// Builds the interactive control surface and accessibility behavior.
    ///
    /// - Parameter resolved: Precomputed render values for current state.
    /// - Returns: A view tree for the control surface.
    private func controlSurface(resolved: ResolvedValues) -> some View {
        ZStack {
            MountView(
                sideLength: resolved.clampedSide,
                strokeWidth: resolved.clampedStroke,
                strokeColor: resolved.theme.mountStroke,
                background: style.mountBackground,
                systemBackground: resolved.theme.mountBackground
            )

            AxleView(
                sideLength: resolved.clampedSide,
                strokeWidth: 2,
                orientation: style.axleOrientation,
                color: resolved.theme.axle
            )

            MedallionView(
                diameter: resolved.medallionDiameter,
                strokeWidth: style.medallionStrokeWidth,
                topColor: resolved.theme.medallionTop,
                bottomColor: resolved.theme.medallionBottom,
                edgeColor: resolved.theme.medallionEdge,
                topImage: style.medallionTopImage,
                bottomImage: style.medallionBottomImage,
                topLabel: style.medallionTopLabel,
                bottomLabel: style.medallionBottomLabel,
                labelFont: style.medallionLabelFont ?? .caption,
                labelColor: resolved.theme.medallionLabel,
                shape: style.medallionShape,
                rotationDegrees: rotationDegrees,
                rotationAxis: resolved.rotationAxis
            )
            .scaleEffect(pulseScale)
        }
        .frame(width: resolved.clampedSide, height: resolved.clampedSide)
        .contentShape(Rectangle())
        .gesture(spinGesture(resolved: resolved))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("ButterflyButton"))
        .accessibilityValue(Text(isOn ? style.medallionTopLabel : style.medallionBottomLabel))
        .accessibilityAction(named: Text("Toggle")) {
            guard isEnabled else { return }
            triggerSpin(direction: isOn ? .topToBottom : .bottomToTop, velocity: 0, duration: resolved.validDuration)
        }
        .frame(minWidth: UIConstants.minimumHitSize, minHeight: UIConstants.minimumHitSize)
        .allowsHitTesting(isEnabled)
    }

    /// Creates the drag gesture used to infer spin direction and velocity.
    ///
    /// - Parameter resolved: Precomputed render values for current state.
    /// - Returns: A drag gesture that triggers a spin when ended.
    private func spinGesture(resolved: ResolvedValues) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                guard isEnabled else { return }
                let direction = ButterflyValidation.direction(
                    for: value.location,
                    in: CGSize(width: resolved.clampedSide, height: resolved.clampedSide)
                )
                let velocity = predictedVelocityMagnitude(for: value)
                triggerSpin(direction: direction, velocity: velocity, duration: resolved.validDuration)
            }
    }

    /// Computes gesture velocity magnitude from current and predicted locations.
    ///
    /// - Parameter value: Final drag value.
    /// - Returns: Velocity magnitude used for flick physics.
    private func predictedVelocityMagnitude(for value: DragGesture.Value) -> CGFloat {
        let deltaX = value.predictedEndLocation.x - value.location.x
        let deltaY = value.predictedEndLocation.y - value.location.y
        return hypot(deltaX, deltaY)
    }

    /// Applies external binding changes using animation policy from the coordinator.
    ///
    /// - Parameter newValue: New external `isOn` value.
    private func handleExternalStateChange(newValue: Bool) {
        switch coordinator.actionForExternalStateChange(newValue: newValue, isEnabled: isEnabled) {
        case .none:
            return
        case let .animate(sign):
            animateExternalStateChange(newValue: newValue, sign: sign)
        }
    }

    /// Animates a state change initiated outside of local gesture interaction.
    ///
    /// - Parameters:
    ///   - newValue: Target external `isOn` value.
    ///   - sign: Rotation direction sign.
    private func animateExternalStateChange(newValue: Bool, sign: Double) {
        let duration = max(
            ButterflyValidation.validSpinDuration(spinDecelerationDuration),
            MotionConstants.externalStateMinimumDuration
        )
        let speed = ButterflyValidation.validSpinSpeed(spinSpeed)
        let totalDegrees = ButterflyValidation.spinDegrees(
            duration: duration,
            spinSpeed: speed,
            velocity: 0,
            enableFlickPhysics: false
        )

        Task { @MainActor in
            let token = coordinator.beginSpin()
            let halfTurns = ButterflyValidation.fittedHalfTurns(
                from: totalDegrees,
                duration: duration,
                minimumSegmentDuration: MotionConstants.minimumHalfTurnDuration
            )
            await animateHalfTurns(
                token: token,
                halfTurns: halfTurns,
                sign: sign,
                totalDuration: duration
            )
            guard coordinator.isCurrentSpinToken(token) else { return }
            guard isOn == newValue else { return }
            rotationDegrees = ButterflyValidation.snappedStopRotationDegrees(
                current: rotationDegrees,
                isOn: newValue
            )
            onSpinEnded?(isOn)
        }
    }

    /// Starts a spin sequence for user interaction.
    ///
    /// - Parameters:
    ///   - direction: Requested spin direction.
    ///   - velocity: Gesture velocity magnitude.
    ///   - duration: Total spin duration.
    private func triggerSpin(direction: SpinDirection, velocity: CGFloat, duration: TimeInterval) {
        let token = coordinator.beginSpin()
        let targetIsOn = !isOn
        onSpinBegan?()

        let mode = ButterflyAnimationMode.from(reduceMotion: reduceMotion)
        if mode == .reducedMotion {
            withAnimation(.easeInOut(duration: MotionConstants.reducedMotionPhaseDuration)) {
                pulseScale = MotionConstants.reducedMotionDownScale
            }
            withAnimation(.easeInOut(duration: MotionConstants.reducedMotionPhaseDuration).delay(MotionConstants.reducedMotionPhaseDuration)) {
                pulseScale = 1
            }
            Task { @MainActor in
                guard await sleepForAnimationInterval(
                    MotionConstants.reducedMotionTotalDuration,
                    context: "reducedMotionCompletion"
                ) else { return }
                finalizeSpinIfTokenIsCurrent(token: token, targetIsOn: targetIsOn)
            }
            return
        }

        let totalDegrees = ButterflyValidation.spinDegrees(
            duration: duration,
            spinSpeed: ButterflyValidation.validSpinSpeed(spinSpeed),
            velocity: velocity,
            enableFlickPhysics: enableFlickPhysics
        )
        let sign = direction == .topToBottom ? 1.0 : -1.0
        let halfTurns = ButterflyValidation.fittedHalfTurns(
            from: totalDegrees,
            duration: duration,
            minimumSegmentDuration: MotionConstants.minimumHalfTurnDuration
        )

        Task { @MainActor in
            await animateHalfTurns(
                token: token,
                halfTurns: halfTurns,
                sign: sign,
                totalDuration: duration
            )
            finalizeSpinIfTokenIsCurrent(token: token, targetIsOn: targetIsOn)
        }
    }

    /// Finalizes a spin if the provided token still matches the active spin.
    ///
    /// - Parameters:
    ///   - token: Token captured when the spin started.
    ///   - targetIsOn: Target state expected at completion.
    private func finalizeSpinIfTokenIsCurrent(token: UInt64, targetIsOn: Bool) {
        guard coordinator.isCurrentSpinToken(token) else { return }
        coordinator.markInternalToggle()
        let snapped = ButterflyValidation.snappedStopRotationDegrees(
            current: rotationDegrees,
            isOn: targetIsOn
        )
        rotationDegrees = snapped
        isOn = ButterflyValidation.visibleTopFace(rotationDegrees: snapped)
        onSpinCompleted?(isOn)
        onSpinEnded?(isOn)
    }

    /// Animates discrete half-turn segments for the current spin.
    ///
    /// - Parameters:
    ///   - token: Token captured when the spin started.
    ///   - halfTurns: Number of half-turn segments to animate.
    ///   - sign: Rotation direction sign.
    ///   - totalDuration: Requested duration for the full spin.
    private func animateHalfTurns(token: UInt64, halfTurns: Int, sign: Double, totalDuration: TimeInterval) async {
        let segmentDuration = max(
            totalDuration / Double(max(halfTurns, 1)),
            0.001
        )

        for _ in 0..<halfTurns {
            guard coordinator.isCurrentSpinToken(token) else { return }
            withAnimation(.linear(duration: segmentDuration)) {
                rotationDegrees += sign * 180
            }
            guard await sleepForAnimationInterval(
                segmentDuration,
                context: "halfTurnSegment"
            ) else { return }
        }
    }

    /// Sleeps for an animation interval with explicit cancellation/error handling.
    ///
    /// - Parameters:
    ///   - seconds: Interval length in seconds.
    ///   - context: Log context for diagnostics.
    /// - Returns: `true` when sleep completes; otherwise `false`.
    private func sleepForAnimationInterval(_ seconds: TimeInterval, context: StaticString) async -> Bool {
        do {
            try await Task.sleep(for: .seconds(seconds))
            return true
        } catch is CancellationError {
            logger.debug("animation sleep cancelled: \(context)")
            return false
        } catch {
            logger.error("animation sleep failed: \(context)")
            return false
        }
    }

    /// Initializes baseline render state and emits configuration warnings.
    ///
    /// - Parameter resolved: Precomputed render values for current state.
    private func handleAppear(resolved: ResolvedValues) {
        rotationDegrees = ButterflyValidation.baselineRotationDegrees(for: isOn)
        coordinator.initialize(isOn: isOn)

        if spinDecelerationDuration <= 0 {
            logger.warning("spinDecelerationDuration <= 0. Falling back to 2.0s")
        }
        if spinSpeed <= 0 {
            logger.warning("spinSpeed <= 0. Falling back to 1.0")
        }
        if resolved.clampedSide != sideLength {
            logger.warning("sideLength clamped from \(sideLength, privacy: .public) to \(resolved.clampedSide, privacy: .public)")
        }
        if resolved.clampedStroke != style.mountStrokeWidth {
            logger.warning("mountStrokeWidth clamped from \(style.mountStrokeWidth, privacy: .public) to \(resolved.clampedStroke, privacy: .public)")
        }
    }
}

/// Preview host showing size and orientation variants of the control.
private struct ButterflyPreviewHost: View {
    @State private var isOn = true
    @State private var second = false
    @State private var third = true

    var body: some View {
        VStack(spacing: 20) {
            ButterflyButton(
                isOn: $isOn,
                sideLength: 44,
                style: ButterflyButtonStyle(axleOrientation: .horizontal)
            ) { Text("44") }
            ButterflyButton(
                isOn: $second,
                sideLength: 60,
                style: ButterflyButtonStyle(axleOrientation: .vertical)
            ) { Text("60") }
            ButterflyButton(
                isOn: $third,
                sideLength: 120,
                style: ButterflyButtonStyle(axleOrientation: .diagonalLTR)
            ) { Text("120") }
        }
        .padding()
    }
}

#Preview("Default") {
    ButterflyPreviewHost()
}
