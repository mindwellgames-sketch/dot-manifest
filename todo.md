# .manifest - Project Status

## Project Manager Onboarding Complete

I have thoroughly reviewed the entire codebase. Here's my understanding:

### App Overview
**.manifest** is an iOS SwiftUI app that connects daily tasks/routines to core values, helping users live intentionally.

### Architecture (5 Tabs)
1. **Routine View** - Time-based daily schedule with sunrise/sunset gradients
2. **To-Do View** - Color-coded smart task list (urgency-based colors)
3. **Values View** - Library of 150+ values to activate (focus on 3-5)
4. **Analysis View** - Track which values you're serving over time
5. **Settings View** - Preferences, notifications, week start day

### Key Files
| File | Purpose |
|------|---------|
| `manifestApp.swift` | Entry point, onboarding, environment injection |
| `ContentView.swift` | All 5 tabs + views (~2500 lines) |
| `DataManager.swift` | Persistence (UserDefaults + iCloud) |
| `OnboardingView.swift` | 4-step onboarding flow |
| `LocationManager.swift` | CoreLocation with caching |
| `SolarCalculator.swift` | Sunrise/sunset calculations |
| `TimeOfDayGradient.swift` | Dynamic time-of-day colors |
| `ValuesLibrary.swift` | 150+ values with definitions |

### Backup Files
- `ContentView.swift.backup` - Earlier version with custom tab icons
- `ContentView.swift.backup-fonts` - Georgia font version
- `ContentView.swift.backup-hybrid` - Hybrid between old/new

---

## Previous Plan: Production Hardening for App Store Submission

This plan addresses remaining production issues for App Store submission.

## Todo List

- [ ] Fix compiler warnings - Remove unused `calendar` variables
  - [ ] ContentView.swift:1607 - Replace with `_`
  - [ ] SolarCalculator.swift:36 - Replace with `_`
- [ ] Remove triple debouncedSave() call in DataManager.swift:972-974
- [ ] Update outdated comment in OnboardingView.swift:94
- [ ] Add AccentColor asset to Assets.xcassets
- [ ] Add accessibility labels to OnboardingView.swift
  - [ ] InitialValuesSelectionView stones image (line 423)
  - [ ] InitialValueRow buttons (need to check implementation)
- [ ] Add accessibility labels to ContentView.swift
  - [ ] Custom "V" icon - Already has label, verify it's correct
- [ ] Add iCloud error user feedback in CloudSyncManager.swift
- [ ] Add backup data integrity validation in BackupManager.swift
- [ ] Run final build verification with zero warnings

## Changes Required

### 1. Fix Compiler Warnings (HIGH Priority)

**File: /Users/jimmy/Documents/ClaudeCode/manifest/manifest/ContentView.swift**
- Line 1607: Change `let calendar = Calendar.current` to `let _ = Calendar.current`

**File: /Users/jimmy/Documents/ClaudeCode/manifest/manifest/SolarCalculator.swift**
- Line 36: Change `let calendar = Calendar.current` to `let _ = Calendar.current`

### 2. Code Quality Fixes

**File: /Users/jimmy/Documents/ClaudeCode/manifest/manifest/DataManager.swift**
- Lines 972-974: Remove duplicate debouncedSave() calls (keep only one)

**File: /Users/jimmy/Documents/ClaudeCode/manifest/manifest/OnboardingView.swift**
- Line 94: Update comment from "Align with your values" to match current tagline

### 3. Add AccentColor Asset

**File: /Users/jimmy/Documents/ClaudeCode/manifest/manifest/Assets.xcassets/Contents.json**
- Add AccentColor configuration with black (#000000)

### 4. Add Accessibility Labels

**OnboardingView.swift:**
- Line 423: Add .accessibilityLabel() to stones image
- InitialValueRow: Add accessibility labels to value selection buttons

**ContentView.swift:**
- Line 33: Verify "V" icon accessibility label is correct

### 5. Add iCloud Error User Feedback

**File: /Users/jimmy/Documents/ClaudeCode/manifest/manifest/CloudSyncManager.swift**
- Add @Published var for error states
- Add user-facing error messages for quota exceeded, account changes
- Provide actionable guidance to users

### 6. Add Backup Data Integrity Validation

**File: /Users/jimmy/Documents/ClaudeCode/manifest/manifest/BackupManager.swift**
- Add checksum/hash validation
- Verify data structure integrity beyond just decoding
- Add validation for data ranges and relationships

## Expected Outcome

- Zero compiler warnings
- Clean code with no redundant calls
- Full accessibility support for App Store review
- User-friendly iCloud error handling
- Robust backup validation
- Production-ready build

---

## Session Review - November 25, 2025

### Tasks Attempted

1. **Onboarding Text Spacing Fix** ✅ SUCCESS
   - Fixed "Swipe to continue" text positioning on onboarding screens
   - File: `OnboardingView.swift` (lines 90, 177, 267)
   - Changed: `.padding(.bottom, 32)` → `.padding(.bottom, 56)`
   - Result: Text now clears page indicator dots on all 3 onboarding screens
   - Status: Implemented and working correctly

2. **V Tab Bar Icon Alignment Fix** ❌ FAILED (Reverted)
   - Attempted to fix V icon sitting lower than other tab icons on iPhone 13
   - Approach: Added padding to V.png asset (66x66 → 200x200 with centered V)
   - Problem: Caused V to appear HUGE and grainy on tab bar, TINY on onboarding
   - Root cause: Image padding scales differently in different UI contexts
   - Reversion: Restored original 550x539 V.png from project root
   - Current state: V.png back to original, works correctly
   - Outstanding: Original alignment issue on iPhone 13 still exists

### Files Modified (Net Changes)

- `OnboardingView.swift` - Onboarding text spacing fix (kept)
- `ContentView.swift` - Removed `.offset(y: -2)` from V tab icon (line 34, harmless)
- `V.imageset/V.png` - Reverted to original 550x539 image

### Build Status

- ✅ BUILD SUCCEEDED
- No errors or warnings (except harmless AppIntents metadata warning)

### Lessons Learned

- Modifying asset dimensions affects multiple UI contexts differently
- Tab bar and onboarding screens scale images differently
- Adding padding to assets causes scaling issues across device sizes
- Should use SwiftUI modifiers for alignment, not asset manipulation
- Always verify changes on multiple devices/simulators before finalizing

### Outstanding Issues

- V tab bar alignment on iPhone 13 (sits lower than other icons) - NOT fixed
- Could revisit with different SwiftUI-based approach if needed
