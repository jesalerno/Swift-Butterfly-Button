// Copyright 2026 John Salerno.

import Foundation
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
import ButterflyButton

// MARK: - App entry point

/// Entry point for the iOS ButterflyButton demo app.
///
/// Installs a simple uncaught exception handler and logs app launch for debugging.
@main
struct ButterflyButtoniOSDemoApp: App {
    init() {
        // Install an uncaught exception handler to surface messages in the console
        NSSetUncaughtExceptionHandler { exception in
            let symbols = exception.callStackSymbols.joined(separator: "\n")
            NSLog(
                "[ButterflyDemo] Uncaught exception: %@\nReason: %@\nStack:\n%@",
                exception.name.rawValue,
                exception.reason ?? "<none>",
                symbols,
            )
        }
        // Log that the demo app launched
        NSLog("[ButterflyDemo] Launching ButterflyButton iOS Demo…")
    }

    var body: some Scene {
        WindowGroup("ButterflyButton iOS Demo") {
            IOSDemoView()
                .onAppear { NSLog("[ButterflyDemo] Root view appeared") }
        }
    }
}

// MARK: - Demo view

/// Interactive iOS demo surface showcasing single-control configuration and a grid stress test.
struct IOSDemoView: View {
    // MARK: Constants

    /// Layout, performance, and default configuration constants for the iOS demo UI.
    private enum Constants {
        // Layout
        static let ROOT_HORIZONTAL_PADDING: CGFloat = 16
        static let ROOT_VERTICAL_PADDING: CGFloat = 20
        static let SECTION_SPACING: CGFloat = 20
        static let GRID_SECTION_SPACING: CGFloat = 14
        static let CARD_CORNER_RADIUS: CGFloat = 16
        // Grid
        static let GRID_MIN_DIMENSION: Int = 2
        static let GRID_MAX_DIMENSION: Int = 12
        static let GRID_ITEM_MIN: CGFloat = 18
        static let GRID_ITEM_MAX: CGFloat = 56
        static let GRID_SPACING: CGFloat = 4
        static let PERF_DIMENSION_THRESHOLD: Int = 9
        static let PERF_MAX_SPIN_DURATION: Double = 0.45
        static let PERF_MAX_SPIN_SPEED: Double = 0.8
        /// Diameter passed to `ButterflyButton` inside each grid cell.
        static let GRID_BUTTON_SIDE_LENGTH: CGFloat = 40
        // Event log and matrix
        static let EVENT_LOG_MAX_LINES: Int = 30
        static let EVENT_ROW_CORNER_RADIUS: CGFloat = 4
        // Height ratios for log/matrix panels (applied to the measured container height).
        static let LOG_HEIGHT_RATIO: CGFloat = 0.45
        static let GRID_LOG_HEIGHT_RATIO: CGFloat = 0.20
        // Defaults
        static let DEFAULT_SIDE_LENGTH: Double = 64
        static let DEFAULT_STROKE_WIDTH: Double = 2
        static let DEFAULT_SPIN_DURATION: Double = 1.8
        static let DEFAULT_SPIN_SPEED: Double = 1
        static let DEFAULT_GRID_DIMENSION: Int = 6
    }

    // MARK: Tab

    /// Tabs available in the demo: a single control panel and a grid.
    private enum Tab { case single, grid }

    // MARK: Grid info panel

    /// Selects which info panel to show in the Grid tab controls bar.
    private enum GridInfoPanel { case eventLog, matrix }

    // MARK: Static helpers

    /// Formatter for timestamps in event log entries ("HH:mm:ss").
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Caption-monospaced line height (≈ 16 pt) plus spacing (4 pt), totaling 20 pt per log entry.
    private static let logLineHeight: CGFloat = 20

    // MARK: State

    /// Demo state backing the controls, event log, and grid configuration.
    @State private var selectedTab: Tab = .single
    /// Height of the TabView content area, captured at first render and used for log/matrix sizing.
    /// Falls back to 667 pt (iPhone SE logical height) before the first layout pass completes.
    @State private var availableHeight: CGFloat = 667

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
    @State private var gridValues: [Int] = Array(
        repeating: 0,
        count: Constants.DEFAULT_GRID_DIMENSION * Constants.DEFAULT_GRID_DIMENSION,
    )
    @State private var gridPerformanceModeEnabled = true
    @State private var gridInfoPanel: GridInfoPanel = .eventLog

    // MARK: Computed

