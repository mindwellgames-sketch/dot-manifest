import Foundation
import CoreLocation

struct SolarTimes {
    let sunrise: Date
    let sunset: Date
    let calculatedDate: Date
    let location: CLLocationCoordinate2D
}

class SolarCalculator {
    private var cachedTimes: SolarTimes?

    // Calculate sunrise and sunset for a given location and date
    func calculateSolarTimes(for location: CLLocation, on date: Date = Date()) -> SolarTimes {
        // Check cache first
        if let cached = cachedTimes,
           Calendar.current.isDate(cached.calculatedDate, inSameDayAs: date),
           cached.location.latitude == location.coordinate.latitude,
           cached.location.longitude == location.coordinate.longitude {
            return cached
        }

        // Use a simpler, more reliable algorithm
        let solarTimes = calculateSimpleSolarTimes(for: location, on: date)

        // Cache the result
        cachedTimes = solarTimes

        return solarTimes
    }

    // Simplified solar calculation using the sunset equation
    private func calculateSimpleSolarTimes(for location: CLLocation, on date: Date) -> SolarTimes {
        let coordinate = location.coordinate
        _ = Calendar.current
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current

        // Get day of year
        let dayOfYear = utcCalendar.ordinality(of: .day, in: .year, for: date) ?? 1

        // Calculate solar declination (simplified)
        let declinationAngle = 23.45 * sin((360.0 / 365.0) * (Double(dayOfYear) - 81) * .pi / 180.0)

        // Calculate hour angle
        let latRad = coordinate.latitude * .pi / 180.0
        let declRad = declinationAngle * .pi / 180.0

        let cosHourAngle = -tan(latRad) * tan(declRad)

        // If sun doesn't rise or set (polar regions), use defaults
        if cosHourAngle < -1 || cosHourAngle > 1 {
            return defaultSolarTimes(for: date)
        }

        let hourAngle = acos(cosHourAngle) * 180.0 / .pi

        // Calculate UTC times (in decimal hours)
        let solarNoon = 12.0 - (coordinate.longitude / 15.0)
        let sunriseHour = solarNoon - (hourAngle / 15.0)
        let sunsetHour = solarNoon + (hourAngle / 15.0)

        // Convert to Date objects in UTC
        let components = utcCalendar.dateComponents([.year, .month, .day], from: date)

        var sunriseComponents = components
        sunriseComponents.hour = Int(sunriseHour)
        sunriseComponents.minute = Int((sunriseHour - floor(sunriseHour)) * 60)
        sunriseComponents.second = 0
        sunriseComponents.timeZone = TimeZone(secondsFromGMT: 0)

        var sunsetComponents = components
        sunsetComponents.hour = Int(sunsetHour)
        sunsetComponents.minute = Int((sunsetHour - floor(sunsetHour)) * 60)
        sunsetComponents.second = 0
        sunsetComponents.timeZone = TimeZone(secondsFromGMT: 0)

        let sunrise = utcCalendar.date(from: sunriseComponents) ?? date
        let sunset = utcCalendar.date(from: sunsetComponents) ?? date

        return SolarTimes(
            sunrise: sunrise,
            sunset: sunset,
            calculatedDate: date,
            location: coordinate
        )
    }

    // Convert Julian day to Date
    private func julianDayToDate(_ jd: Double, for baseDate: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: baseDate)

        // Julian day fractional part represents the time of day
        let fractionalDay = jd - floor(jd)
        let hours = fractionalDay * 24.0
        let minutes = (hours - floor(hours)) * 60.0

        var dateComponents = DateComponents()
        dateComponents.year = components.year
        dateComponents.month = components.month
        dateComponents.day = components.day
        dateComponents.hour = Int(floor(hours))
        dateComponents.minute = Int(floor(minutes))
        dateComponents.second = 0
        // Keep UTC timezone for astronomical calculations
        dateComponents.timeZone = TimeZone(secondsFromGMT: 0)

        return calendar.date(from: dateComponents) ?? baseDate
    }

    // Default solar times if calculation fails or no location available
    private func defaultSolarTimes(for date: Date) -> SolarTimes {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        var sunriseComponents = components
        sunriseComponents.hour = 6
        sunriseComponents.minute = 30
        sunriseComponents.second = 0

        var sunsetComponents = components
        sunsetComponents.hour = 18
        sunsetComponents.minute = 30
        sunsetComponents.second = 0

        let sunrise = calendar.date(from: sunriseComponents) ?? date
        let sunset = calendar.date(from: sunsetComponents) ?? date

        return SolarTimes(
            sunrise: sunrise,
            sunset: sunset,
            calculatedDate: date,
            location: CLLocationCoordinate2D(latitude: 40.0, longitude: -100.0)
        )
    }

    // Clear cache (useful when location changes significantly)
    func clearCache() {
        cachedTimes = nil
    }
}
