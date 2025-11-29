# Dark Mode Support - Semantic Color Conversion Plan

## Overview
Converting manifest app to support system dark mode by replacing all hardcoded colors with semantic colors.

## Todo Items

### 1. Replace .foregroundColor(.black) with .foregroundColor(.primary)
- [ ] Replace all instances of `.foregroundColor(.black)` throughout the file (~20+ instances)

### 2. Replace .accentColor(.black) with .tint(.primary)
- [ ] Replace `.accentColor(.black)` instance(s)

### 3. Replace background Color.white with semantic equivalents
- [ ] Main screen backgrounds: `Color.white` → `Color(uiColor: .systemBackground)`
- [ ] Card/container `.fill(Color.white)` → `.fill(Color(uiColor: .secondarySystemBackground))`
- [ ] Card/container `.background(Color.white)` → `.background(Color(uiColor: .secondarySystemBackground))`

### 4. Replace custom light gray background
- [ ] Replace `Color(red: 0.98, green: 0.98, blue: 0.98)` with `Color(uiColor: .systemGroupedBackground)`

### 5. Update shadow colors to be adaptive
- [ ] Replace all `.shadow(color: Color.black.opacity(X), ...)` with `.shadow(color: Color.primary.opacity(X * 0.3), ...)`

### 6. Update DateSelector selected state
- [ ] Selected background: `.fill(Color.black)` → `.fill(Color.primary)`
- [ ] Selected text color adjustment if needed
- [ ] Unselected text: ensure uses `.foregroundColor(.primary)`

### 7. Update Toast backgrounds
- [ ] Toast background: `Color.black.opacity(0.85)` → `Color(uiColor: .secondarySystemBackground).opacity(0.95)`
- [ ] Toast text: from `.white` to `.primary`

### 8. Update FAB (Floating Action Button) strokes
- [ ] Replace `.stroke(Color.white.opacity(0.5))` with `.stroke(Color(uiColor: .systemBackground).opacity(0.5))`

### 9. Test build
- [ ] Build the project and verify no compilation errors
- [ ] Review any warnings

## Notes
- Do NOT change Color.red, Color.orange, Color.yellow, Color.green (task priority colors)
- Do NOT change Color.gray or Color.secondary (already semantic)
- Use replace_all where appropriate for efficiency

## Review
(To be completed after all changes)
