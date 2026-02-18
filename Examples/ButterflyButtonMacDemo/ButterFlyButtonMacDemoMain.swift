// Copyright 2026 John Salerno.

import Foundation
import SwiftUI
import ButterflyButton

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

/// Interactive demo surface for single-control and grid scenarios.
struct DemoView: View {
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    @State private var selectedTab: Int = 0

    @State private var isOn = true
    @State private var sideLength: Double = 60
    @State private var strokeWidth: Double = 2
    @State private var spinDuration: Double = 2
    @State private var spinSpeed: Double = 1
    @State private var enableFlickPhysics = true
    @State private var hapticsEnabled = true
    @State private var isControlDisabled = false
    @State private var orientation: AxleOrientation = .horizontal
    @State private var medallionShape: MedallionShape = .circle
    @State private var placement: LabelPlacement = .top
    @State private var eventLog: [String] = []

    @State private var gridDimension: Int = 9
    @State private var gridValues: [Int] = Array(repeating: 0, count: 4)
    @State private var gridPerformanceModeEnabled: Bool = true

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private enum Constants {
        // Layout and spacing
        static let ROOT_PADDING: CGFloat = 16
        static let SECTION_SPACING: CGFloat = 24
        static let CONTROL_PANEL_WIDTH: CGFloat = 380
        static let CONTROL_PANEL_SPACING: CGFloat = 14
        // Cards and corners
        static let CARD_CORNER_RADIUS: CGFloat = 16
        static let GRID_CARD_CORNER_RADIUS: CGFloat = 12
        // Paddings
        static let OUTER_PADDING: CGFloat = 30
        static let GRID_OUTER_PADDING: CGFloat = 12
        // Grid geometry
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
        // Defaults
        static let DEFAULT_SIDE_LENGTH: Double = 60
        static let DEFAULT_STROKE_WIDTH: Double = 2
        static let DEFAULT_SPIN_DURATION: Double = 2
        static let DEFAULT_SPIN_SPEED: Double = 1
        // Tabs
        static let TAB_SINGLE: Int = 0
        static let TAB_GRID: Int = 1
    }

    var body: some View { rootBody }

}

private extension DemoView {

    var rootBody: some View {
        TabView(selection: $selectedTab) {
            singleControlTab
                .tabItem { Text("Single") }
                .tag(Constants.TAB_SINGLE)

            gridControlTab
                .tabItem { Text("Grid") }
                .tag(Constants.TAB_GRID)
        }
        .padding(Constants.ROOT_PADDING)
        .onAppear {
            resizeGrid(to: gridDimension)
        }
    }

    private var singleControlTab: some View {
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
                .background(
                    Group {
                        if reduceTransparency {
                            RoundedRectangle(cornerRadius: Constants.CARD_CORNER_RADIUS)
                                .fill(Color(nsColor: .windowBackgroundColor))
                        } else {
                            RoundedRectangle(cornerRadius: Constants.CARD_CORNER_RADIUS)
                                .fill(.regularMaterial)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: Constants.CARD_CORNER_RADIUS))

                HStack(spacing: Constants.CONTROL_PANEL_SPACING) {
                    Toggle("On / Off", isOn: $isOn)
                        .toggleStyle(.switch)
                        .disabled(isControlDisabled)
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
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Constants.SECTION_SPACING)
        }
    }

    private var gridControlTab: some View {
        return HStack(spacing: Constants.SECTION_SPACING) {
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
                        in: 2...20,
                        step: 1
                    )
                    Text("\(gridDimension)x\(gridDimension)")
                        .monospacedDigit()
                        .frame(width: 76)
                }

                Button("Reset Grid To 0") {
                    resizeGrid(to: gridDimension)
                }

                Toggle("Grid Performance Mode", isOn: $gridPerformanceModeEnabled)

