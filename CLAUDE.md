# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MediGuide is an iOS SwiftUI app that guides users through a medical triage process and outputs one of four care-level recommendations: Call 911, Go to ER, Urgent Care, or Monitor at Home. It integrates Claude API for natural language symptom parsing, HealthKit for real-time biometric data, Apple Watch, camera/vision AI, voice I/O, offline-first architecture, and local-only encrypted health profiles.

## Build & Run

Open `MediGuide.xcodeproj` in Xcode (no package manager or external dependencies yet). Build target is iOS.

```bash
# Build for simulator
xcodebuild -project MediGuide.xcodeproj -scheme MediGuide \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run all tests
xcodebuild -project MediGuide.xcodeproj -scheme MediGuide \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a single test class
xcodebuild -project MediGuide.xcodeproj -scheme MediGuide \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MediGuideTests/TriageEngineTests test
```

HealthKit and CallKit require a real device. Watch features require a paired Apple Watch. All other features run in the simulator.

## Architecture

### Triage Engine (core scoring logic)

All scoring configuration is in `Resources/DecisionTree.json`. The engine flow:

1. Sum `symptomWeights` for selected symptoms
2. Sum `modifierWeights` for active modifiers (conditions, context flags)
3. Multiply total by `AgeGroup.scoreMultiplier` (infant ×1.5, child ×1.2, adult ×1.0, elderly ×1.3)
4. **Hard override check**: if any selected symptom appears in `hardOverrides`, immediately return `.call911` — this bypasses score
5. Map score to `RecommendationTier` using `minScore` thresholds (highest matching tier wins)

`TriageSession` holds all mutable state for one triage run: selected symptoms, active modifiers, age group, override flags, and running totals. It is never persisted — session data is cleared on reset or app close.

The `instinct_override` modifier ("Something feels wrong" button) adds the `instinct_override` weight from `modifierWeights` and sets `instinctOverrideUsed = true` on the session.

Re-assessment: if the user reports "same" or "worse" at a timer check-in, escalate the `RecommendationTier` by one level (Monitor → Urgent Care → ER → 911).

### Health Profiles

- Stored locally using Keychain (sensitive fields) and UserDefaults (non-sensitive metadata)
- Protected by Face ID / Touch ID
- Support multiple named profiles (family members)
- When a profile is active, its conditions/age automatically populate `TriageSession` modifiers — no manual entry needed
- Profile data is never transmitted; deleted with the app; never written to iCloud or any sync store

### AI Integration (Claude API)

- Natural language symptom input is sent to Claude API to extract structured symptom flags matching keys in `DecisionTree.json`
- Vision API analyzes photos (rash, wound, etc.) and returns structured symptom flags in the same format
- API calls are stateless — no user identifiers sent
- If APIs are unavailable, fall back to guided question flow and local keyword matching against `symptomWeights` keys
- Photos are discarded immediately after API response; never stored

### HealthKit / Apple Watch

- Read-only HealthKit access (heart rate, SpO2, respiratory rate, fall detection)
- Watch data feeds directly into the scoring engine: e.g., HR > 150 flags `rapid_heartrate`, SpO2 < 92 flags `low_oxygen`
- Never write to HealthKit

### Emergency Response Flow

1. User (or auto-trigger from hard override) initiates 911 flow
2. 10-second countdown shown with cancel option; voice readout of countdown
3. CallKit places actual call to 911
4. SMS sent to emergency contact from active profile: includes GPS location, blood type, medications
5. Location is captured momentarily for this SMS only — never stored

### Offline-First

The decision tree, symptom weights, first aid content, and health profiles all work without internet. API-dependent features (NLP input, photo analysis) degrade gracefully to guided question mode. No feature should hard-fail if the network is absent.

### First Aid Content

Bundled as a local JSON library. Each emergency type has a step list with optional per-step timers. The UI auto-advances when a timed step completes. Visual/video guides are embedded for offline playback.

## Key Constraints

- **No medical session persistence**: symptoms, triage results, and photos must never be written to disk, UserDefaults, iCloud, or any store. In-memory only; wiped on session reset or app close.
- **Hard overrides are absolute**: a symptom in `hardOverrides` always produces Call 911 regardless of score, age multiplier, or any other factor.
- **Age is a multiplier, not a branch**: infants, children, and elderly use the same decision tree with score multipliers — there is no separate pediatric or elderly tree.
- **Profile data stays on device**: never sync, never transmit, never log.
- **HealthKit is read-only**: never call `HKHealthStore.save(_:with:)`.
- **911 button must be reachable from every screen** at all times.
