// Copyright 2026 John Salerno.

import Foundation
import SwiftUI
import ButterflyButton
#if canImport(AppKit)
import AppKit
#endif

// MARK: - App entry point

@main
/// Entry point for the macOS ButterflyButton demo app.
struct ButterflyButtonMacDemoApp: App {
    private enum Constants {
        static let WINDOW_MIN_WIDTH: CGFloat = 980
        static let WINDOW_MIN_HEIGHT: CGFloat = 680
    }

    var body: some Scene {
        WindowGroup("ButterflyButton macOS Demo") {
            DemoView()
                .frame(minWidth: Constants.WINDOW_MIN_WIDTH, minHeight: Constants.WINDOW_MIN_HEIGHT)
        }
        .windowResizability(.contentSize)
    }
}

private extension Color {
    static var platformWindowBackground: Color {
        #if canImport(AppKit)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
    static var platformControlBackground: Color {
        #if canImport(AppKit)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }
}

// MARK: - Adaptive card background modifier

/// Applies a rounded-rectangle background that uses a solid system colour when
/// Reduce Transparency is on, and a material otherwise.
private struct AdaptiveCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let solidColor: Color
    let material: any ShapeStyle

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: cornerRadius).fill(solidColor)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius).fill(AnyShapeStyle(material))
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private extension View {
    func adaptiveCard(cornerRadius: CGFloat, solid: Color, material: some ShapeStyle) -> some View {
        modifier(AdaptiveCardModifier(cornerRadius: cornerRadius, solidColor: solid, material: material))
    }
}

// MARK: - Demo view

/// Interactive demo surface for single-control and grid scenarios.
struct DemoView: View {

    // MARK: Constants

    private enum Constants {
        // Layout and spacing
        static let ROOT_PADDING: CGFloat = 16
        static let SECTION_SPACING: CGFloat = 24
        static let CONTROL_PANEL_WIDTH: CGFloat = 380
        static let CONTROL_PANEL_SPACING: CGFloat = 14
        // Cards and corners
        static let CARD_CORNER_RADIUS: CGFloat = 16
        static let GRID_CARD_CORNER_RADIUS: CGFloat = 12
        static let PANEL_CORNER_RADIUS: CGFloat = 10
        // Paddings
        static let OUTER_PADDING: CGFloat = 30
        static let GRID_OUTER_PADDING: CGFloat = 12
        // Grid geometry
        static let GRID_MIN_DIMENSION: Int = 2
        static let GRID_MAX_DIMENSION: Int = 20
        static let GRID_SPACING: CGFloat = 4
        static let GRID_CELL_MIN: CGFloat = 18
        static let GRID_CELL_MAX: CGFloat = 64
        static let PERF_DIMENSION_THRESHOLD: Int = 14
        // Performance caps
        static let PERF_MAX_SPIN_DURATION: Double = 0.45
        static let PERF_MAX_SPIN_SPEED: Double = 0.8
        // Event log
        static let EVENT_ROW_SPACING: CGFloat = 3
        static let EVENT_ROW_CORNER_RADIUS: CGFloat = 4
        static let EVENT_SCROLL_MAX_HEIGHT: CGFloat = 220
        static let EVENT_LOG_MAX_LINES: Int = 30
        // Slider value labels (unified width covers all formatted values)
        static let SLIDER_VALUE_WIDTH: CGFloat = 64
        // Defaults
        static let DEFAULT_SIDE_LENGTH: Double = 60
        static let DEFAULT_STROKE_WIDTH: Double = 2
        static let DEFAULT_SPIN_DURATION: Double = 2
        static let DEFAULT_SPIN_SPEED: Double = 1
        static let DEFAULT_GRID_DIMENSION: Int = 9
    }

    // MARK: Tab

    private enum Tab { case single, grid }

    // MARK: Static helpers

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    // MARK: State

    @State private var selectedTab: Tab = .single

    @State private var isOn = true
    @State private var sideLength: Double = Constants.DEFAULT_SIDE_LENGTH
    @State private var strokeWidth: Double = Constants.DEFAULT_STROKE_WIDTH
    @State private var spinDuration: Double = Constants.DEFAULT_SPIN_DURATION
    @State private var spinSpeed: Double = Constants.DEFAULT_SPIN_SPEED
    @State private var enableFlickPhysics = true
    @State private var hapticsEnabled = true
    @State private var isControlDisabled = false
    @State private var orientation: AxleOrientation = .horizontal
    @State private var medallionShape: MedallionShape = .circle
    @State private var placement: LabelPlacement = .top
    @State private var eventLog: [String] = []

