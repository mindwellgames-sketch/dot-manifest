# Time Bracket Analysis for Vancouver, BC - November 20, 2025

## Verified Solar Times (from timeanddate.com)
- **Sunrise:** 7:31 AM PST = 07:31 = 451 minutes since midnight
- **Sunset:** 4:24 PM PST = 16:24 = 984 minutes since midnight
- **Current Time:** 2:46 PM PST = 14:46 = 866 minutes since midnight
- **Daylight Duration:** 8 hours, 53 minutes

## Time Calculations

### Current Time Analysis
- Current: 2:46 PM = 866 minutes
- Sunset: 4:24 PM = 984 minutes
- Minutes before sunset: 984 - 866 = **118 minutes** (1 hour 58 minutes before sunset)

## Time Bracket Logic Review (TimeOfDayGradient.swift)

Looking at lines 54-59 of TimeOfDayGradient.swift:

```swift
// Afternoon (2 PM - 5 PM or 2 hours before sunset)
} else if currentMinutes >= 840 && currentMinutes < sunsetMinutes - 120 {
    colors = [
        Color(red: 1.0, green: 0.75, blue: 0.3),  // Deep golden
        Color(red: 1.0, green: 0.85, blue: 0.5)   // Golden yellow
    ]
```

### The Problem

**Afternoon bracket:** `currentMinutes >= 840 && currentMinutes < sunsetMinutes - 120`

Let's evaluate for 2:46 PM in Vancouver:
- `currentMinutes` = 866
- `sunsetMinutes` = 984
- `sunsetMinutes - 120` = 984 - 120 = 864

**Check condition:**
- `866 >= 840` ✅ TRUE (2:46 PM is after 2:00 PM)
- `866 < 864` ❌ **FALSE** (866 is NOT less than 864!)

**Result:** The afternoon bracket check **FAILS**!

## What Bracket Does 2:46 PM Fall Into?

Let's check the **Sunset window** (lines 61-67):

```swift
// Sunset window (30 min before to 30 min after)
} else if abs(currentMinutes - sunsetMinutes) <= 30 {
    colors = [
        Color(red: 1.0, green: 0.4, blue: 0.1),  // Deep orange
        Color(red: 1.0, green: 0.3, blue: 0.3),  // Red-orange
        Color(red: 0.6, green: 0.2, blue: 0.5)   // Deep purple
    ]
```

**Check condition:**
- `abs(866 - 984)` = `abs(-118)` = 118
- `118 <= 30` ❌ **FALSE** (118 minutes is way more than 30!)

**Result:** The sunset window check also **FAILS**!

## What Bracket Does 2:46 PM ACTUALLY Fall Into?

Let's check the **Evening bracket** (lines 69-74):

```swift
// Evening (sunset + 1h to 10 PM)
} else if currentMinutes > sunsetMinutes + 60 && currentMinutes < 1320 {
    colors = [
        Color(red: 0.4, green: 0.2, blue: 0.6),  // Purple (LAVENDER!)
        Color(red: 0.3, green: 0.3, blue: 0.5)   // Deep blue
    ]
```

**Check condition:**
- `866 > (984 + 60)` = `866 > 1044` ❌ **FALSE**

**Result:** Evening bracket check also **FAILS**!

Since none of the above conditions match, it falls through to the **Night bracket** (lines 76-82):

```swift
// Night (10 PM - 4 AM)
} else {
    colors = [
        Color(red: 0.2, green: 0.2, blue: 0.4),  // Dark blue
        Color(red: 0.1, green: 0.1, blue: 0.2)   // Very dark
    ]
}
```

**WAIT!** Let me check the logic flow more carefully...

Actually, looking at the condition order:

1. Pre-dawn check - FAILS (866 is not < 391)
2. Sunrise window check - FAILS
3. Morning check - FAILS (866 is not < 660)
4. Midday check - FAILS (866 is not < 840)
5. **Afternoon check** - FAILS (866 < 864 is FALSE)
6. Sunset window check - FAILS
7. Evening check - FAILS
8. **ELSE (Night) - MATCHES!**

## The Bug Discovered!

**The issue:** With Vancouver's early sunset (4:24 PM = 984 minutes), the afternoon bracket ends at:
- `sunsetMinutes - 120` = 984 - 120 = **864 minutes** = **2:24 PM**

**At 2:46 PM (866 minutes):**
- It's past the afternoon bracket cutoff (2:24 PM)
- It's NOT in the sunset window (which is 3:54 PM to 4:54 PM)
- It's NOT in the evening bracket (which starts at 5:24 PM)
- **It falls through to the ELSE clause and gets the NIGHT colors!**

The "lavender" color you're seeing is actually the NIGHT gradient being applied in the middle of the afternoon!

## Root Cause

The logic assumes there's a time between:
1. End of afternoon (sunset - 2 hours)
2. Start of sunset window (sunset - 30 min)

But there's NO bracket defined for this gap! When sunset is early (like in Vancouver in November), times between 2:24 PM and 3:54 PM fall through to the night bracket.

## Recommended Fix

**Option 1: Extend afternoon bracket to sunset window start**
```swift
// Afternoon (2 PM to 30 min before sunset)
} else if currentMinutes >= 840 && currentMinutes < sunsetMinutes - 30 {
```

Change line 55 from `sunsetMinutes - 120` to `sunsetMinutes - 30`

This ensures the afternoon bracket extends right up to when the sunset window begins, leaving no gaps.

**Option 2: Add a "late afternoon" bracket for the gap**
```swift
// Afternoon (2 PM to 2 hours before sunset)
} else if currentMinutes >= 840 && currentMinutes < sunsetMinutes - 120 {
    // ... existing afternoon colors ...

// Late afternoon (2 hours before to 30 min before sunset)
} else if currentMinutes >= sunsetMinutes - 120 && currentMinutes < sunsetMinutes - 30 {
    colors = [
        Color(red: 1.0, green: 0.8, blue: 0.4),   // Warm golden
        Color(red: 1.0, green: 0.7, blue: 0.3)    // Rich orange-gold
    ]

// Sunset window (30 min before to 30 min after)
} else if abs(currentMinutes - sunsetMinutes) <= 30 {
```

This adds a distinct bracket for the late afternoon period.

## Verification

With **Option 1** fix applied:
- Afternoon bracket: `866 >= 840 && 866 < 954` (sunset - 30)
- `866 >= 840` ✅ TRUE
- `866 < 954` ✅ TRUE
- **Result: MATCHES afternoon bracket!** ✅

Expected colors: Deep golden (#FFC04D) and Golden yellow (#FFD980)