                Text("Row-major values (0/1)")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        LazyVStack(alignment: .leading, spacing: Constants.EVENT_ROW_SPACING) {
                            ForEach(0..<gridDimension, id: \.self) { row in
                                let start = row * gridDimension
                                let end = start + gridDimension
                                let rowString = gridValues[start..<end].map(String.init).joined(separator: " ")
                                Text(rowString)
                                    .font(.caption2.monospacedDigit())
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: Constants.EVENT_ROW_CORNER_RADIUS)
                                            .fill(Color(nsColor: .controlBackgroundColor))
                                    )
                            }
                        }
                    }
                }
                .frame(maxHeight: Constants.EVENT_SCROLL_MAX_HEIGHT)
                .padding(8)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

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
                                hapticsEnabled: gridHapticsEnabled
                            )
                            .disabled(isControlDisabled)
                        }
                    }
                    .padding(Constants.GRID_OUTER_PADDING)
                    .background(
                        Group {
                            if reduceTransparency {
                                RoundedRectangle(cornerRadius: Constants.GRID_CARD_CORNER_RADIUS)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            } else {
                                RoundedRectangle(cornerRadius: Constants.GRID_CARD_CORNER_RADIUS)
                                    .fill(.thinMaterial)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.GRID_CARD_CORNER_RADIUS))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(Constants.SECTION_SPACING)
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: Constants.CONTROL_PANEL_SPACING) {
            Text("ButterflyButton Controls")
                .font(.title2.weight(.semibold))

            Toggle("Enable Flick Physics", isOn: $enableFlickPhysics)
            Toggle("Haptics Enabled", isOn: $hapticsEnabled)
            Toggle("Disable ButterflyButton", isOn: $isControlDisabled)

            HStack {
                Text("Size")
                Slider(value: $sideLength, in: 44...140, step: 1)
                Text("\(Int(sideLength))")
                    .monospacedDigit()
                    .frame(width: 36)
            }

            HStack {
                Text("Mount Stroke")
                Slider(value: $strokeWidth, in: 1...14, step: 0.5)
                Text(String(format: "%.1f", strokeWidth))
                    .monospacedDigit()
                    .frame(width: 44)
            }

            HStack {
                Text("Spin Duration")
                Slider(value: $spinDuration, in: 0.2...4.0, step: 0.1)
                Text(String(format: "%.1fs", spinDuration))
                    .monospacedDigit()
                    .frame(width: 52)
            }

            HStack {
                Text("Spin Speed")
                Slider(value: $spinSpeed, in: 0.25...3.0, step: 0.05)
                Text(String(format: "%.2fx", spinSpeed))
                    .monospacedDigit()
                    .frame(width: 60)
            }

            Picker("Axle Orientation", selection: $orientation) {
                Text("Horizontal").tag(AxleOrientation.horizontal)
                Text("Vertical").tag(AxleOrientation.vertical)
                Text("Diagonal LTR").tag(AxleOrientation.diagonalLTR)
                Text("Diagonal RTL").tag(AxleOrientation.diagonalRTL)
            }

            Picker("Label Placement", selection: $placement) {
                Text("Top").tag(LabelPlacement.top)
                Text("Bottom").tag(LabelPlacement.bottom)
                Text("Leading").tag(LabelPlacement.leading)
                Text("Trailing").tag(LabelPlacement.trailing)
                Text("Auto").tag(LabelPlacement.auto)
            }

            Picker("Medallion Shape", selection: $medallionShape) {
                Text("Circle").tag(MedallionShape.circle)
                Text("Square").tag(MedallionShape.square)
            }

            Spacer(minLength: 10)

            Text("Event Log")
                .font(.headline)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Constants.EVENT_ROW_SPACING) {
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
            .clipShape(RoundedRectangle(cornerRadius: Constants.EVENT_ROW_CORNER_RADIUS))

            Button("Clear Log") {
                eventLog.removeAll(keepingCapacity: true)
            }
        }
    }

    /// Builds a style used by demo controls.
    ///
    /// - Parameter mountStrokeWidth: Stroke width to apply.
    /// - Returns: Style configured from current demo selections.
    private func butterflyStyle(mountStrokeWidth: CGFloat) -> ButterflyButtonStyle {
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

    /// Resizes the demo grid and resets all cell values.
    ///
    /// - Parameter dimension: Requested grid dimension.
    private func resizeGrid(to dimension: Int) {
        let safeDimension = min(max(dimension, 2), 20)
        gridDimension = safeDimension
        gridValues = Array(repeating: 0, count: safeDimension * safeDimension)
    }

    /// Creates a boolean binding for a row-major grid cell index.
    ///
    /// - Parameter index: Row-major cell index.
    /// - Returns: Binding that reads/writes a cell as on/off.
    private func cellBinding(for index: Int) -> Binding<Bool> {
        Binding(
            get: {
                precondition(gridValues.indices.contains(index), "Grid index out of bounds: \(index)")
                return gridValues[index] == 1
            },
            set: { newValue in
                precondition(gridValues.indices.contains(index), "Grid index out of bounds: \(index)")
                gridValues[index] = newValue ? 1 : 0
            }
        )
    }

    /// Prepends a timestamped message to the event log.
    ///
    /// - Parameter message: Log message text.
    private func appendLog(_ message: String) {
        let timestamp = Self.timestampFormatter.string(from: Date())
        eventLog.insert("[\(timestamp)] \(message)", at: 0)
        if eventLog.count > Constants.EVENT_LOG_MAX_LINES {
            eventLog.removeLast(eventLog.count - Constants.EVENT_LOG_MAX_LINES)
        }
    }
}