    @State private var gridDimension: Int = Constants.DEFAULT_GRID_DIMENSION
    @State private var gridValues: [Int] = Array(repeating: 0, count: Constants.DEFAULT_GRID_DIMENSION * Constants.DEFAULT_GRID_DIMENSION)
    @State private var gridPerformanceModeEnabled: Bool = true

    // MARK: Body

    var body: some View {
        TabView(selection: $selectedTab) {
            singleControlTab
                .tabItem { Text("Single") }
                .tag(Tab.single)

            gridControlTab
                .tabItem { Text("Grid") }
                .tag(Tab.grid)
        }
        .padding(Constants.ROOT_PADDING)
        .onAppear {
            resizeGrid(to: gridDimension)
        }
    }
}

// MARK: - Views

private extension DemoView {

    var singleControlTab: some View {
        HStack(spacing: Constants.SECTION_SPACING) {
            controlPanel
                .frame(width: Constants.CONTROL_PANEL_WIDTH)

            Divider()

            VStack(spacing: Constants.SECTION_SPACING) {
                Text("Visual Test Surface")
                    .font(.title3.weight(.medium))

                ButterflyButton(
                    isOn: $isOn,
                    sideLength: sideLength,
                    labelPlacement: placement,
                    style: butterflyStyle(mountStrokeWidth: strokeWidth),
                    spinDecelerationDuration: spinDuration,
                    spinSpeed: spinSpeed,
                    enableFlickPhysics: enableFlickPhysics,
                    hapticsEnabled: hapticsEnabled,
                    onSpinBegan: {
                        appendLog("spin began")
                    },
                    onSpinCompleted: { newValue in
                        appendLog("spin completed isOn=\(newValue)")
                    },
                    onSpinEnded: { newValue in
                        isOn = newValue
                        appendLog("spin ended isOn=\(newValue)")
                    }
                ) {
                    Text("Butterfly")
                        .font(.headline)
                }
                .tint(.white)
                .disabled(isControlDisabled)
                .padding(Constants.OUTER_PADDING)
                .adaptiveCard(
                    cornerRadius: Constants.CARD_CORNER_RADIUS,
                    solid: Color.platformWindowBackground,
                    material: .regularMaterial
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Constants.SECTION_SPACING)
        }
    }

    var gridControlTab: some View {
        HStack(spacing: Constants.SECTION_SPACING) {
            VStack(alignment: .leading, spacing: Constants.CONTROL_PANEL_SPACING) {
                Text("Grid Test")
                    .font(.title2.weight(.semibold))

                HStack {
                    Text("Grid Size")
                    Slider(
                        value: Binding(
                            get: { Double(gridDimension) },
                            set: { newValue in resizeGrid(to: Int(newValue.rounded())) }
                        ),
                        in: Double(Constants.GRID_MIN_DIMENSION)...Double(Constants.GRID_MAX_DIMENSION),
                        step: 1
                    ) { editing in
                        if !editing { appendLog("gridSize → \(gridDimension)x\(gridDimension)") }
                    }
                    Text("\(gridDimension)x\(gridDimension)")
                        .monospacedDigit()
                        .frame(width: Constants.SLIDER_VALUE_WIDTH)
                }

                Button("Reset Grid To 0") {
                    resizeGrid(to: gridDimension)
                    appendLog("reset grid to 0")
                }

                Toggle("Grid Performance Mode", isOn: $gridPerformanceModeEnabled)
                    .onChange(of: gridPerformanceModeEnabled) { _, new in appendLog("gridPerf → \(new)") }

                Text("Row-major values (0/1)")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.EVENT_ROW_SPACING) {
                        ForEach(0..<gridDimension, id: \.self) { row in
                            let start = row * gridDimension
                            let end = start + gridDimension
                            if end <= gridValues.count {
                                let rowString = gridValues[start..<end].map(String.init).joined(separator: " ")
                                Text(rowString)
                                    .font(.caption2.monospacedDigit())
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: Constants.EVENT_ROW_CORNER_RADIUS)
                                            .fill(Color.platformControlBackground)
                                    )
                            }
                        }
                    }
                }
                .frame(maxHeight: Constants.EVENT_SCROLL_MAX_HEIGHT)
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: Constants.PANEL_CORNER_RADIUS))

                Spacer()
            }
            .frame(width: Constants.CONTROL_PANEL_WIDTH)

            Divider()

            GeometryReader { geometry in
                let spacing: CGFloat = Constants.GRID_SPACING
                let availableWidth = max(geometry.size.width - CGFloat(gridDimension - 1) * spacing, 100)
                let cellSide = max(min(availableWidth / CGFloat(gridDimension), Constants.GRID_CELL_MAX), Constants.GRID_CELL_MIN)
                let columns = Array(repeating: GridItem(.fixed(cellSide), spacing: spacing), count: gridDimension)
                let gridStyle = butterflyStyle(mountStrokeWidth: max(1, cellSide * 0.05))
                let usePerformanceMode = gridPerformanceModeEnabled || gridDimension >= Constants.PERF_DIMENSION_THRESHOLD
                let gridSpinDuration = usePerformanceMode ? min(spinDuration, Constants.PERF_MAX_SPIN_DURATION) : spinDuration
                let gridSpinSpeed = usePerformanceMode ? min(spinSpeed, Constants.PERF_MAX_SPIN_SPEED) : spinSpeed
                let gridFlickPhysics = usePerformanceMode ? false : enableFlickPhysics
                let gridHapticsEnabled = usePerformanceMode ? false : hapticsEnabled

                ScrollView([.vertical, .horizontal]) {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(0..<(gridDimension * gridDimension), id: \.self) { index in
                            ButterflyButton(
                                isOn: cellBinding(for: index),
                                sideLength: cellSide,
                                style: gridStyle,
                                spinDecelerationDuration: gridSpinDuration,
                                spinSpeed: gridSpinSpeed,
                                enableFlickPhysics: gridFlickPhysics,
                                hapticsEnabled: gridHapticsEnabled,
                                onSpinEnded: { newValue in
                                    appendLog("grid[\(index)] isOn=\(newValue)")
                                }
                            )
                            .disabled(isControlDisabled)
                        }
                    }
                    .padding(Constants.GRID_OUTER_PADDING)
                    .adaptiveCard(
                        cornerRadius: Constants.GRID_CARD_CORNER_RADIUS,
                        solid: Color.platformControlBackground,
                        material: .thinMaterial
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(Constants.SECTION_SPACING)
        }
    }

    var controlPanel: some View {
        VStack(alignment: .leading, spacing: Constants.CONTROL_PANEL_SPACING) {
            Text("ButterflyButton Controls")
                .font(.title2.weight(.semibold))

            // MARK: State controls
            Toggle("On / Off", isOn: $isOn)
                .disabled(isControlDisabled)
                .onChange(of: isOn) { _, new in appendLog("isOn → \(new)") }
            Toggle("Enable Flick Physics", isOn: $enableFlickPhysics)
                .onChange(of: enableFlickPhysics) { _, new in appendLog("flickPhysics → \(new)") }
            Toggle("Haptics Enabled", isOn: $hapticsEnabled)
                .onChange(of: hapticsEnabled) { _, new in appendLog("haptics → \(new)") }
            Toggle("Disable ButterflyButton", isOn: $isControlDisabled)
                .onChange(of: isControlDisabled) { _, new in appendLog("disabled → \(new)") }

            // MARK: Dimension controls
            HStack {
                Text("Size")
                Slider(value: $sideLength, in: 44...140, step: 1) { editing in
                    if !editing { appendLog("size → \(Int(sideLength))") }
                }
                Text("\(Int(sideLength))")
                    .monospacedDigit()
                    .frame(width: Constants.SLIDER_VALUE_WIDTH)
            }

            HStack {
                Text("Mount Stroke")
                Slider(value: $strokeWidth, in: 1...14, step: 0.5) { editing in
                    if !editing { appendLog("stroke → \(String(format: "%.1f", strokeWidth))") }
                }
                Text(String(format: "%.1f", strokeWidth))
                    .monospacedDigit()
                    .frame(width: Constants.SLIDER_VALUE_WIDTH)
            }

            HStack {
                Text("Spin Duration")
                Slider(value: $spinDuration, in: 0.2...4.0, step: 0.1) { editing in
                    if !editing { appendLog("duration → \(String(format: "%.1fs", spinDuration))") }
                }
                Text(String(format: "%.1fs", spinDuration))
                    .monospacedDigit()
                    .frame(width: Constants.SLIDER_VALUE_WIDTH)
            }

            HStack {
                Text("Spin Speed")
                Slider(value: $spinSpeed, in: 0.25...3.0, step: 0.05) { editing in
                    if !editing { appendLog("speed → \(String(format: "%.2fx", spinSpeed))") }
                }
                Text(String(format: "%.2fx", spinSpeed))
                    .monospacedDigit()
                    .frame(width: Constants.SLIDER_VALUE_WIDTH)
            }

            // MARK: Style controls
            Picker("Axle Orientation", selection: $orientation) {
                Text("Horizontal").tag(AxleOrientation.horizontal)
                Text("Vertical").tag(AxleOrientation.vertical)
                Text("Diagonal LTR").tag(AxleOrientation.diagonalLTR)
                Text("Diagonal RTL").tag(AxleOrientation.diagonalRTL)
            }
            .onChange(of: orientation) { _, new in appendLog("orientation → \(new)") }

            Picker("Label Placement", selection: $placement) {
                Text("Top").tag(LabelPlacement.top)
                Text("Bottom").tag(LabelPlacement.bottom)
                Text("Leading").tag(LabelPlacement.leading)
                Text("Trailing").tag(LabelPlacement.trailing)
                Text("Auto").tag(LabelPlacement.auto)
            }
            .onChange(of: placement) { _, new in appendLog("placement → \(new)") }

            Picker("Medallion Shape", selection: $medallionShape) {
                Text("Circle").tag(MedallionShape.circle)
                Text("Square").tag(MedallionShape.square)
            }
            .onChange(of: medallionShape) { _, new in appendLog("shape → \(new)") }

            // MARK: Reset
            Button("Reset Defaults") {
                sideLength = Constants.DEFAULT_SIDE_LENGTH
                strokeWidth = Constants.DEFAULT_STROKE_WIDTH
                spinDuration = Constants.DEFAULT_SPIN_DURATION
                spinSpeed = Constants.DEFAULT_SPIN_SPEED
                enableFlickPhysics = true
                hapticsEnabled = true
                isControlDisabled = false
                orientation = .horizontal
                medallionShape = .circle
                placement = .top
                appendLog("reset defaults")
            }

            Spacer(minLength: 10)

            // MARK: Event log
            Text("Event Log")
                .font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.EVENT_ROW_SPACING) {
                    ForEach(Array(eventLog.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: Constants.EVENT_SCROLL_MAX_HEIGHT)
            .padding(8)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Constants.PANEL_CORNER_RADIUS))

            Button("Clear Log") {
                eventLog.removeAll(keepingCapacity: true)
            }
        }
    }
}

