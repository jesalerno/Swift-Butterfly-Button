// Copyright 2026 John Salerno.

import Foundation
import Testing
@testable import ButterflyButton

/// Returns a file URL rooted at the package directory.
private func packageRootURL() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // ButterflyRegressionTests.swift
        .deletingLastPathComponent() // ButterflyButtonTests
        .deletingLastPathComponent() // Tests
}

/// Loads a UTF-8 file from the package tree.
private func loadSource(relativePath: String) throws -> String {
    let url = packageRootURL().appendingPathComponent(relativePath)
    return try String(contentsOf: url, encoding: .utf8)
}

// MARK: - Logger subsystem typo regression

/// Regression: the logger subsystem must spell "ButterflyButton" correctly.
/// Previously it was misspelled as "ButterfylButton" in ButterflyPrimitives.swift.
@Test func loggerSubsystem_neverContainsButterfylTypo() throws {
    let primitives = try loadSource(
        relativePath: "Sources/ButterflyButton/Internal/ButterflyPrimitives.swift",
    )
    let button = try loadSource(
        relativePath: "Sources/ButterflyButton/ButterflyButton.swift",
    )

    // The typo "ButterfylButton" (missing second 't') should never appear.
    #expect(!primitives.contains("ButterfylButton"))
    #expect(!button.contains("ButterfylButton"))

    // The correct subsystem should be present.
    #expect(primitives.contains("com.integracode.ButterflyButton"))
    #expect(button.contains("com.integracode.ButterflyButton"))
}

// MARK: - Double scaleEffect regression

/// Regression: .scaleEffect(pulseScale) must appear exactly once in ButterflyButton.swift.
/// A previous bug applied it inside ButterflyButtonViewBuilders AND in controlSurface,
/// causing pulseScale² hover scaling.
@Test func scaleEffectPulseScale_appearsExactlyOnce() throws {
    let source = try loadSource(
        relativePath: "Sources/ButterflyButton/ButterflyButton.swift",
    )

    let occurrences = source.components(separatedBy: ".scaleEffect(pulseScale)").count - 1
    #expect(occurrences == 1)
}

// MARK: - ButterflyButtonViewBuilders deletion regression

/// Regression: the pass-through ButterflyButtonViewBuilders file must remain deleted.
@Test func viewBuildersFile_remainsDeleted() {
    let url = packageRootURL().appendingPathComponent(
        "Sources/ButterflyButton/ButterflyButtonViewBuilders.swift",
    )
    let exists = FileManager.default.fileExists(atPath: url.path)
    #expect(!exists)
}

// MARK: - ThemeInput convenience init placement regression

/// Regression: the ThemeInput convenience init must be in an extension, not the struct body.
/// Placing it inside the struct body suppresses Swift's auto-generated memberwise initializer.
@Test func themeInputConvenienceInit_isInExtensionNotStructBody() throws {
    let source = try loadSource(
        relativePath: "Sources/ButterflyButton/Internal/ButterflyTheme.swift",
    )

    // The struct body should NOT contain "init(style:".
    // We look for "struct ThemeInput" … "}" and check it doesn't contain the convenience init.
    // A simpler check: "extension ThemeInput" must appear, and the convenience init must follow it.
    #expect(source.contains("extension ThemeInput"))

    // The pattern "struct ThemeInput" followed by "init(style:" before "extension ThemeInput"
    // would indicate the init is inside the struct body. We check the extension appears first.
    if
        let structRange = source.range(of: "struct ThemeInput"),
        let extensionRange = source.range(of: "extension ThemeInput"),
        let initStyleRange = source.range(of: "init(style:")
    {
        // The convenience init should appear AFTER the extension keyword, not in the struct body.
        #expect(initStyleRange.lowerBound > extensionRange.lowerBound)
        _ = structRange // suppress unused warning
    }
}

// MARK: - ExternalChangeAction nesting regression

/// Regression: ExternalChangeAction should be nested as ButterflyInteractionCoordinator.Action,
/// not a standalone file-scope enum.
@Test func externalChangeAction_isNestedInsideCoordinator() throws {
    let source = try loadSource(
        relativePath: "Sources/ButterflyButton/Internal/ButterflyInteractionEngine.swift",
    )

    // The old standalone enum name should not appear at file scope.
    #expect(!source.contains("enum ExternalChangeAction"))

    // The nested type should exist.
    #expect(source.contains("enum Action: Equatable"))
}

// MARK: - Accessibility keys are localized (not hardcoded strings)

/// Regression: ButterflyButton must NOT use hardcoded accessibility text.
@Test func accessibilityKeys_areNotHardcoded() throws {
    let source = try loadSource(
        relativePath: "Sources/ButterflyButton/ButterflyButton.swift",
    )

    // These hardcoded patterns should never appear.
    #expect(!source.contains(".accessibilityLabel(Text(\"ButterflyButton\"))"))
    #expect(!source.contains(".accessibilityAction(named: Text(\"Toggle\"))"))

    // The localized key constants should be present.
    #expect(source.contains("ButterflyButton.accessibility.label"))
    #expect(source.contains("ButterflyButton.accessibility.hint"))
    #expect(source.contains("ButterflyButton.accessibility.action.toggle"))
}

// MARK: - MountBackground Sendable conformance

/// Regression: MountBackground must conform to Sendable.
@Test func mountBackgroundSendableConformance_isPresent() throws {
    let source = try loadSource(
        relativePath: "Sources/ButterflyButton/ButterflyButtonTypes.swift",
    )

    #expect(source.contains("MountBackground: Sendable"))
}