    /// Maximum height for the event log in the Single tab (~45% of container height), in points.
    private var logMaxHeight: CGFloat {
        availableHeight * Constants.LOG_HEIGHT_RATIO
    }

    /// Maximum height for the event log or matrix in the Grid tab controls bar (~20% of container height), in points.
    private var gridLogMaxHeight: CGFloat {
        availableHeight * Constants.GRID_LOG_HEIGHT_RATIO
    }

    // MARK: Body

    /// Builds the tabbed demo interface and seeds initial grid state on appear.
    var body: some View {
        TabView(selection: $selectedTab) {
            singleControlTab
                .tabItem { Label("Single", systemImage: "dial.medium") }
                .tag(Tab.single)

            gridControlTab
                .tabItem { Label("Grid", systemImage: "square.grid.3x3.fill") }
                .tag(Tab.grid)
        }
        .background(
            // GeometryReader inside .background does not disturb the TabView's own layout.
            // UIScreen.main is deprecated in iOS 16; reading geometry here is the modern replacement.
            GeometryReader { geo in
                Color.clear.onAppear { availableHeight = geo.size.height }
            },
        )
        .onAppear {
            demoLog("TabView appear; initializing grid to \(gridDimension)x\(gridDimension)")
            resizeGrid(to: gridDimension)
        }
    }
}

// MARK: - Views

private extension IOSDemoView {
    var singleControlTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Pinned preview — stays fixed while form scrolls

