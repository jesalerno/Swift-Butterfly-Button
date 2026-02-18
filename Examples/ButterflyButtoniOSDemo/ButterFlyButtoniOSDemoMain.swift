// Copyright 2026 John Salerno.

import Foundation
import SwiftUI
import ButterflyButton

@main
/// Entry point for the iOS ButterflyButton demo app.
struct ButterflyButtoniOSDemoApp: App {
    var body: some Scene {
        WindowGroup("ButterflyButton iOS Demo") {
            IOSDemoView()
        }
    }
}

/// Interactive iOS demo surface for single-control and grid scenarios.
struct IOSDemoView: View {
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
        static let GRID_CELL_SIDE: CGFloat = 40
        // Defaults
        static let DEFAULT_SIDE_LENGTH: Double = 64
        static let DEFAULT_STROKE_WIDTH: Double = 2
        static let DEFAULT_SPIN_DURATION: Double = 1.8
        static let DEFAULT_SPIN_SPEED: Double = 1
        // Event log
        static let EVENT_LOG_MAX_HEIGHT: CGFloat = 140
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var selectedTab = 0

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

    @State private var gridDimension: Int = 6
    @State private var gridValues: [Int] = Array(repeating: 0, count: 4)
    @State private var gridPerformanceModeEnabled = true

    var body: some View {
        TabView(selection: $selectedTab) {
            singleControlTab
                .tabItem { Label("Single", systemImage: "dial.medium") }
                .tag(0)

            gridControlTab
                .tabItem { Label("Grid", systemImage: "square.grid.3x3.fill") }
                .tag(1)
        }
        .onAppear {
            resizeGrid(to: gridDimension)
        }
    }

    private var singleControlTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.SECTION_SPACING) {
                    Text("Visual Test Surface")
                        .font(.headline)

                    let styleValue = butterflyStyle(mountStrokeWidth: strokeWidth)

                    ButterflyButton(
                        isOn: $isOn,
                        sideLength: sideLength,
                        labelPlacement: placement,
                        style: styleValue,
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
                    .disabled(isControlDisabled)
                    .padding(Constants.ROOT_VERTICAL_PADDING)
                    .background(
                        Group {
                            if reduceTransparency {
                                RoundedRectangle(cornerRadius: Constants.CARD_CORNER_RADIUS)
                                    .fill(.ultraThinMaterial)
                            } else {
                                RoundedRectangle(cornerRadius: Constants.CARD_CORNER_RADIUS)
                                    .fill(.regularMaterial)
                            }
                        }
                    )

                    controlPanel

                    eventLogPanel
                }
                .padding(.horizontal, Constants.ROOT_HORIZONTAL_PADDING)
                .padding(.vertical, Constants.ROOT_VERTICAL_PADDING)
            }
            .navigationTitle("Butterfly iOS")
        }
    }

    private var gridControlTab: some View {
        NavigationStack {
            VStack(spacing: Constants.GRID_SECTION_SPACING) {
                HStack {
                    Text("Grid Size")
                    Slider(
                        value: Binding(
                            get: { Double(gridDimension) },
                            set: { newValue in resizeGrid(to: Int(newValue.rounded())) }
                        ),
                        in: Double(Constants.GRID_MIN_DIMENSION)...Double(Constants.GRID_MAX_DIMENSION),
                        step: 1
                    )
                    Text("\(gridDimension)x\(gridDimension)")
                        .font(.caption.monospacedDigit())
                }

                Toggle("Grid Performance Mode", isOn: $gridPerformanceModeEnabled)

                let gridItem = GridItem(
                    .flexible(minimum: Constants.GRID_ITEM_MIN, maximum: Constants.GRID_ITEM_MAX),
                    spacing: Constants.GRID_SPACING
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

                ScrollView {
                    LazyVGrid(columns: columns, spacing: Constants.GRID_SPACING) {
                        ForEach(0..<(gridDimension * gridDimension), id: \.self) { index in
                            ButterflyButton(
                                isOn: cellBinding(for: index),
                                sideLength: Constants.GRID_CELL_SIDE,
                                style: gridStyle,
                                spinDecelerationDuration: gridSpinDuration,
                                spinSpeed: gridSpinSpeed,
                                enableFlickPhysics: gridFlickPhysics,
                                hapticsEnabled: gridHapticsEnabled
                            )
                            .disabled(isControlDisabled)
                        }
                    }
                    .padding(.vertical, Constants.GRID_SPACING + 2)
                }

                Button("Reset Grid To 0") {
                    resizeGrid(to: gridDimension)
                }
                .buttonStyle(.bordered)
            }
            .padding(Constants.ROOT_HORIZONTAL_PADDING)
            .navigationTitle("Grid Demo")
        }
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("On / Off", isOn: $isOn)
                .disabled(isControlDisabled)
            Toggle("Enable Flick Physics", isOn: $enableFlickPhysics)
            Toggle("Haptics Enabled", isOn: $hapticsEnabled)
            Toggle("Disable ButterflyButton", isOn: $isControlDisabled)

            HStack {
                Text("Size")
                Slider(value: $sideLength, in: 44...120, step: 1)
                Text("\(Int(sideLength))")
                    .font(.caption.monospacedDigit())
            }

            HStack {
                Text("Stroke")
                Slider(value: $strokeWidth, in: 1...10, step: 0.5)
                Text(String(format: "%.1f", strokeWidth))
                    .font(.caption.monospacedDigit())
            }

            HStack {
                Text("Duration")
                Slider(value: $spinDuration, in: 0.2...3.0, step: 0.1)
                Text(String(format: "%.1fs", spinDuration))
                    .font(.caption.monospacedDigit())
            }

            HStack {
                Text("Speed")
                Slider(value: $spinSpeed, in: 0.25...2.5, step: 0.05)
                Text(String(format: "%.2fx", spinSpeed))
                    .font(.caption.monospacedDigit())
            }

            Picker("Axle Orientation", selection: $orientation) {
                Text("Horizontal").tag(AxleOrientation.horizontal)
                Text("Vertical").tag(AxleOrientation.vertical)
                Text("Diagonal LTR").tag(AxleOrientation.diagonalLTR)
                Text("Diagonal RTL").tag(AxleOrientation.diagonalRTL)
            }
            .pickerStyle(.segmented)

            Picker("Label Placement", selection: $placement) {
                Text("Top").tag(LabelPlacement.top)
                Text("Bottom").tag(LabelPlacement.bottom)
                Text("Lead").tag(LabelPlacement.leading)
                Text("Trail").tag(LabelPlacement.trailing)
                Text("Auto").tag(LabelPlacement.auto)
            }
            .pickerStyle(.segmented)

            Picker("Medallion Shape", selection: $medallionShape) {
                Text("Circle").tag(MedallionShape.circle)
                Text("Square").tag(MedallionShape.square)
            }
            .pickerStyle(.segmented)

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
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
        )
    }

    private var eventLogPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Event Log")
                .font(.headline)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(eventLog.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: Constants.EVENT_LOG_MAX_HEIGHT)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
        )
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
        let safeDimension = min(max(dimension, Constants.GRID_MIN_DIMENSION), Constants.GRID_MAX_DIMENSION)
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
        if eventLog.count > 30 {
            eventLog.removeLast(eventLog.count - 30)
        }
    }
}

