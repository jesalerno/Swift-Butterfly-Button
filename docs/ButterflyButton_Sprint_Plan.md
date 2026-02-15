<!-- Copyright 2026 John Salerno. -->

# ButterflyButton Sprint Plan

Project: Universal UX control library in Swift/Xcode for macOS, iOS, and iPadOS.

## Sprint 1 (Week 1): Foundation + Core Rendering

### Step 1: Repo and package bootstrap
- Create Swift Package `ButterflyButton` with targets:
  - `ButterflyButton` (library)
  - `ButterflyButtonTests` (Swift Testing)
  - Demo host app/workspace for iOS, iPadOS, macOS
- Set deployment targets:
  - iOS 17+, iPadOS 17+, macOS 14+
- Create base structure:
  - `Sources/ButterflyButton/`
  - `Tests/ButterflyButtonTests/`
  - `Sources/ButterflyButton/Resources/Localization/`
  - `README.md`, `CHANGELOG.md`
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed (e.g., `osv-scanner` or org-approved SCA tool)
  - Refactoring suggestions reviewed and applied before step close

### Step 2: Public API and domain model
- Implement:
  - `ButterflyButton: View`
  - `LabelPlacement`, `AxleOrientation`, `MountBackground`
  - Public init signatures from spec
- Add validation/clamping utilities:
  - `sideLength >= 44`
  - `mountStrokeWidth in [1, sideLength * 0.10]`
  - `spinDecelerationDuration > 0` fallback to `2.0`
- Add public doc comments for all API symbols
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

### Step 3: Mount + axle + medallion rendering
- Build composable internal views:
  - `MountView`
  - `AxleView`
  - `MedallionView`
  - `OuterLabelView`
- Enforce geometry rules:
  - Control square sizing rules
  - Medallion diameter = 90% of mount interior
- Add adaptive color defaults for light/dark and contrast environments
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

## Sprint 2 (Week 2): Interaction + Accessibility + Localization

### Step 4: Interaction and state transitions
- Implement tap/click toggle path
- Implement drag/flick path with axle-projected velocity and direction rules
- Wire callbacks:
  - `onSpinBegan`
  - `onSpinCompleted`
- Ensure deterministic state machine transitions
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

### Step 5: Animation behavior and reduced motion
- Implement spin animation profile with spring/ease-out behavior
- Support `spinDecelerationDuration`
- Respect reduced motion with non-rotation fallback (fade/scale)
- Ensure parity for macOS/iOS/iPadOS interactions
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

### Step 6: Accessibility and localization
- Accessibility:
  - Toggle role/value semantics
  - VoiceOver phrasing for outer label + current state
  - Hit area >= 44x44
- Localization:
  - Add `Localizable.strings` base and platform variants
  - Keys: `ButterflyButton.true`, `ButterflyButton.false`
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

## Sprint 3 (Week 3): Hardening + Release

### Step 7: Logging, error handling, and previews
- Integrate `os.Logger` for non-fatal validation/fallback logs
- Add preview matrix:
  - Light/dark, RTL, dynamic type, reduced motion, increased contrast
  - Axle variants
  - Sizes 44 / 60 / 120
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

### Step 8: Test expansion and regression coverage
- Add tests for:
  - Clamping and validation
  - Geometry constraints
  - Gesture/state transitions
  - Callback sequencing
  - Accessibility attributes/values
- Add CI pipeline for build + tests on macOS + iOS simulator
- Exit gate (required):
  - Unit tests run and pass: `swift test` (+ CI green)
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

### Step 9: Documentation and release
- Complete `README.md`:
  - Installation
  - API usage
  - Theming/examples
  - Accessibility/localization notes
- Prepare release artifacts:
  - `0.1.0` tag
  - release notes
  - compatibility matrix
- Exit gate (required):
  - Unit tests run and pass: `swift test`
  - Vulnerability scan run and reviewed
  - Refactoring suggestions reviewed and applied before step close

## Standard Step-Closure Checklist (applies to every step)
- [ ] Unit tests executed and validated
- [ ] Vulnerability scan executed and findings triaged/fixed
- [ ] Refactoring suggestions reviewed and applied
- [ ] Step acceptance criteria met and documented

