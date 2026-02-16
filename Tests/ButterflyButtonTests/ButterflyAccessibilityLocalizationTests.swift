// Copyright 2026 John Salerno.

import Foundation
import Testing

/// Returns a file URL rooted at the package directory.
private func packageRootURL() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // ButterflyAccessibilityLocalizationTests.swift
        .deletingLastPathComponent() // ButterflyButtonTests
        .deletingLastPathComponent() // Tests
}

/// Loads a UTF-8 file from the package tree.
private func loadFile(relativePath: String) throws -> String {
    let url = packageRootURL().appendingPathComponent(relativePath)
    return try String(contentsOf: url, encoding: .utf8)
}

/// Parses simple `.strings` entries in the form `"key" = "value";`.
private func parseStringsTable(_ contents: String) -> [String: String] {
    var table: [String: String] = [:]
    let pattern = #""([^"]+)"\s*=\s*"([^"]*)";"#
    let regex = try? NSRegularExpression(pattern: pattern)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    regex?.enumerateMatches(in: contents, options: [], range: nsRange) { match, _, _ in
        guard
            let match,
            let keyRange = Range(match.range(at: 1), in: contents),
            let valueRange = Range(match.range(at: 2), in: contents)
        else { return }
        table[String(contents[keyRange])] = String(contents[valueRange])
    }
    return table
}

/// Verifies required localization keys exist for labels, state, and accessibility text.
@Test func localizableStringsContainsRequiredAccessibilityKeys() throws {
    let strings = try loadFile(relativePath: "Sources/ButterflyButton/Resources/en.lproj/Localizable.strings")
    let table = parseStringsTable(strings)

    let requiredKeys = [
        "ButterflyButton.true",
        "ButterflyButton.false",
        "ButterflyButton.accessibility.label",
        "ButterflyButton.accessibility.hint",
        "ButterflyButton.accessibility.action.toggle",
        "ButterflyButton.accessibility.state.on",
        "ButterflyButton.accessibility.state.off"
    ]

    for key in requiredKeys {
        #expect(table[key] != nil)
        #expect(!(table[key]?.isEmpty ?? true))
    }

    #expect(table["ButterflyButton.accessibility.state.on"] != table["ButterflyButton.accessibility.state.off"])
}

/// Verifies the control implementation references localized accessibility keys.
@Test func butterflyButtonUsesLocalizedAccessibilityText() throws {
    let source = try loadFile(relativePath: "Sources/ButterflyButton/ButterflyButton.swift")

    #expect(source.contains("ButterflyButton.accessibility.label"))
    #expect(source.contains("ButterflyButton.accessibility.hint"))
    #expect(source.contains("ButterflyButton.accessibility.action.toggle"))
    #expect(source.contains("ButterflyButton.accessibility.state.on"))
    #expect(source.contains("ButterflyButton.accessibility.state.off"))

    #expect(!source.contains(".accessibilityLabel(Text(\"ButterflyButton\"))"))
    #expect(!source.contains(".accessibilityAction(named: Text(\"Toggle\"))"))
}
