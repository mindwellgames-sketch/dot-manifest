import SwiftUI
import Foundation

struct TimeOfDayGradient {
    // Generate a gradient based on the time of day
    static func gradientForTime(_ time: Date, sunrise: Date, sunset: Date) -> LinearGradient {
        // Use UTC calendar for consistent comparison with UTC solar times
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current

        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        // Get sunrise and sunset hours for comparison (also in UTC)
        let sunriseHour = calendar.component(.hour, from: sunrise)
        let sunriseMinute = calendar.component(.minute, from: sunrise)
        let sunsetHour = calendar.component(.hour, from: sunset)
        let sunsetMinute = calendar.component(.minute, from: sunset)

        // Convert to minutes since midnight for easier comparison
        var currentMinutes = hour * 60 + minute
        let sunriseMinutes = sunriseHour * 60 + sunriseMinute
        var sunsetMinutes = sunsetHour * 60 + sunsetMinute

        #if DEBUG
        // Debug logging (only in debug builds)
        print("🔍 GRADIENT DEBUG:")
        print("   Current: \(hour):\(String(format: "%02d", minute)) = \(currentMinutes) min", terminator: "")
        #endif

        // Handle sunset wraparound (when sunset is past midnight UTC)
        // This happens for western timezones where sunset occurs in early UTC hours of next day
        if sunsetMinutes < sunriseMinutes {
            sunsetMinutes += 1440  // Add 24 hours worth of minutes
        }

        // Handle current time wraparound (when current time is past midnight UTC)
        // This happens in western timezones in the evening/night
        if currentMinutes < sunriseMinutes && sunsetMinutes > sunriseMinutes {
            currentMinutes += 1440  // Add 24 hours worth of minutes
            #if DEBUG
            print(" → adjusted to \(currentMinutes) min")
            #endif
        } else {
            #if DEBUG
            print("")
            #endif
        }

        #if DEBUG
        print("   Sunrise: \(sunriseHour):\(String(format: "%02d", sunriseMinute)) = \(sunriseMinutes) min")
        print("   Sunset:  \(sunsetHour):\(String(format: "%02d", sunsetMinute)) = \(sunsetMinutes) min")
        #endif

        // Define gradient colors with strong visibility
        let colors: [Color]
        var matchedCondition = "UNKNOWN"

        // Pre-dawn (4-5 AM or 1 hour before sunrise)
        if currentMinutes < sunriseMinutes - 60 && currentMinutes >= 240 {
            matchedCondition = "PRE-DAWN"
            colors = [
                Color(red: 0.4, green: 0.2, blue: 0.6),  // Deep purple
                Color(red: 0.2, green: 0.3, blue: 0.5)   // Dark blue
            ]

        // Sunrise window (30 min before to 30 min after)
        } else if abs(currentMinutes - sunriseMinutes) <= 30 {
            matchedCondition = "SUNRISE"
            colors = [
                Color(red: 1.0, green: 0.5, blue: 0.2),  // Vivid orange
                Color(red: 1.0, green: 0.7, blue: 0.3),  // Golden orange
                Color(red: 1.0, green: 0.85, blue: 0.5)  // Golden yellow
            ]

        // Morning (sunrise + 1h to 11 AM)
        } else if currentMinutes > sunriseMinutes + 60 && currentMinutes < 660 {
            matchedCondition = "MORNING"
            colors = [
                Color(red: 1.0, green: 0.85, blue: 0.4), // Bold yellow
                Color(red: 1.0, green: 0.9, blue: 0.6)   // Bright yellow
            ]

        // Midday (11 AM - 2 PM)
        } else if currentMinutes >= 660 && currentMinutes < 840 {
            matchedCondition = "MIDDAY"
            colors = [
                Color(red: 1.0, green: 0.85, blue: 0.3),  // Vibrant yellow
                Color(red: 1.0, green: 0.9, blue: 0.5)    // Strong yellow
            ]

        // Afternoon (2 PM until sunset window)
        } else if currentMinutes >= 840 && currentMinutes < sunsetMinutes - 30 {
            matchedCondition = "AFTERNOON (\(840)-\(sunsetMinutes - 30))"
            colors = [
                Color(red: 1.0, green: 0.75, blue: 0.3),  // Deep golden
                Color(red: 1.0, green: 0.85, blue: 0.5)   // Golden yellow
            ]

        // Sunset window (30 min before to 30 min after)
        } else if abs(currentMinutes - sunsetMinutes) <= 30 {
            matchedCondition = "SUNSET"
            colors = [
                Color(red: 1.0, green: 0.4, blue: 0.1),  // Deep orange
                Color(red: 1.0, green: 0.3, blue: 0.3),  // Red-orange
                Color(red: 0.6, green: 0.2, blue: 0.5)   // Deep purple
            ]

        // Evening (sunset + 1h to 10 PM)
        } else if currentMinutes > sunsetMinutes + 60 && currentMinutes < 1320 {
            matchedCondition = "EVENING"
            colors = [
                Color(red: 0.4, green: 0.2, blue: 0.6),  // Purple
                Color(red: 0.3, green: 0.3, blue: 0.5)   // Deep blue
            ]

        // Night (10 PM - 4 AM) / Default
        } else {
            matchedCondition = "NIGHT/DEFAULT"
            colors = [
                Color(red: 0.6, green: 0.8, blue: 1.0),  // Light sky blue
                Color(red: 0.7, green: 0.85, blue: 1.0)  // Lighter blue
            ]
        }

        #if DEBUG
        print("   ✅ Matched: \(matchedCondition)")
        #endif

        // Return colors without additional opacity adjustment
        let adjustedColors = colors

        return LinearGradient(
            gradient: Gradient(colors: adjustedColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Helper function for easier SwiftUI integration
    static func gradient(for routine: RoutineItem, sunrise: Date, sunset: Date) -> LinearGradient? {
        guard let startTime = routine.startTime else { return nil }
        return gradientForTime(startTime, sunrise: sunrise, sunset: sunset)
    }
}

// Extension for RoutineItem to make it easier to use
extension RoutineItem {
    func timeOfDayGradient(sunrise: Date, sunset: Date) -> LinearGradient? {
        return TimeOfDayGradient.gradient(for: self, sunrise: sunrise, sunset: sunset)
    }
}