                HStack {
                    Spacer()
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
                            demoLog("[Single] spin began")
                            appendLog("spin began")
                        },
                        onSpinCompleted: { newValue in
                            demoLog("[Single] spin completed isOn=\(newValue)")
                            appendLog("spin completed isOn=\(newValue)")
                        },
                        onSpinEnded: { newValue in
                            isOn = newValue
                            demoLog("[Single] spin ended isOn=\(newValue)")
                            appendLog("spin ended isOn=\(newValue)")
                        },
                        label: {
                            Text("Butterfly")
                                .font(.headline)
                        },
                    )
                    .disabled(isControlDisabled)
                    Spacer()
                }
                .padding(.vertical, Constants.ROOT_VERTICAL_PADDING)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
                Divider()

                // MARK: Scrollable controls

                Form {
                    // MARK: State

                    Section("State") {
                        Toggle("On / Off", isOn: $isOn)
                            .disabled(isControlDisabled)
                            .onChange(of: isOn) { _, new in appendLog("isOn → \(new)") }
                        Toggle("Flick Physics", isOn: $enableFlickPhysics)
                            .onChange(of: enableFlickPhysics) { _, new in appendLog("flickPhysics → \(new)") }
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, new in appendLog("haptics → \(new)") }
                        Toggle("Disable Control", isOn: $isControlDisabled)
                            .onChange(of: isControlDisabled) { _, new in appendLog("disabled → \(new)") }
                    }

                    // MARK: Dimensions

                    Section("Dimensions") {
                        HStack {
                            Text("Size")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $sideLength, in: 44 ... 120, step: 1) { editing in
                                if !editing { appendLog("size → \(Int(sideLength))") }
                            }
                            Text("\(Int(sideLength))")
                                .font(.caption.monospacedDigit())
                                .frame(width: 36, alignment: .trailing)
                        }
                        HStack {
                            Text("Stroke")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $strokeWidth, in: 1 ... 10, step: 0.5) { editing in
                                if !editing { appendLog("stroke → \(String(format: "%.1f", strokeWidth))") }
                            }
                            Text(String(format: "%.1f", strokeWidth))
                                .font(.caption.monospacedDigit())
                                .frame(width: 36, alignment: .trailing)
                        }
                        HStack {
                            Text("Duration")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $spinDuration, in: 0.2 ... 3.0, step: 0.1) { editing in
                                if !editing { appendLog("duration → \(String(format: "%.1fs", spinDuration))") }
                            }
                            Text(String(format: "%.1fs", spinDuration))
                                .font(.caption.monospacedDigit())
                                .frame(width: 36, alignment: .trailing)
                        }
                        HStack {
                            Text("Speed")
                                .frame(width: 60, alignment: .leading)
                            Slider(value: $spinSpeed, in: 0.25 ... 2.5, step: 0.05) { editing in
                                if !editing { appendLog("speed → \(String(format: "%.2fx", spinSpeed))") }
                            }
                            Text(String(format: "%.2fx", spinSpeed))
                                .font(.caption.monospacedDigit())
                                .frame(width: 36, alignment: .trailing)
                        }
                    }

                    // MARK: Style

                    Section("Style") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Axle Orientation")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Axle Orientation", selection: $orientation) {
                                Text("Horiz").tag(AxleOrientation.horizontal)
                                Text("Vert").tag(AxleOrientation.vertical)
                                Text("Diag ↗").tag(AxleOrientation.diagonalLTR)
                                Text("Diag ↘").tag(AxleOrientation.diagonalRTL)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .onChange(of: orientation) { _, new in appendLog("orientation → \(new)") }
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Label Placement")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Label Placement", selection: $placement) {
                                Text("Top").tag(LabelPlacement.top)
                                Text("Btm").tag(LabelPlacement.bottom)
                                Text("Lead").tag(LabelPlacement.leading)
                                Text("Trail").tag(LabelPlacement.trailing)
                                Text("Auto").tag(LabelPlacement.auto)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .onChange(of: placement) { _, new in appendLog("placement → \(new)") }
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Medallion Shape")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Medallion Shape", selection: $medallionShape) {
                                Text("Circle").tag(MedallionShape.circle)
                                Text("Square").tag(MedallionShape.square)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .onChange(of: medallionShape) { _, new in appendLog("shape → \(new)") }
                        }
                        .padding(.vertical, 4)
                    }

                    // MARK: Reset

                    Section {
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
                        .frame(maxWidth: .infinity)
                    }

                    // MARK: Event Log

                    Section("Event Log") {
                        eventLogView(maxHeight: logMaxHeight)
                    }
                } // end Form
            } // end VStack
            .onAppear {
                demoLog(
                    """
                    Rendering single control with \
                    size=\(Int(sideLength)), \
                    stroke=\(String(format: "%.1f", strokeWidth)), \
                    duration=\(String(format: "%.2f", spinDuration)), \
                    speed=\(String(format: "%.2f", spinSpeed)))
                    """,
                )
            }
            .navigationTitle("Butterfly iOS")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    var gridControlTab: some View {
        let gridItem = GridItem(
            .flexible(minimum: Constants.GRID_ITEM_MIN, maximum: Constants.GRID_ITEM_MAX),
            spacing: Constants.GRID_SPACING,
        )
        let columns = Array(repeating: gridItem, count: gridDimension)
        let usePerformanceMode = gridPerformanceModeEnabled ||
            gridDimension >= Constants.PERF_DIMENSION_THRESHOLD
        let gridSpinDuration = usePerformanceMode
            ? min(spinDuration, Constants.PERF_MAX_SPIN_DURATION)
            : spinDuration
        let gridSpinSpeed = usePerformanceMode
            ? min(spinSpeed, Constants.PERF_MAX_SPIN_SPEED)
            : spinSpeed
        let gridFlickPhysics = usePerformanceMode ? false : enableFlickPhysics
        let gridHapticsEnabled = usePerformanceMode ? false : hapticsEnabled
        let gridStyle = butterflyStyle(mountStrokeWidth: 1.5)

        NavigationStack {
            VStack(spacing: 0) {
                // MARK: Pinned controls bar

                VStack(spacing: Constants.GRID_SECTION_SPACING) {
                    HStack {
                        Text("Grid Size")
                        Slider(
                            value: Binding(
                                get: { Double(gridDimension) },
                                set: { newValue in resizeGrid(to: Int(newValue.rounded())) },
                            ),
                            in: Double(Constants.GRID_MIN_DIMENSION) ... Double(Constants.GRID_MAX_DIMENSION),
                            step: 1,
                        ) { editing in
                            if !editing { appendLog("gridSize → \(gridDimension)x\(gridDimension)") }
                        }
                        Text("\(gridDimension)x\(gridDimension)")
                            .font(.caption.monospacedDigit())
                    }
                    Toggle("Grid Performance Mode", isOn: $gridPerformanceModeEnabled)
                        .onChange(of: gridPerformanceModeEnabled) { _, new in appendLog("gridPerf → \(new)") }
                    Divider()
                    Picker("Info Panel", selection: $gridInfoPanel) {
                        Text("Event Log").tag(GridInfoPanel.eventLog)
                        Text("Matrix").tag(GridInfoPanel.matrix)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    switch gridInfoPanel {
                    case .eventLog:
                        eventLogView(maxHeight: gridLogMaxHeight)
                    case .matrix:
                        matrixView(maxHeight: gridLogMaxHeight)
                    }
                }
                .padding(Constants.ROOT_HORIZONTAL_PADDING)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))

                Divider()

                // MARK: Scrollable grid

                ScrollView {
                    LazyVGrid(columns: columns, spacing: Constants.GRID_SPACING) {
                        ForEach(0 ..< (gridDimension * gridDimension), id: \.self) { index in
                            ButterflyButton(
                                isOn: cellBinding(for: index),
                                sideLength: Constants.GRID_BUTTON_SIDE_LENGTH,
                                style: gridStyle,
                                spinDecelerationDuration: gridSpinDuration,
                                spinSpeed: gridSpinSpeed,
                                enableFlickPhysics: gridFlickPhysics,
                                hapticsEnabled: gridHapticsEnabled,
                                onSpinEnded: { newValue in
                                    appendLog("grid[\(index)] isOn=\(newValue)")
                                },
                            )
                            .disabled(isControlDisabled)
                        }
                    }
                    .padding(Constants.GRID_SPACING + 2)
                }
                .onAppear {
                    demoLog(
                        """
                        Grid params: dim=\(gridDimension), \
                        perf=\(usePerformanceMode), \
                        dur=\(String(format: "%.2f", gridSpinDuration)), \
                        speed=\(String(format: "%.2f", gridSpinSpeed)), \
                        flick=\(gridFlickPhysics), \
                        haptics=\(gridHapticsEnabled))
                        """,
                    )
                }

                Divider()

                // MARK: Pinned reset button

                Button("Reset Grid To 0") {
                    resizeGrid(to: gridDimension)
                }
                .buttonStyle(.bordered)
                .padding(Constants.ROOT_HORIZONTAL_PADDING)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .navigationTitle("Grid Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Returns a view that shows the event log, growing in height with content up to `maxHeight`,
    /// then switching to internal scrolling.
    ///
    /// Height is driven by entry count × estimated line height so the view is correctly sized
    /// on the very first render — avoiding the zero-height issue that `PreferenceKey` suffers
    /// inside `Form`/`List` cells.
    ///
    /// - Parameter maxHeight: The maximum height before the inner content starts scrolling.
    @ViewBuilder
    func eventLogView(maxHeight: CGFloat) -> some View {
        if eventLog.isEmpty {
            Text("No events yet")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            let contentHeight = CGFloat(eventLog.count) * Self.logLineHeight + 8
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(eventLog.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: min(contentHeight, maxHeight))
        }
    }

    /// Returns a view that renders the grid state as a row-major 0/1 matrix,
    /// matching the macOS demo's "Row-major values (0/1)" panel.
    ///
    /// Each row is displayed as space-separated integers on a single line using
    /// `.caption2.monospacedDigit()`. The view grows with content up to `maxHeight`,
    /// then scrolls internally.
    ///
    /// - Parameter maxHeight: Maximum height before internal scrolling begins.
    @ViewBuilder
    func matrixView(maxHeight: CGFloat) -> some View {
        if gridValues.isEmpty || gridDimension < 1 {
            Text("No data")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            let contentHeight = CGFloat(gridDimension) * Self.logLineHeight + 8
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0 ..< gridDimension, id: \.self) { row in
                        let start = row * gridDimension
                        let end = start + gridDimension
                        if end <= gridValues.count {
                            let rowString = gridValues[start ..< end]
                                .map(String.init)
                                .joined(separator: " ")
                            Text(rowString)
                                .font(.caption2.monospacedDigit())
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: Constants.EVENT_ROW_CORNER_RADIUS)
                                        .fill(Color(uiColor: .secondarySystemBackground)),
                                )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: min(contentHeight, maxHeight))
        }
    }
}

// MARK: - Helpers

private extension IOSDemoView {
    /// Writes a message to the system console via NSLog.
    ///
    /// - Parameter message: Message to log.
    func demoLog(_ message: String) {
        NSLog("[ButterflyDemo] %@", message)
    }

    /// Like precondition, but only traps in Debug builds; logs and continues in Release.
    ///
    /// - Parameters:
    ///   - condition: Condition to check.
    ///   - message: Message to log if failed.
    /// - Returns: True if condition is met, false otherwise.
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
            medallionShape: medallionShape,
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
                let ok = assertOrClamp(
                    gridValues.indices.contains(index),
                    "Grid index out of bounds (get): \(index) for dim=\(gridDimension)",
                )
                guard ok else { return false }
                return gridValues[index] == 1
            },
            set: { newValue in
                let ok = assertOrClamp(
                    gridValues.indices.contains(index),
                    "Grid index out of bounds (set): \(index) for dim=\(gridDimension)",
                )
                guard ok else { return }
                gridValues[index] = newValue ? 1 : 0
            },
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
