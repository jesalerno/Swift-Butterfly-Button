<!-- Copyright 2026 John Salerno. -->

# Refactoring Log

Date: 2026-02-14

## Applied Refactorings
- Extracted validation math into `ButterflyValidation` for deterministic unit tests.
- Extracted interaction token logic into `ButterflyInteractionEngine` for interrupt policy testing.
- Extracted rendering primitives (`MountView`, `AxleView`, `MedallionView`, `OuterLabelView`) to reduce complexity in `ButterflyButton`.
- Consolidated theme/color fallback logic into `ButterflyTheme`.
- Reworked preview scaffolding to avoid platform-incompatible environment overrides.

## Regression Safety
- `swift test` passes with 10 tests validating core rules and interaction behavior.
- Vulnerability scan gate passes with no High/Critical findings.