// MARK: - Helpers

private extension DemoView {

    /// Writes a message to the system console via NSLog.
    func demoLog(_ message: String) {
        NSLog("[ButterflyDemo] %@", message)
    }

    /// Like precondition, but only traps in Debug builds; logs and continues in Release.
    @discardableResult
    func assertOrClamp(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String) -> Bool {
        #if DEBUG
        precondition(condition(), message())
        return condition()
        #else
        let ok = condition()
        if !ok { demoLog("ASSERTION WOULD FAIL: \(message())") }
        return ok
        #endif
    }

    /// Builds a `ButterflyButtonStyle` from the current control panel selections.
    ///
    /// Label and image parameters are passed as nil / empty / clear because this
    /// demo exercises button mechanics only, not label or image customisation.
    ///
    /// - Parameter mountStrokeWidth: Stroke width to apply to the mount ring.
    /// - Returns: Style configured from current demo selections.
    func butterflyStyle(mountStrokeWidth: CGFloat) -> ButterflyButtonStyle {
        ButterflyButtonStyle(
            mountStrokeWidth: mountStrokeWidth,
            mountBackground: .systemAutomatic,
            axleOrientation: orientation,
            medallionTopImage: nil,
            medallionBottomImage: nil,
            medallionTopLabel: "",
            medallionBottomLabel: "",
            medallionLabelColor: .clear,
            medallionShape: medallionShape
        )
    }

    /// Resizes the demo grid and resets all cell values to 0.
    ///
    /// - Parameter dimension: Requested grid dimension (clamped to valid range).
    func resizeGrid(to dimension: Int) {
        let safeDimension = min(max(dimension, Constants.GRID_MIN_DIMENSION), Constants.GRID_MAX_DIMENSION)
        demoLog("Resizing grid to \(safeDimension)x\(safeDimension)")
        gridDimension = safeDimension
        gridValues = Array(repeating: 0, count: safeDimension * safeDimension)
    }

    /// Creates a `Bool` binding for a row-major grid cell index.
    ///
    /// - Parameter index: Row-major cell index.
    /// - Returns: Binding that reads/writes the cell as on/off.
    func cellBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: {
                let ok = assertOrClamp(gridValues.indices.contains(index), "Grid index out of bounds (get): \(index) for dim=\(gridDimension)")
                guard ok else { return false }
                return gridValues[index] == 1
            },
            set: { newValue in
                let ok = assertOrClamp(gridValues.indices.contains(index), "Grid index out of bounds (set): \(index) for dim=\(gridDimension)")
                guard ok else { return }
                gridValues[index] = newValue ? 1 : 0
            }
        )
    }

    /// Prepends a timestamped message to the event log and mirrors it to the console.
    ///
    /// - Parameter message: Log message text.
    func appendLog(_ message: String) {
        demoLog(message)
        let timestamp = Self.timestampFormatter.string(from: Date())
        eventLog.insert("[\(timestamp)] \(message)", at: 0)
        if eventLog.count > Constants.EVENT_LOG_MAX_LINES {
            eventLog.removeLast(eventLog.count - Constants.EVENT_LOG_MAX_LINES)
        }
    }
}

